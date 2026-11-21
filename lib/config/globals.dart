import 'package:flutter/material.dart';

// Base URL Server (Ubah jika running local Laragon: misal 'http://10.0.2.2/project-desa-rambipuji/public' untuk Android emulator atau 'http://localhost/project-desa-rambipuji/public' untuk Web/Chrome)
const String serverURL = "https://desarambipuji-jember.com";

// Base URL API
const String baseURL = "$serverURL/api";

const String appUserAgent = "Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36";

const Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'User-Agent': appUserAgent,
};

Map<String, String> getApiHeaders({String? token, bool isJson = true}) {
  return {
    if (isJson) 'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
    'User-Agent': appUserAgent,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

void errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Text(text),
      duration: const Duration(seconds: 3),
    ),
  );
}