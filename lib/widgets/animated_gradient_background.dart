import 'dart:math' as math;
import 'package:flutter/material.dart';

/// خلفية عالمية ثابتة وخفيفة (بنفسجي → أسود) + توهّج خفيف من الزوايا.
/// استخدمها داخل MaterialApp.builder:
///
/// builder: (context, child) => Stack(
///   children: const [
///     Positioned.fill(child: GlobalBackground()),
///   ],
/// )
class GlobalBackground extends StatelessWidget {
  const GlobalBackground({super.key});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8A2BE2);
    const black = Color(0xFF0E0E12);

    return Stack(
      fit: StackFit.expand,
      children: [
        // طبقة التدرّج الأساسية (ثابت)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [purple, black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // توهّج خفيف من زاويتين (من دون بلور مكلف)
        IgnorePointer(
          child: CustomPaint(
            painter: _CornerGlowPainter(color: purple.withOpacity(0.10)),
          ),
        ),
      ],
    );
  }
}

class _CornerGlowPainter extends CustomPainter {
  _CornerGlowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x338A2BE2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 240));

    // أعلى اليسار
    canvas.save();
    canvas.translate(0, 0);
    canvas.drawCircle(const Offset(0, 0), 240, paint);
    canvas.restore();

    // أسفل اليمين
    final paint2 = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x228A2BE2), Colors.transparent],
      ).createShader(Rect.fromCircle(center: const Offset(0, 0), radius: 200));

    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.drawCircle(const Offset(0, 0), 200, paint2);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// نسخة متوافقة مع الكود القديم:
/// - الافتراضي الآن "ثابت" (animated=false) → أداء خفيف.
/// - لو أردت حركة خفيفة: مرّر animated:true (أنيميشن مخفّف).
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final bool animated;
  final Duration duration;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.animated = false, // افتراضي: ثابت
    this.duration = const Duration(seconds: 24),
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGradientBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated && _c == null) {
      _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
    } else if (!widget.animated && _c != null) {
      _c!.dispose();
      _c = null;
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c == null) {
      // ثابت (خفيف)
      return Stack(
        fit: StackFit.expand,
        children: [
          const GlobalBackground(),
          widget.child,
        ],
      );
    }

    // أنيميشن خفيف (أخف من السابق: بدون Blur/طبقات ثقيلة)
    return AnimatedBuilder(
      animation: _c!,
      builder: (context, _) {
        final t = _c!.value;
        final angle = t * 2 * math.pi;

        const purple = Color(0xFF8A2BE2);
        const black = Color(0xFF0E0E12);

        final glowCenter = Alignment(
          math.cos(angle) * 0.15,
          math.sin(angle) * 0.15,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // أساس ثابت
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [purple, black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // توهّج Radial يتحرك ببطء
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: glowCenter,
                  radius: 1.0,
                  colors: [purple.withOpacity(0.12), Colors.transparent],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
