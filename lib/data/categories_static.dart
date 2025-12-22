class CategoryTile {
  final String id;          // bein, dazn, ...
  final String title;       // العنوان بالعربي
  final String assetIcon;   // مسار صورة الكرت
  final String playlistUrl; // رابط m3u على GitHub
  const CategoryTile({
    required this.id,
    required this.title,
    required this.assetIcon,
    required this.playlistUrl,
  });
}

/// ملاحظة:
/// تأكد أن الصور موجودة فعلاً داخل نفس المسارات المذكورة.
/// إذا تحب، نضيف fallback بالصورة داخل الواجهة بدل ما التطبيق يوقع.
const List<CategoryTile> kCategories = [
  CategoryTile(
    id: 'bein',
    title: 'باقة بي إن',
    assetIcon: 'assets/bein/bein.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/bein.m3u',
  ),
  CategoryTile(
    id: 'dazn',
    title: 'باقة دازن',
    assetIcon: 'assets/dazn/DAZN.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/dazn.m3u',
  ),
  CategoryTile(
    id: 'espn',
    title: 'باقة ESPN',
    assetIcon: 'assets/espn/ESPN.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/espn.m3u',
  ),
  CategoryTile(
    id: 'mbc',
    title: 'باقة MBC',
    assetIcon: 'assets/mbc/MBC.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/mbc.m3u',
  ),
  CategoryTile(
    id: 'seriaa',
    title: 'الدوري الإيطالي',
    assetIcon: 'assets/SeriaA/SERIA.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/SeriaA.m3u',
  ),
  CategoryTile(
    id: 'roshnleague',
    title: 'دوري روشن السعودي',
    assetIcon: 'assets/roshnleague/ROSNH.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/roshnleague.m3u',
  ),
  CategoryTile(
    id: 'premierleague',
    title: 'الدوري الإنجليزي الممتاز',
    assetIcon: 'assets/premierleague/PREMIER LEAGUE.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/premierleague.m3u',
  ),
  CategoryTile(
    id: 'generalsports',
    title: 'قنوات رياضية عامة',
    assetIcon: 'assets/generalsports/1.png',
    playlistUrl: 'https://raw.githubusercontent.com/a7shk1/m3u-broadcast/refs/heads/main/generalsports.m3u',
  ),
];
