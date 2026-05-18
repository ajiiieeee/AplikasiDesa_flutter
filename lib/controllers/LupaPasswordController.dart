import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../auth/OtpVerifikasi.dart';

class LupaPasswordController extends ChangeNotifier {
  String _noHp = '';
  bool _isLoading = false;

  String get noHp => _noHp;
  bool get isLoading => _isLoading;

  void setNoHp(String value) {
    _noHp = value;
    notifyListeners();
  }

  Future<void> sendOtp(
    BuildContext context, {
    required void Function({
      required String message,
      required Color backgroundColor,
      IconData? icon,
    })
    showSnackbar,
  }) async {
    if (_noHp.isEmpty || _noHp.length < 10) {
      showSnackbar(
        message: 'Masukkan nomor HP yang valid',
        backgroundColor: Colors.red,
        icon: Icons.warning,
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseURL/forgot-password'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
        body: json.encode({'no_hp': _noHp}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 200) {
        showSnackbar(
          message: data['message'] ?? 'Kode OTP berhasil dikirim',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(noHp: _noHp),
            ),
          );
        });
      } else {
        showSnackbar(
          message: data['message'] ?? 'Gagal mengirim OTP',
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      showSnackbar(
        message: 'Terjadi kesalahan: $e',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
