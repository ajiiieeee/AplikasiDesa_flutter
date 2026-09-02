import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/globals.dart';
import '../services/secure_storage_service.dart';

Future<Map<String, dynamic>?> fetchUserData() async {
  final token = await SecureStorageService.instance.getToken();

  if (token == null || token.isEmpty) {
    return null;
  }

  try {
    final response = await http.get(
      Uri.parse('$baseURL/getdata'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final data = json.decode(responseBody)['data'];
      return data;
    }
  } catch (e) {
    // silent fail
  }

  return null;
}
