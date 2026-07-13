// lib/services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Ketersediaan model & kuota free-tier Gemini beda-beda tergantung key/akun
  // (ada yang "no longer available to new users", ada yang limit kuotanya 0).
  // Coba berurutan sampai ada yang berhasil.
  static const _models = [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-flash-latest',
  ];

  static Future<String> getRecommendation({
    required String apiKey,
    required List<String> ingredients,
    required String mood,
    required String mealTime,
    String? customQuestion,
  }) async {
    final hasCustomQuestion = customQuestion != null && customQuestion.trim().isNotEmpty;

    final prompt = hasCustomQuestion
        ? '''
Kamu adalah asisten masak yang ramah dan membantu merekomendasikan menu makanan sehari-hari.

Permintaan pengguna: "${customQuestion.trim()}"
Waktu makan sekarang: $mealTime.
Mood pengguna saat ini: $mood.
Bahan yang tersedia di kulkas: ${ingredients.isEmpty ? 'tidak ada data bahan' : ingredients.join(', ')}.

Jawab permintaan pengguna di atas dengan SATU rekomendasi menu makanan yang sesuai, dalam Bahasa Indonesia.
Perhatikan baik-baik preferensi atau pantangan yang disebutkan pengguna (misal tanpa bahan tertentu, level pedas, porsi, dsb).
Jawab singkat, maksimal 3 kalimat, dengan nada ramah dan menyemangati.
'''
        : '''
Kamu adalah asisten masak yang ramah dan membantu merekomendasikan menu makanan sehari-hari.

Waktu makan sekarang: $mealTime.
Mood pengguna saat ini: $mood.
Bahan yang tersedia di kulkas: ${ingredients.isEmpty ? 'tidak ada data bahan' : ingredients.join(', ')}.

Berikan SATU rekomendasi menu makanan yang cocok untuk situasi ini, dalam Bahasa Indonesia.
Jawab singkat, maksimal 3 kalimat, dengan nada ramah dan menyemangati.
Kalau memungkinkan, manfaatkan bahan yang ada di kulkas supaya tidak terbuang sia-sia.
''';

    Exception? lastError;
    for (final model in _models) {
      try {
        return await _callModel(model: model, apiKey: apiKey, prompt: prompt);
      } catch (e) {
        final msg = e.toString().toLowerCase();
        // Hanya berhenti lebih awal kalau errornya soal API key itu sendiri —
        // itu akan gagal untuk model manapun juga, jadi percuma dicoba ulang.
        final isAuthError = msg.contains('api key not valid') ||
            msg.contains('api_key_invalid') ||
            msg.contains('permission_denied') ||
            msg.contains('unauthenticated') ||
            msg.contains('api key expired');
        lastError = e is Exception ? e : Exception(e.toString());
        if (isAuthError) rethrow;
        // Selain itu (quota habis, model dihentikan, model tidak ada, dll) → coba model berikutnya.
      }
    }
    throw lastError ?? Exception('Semua model Gemini gagal diakses.');
  }

  static Future<String> _callModel({
    required String model,
    required String apiKey,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Gagal menghubungi AI (kode ${response.statusCode})';
      try {
        final err = jsonDecode(response.body);
        final apiMessage = err['error']?['message'];
        if (apiMessage != null) message = apiMessage.toString();
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(response.body);
    final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
    if (text == null || text.toString().trim().isEmpty) {
      throw Exception('Respons AI kosong, coba lagi.');
    }
    return text.toString().trim();
  }
}
