import 'dart:convert';
import '../models/channel.dart';

List<Channel> parseM3U(String content) {
  final lines = const LineSplitter()
      .convert(content)
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final List<Channel> out = [];
  String? name;

  for (final l in lines) {
    if (l.startsWith('#EXTINF')) {
      // الاسم غالباً بعد الفاصلة
      final idx = l.indexOf(',');
      name = (idx >= 0 ? l.substring(idx + 1) : 'Channel').trim();

      // تنظيف الاسم مثل القديم تماماً
      name = name.replaceAll(RegExp(r'\[.*?\]'), '').trim();
      name = name.replaceAll(RegExp(r'\s+'), ' ');
      continue;
    }

    // رابط القناة
    if (RegExp(r'^(https?|rtmp|udp)://', caseSensitive: false).hasMatch(l)) {
      if (name != null && name.isNotEmpty) {
        out.add(Channel(name: name, url: l));
      }
      name = null;
    }
  }

  return out;
}
