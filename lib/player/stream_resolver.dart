import 'dart:convert';
import 'package:http/http.dart' as http;

class ResolvedStream {
  final String url;
  final Map<String, String> headers;
  const ResolvedStream(this.url, this.headers);
}

class StreamResolver {
  static Future<ResolvedStream> resolve(
    String rawUrl, {
    Map<String, String>? headers,
    bool preferHls = false,
  }) async {
    final baseUri = Uri.parse(rawUrl);
    final h = _merge(_defaultHeaders(baseUri), headers ?? {});

    // 0) iOS: جرّب HLS candidates أولاً
    if (preferHls) {
      final candidates = _hlsCandidates(rawUrl);
      for (final c in candidates) {
        final ok = await _tryM3u8(Uri.parse(c), h);
        if (ok != null) return ResolvedStream(ok.requestUrl, ok.headers);
      }
    }

    // 1) Try HEAD
    final head = await _safeHead(baseUri, h);
    if (head != null) {
      if (_looksLikeStream(head.requestUrl, head.contentType)) {
        // إذا تفضّل HLS وحصلنا TS/unknown، جرّب candidates بناء على URL النهائي
        if (preferHls) {
          final candidates = _hlsCandidates(head.requestUrl);
          for (final c in candidates) {
            final ok = await _tryM3u8(Uri.parse(c), head.headers);
            if (ok != null) return ResolvedStream(ok.requestUrl, ok.headers);
          }
        }
        return ResolvedStream(head.requestUrl, head.headers);
      }
    }

    // 2) GET
    final get = await _get(baseUri, h);
    if (_looksLikeStream(get.requestUrl, get.contentType)) {
      if (preferHls) {
        final candidates = _hlsCandidates(get.requestUrl);
        for (final c in candidates) {
          final ok = await _tryM3u8(Uri.parse(c), get.headers);
          if (ok != null) return ResolvedStream(ok.requestUrl, ok.headers);
        }
      }
      return ResolvedStream(get.requestUrl, get.headers);
    }

    // 3) Extract m3u8 from HTML/text
    final extracted = _extractM3u8(get.body, get.requestUrl);
    if (extracted != null) {
      final ok = await _tryM3u8(Uri.parse(extracted), get.headers);
      if (ok != null) return ResolvedStream(ok.requestUrl, ok.headers);
      return ResolvedStream(extracted, get.headers);
    }

    return ResolvedStream(get.requestUrl, get.headers);
  }

  // -------- Link parsing (نفس اللي عندك) --------
  static ({String? url, Map<String, String> headers}) parseIncoming(String raw) {
    Map<String, String> hdr = {};
    String? out;

    if (raw.startsWith('varplayer://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host == 'play') {
        hdr = _merge(_defaultHeaders(null), _headersFromQuery(uri.queryParametersAll));
        final t = uri.queryParameters['t'];
        if (t != null && t.isNotEmpty) {
          final dec = _decodeB64Url(t) ?? (t.startsWith('http') ? t : null);
          if (dec != null) out = _extractUrlFromPayload(dec) ?? dec;
        }
      }
      return (url: (out != null && out.startsWith('http')) ? out : null, headers: hdr);
    }

    if (raw.startsWith('http')) {
      final uri = Uri.tryParse(raw);
      hdr = _merge(_defaultHeaders(uri), _headersFromQuery(uri?.queryParametersAll ?? const {}));
      return (url: raw, headers: hdr);
    }

    out = _extractUrlFromPayload(raw);
    hdr = _defaultHeaders(Uri.tryParse(out ?? ''));
    return (url: (out != null && out.startsWith('http')) ? out : null, headers: hdr);
  }

  // ---------------- internals ----------------

  static List<String> _hlsCandidates(String url) {
    final u = url;
    final lower = u.toLowerCase();
    final out = <String>{};

    // لو أصلاً m3u8
    if (lower.contains('.m3u8')) {
      out.add(u);
      return out.toList();
    }

    // ts -> m3u8
    if (RegExp(r'\.ts(\?.*)?$', caseSensitive: false).hasMatch(u)) {
      out.add(u.replaceFirst(RegExp(r'\.ts(\?.*)?$', caseSensitive: false), '.m3u8${_qs(u)}'));
    }

    // بدون امتداد مثل /XtreamCodes/494
    final uri = Uri.tryParse(u);
    if (uri != null) {
      final path = uri.path;
      final hasDot = path.split('/').last.contains('.');
      if (!hasDot) {
        out.add(uri.replace(path: '$path.m3u8').toString());
        out.add(uri.replace(path: '$path/index.m3u8').toString());

        // بعض البورتالات تسوي type=m3u8
        final q = Map<String, dynamic>.from(uri.queryParameters);
        q['type'] = 'm3u8';
        out.add(uri.replace(queryParameters: q.map((k, v) => MapEntry(k, '$v'))).toString());
      }
    }

    return out.toList();
  }

  static String _qs(String url) {
    final i = url.indexOf('?');
    return i >= 0 ? url.substring(i) : '';
  }

  static Future<_Resp?> _tryM3u8(Uri uri, Map<String, String> headers) async {
    // GET صغير حتى نتأكد body فعلاً playlist
    try {
      final c = http.Client();
      final r = await c.get(uri, headers: headers).timeout(const Duration(seconds: 10));
      final merged = _mergeCookies(headers, r.headers);
      final finalUrl = (r.request?.url ?? uri).toString();
      final ct = (r.headers['content-type'] ?? '').toLowerCase();
      final body = r.body;
      c.close();

      final looksM3u8 =
          finalUrl.toLowerCase().contains('.m3u8') ||
          ct.contains('application/vnd.apple.mpegurl') ||
          ct.contains('application/x-mpegurl') ||
          body.trimLeft().startsWith('#EXTM3U');

      if (r.statusCode >= 200 && r.statusCode < 400 && looksM3u8) {
        return _Resp(finalUrl, merged, r.headers['content-type'] ?? '', body);
      }
    } catch (_) {}
    return null;
  }

  static Future<_Resp?> _safeHead(Uri uri, Map<String, String> headers) async {
    try {
      final c = http.Client();
      final r = await c.head(uri, headers: headers).timeout(const Duration(seconds: 8));
      final merged = _mergeCookies(headers, r.headers);
      final finalUrl = (r.request?.url ?? uri).toString();
      final ct = r.headers['content-type'] ?? '';
      c.close();
      return _Resp(finalUrl, merged, ct, '');
    } catch (_) {
      return null;
    }
  }

  static Future<_Resp> _get(Uri uri, Map<String, String> headers) async {
    final c = http.Client();
    final r = await c.get(uri, headers: headers).timeout(const Duration(seconds: 12));
    final merged = _mergeCookies(headers, r.headers);
    final finalUrl = (r.request?.url ?? uri).toString();
    final ct = r.headers['content-type'] ?? '';
    final body = r.body;
    c.close();
    return _Resp(finalUrl, merged, ct, body);
  }

  static bool _looksLikeStream(String url, String ct) {
    final u = url.toLowerCase();
    final c = ct.toLowerCase();
    if (u.contains('.m3u8') || u.contains('.mp4') || u.contains('.mpd') || u.contains('.ts')) return true;
    if (c.contains('application/vnd.apple.mpegurl') ||
        c.contains('application/x-mpegurl') ||
        c.contains('application/dash+xml') ||
        c.contains('video/') ||
        c.contains('application/octet-stream')) return true;
    return false;
  }

  static String? _extractM3u8(String body, String baseUrl) {
    try {
      final base = Uri.parse(baseUrl);

      final rx = <RegExp>[
        RegExp(r'''https?:\/\/[^\s"'<>]+\.m3u8[^\s"'<>]*''', caseSensitive: false),
        RegExp(r'''src\s*=\s*["']([^"']+\.m3u8[^"']*)["']''', caseSensitive: false),
        RegExp(r'''(data-file|data-src|href)\s*=\s*["']([^"']+\.m3u8[^"']*)["']''', caseSensitive: false),
        RegExp(r'''<meta[^>]+http-equiv=["']refresh["'][^>]+content=["'][^"']*url=([^"']+)["']''',
            caseSensitive: false),
        RegExp(r'''<source[^>]+src=["']([^"']+\.m3u8[^"']*)["'][^>]*>''', caseSensitive: false),
      ];

      for (final r in rx) {
        final m = r.firstMatch(body);
        if (m == null) continue;
        final g = m.groupCount >= 2 ? (m.group(2) ?? m.group(1)) : m.group(0);
        if (g == null) continue;
        return base.resolve(g).toString();
      }
    } catch (_) {}
    return null;
  }

  static String? _decodeB64Url(String s) {
    try {
      final pad = s.length % 4 == 0 ? s : s.padRight(s.length + (4 - s.length % 4), '=');
      return utf8.decode(base64Url.decode(pad));
    } catch (_) {
      return null;
    }
  }

  static String? _extractUrlFromPayload(String payload) {
    try {
      final data = json.decode(payload);
      if (data is! Map) return null;
      final u = (data['url'] ?? data['main'] ?? data['m'])?.toString();
      if (u != null && u.startsWith('http')) return u;
    } catch (_) {}
    return null;
  }

  static Map<String, String> _defaultHeaders(Uri? uri) {
    final ref = uri != null && uri.host.isNotEmpty ? '${uri.scheme}://${uri.host}/' : null;
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
      // هذا يفيد بعض السيرفرات تطلع content-length بشكل أوضح
      'Accept-Encoding': 'identity',
      'Connection': 'keep-alive',
      if (ref != null) 'Referer': ref,
      if (ref != null && ref.startsWith('https')) 'Origin': ref.substring(0, ref.length - 1),
      'Icy-MetaData': '1',
    };
  }

  static Map<String, String> _headersFromQuery(Map<String, List<String>> all) {
    String? first(List<String>? l) => (l != null && l.isNotEmpty) ? l.first : null;
    final out = <String, String>{};

    final ua = first(all['ua']);
    final ref = first(all['referer']) ?? first(all['ref']);
    final org = first(all['origin']);
    if (ua?.isNotEmpty == true) out['User-Agent'] = ua!;
    if (ref?.isNotEmpty == true) out['Referer'] = ref!;
    if (org?.isNotEmpty == true) out['Origin'] = org!;

    final hs = all['header'] ?? all['h'];
    if (hs != null) {
      for (final item in hs) {
        final i = item.indexOf(':');
        if (i > 0) out[item.substring(0, i).trim()] = item.substring(i + 1).trim();
      }
    }
    return out;
  }

  static Map<String, String> _merge(Map<String, String> base, Map<String, String> over) {
    final res = Map<String, String>.from(base);
    over.forEach((k, v) => res[k] = v);
    return res;
  }

  static Map<String, String> _mergeCookies(Map<String, String> headers, Map<String, String> respHeaders) {
    final res = Map<String, String>.from(headers);
    final all = <String>[];

    respHeaders.forEach((k, v) {
      if (k.toLowerCase() == 'set-cookie' && v.isNotEmpty) {
        for (final part in v.split(',')) {
          final first = part.split(';').first.trim();
          if (first.contains('=')) all.add(first);
        }
      }
    });

    if (all.isNotEmpty) {
      final existing = res['Cookie'];
      res['Cookie'] = [if (existing != null && existing.isNotEmpty) existing, ...all].join('; ');
    }
    return res;
  }
}

class _Resp {
  final String requestUrl;
  final Map<String, String> headers;
  final String contentType;
  final String body;
  _Resp(this.requestUrl, this.headers, this.contentType, this.body);
}
