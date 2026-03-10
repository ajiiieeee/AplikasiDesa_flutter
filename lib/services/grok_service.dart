import 'dart:convert';
import 'package:http/http.dart' as http;

class GrokService {

  static const String apiKey = "xai-C13PhsyCTtxwpIoJbQpJ4W4s4MdRQtJ7zZbC9ksQ1Dgq0eOXKERF3xcp4NncVCpyqi1N1cBm3H2pXfmc";

  static Future<String> sendMessage(String message) async {

    final url = Uri.parse("https://api.x.ai/v1/chat/completions");

    try {

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey"
        },
        body: jsonEncode({
          "messages": [
            {
              "role": "system",
              "content": "Kamu adalah chatbot pelayanan desa."
            },
            {
              "role": "user",
              "content": message
            }
          ],
          "model": "grok-4-latest",
          "stream": false,
          "temperature": 0
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];

      } else {

        return "Server AI error (${response.statusCode})";

      }

    } catch (e) {

      print(e);
      return "Tidak dapat terhubung ke server AI.";

    }

  }
}