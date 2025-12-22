import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.actions,
    this.logoPath = 'assets/images/logo.png',
    this.title = 'VAR IP TV',
    this.useGradient = true, // تدرّج ثابت داخل الـAppBar (اختياري)
    this.gradientColors = const [Color(0xFF8A2BE2), Color(0xFF1E1E2C)],
  });

  final List<Widget>? actions;
  final String logoPath;
  final String title;

  /// هل نعرض تدرّج ثابت داخل الـAppBar (بدون أنيميشن)؟
  final bool useGradient;

  /// ألوان التدرّج داخل الـAppBar
  final List<Color> gradientColors;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // نستخدم DrawerButton
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent, // نخليها شفافة (الثيم متكفّل)
      titleSpacing: 0,
      flexibleSpace: useGradient
          ? DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      )
          : null,
      title: Row(
        children: [
          const DrawerButton(), // يفتح الـDrawer إذا موجود
          const SizedBox(width: 6),
          // اللوغو
          Image.asset(
            logoPath,
            height: 24,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.tv, size: 22),
          ),
          const SizedBox(width: 8),
          // النص
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
