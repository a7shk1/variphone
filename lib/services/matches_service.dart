import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/matches_models.dart';

class MatchesService {
  static const String _url =
      'https://a7shk1.github.io/liveonsat/matches/filtered_matches.json';

  /// يجلب دائمًا نسخة جديدة (بدون كاش)
  static Future<TodayResponse> fetchFresh() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final uri = Uri.parse('$_url?t=$now'); // كسر الكاش
    final res = await http.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-store, no-cache, must-revalidate, max-age=0',
        'Pragma': 'no-cache',
        'Connection': 'close',
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }

    final text = utf8.decode(res.bodyBytes);
    final data = json.decode(text) as Map<String, dynamic>;
    return TodayResponse.fromJson(data);
  }

  /// ✅ alias علشان توافق الكود القديم
  static Future<TodayResponse> fetch({bool force = false}) {
    return fetchFresh();
  }
}
