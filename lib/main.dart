// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/animated_gradient_background.dart';

import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/developer_info_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ✅ DEMO MODE:
/// - true  => يدخل Home مباشرة (بدون اشتراك/فايربيس)
/// - false => يفتح SubscriptionScreen
const bool kBypassSubscriptions = true;

/// مدة بقاء السبلاتش (حتى يبين بشكل حلو)
const Duration kSplashMinDuration = Duration(milliseconds: 1200);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details);
    };

    runApp(const VarApp());

    // ✅ لا نسوي أي await قبل runApp حتى ما يعلق iOS
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapAfterFirstFrame();
    });
  }, (error, stack) {
    debugPrint('ZONED ERROR: $error');
    debugPrint('$stack');
  });
}

Future<void> _bootstrapAfterFirstFrame() async {
  // ✅ نخلي السبلاتش يثبت شوي
  await Future.delayed(kSplashMinDuration);

  final nav = navigatorKey.currentState;
  if (nav == null) return;

  // ✅ بدون Firebase: قرر وين تروح
  if (kBypassSubscriptions) {
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  } else {
    nav.pushReplacement(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }
}

class VarApp extends StatelessWidget {
  const VarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Var IPTV',
      debugShowCheckedModeBanner: false,
<<<<<<< HEAD
      theme: AppTheme.darkTheme,
      navigatorKey: navigatorKey,

      // ✅ خلفية متحركة/تدرج مثل مشروعك
      builder: (context, child) {
        return Stack(
          children: [
            const Positioned.fill(child: GlobalBackground()),
            if (child != null) child,
          ],
        );
      },

      routes: {
        '/privacy': (_) => const PrivacyPolicyScreen(),
        '/contact': (_) => const ContactScreen(),
        '/developer': (_) => const DeveloperInfoScreen(),
      },

      // ✅ نبدأ بالسبلاتش دائماً
      home: const SplashScreen(),
=======
      home: const HomeMenu(),
    );
  }
}

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Taps: $taps', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: () {
                setState(() => taps++);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TestPage()),
                );
              },
              child: const Text('Open TEST page'),
            ),

            const SizedBox(height: 14),

            ElevatedButton(
              onPressed: () {
                setState(() => taps++);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayerScreen(
                      rawLink:
                          'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
                    ),
                  ),
                );
              },
              child: const Text('Open Player'),
            ),
          ],
        ),
      ),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEST')),
      body: const Center(
        child: Text(
          'Navigator OK ✅',
          style: TextStyle(fontSize: 26),
        ),
      ),
>>>>>>> a422841686eb761c24ce6f3e0c5e87d689426121
    );
  }
}
