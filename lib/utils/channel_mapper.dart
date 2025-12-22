// lib/utils/channel_mapper.dart
// ذكاء مطابقة قنوات عربي/إنجليزي + أرقام + aliases + تطبيع قوي.
// استعمل ChannelMapper.findUrl(channelName) -> String? لتمريرها لـ var player.

class ChannelMapper {
  // ====== روابط أصلية (من قائمتك) ======
  // StarzPlay
  static const _starz1 = "https://stream.supertv.gg:3004/supertv/sport/stv10/ch10/ch10_720.m3u8";
  static const _starz2 = "https://stream.supertv.gg:3004/supertv/sport/stv9/ch9/ch9_720.m3u8";

  // Abu Dhabi Sports
  static const _abudhabi1 = "https://stream.supertv.gg:3004/supertv/sport/stv11/ch11/ch11_720.m3u8";
  static const _abudhabi2 = "https://stream.supertv.gg:3004/supertv/sport/stv12/ch12/ch12_720.m3u8";

  // beIN SPORTS 1..9
  static const _bein1 = "https://test.vartv.live/hls/ch1.m3u8";
  static const _bein2 = "https://test.vartv.live/hls/ch2.m3u8";
  static const _bein3 = "https://test.vartv.live/hls/ch3.m3u8";
  static const _bein4 = "http://het115a.4rouwanda-shop.store/live/9787488847/index.m3u8";
  static const _bein5 = "https://stream.supertv.gg:3004/supertv/sport/stv5/ch5/ch5_720.m3u8";
  static const _bein6 = "https://stream.supertv.gg:3004/supertv/sport/stv6/ch6/ch6_720.m3u8";
  static const _bein7 = "https://maldivesn.net/hilaytv/bein1";
  static const _bein8 = "https://maldivesn.net/hilaytv/bein2";
  static const _bein9 = "https://maldivesn.net/hilaytv/bein3";

  // DAZN 1..6
  static const _dazn1 = "https://maldivesn.net/hilaytv/dazn1";
  static const _dazn2 = "https://maldivesn.net/hilaytv/dazn2";
  static const _dazn3 = "https://maldivesn.net/hilaytv/dazn3";
  static const _dazn4 = "https://maldivesn.net/hilaytv/dazn4";
  static const _dazn5 = "https://maldivesn.net/hilaytv/dazn5";
  static const _dazn6 = "https://maldivesn.net/hilaytv/dazn6";

  // ESPN 1..7
  static const _espn1 = "http://181.119.86.68:8000/play/b031/index.m3u8";
  static const _espn2 = "http://181.119.86.68:8000/play/b032/index.m3u8";
  static const _espn3 = "http://181.119.86.68:8000/play/b033/index.m3u8";
  static const _espn4 = "http://181.119.85.222:8000/play/a00j/index.m3u8";
  static const _espn5 = "http://181.119.86.68:8000/play/b028/index.m3u8";
  static const _espn6 = "http://181.119.85.222:8000/play/a01s/index.m3u8";
  static const _espn7 = "http://181.119.86.68:8000/play/b029/index.m3u8";

  // Varzesh / Varzish / Football HD / IRIB3 / Persiana / Match!
  static const _varzeshIR = "https://lenz.splus.ir/PLTV/88888888/224/3221226845/1.m3u8";
  static const _varzishTJ = "https://stream2.removie.raha.af/live/smil:tjvarzishtv.smil/chunklist_w852771320_b1500000.m3u8";
  static const _footballHD_TJ = "https://stream2.removie.raha.af/live/smil:footballtv.smil/playlist.m3u8";
  static const _irib3 = "https://wo.cma.footballii.ir/hls2/tv3.m3u8";
  static const _persiana = "https://stream.live12.ir/hls2/persiana.m3u8";
  static const _match1 = "http://31.148.48.15:80/Match_Futbol_1_HD/index.m3u8";
  static const _match2 = "http://31.148.48.15/Match_Futbol_2_HD/index.m3u8";
  static const _match3 = "http://31.148.48.15/Match_Futbol_3_HD/index.m3u8";
  static const _matchTV = "http://178.212.71.253:8002/play/a00k/index.m3u8";

  // Sport TV
  static const _sporttv1 = "https://maldivesn.net/hilaytv/sporttv1";
  static const _sporttv2 = "https://maldivesn.net/hilaytv/sporttv2";

  // MBC
  static const _mbc1 = "https://stream.supertv.gg:3029/supertv/enter/stv9/ch9/ch9_720.m3u8";
  static const _mbc2 = "https://stream.supertv.gg:3029/supertv/enter/stv2/ch2/ch2_720.m3u8";
  static const _mbc3 = "https://stream.supertv.gg:3029/supertv/enter/stv3/ch3/ch3_720.m3u8";
  static const _mbc4 = "https://stream.supertv.gg:3029/supertv/enter/stv4/ch4/ch4_720.m3u8";
  static const _mbcAction = "https://stream.supertv.gg:3025/supertv/enter/stv5/ch5/ch5_720.m3u8";
  static const _mbcDramaPlus = "https://stream.supertv.gg:3028/supertv/enter/stv8/ch8/ch8_720.m3u8";
  static const _mbcDrama = "https://stream.supertv.gg:3027/supertv/enter/stv7/ch7/ch7_720.m3u8";
  static const _mbcMasr = "https://stream.supertv.gg:3030/supertv/enter/stv10/ch10/ch10_720.m3u8";
  static const _mbcMasr2 = "https://stream.supertv.gg:3030/supertv/enter/stv11/ch11/ch11_720.m3u8";

  // TNT SPORTS + Sky
  static const _tnt = "http://181.78.201.70:8000/play/a0tx/index.m3u8";
  static const _tnt1 = "https://maldivesn.net/hilaytv/tnt1";
  static const _tnt2 = "https://maldivesn.net/hilaytv/tnt2";
  static const _skyMainEvent = "https://maldivesn.net/hilaytv/skysportsmaineventud";
  static const _skyPremierLeague = "https://maldivesn.net/hilaytv/skypremierleaguehd";

  // SSC + Thmanyah/Dubai (مؤقت)
  static const _ssc1 = "https://maldivesn.net/hilaytv/ssc1";
  static const _ssc2 = "http://het114a.4rouwanda-shop.store/live/33523510/index.m3u8";
  static const _thmanyah1 = "https://yallagoal.stream-e7e.workers.dev/Thmanyah1.m3u8";
  static const _thmanyah2 = "https://yallagoal.stream-e7e.workers.dev/Thmanyah2.m3u8";
  static const _thmanyah3 = "https://yallagoal.stream-e7e.workers.dev/Thmanyah3.m3u8";

  /// القناة الافتراضية إذا ما قدرنا نتعرّف بثقة كافية
  static const String fallback = _bein1;

  // ====== جداول الخرائط بحسب المجموعات ======
  static final Map<int, String> _beinMap = {
    1: _bein1, 2: _bein2, 3: _bein3, 4: _bein4, 5: _bein5,
    6: _bein6, 7: _bein7, 8: _bein8, 9: _bein9,
  };

  static final Map<int, String> _daznMap = {
    1: _dazn1, 2: _dazn2, 3: _dazn3, 4: _dazn4, 5: _dazn5, 6: _dazn6,
  };

  static final Map<int, String> _espnMap = {
    1: _espn1, 2: _espn2, 3: _espn3, 4: _espn4, 5: _espn5, 6: _espn6, 7: _espn7,
  };

  static final Map<int, String> _sscMap = {
    1: _ssc1, 2: _ssc2,
  };

  static final Map<int, String> _abudhabiMap = {
    1: _abudhabi1, 2: _abudhabi2,
  };

  static final Map<int, String> _thmanyahMap = {
    1: _thmanyah1, 2: _thmanyah2, 3: _thmanyah3,
  };

  // قنوات مفردة بدون أرقام
  static final Map<String, String> _singleChannels = {
    // StarzPlay
    "starzplay1": _starz1,
    "starzplay2": _starz2,

    // MBC
    "mbc1": _mbc1,
    "mbc2": _mbc2,
    "mbc3": _mbc3,
    "mbc4": _mbc4,
    "mbc action": _mbcAction,
    "mbc drama+": _mbcDramaPlus,
    "mbc drama": _mbcDrama,
    "mbc masr": _mbcMasr,
    "mbc masr 2": _mbcMasr2,

    // TNT & Sky
    "tnt sports": _tnt,
    "tnt sports 1": _tnt1,
    "tnt sports 2": _tnt2,
    "sky sports main event": _skyMainEvent,
    "sky premier league": _skyPremierLeague,

    // Others
    "varzesh tv": _varzeshIR,
    "varzish tv": _varzishTJ,
    "football hd": _footballHD_TJ,
    "irib tv 3": _irib3,
    "persiana sports": _persiana,
    "match! futbol 1": _match1,
    "match! futbol 2": _match2,
    "match! futbol 3": _match3,
    "match! tv": _matchTV,
    "sport tv 1": _sporttv1,
    "sport tv 2": _sporttv2,
  };

  // ====== aliases (أسماء بديلة) للمجموعات ======
  static final Map<String, List<String>> _groupAliases = {
    "bein": [
      "bein", "بي ان", "بين", "bein sports", "بي ان سبورت", "بي ان سبورتس"
    ],
    "dazn": [
      "dazn", "دازن", "دازون"
    ],
    "espn": [
      "espn", "اي اس بي ان"
    ],
    "ssc": [
      "ssc", "اس اس سي"
    ],
    "abudhabi": [
      "abudhabi", "abu dhabi", "ابوظبي", "ابو ظبي", "ابو ظبى", "ابوظبي الرياضية", "ابو ظبي الرياضية",
      "abudhabi sports"
    ],
    "thmanyah": [
      "thmanyah", "ثمانيه", "ثمانية", "thamania", "dubai", "دبي"
    ],
    "starzplay": [
      "starzplay", "starz", "ستارزبلاي", "ستارز بلاي"
    ],
    "mbc": [
      "mbc", "ام بي سي", "امبيسي"
    ],
    "tnt": [
      "tnt", "tnt sports"
    ],
    "sky": [
      "sky", "sky sports"
    ],
    "varzesh": [
      "varzesh", "varzish", "ورزش", "ورزش tv", "varzesh tv", "varzish tv"
    ],
    "sporttv": [
      "sport tv", "sporttv"
    ],
  };

  /// Normalize: lowercase + إزالة رموز + تحويل بعض العربية → إنجليزي/مبسطة
  static String _norm(String? s) {
    var t = (s ?? "").toLowerCase();

    // إزالة علامات غير أحرف/أرقام مع إبقاء المسافات
    t = t.replaceAll(RegExp(r'[^\p{L}\p{N}\s]+', unicode: true), ' ');

    // بدائل عربية → لاتيني/مبسطة
    t = t
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ـ', '');

    // كلمات مفتاحية وتوحيد عربي→إنجليزي
    t = t
        .replaceAll('ابو ظبي', 'abudhabi')
        .replaceAll('ابوظبي', 'abudhabi')
        .replaceAll('ابو ظبى', 'abudhabi')
        .replaceAll('الرياضيه', 'sports')
        .replaceAll('الرياضية', 'sports')
        .replaceAll('دبي', 'dubai')
        .replaceAll('اس اس سي', 'ssc')
        .replaceAll('بي ان', 'bein')
        .replaceAll('سبورت', 'sport')
        .replaceAll('ثمانيه', 'thmanyah')
        .replaceAll('ثمانية', 'thmanyah')
        .replaceAll('ستارزبلاي', 'starzplay')
        .replaceAll('ستارز بلاي', 'starzplay')
        .replaceAll('ام بي سي', 'mbc')
        .replaceAll('امبيسي', 'mbc')
        .replaceAll('اي اس بي ان', 'espn')
        .replaceAll('دازن', 'dazn')
        .replaceAll('دازون', 'dazn')
        .replaceAll('ورزش', 'varzesh');

    // تبسيط الفراغات
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  /// يحاول يستخرج رقم القناة إن وجد (1..99)
  static int? _extractNumber(String s) {
    final m = RegExp(r'(\d{1,2})').firstMatch(s);
    if (m == null) return null;
    return int.tryParse(m.group(1) ?? '');
  }

  /// فحص وجود أي alias داخل الاسم المطبّع
  static bool _containsAny(String src, List<String> keys) {
    for (final k in keys) {
      if (src.contains(k)) return true;
    }
    return false;
  }

  /// درجة (score) لمطابقة مجموعة معينة مع الاسم — للترتيب بالأفضلية
  static int _scoreGroup(String name, String groupKey) {
    final aliases = _groupAliases[groupKey] ?? const [];
    var score = 0;
    for (final a in aliases) {
      if (name.contains(a)) score += 2; // وجود alias يرفع النتيجة
    }
    // مكافأة لو الاسم يبدأ بالمجموعة (غالبًا اسم نظيف)
    if (name.startsWith(groupKey)) score += 1;
    // مكافأة لو اسم فيه كلمة "sport(s)" لبعض المجموعات الرياضية
    if (name.contains('sport') || name.contains('sports')) score += 1;
    return score;
  }

  /// مطابقة مجموعة مع خريطة أرقام (مثل beIN/DAZN/SSC/ESPN/AbuDhabi/Thmanyah)
  static String? _mapNumbered(String name, String groupKey, Map<int, String> table, {int? defaultNum}) {
    if (!_containsAny(name, _groupAliases[groupKey] ?? const [])) return null;
    final n = _extractNumber(name) ?? defaultNum;
    if (n != null && table.containsKey(n)) return table[n];
    // لو ماكو رقم، رجّع أقل رقم متاح كافتراضي
    if (defaultNum != null && table.containsKey(defaultNum)) return table[defaultNum];
    return table[table.keys.reduce((a, b) => a < b ? a : b)];
  }

  /// مطابقة قنوات مفردة بالاسم (مع دعم المطابقة الجزئية)
  static String? _mapSingles(String name) {
    // تطابق مباشر
    if (_singleChannels.containsKey(name)) return _singleChannels[name];

    // مطابقة جزئية باستخدام contains
    for (final entry in _singleChannels.entries) {
      final key = entry.key;
      if (name.contains(key)) return entry.value;
      // دعم صيغ شائعة مثل "mbc drama plus"
      if (key == "mbc drama+" && (name.contains("mbc drama+") || name.contains("mbc drama plus"))) {
        return entry.value;
      }
    }

    // حالات خاصة شائعة:
    if (name.contains('starzplay')) {
      final n = _extractNumber(name) ?? 1;
      return n == 2 ? _starz2 : _starz1;
    }

    if (name.contains('sky') && name.contains('main') && name.contains('event')) {
      return _skyMainEvent;
    }
    if (name.contains('sky') && (name.contains('premier') || name.contains('league'))) {
      return _skyPremierLeague;
    }

    if (name.contains('varzesh')) return _varzeshIR;
    if (name.contains('varzish')) return _varzishTJ;
    if (name.contains('football hd')) return _footballHD_TJ;
    if (name.contains('irib') && name.contains('3')) return _irib3;
    if (name.contains('persiana')) return _persiana;

    if (name.contains('match') && name.contains('futbol')) {
      final n = _extractNumber(name) ?? 1;
      if (n == 2) return _match2;
      if (n == 3) return _match3;
      return _match1;
    }
    if (name.contains('match') && name.contains(' tv')) return _matchTV;

    if (name.contains('sport tv')) {
      final n = _extractNumber(name) ?? 1;
      return n == 2 ? _sporttv2 : _sporttv1;
    }

    // MBC variants
    if (name.startsWith('mbc')) {
      final n = _extractNumber(name);
      if (n == 1) return _mbc1;
      if (n == 2) return _mbc2;
      if (n == 3) return _mbc3;
      if (n == 4) return _mbc4;
      if (name.contains('action')) return _mbcAction;
      if (name.contains('drama+') || name.contains('drama plus')) return _mbcDramaPlus;
      if (name.contains('drama')) return _mbcDrama;
      if (name.contains('masr 2') || name.contains('masr2')) return _mbcMasr2;
      if (name.contains('masr')) return _mbcMasr;
    }

    if (name.contains('tnt')) {
      final n = _extractNumber(name);
      if (n == 1) return _tnt1;
      if (n == 2) return _tnt2;
      return _tnt;
    }

    return null;
  }

  /// يحاول إيجاد URL للقناة (ذكاء + أرقام + جزئي)
  static String? findUrl(String? channelName) {
    final n = _norm(channelName);
    if (n.isEmpty) return null;

    // 1) قنوات مفردة مباشرة
    final single = _mapSingles(n);
    if (single != null) return single;

    // 2) مجموعات مرقّمة شائعة
    // حساب score للمفاضلة لو الاسم فيه أكثر من مجموعة (نادرًا)
    final groups = <String, int>{
      "bein": _scoreGroup(n, "bein"),
      "dazn": _scoreGroup(n, "dazn"),
      "espn": _scoreGroup(n, "espn"),
      "ssc": _scoreGroup(n, "ssc"),
      "abudhabi": _scoreGroup(n, "abudhabi"),
      "thmanyah": _scoreGroup(n, "thmanyah"),
    };

    // ترتيب حسب الأعلى
    final ordered = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final e in ordered) {
      if (e.value <= 0) continue; // ماكو إشارات للمجموعة
      switch (e.key) {
        case "bein":
          final url = _mapNumbered(n, "bein", _beinMap, defaultNum: 1);
          if (url != null) return url;
          break;
        case "dazn":
          final url = _mapNumbered(n, "dazn", _daznMap, defaultNum: 1);
          if (url != null) return url;
          break;
        case "espn":
          final url = _mapNumbered(n, "espn", _espnMap, defaultNum: 1);
          if (url != null) return url;
          break;
        case "ssc":
          final url = _mapNumbered(n, "ssc", _sscMap, defaultNum: 1);
          if (url != null) return url;
          break;
        case "abudhabi":
          final url = _mapNumbered(n, "abudhabi", _abudhabiMap, defaultNum: 1);
          if (url != null) return url;
          break;
        case "thmanyah":
          final url = _mapNumbered(n, "thmanyah", _thmanyahMap, defaultNum: 1);
          if (url != null) return url;
          break;
      }
    }

    // 3) حالات دبي/ثمانية كمظلّة لـ "dubai sports"
    if (n.contains('dubai') || n.contains('thmanyah')) {
      final t = _mapNumbered(n, "thmanyah", _thmanyahMap, defaultNum: 1);
      if (t != null) return t;
    }

    // 4) لو الاسم فيه "bein" بدون تحديد: رجّع 1 افتراضيًا
    if (n.contains('bein')) return _bein1;

    // 5) آخر خيار: fallback
    return fallback;
  }
}
