// Shared client for the Groq chat completions API used by the assistant and planner.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'openai/gpt-oss-120b';
  static const Duration _timeout = Duration(seconds: 45);
  static const int _maxRetries = 3;

  Future<Map<String, dynamic>> chat({
    required List<Map<String, dynamic>> messages,
    List<Map<String, dynamic>>? tools,
    double? temperature,
  }) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) throw Exception("GROQ_API_KEY missing in .env");

    final body = jsonEncode({
      "model": _model,
      "messages": messages,
      "tools": ?tools,
      if (tools != null) "tool_choice": "auto",
      "temperature": ?temperature,
    });

    http.Response? response;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(_timeout);

      if ((response.statusCode == 429 || response.statusCode >= 500) && attempt < _maxRetries - 1) {
        final waitSeconds = 2 * (attempt + 1);
        debugPrint('Groq limit/server error (${response.statusCode}). Retrying in ${waitSeconds}s...');
        await Future.delayed(Duration(seconds: waitSeconds));
        continue;
      }
      break;
    }

    if (response == null || response.statusCode != 200) {
      throw Exception('Groq API Error: ${response?.statusCode ?? 'Unknown'}');
    }

    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data['choices'][0]['message'] as Map);
  }
}
