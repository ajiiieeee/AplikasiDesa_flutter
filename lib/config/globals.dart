import 'package:flutter/material.dart';

// Base URL untuk debug Chrome
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