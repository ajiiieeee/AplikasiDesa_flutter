import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../config/globals.dart';
import '../widgets/snackbarcustom.dart';
import '../auth/LoginRegis.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nikController       = TextEditingController();
  final _emailController     = TextEditingController();
  final _noHpController      = TextEditingController();
  final _passwordController  = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _isLoading         = false;
  bool _showPassword      = false;
  bool _showKonfirmasi    = false;

  static const _primaryGreen = Color(0xFF16A34A);
  static const _bgColor      = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _nikController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseURL/register'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'nik'      : _nikController.text.trim(),
          'email'    : _emailController.text.trim(),
          'no_hp'    : _noHpController.text.trim(),
          'password' : _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        showCustomSnackbar(
          context: context,
          message: 'Akun berhasil diaktivasi! Silakan login.',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Loginregis()),
        );
      } else if (response.statusCode == 409) {
        showCustomSnackbarAtTop(
          context: context,
          message: data['message'] ?? 'NIK sudah diaktivasi, silakan login.',
          backgroundColor: Colors.orange,
          icon: Icons.warning,
        );
      } else if (response.statusCode == 404) {
        showCustomSnackbarAtTop(
          context: context,
          message: 'NIK tidak ditemukan dalam data penduduk desa. Hubungi kantor desa.',
          backgroundColor: Colors.red,
          icon: Icons.person_off,
        );
      } else if (response.statusCode == 422) {
        // Validation errors
        String msg = 'Validasi gagal.';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            msg = errors.values
                .map((e) => (e is List) ? e.first.toString() : e.toString())
                .join('\n');
          }
        } else {
          msg = data['message'] ?? msg;
        }
        showCustomSnackbarAtTop(
          context: context,
          message: msg,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      } else {
        showCustomSnackbarAtTop(
          context: context,
          message: data['message'] ?? 'Gagal mengaktivasi akun.',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } on SocketException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        backgroundColor: Colors.orange,
        icon: Icons.wifi_off,
      );
    } on TimeoutException {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Koneksi timeout, coba lagi.',
        backgroundColor: Colors.orange,
        icon: Icons.timer_off,
      );
    } catch (e) {
      showCustomSnackbarAtTop(
        context: context,
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1F2937), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primaryGreen.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 44,
                          color: _primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aktivasi Akun Warga',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Masukkan NIK yang terdaftar di desa\nuntuk mengaktifkan akun Anda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Info box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFB45309), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hanya warga yang NIK-nya sudah terdaftar di sistem desa yang dapat mendaftar.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF92400E),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form Card
                Container(
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
                    children: [
                      // NIK
                      _buildField(
                        controller: _nikController,
                        label: 'NIK (16 digit)',
                        icon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
                          if (v.trim().length != 16) return 'NIK harus 16 digit';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Email
                      _buildField(
                        controller: _emailController,
                        label: 'Email Aktif',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v.trim())) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // No HP
                      _buildField(
                        controller: _noHpController,
                        label: 'No. HP / WhatsApp',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'No. HP wajib diisi';
                          if (v.trim().length < 10) return 'No. HP minimal 10 digit';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Password
                      _buildPasswordField(
                        controller: _passwordController,
                        label: 'Password',
                        isVisible: _showPassword,
                        onToggle: () => setState(() => _showPassword = !_showPassword),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib diisi';
                          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(v)) {
                            return 'Min. 8 karakter, huruf besar, huruf kecil, dan angka';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      // Konfirmasi Password
                      _buildPasswordField(
                        controller: _konfirmasiController,
                        label: 'Konfirmasi Password',
                        isVisible: _showKonfirmasi,
                        onToggle: () => setState(() => _showKonfirmasi = !_showKonfirmasi),
                        validator: (v) {
                          if (v != _passwordController.text) return 'Password tidak cocok';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Aktifkan Akun',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Link ke Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const Loginregis()),
                    ),
                    child: RichText(
                      text: TextSpan(
                        text: 'Sudah punya akun? ',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                        children: [
                          TextSpan(
                            text: 'Login',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: _primaryGreen, size: 20),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: _primaryGreen, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF9CA3AF),
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorMaxLines: 2,
      ),
    );
  }
}
