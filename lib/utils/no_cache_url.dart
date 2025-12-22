// lib/utils/no_cache_url.dart
/// أدوات بسيطة لمنع الكاش عند طلب ملفات RAW (M3U / JSON) من GitHub أو أي CDN.
///
/// الاستخدام المعتاد:
/// ```dart
/// final uri = noCacheUri(url);                // كل طلب = نسخة جديدة
/// // أو:
/// final uri = noCacheUri(url, ttl: Duration(minutes: 1)); // نفس الرابط لمدة دقيقة
///
/// final res = await http.get(uri, headers: kNoCacheHeaders);
/// ```
///
/// - [ttl]: لو مرّرتها، نخلي "البكِت" ثابت خلال الفترة المحددة (يفيد لتقليل
///   إعادة التحميل المفرطة). إذا ما مرّرت ttl، راح نضيف باراميتر فريد لكل طلب.
/// - [extraParams]: باراميترات إضافية تحب تلحقها بالرابط.

/// هيدرز موصي بها لتعطيل الكاش (اختياري لكنها مفيدة مع بعض الـ CDN).
const Map<String, String> kNoCacheHeaders = {
  'Cache-Control': 'no-cache, no-store, must-revalidate',
  'Pragma': 'no-cache',
};

/// يُرجع قيمة "بكِت" للكاش-باستر حسب [ttl].
/// - بدون ttl: يرجّع التوقيت الحالي بالملي ثانية (فريد لكل طلب).
/// - مع ttl: يقسّم الزمن على طول ttl ليبقى ثابت ضمن النافذة (تقليل تغيّر الرابط).
int _cacheBucketMillis({Duration? ttl}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  if (ttl == null || ttl.inMilliseconds <= 0) return now;
  return now ~/ ttl.inMilliseconds;
}

/// يبني رابط **string** مع كاش-باستر.
/// أمثلة:
/// - `noCacheUrl('https://.../file.m3u')` → يضيف `?v=<unique>`
/// - `noCacheUrl('https://.../file.m3u?x=1', ttl: 1min)` → يضيف `&v=<bucket>`
String noCacheUrl(
    String url, {
      Duration? ttl,
      Map<String, String>? extraParams,
    }) {
  final bucket = _cacheBucketMillis(ttl: ttl).toString();
  final sep = url.contains('?') ? '&' : '?';

  // نحافظ على أي باراميترات إضافية يمررها المستدعي
  final extras = <String, String>{'v': bucket, ...?extraParams};

  final qp = extras.entries
      .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');

  return '$url$sep$qp';
}

/// نسخة ترجع [Uri] مباشرة (مريحة للاستخدام مع http.get).
Uri noCacheUri(
    String url, {
      Duration? ttl,
      Map<String, String>? extraParams,
    }) {
  return Uri.parse(noCacheUrl(url, ttl: ttl, extraParams: extraParams));
}

/// مولّد بسيط لمفتاح كاش-باستر (مفيد لو تبي تستخدمه خارجياً).
String cacheKeyFor({Duration? ttl}) => _cacheBucketMillis(ttl: ttl).toString();
