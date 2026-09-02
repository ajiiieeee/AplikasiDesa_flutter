import 'package:flutter/material.dart';

// Base URL Server (Ubah jika running local Laragon: misal 'http://10.0.2.2/project-desa-rambipuji/public' untuk Android emulator atau 'http://localhost/project-desa-rambipuji/public' untuk Web/Chrome)
const String serverURL = "https://desarambipuji-jember.com";

// Base URL API
const String baseURL = "$serverURL/api";

const Map<String, String> headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

void errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Text(text),
      duration: const Duration(seconds: 3),
    ),
  );
}