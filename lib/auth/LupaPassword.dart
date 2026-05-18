import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../controllers/LupaPasswordController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';

class LupaPassword extends StatelessWidget {
  const LupaPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LupaPasswordController(),
      child: Consumer<LupaPasswordController>(
        builder:
            (context, controller, _) => Scaffold(
              resizeToAvoidBottomInset: true,
              body: Stack(
                children: [
                  // Background SVG
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

                  // Konten utama
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Lupa Password?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Text(
                            'Masukkan nomor HP akun Anda, kami akan mengirimkan kode OTP melalui WhatsApp',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 40),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: controller.setNoHp,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Masukkan nomor HP',
                                prefixIcon: Icon(Icons.phone_android),
                                hintStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),

                          // Beri jarak antar widget
                          const SizedBox(height: 24),

                          // Tombol Kirim OTP
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  controller.isLoading
                                      ? null
                                      : () {
                                        if (controller.noHp.isEmpty ||
                                            controller.noHp.length < 10) {
                                          showCustomSnackbar(
                                            context: context,
                                            message:
                                                'Masukkan nomor HP yang valid',
                                            backgroundColor: Colors.red,
                                            icon: Icons.error,
                                          );
                                          return;
                                        }

                                        controller.sendOtp(
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
                                backgroundColor: Colors.lightBlueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  controller.isLoading
                                      ? const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      )
                                      : Text(
                                        'Kirim Kode OTP',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          // Tombol kembali
                          // TextButton(
                          //   onPressed: () {
                          //     Navigator.pop(context);
                          //   },
                          //   child: const Text(
                          //     '← Kembali ke Login',
                          //     style: TextStyle(
                          //       color: Colors.white70,
                          //       fontSize: 14,
                          //     ),
                          //   ),
                          // ),
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
}
