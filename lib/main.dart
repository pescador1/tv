import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'constants.dart';
import 'screens/login_screen.dart';
import 'services/app_language.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Force Landscape Orientation across the entire application
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await AppLanguage.init();

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
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.currentLanguage,
      builder: (context, lang, _) {
        final isRtl = AppLanguage.isRtl;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'HR TV',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Constants.primaryColor,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Constants.bgColor,
            fontFamily: 'Tajawal',
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            );
          },
          home: const LoginScreen(),
        );
      },
    );
  }
}
