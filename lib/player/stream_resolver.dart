import 'dart:convert';
import 'package:http/http.dart' as http;

class ResolvedStream {
  final String url;
  final Map<String, String> headers;
  const ResolvedStream(this.url, this.headers);
}

class StreamResolver {
  // -------- Public entry --------
  static Future<ResolvedStream> resolve(
      String rawUrl, {
        Map<String, String>? headers,
        bool preferHls = false,
      }) async {
    final uri = Uri.parse(rawUrl);
    final h = _merge(_defaultHeaders(uri), headers ?? {});

    // 0) Prefer HLS على iOS: جرّب تحويل ts -> m3u8 أولاً إذا ممكن
    if (preferHls) {
      final hls = _tryMakeHlsFromTs(rawUrl);
      if (hls != null) {
        final ok = await _probeStream(Uri.parse(hls), h);
        if (ok != null) {
          return ResolvedStream(ok.requestUrl, ok.headers);
        }
      }
    }

    // 1) Try HEAD (fast)
    final head = await _safeHead(uri, h);
    if (head != null) {
      final finalUrl = head.requestUrl;
      final finalHeaders = head.headers;
      if (_looksLikeStream(finalUrl, head.contentType)) {
        // إذا نفضّل HLS، جرّب بعد التحويل حتى لو الـ HEAD رجّع ts
        if (preferHls) {
          final hls2 = _tryMakeHlsFromTs(finalUrl);
          if (hls2 != null) {
            final ok = await _probeStream(Uri.parse(hls2), finalHeaders);
            if (ok != null) {
              return ResolvedStream(ok.requestUrl, ok.headers);
            }
          }
        }
        return ResolvedStream(finalUrl, finalHeaders);
      }
    }

    // 2) GET (page or stream)
    final get = await _get(uri, h);
    final finalUrl2 = get.requestUrl;
    final headers2 = get.headers;

    if (_looksLikeStream(finalUrl2, get.contentType)) {
      if (preferHls) {
        final hls3 = _tryMakeHlsFromTs(finalUrl2);
        if (hls3 != null) {
          final ok = await _probeStream(Uri.parse(hls3), headers2);
          if (ok != null) {
            return ResolvedStream(ok.requestUrl, ok.headers);
          }
        }
      }
      return ResolvedStream(finalUrl2, headers2);
    }

    // 3) Extract m3u8 from HTML/text
    final extracted = _extractM3u8(get.body, finalUrl2);
    return ResolvedStream(extracted ?? finalUrl2, headers2);
  }

  // -------- Link parsing (supports your 4 formats) --------
  static ({String? url, Map<String, String> headers}) parseIncoming(String raw) {
    Map<String, String> hdr = {};
    String? out;

    // varplayer://play?t=...
    if (raw.startsWith('varplayer://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null && uri.host == 'play') {
        // headers from query
        hdr = _merge(_defaultHeaders(null), _headersFromQuery(uri.queryParametersAll));

        final t = uri.queryParameters['t'];
        if (t != null && t.isNotEmpty) {
          final dec = _decodeB64Url(t) ?? (t.startsWith('http') ? t : null);
          if (dec != null) {
            out = _extractUrlFromPayload(dec) ?? dec;
          }
        }
      }
      return (url: (out != null && out.startsWith('http')) ? out : null, headers: hdr);
    }

    // direct http
    if (raw.startsWith('http')) {
      final uri = Uri.tryParse(raw);
      hdr = _merge(_defaultHeaders(uri), _headersFromQuery(uri?.queryParametersAll ?? const {}));
      return (url: raw, headers: hdr);
    }

    // payload json
    out = _extractUrlFromPayload(raw);
    hdr = _defaultHeaders(Uri.tryParse(out ?? ''));
    return (url: (out != null && out.startsWith('http')) ? out : null, headers: hdr);
  }

  // ---------------- internals ----------------

  // Probe بسيط: GET صغير (Range) حتى نتأكد الرابط صالح كستريم
  static Future<_Resp?> _probeStream(Uri uri, Map<String, String> headers) async {
    try {
      final c = http.Client();
      final h = Map<String, String>.from(headers);

      // بعض السيرفرات تتصرف أحسن مع Range صغير
      h['Range'] = 'bytes=0-1024';

      final r = await c.get(uri, headers: h).timeout(const Duration(seconds: 8));
      final merged = _mergeCookies(headers, r.headers);
      final finalUrl = (r.request?.url ?? uri).toString();
      final ct = r.headers['content-type'] ?? '';
      c.close();

      if (r.statusCode >= 200 && r.statusCode < 400 && _looksLikeStream(finalUrl, ct)) {
        return _Resp(finalUrl, merged, ct, '');
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

  static String? _tryMakeHlsFromTs(String url) {
    final u = url.toLowerCase();

    // إذا أصلاً m3u8 لا تغيّر
    if (u.contains('.m3u8')) return null;

    // ts -> m3u8 (مع الحفاظ على query)
    final m = RegExp(r'\.ts(\?.*)?$').firstMatch(url);
    if (m != null) {
      final q = m.group(1) ?? '';
      return url.replaceFirst(RegExp(r'\.ts(\?.*)?$'), '.m3u8$q');
    }

    return null;
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
        RegExp(
          r'''<meta[^>]+http-equiv=["']refresh["'][^>]+content=["'][^"']*url=([^"']+)["']''',
          caseSensitive: false,
        ),
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
    final ref = (uri != null && uri.host.isNotEmpty) ? '${uri.scheme}://${uri.host}/' : null;

    return {
      'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124 Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9,ar;q=0.8',
      // يساعد بعض السيرفرات تطلع Content-Length مضبوط
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
        if (i > 0) {
          out[item.substring(0, i).trim()] = item.substring(i + 1).trim();
        }
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
        // ملاحظة: هذا تبسيط، بس كافي لمعظم الحالات
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
