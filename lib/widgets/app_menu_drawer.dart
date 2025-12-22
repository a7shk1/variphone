import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppMenuDrawer extends StatelessWidget {
  const AppMenuDrawer({super.key});

  // ====== بياناتك وروابطك ======
  static const String kTelegramChannelUrl = 'https://t.me/medplus2';
  static const String kTelegramUsername   = 'a7shk99'; // دردشة مباشرة تيليجرام
  static const String kWhatsAppNumber     = '+9647858689264';
  static const String kInstagramUrl       = 'https://instagram.com/p_old';

  static const String kDevName  = 'أحمد خالد';
  static const String kDevEmail = 'ahmed.289ahmed@gmail.com';

  // ====== أدوات عامة ======
  Future<void> _openExternal(BuildContext context, String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الرابط')),
        );
      }
    }
  }

  Future<void> _openWhatsAppChat(BuildContext context) async {
    final phone = kWhatsAppNumber.replaceAll('+', '').replaceAll(' ', '');
    await _openExternal(context, 'https://wa.me/$phone');
  }

  Future<void> _openTelegramChat(BuildContext context) async {
    await _openExternal(context, 'https://t.me/$kTelegramUsername');
  }

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version}+${info.buildNumber}";
  }

  void _showDirectChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر طريقة الدردشة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.send),
                  title: const Text('تيليجرام (مباشرة)'),
                  subtitle: const Text('@a7shk99'),
                  onTap: () {
                    Navigator.pop(context);
                    _openTelegramChat(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.phone_in_talk_outlined),
                  title: const Text('واتساب'),
                  subtitle: const Text(kWhatsAppNumber),
                  onTap: () {
                    Navigator.pop(context);
                    _openWhatsAppChat(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'VAR IPTV',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.tv),
      children: const [
        SizedBox(height: 8),
        Text(
          'Var IPTV يوفّر تجربة مشاهدة سلسة وخفيفة للمحتوى والقنوات، '
              'بواجهة داكنة أنيقة وروابط فورية لقنواتنا. نركّز على السرعة والبساطة '
              'والتحديثات المستمرة لتبقى أقرب لكل جديد رياضي.',
          style: TextStyle(height: 1.55),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onSurface;

    return Drawer(
      elevation: 12,
      child: Container(
        // 🔒 خلفية تدرّج بنفسجي/أسود ثابتة (متناسقة مع الواجهة)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF6D28D9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // رأس القائمة: شعار + اسم التطبيق
              Container(
                height: 140,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                alignment: Alignment.bottomLeft,
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', height: 32),
                    const SizedBox(width: 10),
                    const Text(
                      'VAR IPTV',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),

              // دردشة مباشرة
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                title: const Text('دردشة مباشرة'),
                onTap: () => _showDirectChatSheet(context),
              ),

              // قناة تيليجرام
              ListTile(
                leading: const Icon(Icons.campaign_outlined, color: Colors.white70),
                title: const Text('قناتنا على تيليجرام'),
                onTap: () => _openExternal(context, kTelegramChannelUrl),
              ),

              // إنستغرام
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: Colors.white70),
                title: const Text('صفحتنا على إنستغرام'),
                onTap: () => _openExternal(context, kInstagramUrl),
              ),

              const Divider(color: Colors.white24),

              // نبذة
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.white70),
                title: const Text('نبذة عن التطبيق'),
                onTap: () => _openAbout(context),
              ),

              // سياسة الخصوصية
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
                title: const Text('سياسة الخصوصية'),
                onTap: () => Navigator.of(context).pushNamed('/privacy'),
              ),

              // تواصل معنا
              ListTile(
                leading: const Icon(Icons.mail_outline, color: Colors.white70),
                title: const Text('تواصل معنا'),
                onTap: () => Navigator.of(context).pushNamed('/contact'),
              ),

              // معلومات المطوّر
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white70),
                title: const Text('معلومات المطوّر'),
                onTap: () => Navigator.of(context).pushNamed('/developer'),
              ),

              const SizedBox(height: 12),

              // سطر الإصدار الحالي
              FutureBuilder<String>(
                future: _getVersion(),
                builder: (context, snap) {
                  final version = snap.data ?? '';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0, bottom: 24.0),
                      child: Text(
                        version.isNotEmpty
                            ? "الإصدار الحالي: $version"
                            : "جارٍ التحقق من الإصدار...",
                        style: TextStyle(color: textColor.withOpacity(0.7)),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
