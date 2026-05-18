import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:digitalv/controllers/OtpVerifikasiController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';

class OtpVerificationPage extends StatelessWidget {
  final String noHp;

  const OtpVerificationPage({super.key, required this.noHp});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OtpVerifikasiController(),
      child: Consumer<OtpVerifikasiController>(
        builder:
            (context, controller, _) => Scaffold(
              resizeToAvoidBottomInset: true,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Verifikasi',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'Masukkan kode OTP yang telah kami kirim ke WhatsApp Anda',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 40),

                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            obscureText: false,
                            enabled: !controller.isLoading,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(10),
                              fieldHeight: 50,
                              fieldWidth: 45,
                              activeColor: Colors.blueAccent,
                              inactiveColor: Colors.grey[300]!,
                              selectedColor: Colors.lightBlue,
                            ),
                            textStyle: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                            animationDuration: const Duration(
                              milliseconds: 300,
                            ),
                            enableActiveFill: false,
                            onChanged: (value) {
                              controller.setOtpCode(value);
                            },
                            onCompleted: (value) {
                              if (!controller.isLoading) {
                                controller.verifyOtp(
                                  context,
                                  noHp: noHp,
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
                              }
                            },
                            keyboardType: TextInputType.number,
                          ),

                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  controller.isLoading
                                      ? null
                                      : () => controller.verifyOtp(
                                        context,
                                        noHp: noHp,
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
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlueAccent,
                                foregroundColor: Colors.white,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child:
                                  controller.isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                      : Text(
                                        'Verifikasi Kode OTP',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
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
}
