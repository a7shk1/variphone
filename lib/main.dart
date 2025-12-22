import 'package:flutter/material.dart';
import 'player/player_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
    );
  }
}
