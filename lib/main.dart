import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:digitalv/screens/splash_screen.dart';
import 'package:digitalv/services/secure_storage_service.dart';
import 'package:digitalv/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase & Push Notification
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  String? token = await SecureStorageService.instance.getToken();
  String role = await SecureStorageService.instance.getRole();

  if (token != null && token.isNotEmpty) {
    try {
      NotificationService.instance.syncTokenToBackend();
    } catch (_) {}
  }

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;
  const MyApp({super.key, required this.isLoggedIn, this.role = 'warga'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: 'Digital Village Desa Rambipuji',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF004AAD)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const SplashScreen(),
    );
  }
}
