import 'package:digitalv/widgets/bottom_navbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import '../shared/shared.dart';
import '../config/globals.dart';
import '../auth/LupaPassword.dart';
import '../auth/register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';
import '../services/secure_storage_service.dart';

class Loginregis extends StatefulWidget {
  const Loginregis({super.key});

  @override
  _LoginregisState createState() => _LoginregisState();
}

class _LoginregisState extends State<Loginregis> {
  bool isVisible = false;
  bool isPasswordVisible = false;
  final nikLoginController = TextEditingController();
  final loginPasswordController = TextEditingController();

  Future<void> simpanStatusLogin(String token) async {
    // Token disimpan di SecureStorage (terenkripsi)
    await SecureStorageService.instance.saveToken(token);
  }



 Future<void> login(BuildContext context) async {
    final String nikLogin = nikLoginController.text.trim();
    final String passwordLogin = loginPasswordController.text.trim();

    if (nikLogin.isEmpty || passwordLogin.isEmpty) {
      showCustomSnackbarAtTop(
        context: context,
        message: 'NIK dan Password harus diisi',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseURL/login'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({'nik': nikLogin, 'password': passwordLogin}),
      );

      final responseData = jsonDecode(response.body);

      //  Cetak response status dan body untuk debugging
      print('📥 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200 &&
          responseData['status'] == 'success' &&
          responseData['data'] != null) {
        final data = responseData['data'];

        final String namaPengguna = data['nama'] ?? 'Pengguna';
        final String nikPengguna = data['nik'] ?? '';
        final String? token = data['token'];
        final String roleName = data['role_name'] ?? 'warga';
        final int level = (data['level'] as num?)?.toInt() ?? 5;

        // Admin Desa (level 1) dibatasi tidak bisa login dari aplikasi mobile (hanya web)
        if (level == 1) {
          showCustomSnackbarAtTop(
            context: context,
            message: 'Akun Admin Desa (Level 1) hanya dapat diakses melalui portal Website Desa.',
            backgroundColor: Colors.orange,
            icon: Icons.warning,
          );
          return;
        }

        await _saveUserData(namaPengguna, nikPengguna);
        await _saveRoleData(roleName, level);

        if (token != null) {
          await simpanStatusLogin(token);
          print('🔐 TOKEN YANG DISIMPAN: $token');
          print('👤 ROLE: $roleName (level $level)');
        }

        showCustomSnackbar(
          context: context,
          message: 'Selamat Datang, $namaPengguna!',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!context.mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavBar(role: roleName),
          ),
        );
      } else {
        String errorMessage = responseData['message'] ?? 'Login gagal.';
        if (responseData['errors'] != null && responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstErrorList = errors[firstKey];
            if (firstErrorList is List && firstErrorList.isNotEmpty) {
              errorMessage = firstErrorList.first.toString();
            }
          }
        }
        showCustomSnackbarAtTop(
          context: context,
          message: errorMessage,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } on SocketException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Gagal terhubung ke server backend. Pastikan server Laravel berjalan.',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
    } on http.ClientException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Gagal terhubung ke http://localhost:8000. Pastikan backend Laravel aktif & CORS diizinkan.',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
    } on TimeoutException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Koneksi timeout, coba lagi!',
        backgroundColor: Colors.orange,
        icon: Icons.timer_off,
      );
    } catch (e, stackTrace) {
      print('❗ ERROR: $e');
      print('🧾 STACKTRACE: $stackTrace');
      showCustomSnackbarAtTop(
        context: context,
        message: 'Terjadi kesalahan tak terduga: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    }
  }


  Future<void> _saveUserData(String nama, String nik) async {
    // Nama disimpan di SharedPreferences (non-sensitif)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
    // NIK disimpan di SecureStorage (sensitif)
    await SecureStorageService.instance.saveNik(nik);
  }

  Future<void> _saveRoleData(String roleName, int level) async {
    // Role & level disimpan di SecureStorage (sensitif)
    await SecureStorageService.instance.saveRole(roleName, level);
  }


  // Modal untuk Login
  void showLoginModal(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool modalPasswordVisible = false;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 50,
                            height: 5,
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Text(
                          "Login",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: nikLoginController,
                          decoration: const InputDecoration(
                            icon: Icon(Icons.person),
                            labelText: 'NIK',
                            border: OutlineInputBorder(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: loginPasswordController,
                          obscureText: !modalPasswordVisible,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setModalState(() {
                                  modalPasswordVisible = !modalPasswordVisible;
                                });
                              },
                              icon: Icon(
                                modalPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LupaPassword(),
                                ),
                              );
                            },
                            child: Text(
                              'Lupa Password?',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          margin: const EdgeInsets.only(left: 40),
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                login(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'LOGIN',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Desa Rambipuji
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withValues(alpha: 0.12),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/logo/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.account_balance,
                      size: 60,
                      color: primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Digital Village",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Pemerintah Desa Rambipuji",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Sistem Pelayanan Digital Resmi Warga Desa",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 40),

                // Card Ganti Password & Login
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lupa atau ingin mengganti password?",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LupaPassword(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.lock_reset_rounded, size: 20),
                          label: Text(
                            'Ganti Password',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),
                      Text(
                        "Sudah memiliki akun aktif?",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () => showLoginModal(context),
                          icon: const Icon(Icons.login_rounded, size: 20, color: primaryGreen),
                          label: Text(
                            'Masuk / Login',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: primaryGreen, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),
                      Text(
                        "Belum punya akun?",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: Color(0xFF0284C7)),
                          label: Text(
                            'Daftar / Aktivasi Akun',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0284C7), width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "© Digital Village Desa Rambipuji",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
