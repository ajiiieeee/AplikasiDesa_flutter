import 'package:flutter/material.dart';
import 'package:digitalv/screens/splash_screen.dart';
import 'package:digitalv/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? token = await SecureStorageService.instance.getToken();
  String role = await SecureStorageService.instance.getRole();

  runApp(MyApp(isLoggedIn: token != null && token.isNotEmpty, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;
  const MyApp({super.key, required this.isLoggedIn, this.role = 'warga'});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Village Desa Rambipuji',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16A34A)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const SplashScreen(),
    );
  }
}
