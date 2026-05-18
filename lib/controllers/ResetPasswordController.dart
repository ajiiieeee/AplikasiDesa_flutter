import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/LoginRegis.dart';
import '../config/globals.dart';

class ResetPasswordController extends ChangeNotifier {
  String noHp = '';
  String otp = '';
  String newPassword = '';
  String confirmPassword = '';
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setNoHp(String value) {
    noHp = value;
    notifyListeners();
  }

  void setOtp(String value) {
    otp = value;
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
        icon: Icons.error,
      );
      return;
    }

    if (newPassword.length < 8) {
      showSnackbar(
        message: "Password minimal 8 karakter",
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showSnackbar(
        message: "Password tidak cocok",
        backgroundColor: Colors.red,
        icon: Icons.error,
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
          'no_hp': noHp,
          'otp': otp,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        showSnackbar(
          message: data['message'] ?? 'Password berhasil direset',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => Loginregis()),
              (route) => false,
            );
          }
        });
      } else {
        showSnackbar(
          message: data['message'] ?? 'Reset password gagal',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      showSnackbar(
        message: "Terjadi kesalahan: $e",
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
