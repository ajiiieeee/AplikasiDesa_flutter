import 'package:flutter/material.dart';

// Base URL utama
 const String serverURL = "http://192.168.1.22:8000";
// const String serverURL = "http://192.168.1.22:8000";

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
