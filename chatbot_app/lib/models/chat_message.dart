import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String id;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

// API CONFIG — GROQ İÇİN
class ApiConfig {
  static String get groqApiKey => dotenv.env['API_KEY'] ?? '';

  static const String groqModelUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  static bool get hasKey => groqApiKey.isNotEmpty;
}

// CHAT REPO (GROQ VERSION)
class ChatRepository {
  final http.Client _client = http.Client();

  ChatRepository();

  Future<String> getAIResponse(String userMessage) async {
    try {
      if (!ApiConfig.hasKey) {
        throw Exception(
          '❌ API key is missing! Please set it in the .env file.',
        );
      }

      return await _getGroqResponse(userMessage);
    } catch (e) {
      print('API Error: $e');
      return 'Sorry, I am currently unable to process your request.';
    }
  }

  // ⭐ GROQ API REQUEST
  Future<String> _getGroqResponse(String userMessage) async {
    final url = Uri.parse(ApiConfig.groqModelUrl);

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${ApiConfig.groqApiKey}",
    };

    final body = jsonEncode({
      "model": "llama-3.1-8b-instant",
      "messages": [
        {"role": "user", "content": userMessage},
      ],
      "temperature": 0.7,
      "max_tokens": 300,
    });

    final response = await _client.post(url, headers: headers, body: body);

    // OK
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json["choices"][0]["message"]["content"].trim();
    }

    // ERRORS
    if (response.statusCode == 401) {
      throw Exception("❌ Unauthorized! Please check your API key.");
    } else if (response.statusCode == 429) {
      throw Exception("⚠️ Rate limit exceeded! Please try again later.");
    }

    throw Exception(
      "Unsuccessful API call: ${response.statusCode}\n${response.body}",
    );
  }

  void dispose() => _client.close();
}
