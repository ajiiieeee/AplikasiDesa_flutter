import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:digitalv/controllers/OtpVerifikasiController.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:digitalv/widgets/snackbarcustom.dart';

class OtpVerificationPage extends StatelessWidget {
  final String noHp;

  const OtpVerificationPage({super.key, required this.noHp});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);

    return ChangeNotifierProvider(
      create: (_) => OtpVerifikasiController(),
      child: Consumer<OtpVerifikasiController>(
        builder: (context, controller, _) => Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F2937),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge Icon Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryGreen.withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mark_chat_read_rounded,
                        size: 48,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Verifikasi Kode OTP',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Masukkan 6-digit kode OTP yang telah dikirim ke WhatsApp ',
                          ),
                          TextSpan(
                            text: noHp,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Card Form Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode OTP',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 16),

                          PinCodeTextField(
                            appContext: context,
                            length: 6,
                            obscureText: false,
                            enabled: !controller.isLoading,
                            animationType: AnimationType.fade,
                            pinTheme: PinTheme(
                              shape: PinCodeFieldShape.box,
                              borderRadius: BorderRadius.circular(12),
                              fieldHeight: 52,
                              fieldWidth: 44,
                              activeColor: primaryGreen,
                              inactiveColor: const Color(0xFFE2E8F0),
                              selectedColor: primaryGreen,
                              activeFillColor: Colors.white,
                              inactiveFillColor: const Color(0xFFF8FAFC),
                              selectedFillColor: Colors.white,
                            ),
                            textStyle: GoogleFonts.poppins(
                              color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            animationDuration: const Duration(milliseconds: 300),
                            enableActiveFill: true,
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

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: controller.isLoading
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
                              icon: controller.isLoading
                                  ? const SizedBox.shrink()
                                  : const Icon(Icons.check_circle_outline_rounded, size: 20),
                              label: controller.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      'Verifikasi Kode OTP',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
