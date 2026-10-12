import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/LoginRegis.dart';
import '../config/globals.dart';

class ResetPasswordController extends ChangeNotifier {
  String email = '';
  String otp = '';
  String newPassword = '';
  String confirmPassword = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String get noHp => email;

  void setEmail(String value) {
    email = value.trim();
    notifyListeners();
  }

  void setNoHp(String value) {
    setEmail(value);
  }

  void setOtp(String value) {
    otp = value.trim();
    notifyListeners();
  }

  void setNewPassword(String value) {
    newPassword = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    confirmPassword = value;
    notifyListeners();
  }

  Future<void> resetPassword(
    BuildContext context, {
    required void Function({
      required String message,
      required Color backgroundColor,
      IconData? icon,
    })
    showSnackbar,
  }) async {
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showSnackbar(
        message: "Password tidak boleh kosong",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    if (newPassword.length < 8) {
      showSnackbar(
        message: "Password minimal 8 karakter",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    final hasUpper = newPassword.contains(RegExp(r'[A-Z]'));
    final hasLower = newPassword.contains(RegExp(r'[a-z]'));
    final hasDigit = newPassword.contains(RegExp(r'[0-9]'));
    if (!hasUpper || !hasLower || !hasDigit) {
      showSnackbar(
        message: "Password harus mengandung huruf besar, huruf kecil, dan angka",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showSnackbar(
        message: "Konfirmasi password tidak cocok",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseURL/reset-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email.trim(),
          'otp': otp.trim(),
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = null;
      }

      String message = 'Reset password gagal';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (data is Map && data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            message = firstVal.first.toString();
          }
        }
      }

      if (response.statusCode == 200 && data is Map && data['status'] == 200) {
        showSnackbar(
          message: message.isNotEmpty ? message : 'Password berhasil direset',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const Loginregis()),
              (route) => false,
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
