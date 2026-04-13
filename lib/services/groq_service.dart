import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {

  // 🔒 Sebaiknya nanti pindahkan ke .env
  static const String apiKey = "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";

  static Future<String> sendMessage(String message) async {

    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    try {

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "max_tokens": 300, 
          "temperature": 0.7,
          "messages": [
            {
              "role": "system",
              "content": """
Kamu adalah chatbot pelayanan desa di Indonesia.

Tugasmu:
- Menjawab persyaratan surat
- Menjelaskan cara pengajuan surat
- Memberikan informasi administrasi desa

Jawab dengan singkat, jelas, dan bahasa Indonesia.

Jika di luar topik:
jawab: Maaf, saya hanya membantu pelayanan desa.
"""
            },
            {
              "role": "user",
              "content": message.trim()
            }
          ]
        }),
      );

      // 🔍 DEBUG (penting kalau error)
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data["choices"] != null &&
            data["choices"].isNotEmpty) {

          return data["choices"][0]["message"]["content"] ?? "Tidak ada jawaban.";

        } else {

          return "AI tidak memberikan respon.";

        }

      } else {

        return "Server AI error (${response.statusCode})";

      }

    } catch (e) {

      print("ERROR: $e");
      return "Tidak dapat terhubung ke server AI.";

    }

  }
}