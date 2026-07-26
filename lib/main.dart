import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Request notification permission (Android 13+ and iOS)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Subscribe to 'all' topic to receive push notifications
    await FirebaseMessaging.instance.subscribeToTopic('all');
    
    // Get device locale and subscribe to language-specific topic
    String langCode = Platform.localeName.split('_')[0].toLowerCase();
    if (['fr', 'en', 'es', 'ar'].contains(langCode)) {
      await FirebaseMessaging.instance.subscribeToTopic('lang_$langCode');
    }
  } catch (e) {
    print("Firebase initialization error: $e");
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HR TV',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  bool isLoading = true;
  bool hasError = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool isConnected = true;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();

    subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      bool currentConnection = !result.contains(ConnectivityResult.none);
      if (currentConnection != isConnected) {
        setState(() {
          isConnected = currentConnection;
          if (isConnected && hasError) {
            hasError = false;
            isLoading = true;
            controller.reload();
          }
        });
      }
    });

    if (isSupported) {
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent('Mozilla/5.0 (Linux; Android 10; Mobile) PanelTV_Official HRTV_App')
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..addJavaScriptChannel(
          'FlutterCast',
          onMessageReceived: (JavaScriptMessage message) {
            // سيتم تفعيل ميزة الكاست لاحقاً هنا
            print('Cast requested for: ${message.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('جاري فتح مشغل التلفاز...')),
            );
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                hasError = false;
              });
            },
            onPageFinished: (String url) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    isLoading = false;
                  });
                }
              });
            },
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    hasError = true;
                    isLoading = false;
                  });
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('https://app.hr-tech.site/'));

      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
      }
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() {
      hasError = false;
      isLoading = true;
    });
    controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!isSupported) return _buildUnsupportedDevice();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            if (isConnected)
              Opacity(
                opacity: (isLoading || hasError) ? 0.0 : 1.0,
                child: WebViewWidget(controller: controller),
              ),

            if (isLoading && !hasError && isConnected) _buildLoadingScreen(),
            if (hasError || !isConnected) _buildNoInternetScreen(),
          ],
        ),
      ),
    );
  }

  String _getLoadingMessage(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    if (lang.startsWith('ar')) {
      return 'جاري تحميل القنوات...';
    } else if (lang.startsWith('fr')) {
      return 'Chargement des chaînes...';
    } else if (lang.startsWith('es')) {
      return 'Cargando canales...';
    } else {
      return 'Loading channels...';
    }
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.tv, size: 80, color: Colors.blueAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'HR TV',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              _getLoadingMessage(context),
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInternetScreen() {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    String title = 'لا يوجد اتصال بالإنترنت';
    String message = 'يرجى التحقق من اتصالك بالشبكة والمحاولة مجدداً.';
    String btnText = 'إعادة المحاولة';

    if (lang.startsWith('fr')) {
      title = 'Pas de connexion Internet';
      message = 'Veuillez vérifier votre réseau et réessayer.';
      btnText = 'Réessayer';
    } else if (lang.startsWith('es')) {
      title = 'Sin conexión a Internet';
      message = 'Por favor comprueba tu red e inténtalo de nuevo.';
      btnText = 'Reintentar';
    } else if (!lang.startsWith('ar')) {
      title = 'No Internet Connection';
      message = 'Please check your network connection and try again.';
      btnText = 'Retry';
    }

    return Container(
      width: double.infinity,
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 100,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: Text(btnText, style: const TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsupportedDevice() {
    return const Scaffold(body: Center(child: Text('Platform not supported')));
  }
}
