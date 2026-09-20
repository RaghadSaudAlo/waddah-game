import 'dart:convert';
import 'package:http/http.dart' as http;

class DiagnosisService {
  static const String baseUrl = "http://127.0.0.1:8002";

  static Future<Map<String, dynamic>> diagnose({
    required String word,
    required String phoneme,
    required String position,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/diagnosis-mock'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "word": word,
        "target_phoneme": phoneme,
        "position": position,
      }),
    );

    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      throw Exception("Diagnosis failed: $decodedBody");
    }
  }

  static Future<Map<String, dynamic>> diagnoseWithAudio({
    required String audioPath,
    required String word,
    required String phoneme,
    required String position,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/diagnosis-upload'),
    );

    request.fields['word'] = word;
    request.fields['target_phoneme'] = phoneme;
    request.fields['position'] = position;

    request.files.add(
      await http.MultipartFile.fromPath('audio_file', audioPath),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final decodedBody = utf8.decode(response.bodyBytes);

    if (response.statusCode == 200) {
      return jsonDecode(decodedBody) as Map<String, dynamic>;
    } else {
      throw Exception("Diagnosis upload failed: $decodedBody");
    }
  }
}