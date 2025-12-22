import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/channel.dart';
import '../core/m3u_parser.dart';

class ChannelsRepository {
  static const _timeout = Duration(seconds: 15);

  // Headers بسيطة حتى يصير الجلب ثابت على iOS + GitHub raw
  static const Map<String, String> _headers = {
    'User-Agent': 'VarIPTV/1.0 (Flutter)',
    'Accept': '*/*',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };

  Future<List<Channel>> fetchChannelsFromUrl(String playlistUrl) async {
    final uri = Uri.parse(playlistUrl);

    final res = await http.get(uri, headers: _headers).timeout(_timeout);

    if (res.statusCode != 200) {
      throw Exception('فشل بجلب playlist: ${res.statusCode} (${uri.host})');
    }

    final text = utf8.decode(res.bodyBytes);
    final channels = parseM3U(text);

    if (channels.isEmpty) {
      throw Exception('الملف انجاب بس ما بي قنوات (m3u فارغ أو صيغة غير مدعومة)');
    }

    return channels;
  }
}
