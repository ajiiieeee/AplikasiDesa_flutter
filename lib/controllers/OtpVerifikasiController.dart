import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../auth/ResetPassword.dart';

class OtpVerifikasiController extends ChangeNotifier {
  String _email = '';
  String get email => _email;
  String get noHp => _email;

  String _otpCode = '';
  String get otpCode => _otpCode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void setNoHp(String value) {
    setEmail(value);
  }

  void setOtpCode(String value) {
    _otpCode = value.trim();
    notifyListeners();
  }

  Future<void> verifyOtp(
    BuildContext context, {
    String? email,
    String? noHp,
    required void Function({
      required String message,
      required Color backgroundColor,
      IconData? icon,
    })
    showSnackbar,
  }) async {
    final cleanEmail = (email ?? noHp ?? _email).trim();
    final cleanOtp = _otpCode.trim();

    if (cleanOtp.isEmpty || cleanOtp.length != 6) {
      showSnackbar(
        message: "Kode OTP harus 6 digit angka",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseURL/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'otp': cleanOtp, 'email': cleanEmail}),
      );

      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = null;
      }

      String message = 'Kode OTP tidak valid';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      if (response.statusCode == 200 && data is Map && data['status'] == 200) {
        showSnackbar(
          message: message.isNotEmpty ? message : "Kode OTP valid",
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => ResetPasswordPage(email: cleanEmail, otp: cleanOtp),
              ),
            );
          }
        });
      } else {
        showSnackbar(
          message: message,
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      showSnackbar(
        message: "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
