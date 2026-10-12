import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../auth/OtpVerifikasi.dart';

class LupaPasswordController extends ChangeNotifier {
  String _email = '';
  bool _isLoading = false;

  String get email => _email;
  String get noHp => _email;
  bool get isLoading => _isLoading;

  void setEmail(String value) {
    _email = value.trim();
    notifyListeners();
  }

  void setNoHp(String value) {
    setEmail(value);
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
    final cleanEmail = _email.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      showSnackbar(
        message: 'Masukkan format alamat email yang valid',
        backgroundColor: Colors.red,
        icon: Icons.warning_amber_rounded,
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
        body: json.encode({'email': cleanEmail}),
      );

      dynamic data;
      try {
        data = json.decode(response.body);
      } catch (_) {
        data = null;
      }

      String message = 'Gagal mengirim kode OTP.';
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
          message: message.isNotEmpty ? message : 'Kode OTP berhasil dikirim ke email',
          backgroundColor: Colors.green,
          icon: Icons.mark_email_read_rounded,
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationPage(email: cleanEmail),
              ),
            );
          }
        });
      } else {
        showSnackbar(
          message: message,
          backgroundColor: Colors.red,
          icon: Icons.error_rounded,
        );
      }
    } catch (e) {
      showSnackbar(
        message: 'Terjadi kesalahan koneksi: $e',
        backgroundColor: Colors.red,
        icon: Icons.wifi_off_rounded,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
