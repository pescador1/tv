import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    
    // Request permission for iOS
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
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
              setState(() {
                hasError = true;
                isLoading = false;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse('https://app.hr-tech.site/'));
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

  Widget _buildLoadingScreen() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tv, size: 90, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              'HR TV',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              'جاري تحميل القنوات...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoInternetScreen() {
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
          const Text(
            'لا يوجد اتصال بالإنترنت',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          const Text(
            'يرجى التحقق من اتصالك بالشبكة والمحاولة مجدداً.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
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
