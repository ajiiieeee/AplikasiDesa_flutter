import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {

  static const String apiKey = "AIzaSyA0PxIjEndyxIxKOipR9TBoLrCLIqcXNSk";

  static Future<String> sendMessage(String message) async {

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey"
    );

    try {
      
      await Future.delayed(Duration(seconds: 2));

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Kamu adalah chatbot pelayanan desa.

Tugasmu membantu masyarakat tentang:
- syarat membuat KTP
- syarat membuat KK
- syarat akta kelahiran
- syarat surat miskin
- cara pengajuan surat di aplikasi desa

Jika pertanyaan tidak berhubungan dengan pelayanan desa,
jawab: Maaf saya hanya membantu pelayanan desa.

Pertanyaan:
$message
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];

      } 

      else if (response.statusCode == 429) {

        return "Server AI sedang sibuk, silakan coba lagi sebentar.";

      } 

      else if (response.statusCode == 403) {

        return "API key tidak memiliki izin.";

      }

      else {

        print(response.body);
        return "AI Error ${response.statusCode}";

      }

    } catch (e) {

      print(e);
      return "Tidak dapat terhubung ke server AI.";

    }

  }
}