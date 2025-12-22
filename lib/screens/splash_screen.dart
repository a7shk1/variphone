import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Splash مرسوم دائماً (حتى لو Firebase تعلّق)
/// - خلفية سوداء
/// - لوغو وسط
/// - توهّج خفيف + فِيد
/// - ما يسوي أي Firestore/DeviceInfo هنا
/// التوجيه يصير من main.dart عبر navigatorKey
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  bool _fallbackShown = false;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_fadeCtrl);

    _fadeCtrl.forward();

    // فاليباك UI إذا ما صار أي تنقّل (مثلاً Firebase علق/لا نت)
    Future.delayed(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _fallbackShown = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/images/logo.png'), context);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF000000);

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (_, __) {
                final t = _glowCtrl.value;
                final size = 240.0 + 12.0 * t;
                final opacity = 0.10 + 0.18 * t;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF7A3BFF).withOpacity(opacity),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                );
              },
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _fade,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 16),
                if (_fallbackShown)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'إذا طول التحميل، تأكد من الإنترنت أو أعد فتح التطبيق.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
