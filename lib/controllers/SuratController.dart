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
      if (data is Map<String, dynamic>) {
        return data;
      }
    } else {
      print('⚠️ /getdata status ${response.statusCode}, mencoba fallback ke /getprofil...');
    }

    // Fallback: panggil /getprofil jika /getdata bermasalah
    final fallbackRes = await http.get(
      Uri.parse('$baseURL/getprofil'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (fallbackRes.statusCode == 200) {
      final pData = json.decode(fallbackRes.body)['data'];
      if (pData is Map<String, dynamic>) {
        return {
          'nama': pData['nama_lengkap'] ?? '',
          'nama_lengkap': pData['nama_lengkap'] ?? '',
          'nik': pData['nik'] ?? '',
          'no_kk': pData['no_kk'] ?? '',
          'dusun': pData['dusun'] ?? '',
          'alamat': pData['alamat'] ?? '',
          'rt': pData['rt'] ?? '',
          'rw': pData['rw'] ?? '',
        };
      }
    }
  } catch (e) {
    print('❌ Error fetchUserData: $e');
  }

  return null;
}
