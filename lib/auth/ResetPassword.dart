import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:digitalv/controllers/ResetPasswordController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';

class ResetPasswordPage extends StatefulWidget {
  final String noHp;
  final String otp;

  const ResetPasswordPage({super.key, required this.noHp, required this.otp});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}
class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;

  late ResetPasswordController controller;

  @override
  void initState() {
    super.initState();
    controller = ResetPasswordController();
    controller.setNoHp(widget.noHp);
    controller.setOtp(widget.otp);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => controller,
      child: Consumer<ResetPasswordController>(
        builder:
            (context, controller, _) => Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      'assets/images/bk_password.svg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: 15,
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'Reset Password',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Masukkan password baru dan konfirmasi untuk melanjutkan.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 32),
                          buildTextField(
                            hint: 'Password Baru',
                            obscureText: !isPasswordVisible,
                            onChanged: controller.setNewPassword,
                            isVisible: isPasswordVisible,
                            onVisibilityToggle: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            hint: 'Konfirmasi Password',
                            obscureText: !isConfirmPasswordVisible,
                            onChanged: controller.setConfirmPassword,
                            isVisible: isConfirmPasswordVisible,
                            onVisibilityToggle: () {
                              setState(() {
                                isConfirmPasswordVisible =
                                    !isConfirmPasswordVisible;
                              });
                            },
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                            onPressed: () {
                                controller.resetPassword(
                                  context,
                                  showSnackbar: ({
                                    required String message,
                                    required Color backgroundColor,
                                    IconData? icon,
                                  }) {
                                    showCustomSnackbar(
                                      context: context,
                                      message: message,
                                      backgroundColor: backgroundColor,
                                      icon: icon,
                                    );
                                  },
                                );
                              },

                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.lightBlueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                              ),
                              child: Text(
                                'Reset Password',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget buildTextField({
    required String hint,
    required bool obscureText,
    required ValueChanged<String> onChanged,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: hint,
          border: InputBorder.none,
          hintStyle: GoogleFonts.poppins(),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey,
            ),
            onPressed: onVisibilityToggle,
          ),
        ),
      ),
    );
  }
}
