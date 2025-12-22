import 'package:flutter/material.dart';
import 'player/player_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Taps: $taps', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () {
                  setState(() => taps++);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _TestPage(),
                    ),
                  );
                },
                child: const Text('Open TEST page'),
              ),

              const SizedBox(height: 12),

              ElevatedButton(
                onPressed: () async {
                  setState(() => taps++);
                  try {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PlayerScreen(
                          rawLink:
                              'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: Text(e.toString()),
                      ),
                    );
                  }
                },
                child: const Text('Open Player'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestPage extends StatelessWidget {
  const _TestPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TEST')),
      body: const Center(child: Text('Navigator OK ✅', style: TextStyle(fontSize: 26))),
    );
  }
}
