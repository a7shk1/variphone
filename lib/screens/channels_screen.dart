// lib/screens/channels_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories_static.dart';
import '../data/channels_repository.dart';
import '../models/channel.dart';
import '../utils/no_cache_url.dart';

// ✅ المشغل المدمج
import '../player/player_screen.dart';

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> {
  void _openEmbeddedPlayer({required String url, required String name}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(rawLink: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6D28D9);
    final mainCardBg = const Color(0xFF242A40);
    final mainBorder = purple.withOpacity(0.26);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tv, color: Colors.white),
            SizedBox(width: 8),
            Text("القنوات"),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.05,
        ),
        itemCount: kCategories.length,
        itemBuilder: (context, i) {
          final tile = kCategories[i];
          return _PressableScale(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _CategoryChannelsScreen(
                    categoryId: tile.id,
                    title: tile.title,
                    playlistUrl: tile.playlistUrl,
                    openEmbeddedPlayer: _openEmbeddedPlayer,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: mainCardBg,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: purple.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: mainBorder, width: 1),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 72,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _SmartTileIcon(
                          categoryId: tile.id,
                          primaryPath: tile.assetIcon,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tile.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChannelsScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final String playlistUrl;
  final void Function({required String url, required String name}) openEmbeddedPlayer;

  const _CategoryChannelsScreen({
    required this.categoryId,
    required this.title,
    required this.playlistUrl,
    required this.openEmbeddedPlayer,
  });

  @override
  State<_CategoryChannelsScreen> createState() => _CategoryChannelsScreenState();
}

class _CategoryChannelsScreenState extends State<_CategoryChannelsScreen> {
  final repo = ChannelsRepository();
  bool isLoading = true;
  String? error;
  List<Channel> channels = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final freshUrl = noCacheUrl(widget.playlistUrl);
      final fetched = await repo.fetchChannelsFromUrl(freshUrl);
      if (!mounted) return;
      setState(() {
        channels = fetched;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "فشل تحميل القنوات: $e";
        isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => isLoading = true);
    await _load();
  }

  String _assetFolder(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'seriaa':
        return 'assets/SeriaA';
      default:
        return 'assets/${categoryId.toLowerCase()}';
    }
  }

  String _slug(String s, {bool underscored = false, bool lower = false}) {
    var t = s.trim();
    if (lower) t = t.toLowerCase();
    t = t.replaceAll(RegExp(r'[^\p{L}\p{N}\s_\.-]+', unicode: true), '');
    t = t.replaceAll(RegExp(r'\s+'), underscored ? '_' : ' ');
    t = t.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    return t;
  }

  List<String> _logoCandidates(String categoryId, String channelName) {
    final folder = _assetFolder(categoryId);
    final raw = channelName.trim();
    final lc = raw.toLowerCase();
    final clean = _slug(raw, underscored: false, lower: false);
    final cleanLc = _slug(raw, underscored: false, lower: true);
    final under = _slug(raw, underscored: true, lower: true);

    final List<String> paths = [
      '$folder/$raw.png',
      '$folder/$lc.png',
      '$folder/$clean.png',
      '$folder/$under.png',
      '$folder/$cleanLc.png',
    ];

    final m = RegExp(r'(\d+)').firstMatch(raw);
    final num = m?.group(1);
    if (num != null) {
      switch (categoryId.toLowerCase()) {
        case 'bein':
          paths.add('$folder/bein$num.png');
          break;
        case 'dazn':
          paths.add('$folder/dazn$num.png');
          break;
        case 'espn':
          paths.add('$folder/espn$num.png');
          break;
        case 'mbc':
          paths.add('$folder/mbc$num.png');
          break;
        case 'premierleague':
          paths.add('$folder/premierleague$num.png');
          break;
        case 'roshnleague':
          paths.add('$folder/roshnleague$num.png');
          break;
        case 'generalsports':
          paths.add('$folder/generalsports$num.png');
          break;
        case 'seriaa':
          paths.addAll([
            '$folder/Stars Play $num.png',
            '$folder/Abu Dhabi Sports $num.png',
          ]);
          break;
      }
    }
    paths.add('$folder/logo.png');
    return paths.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(0xFF6D28D9);
    final innerCardBg = const Color(0xFF20263A);
    final innerBorder = purple.withOpacity(0.24);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text("إعادة المحاولة"),
          ),
        ]),
      )
          : RefreshIndicator(
        onRefresh: _refresh,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: channels.length,
          itemBuilder: (_, i) {
            final ch = channels[i];
            final candidates = _logoCandidates(widget.categoryId, ch.name);
            return _PressableScale(
              onPressed: () => widget.openEmbeddedPlayer(url: ch.url, name: ch.name),
              child: Container(
                decoration: BoxDecoration(
                  color: innerCardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: innerBorder, width: 1),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _SmartAssetLogo(candidates: candidates),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: Text(
                        ch.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.openEmbeddedPlayer(url: ch.url, name: ch.name),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text("Play"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 14),
                          minimumSize: const Size.fromHeight(36),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ======= Asset Manifest Resolver =======
class _AssetPathResolver {
  static Map<String, bool>? _allAssets;

  static Future<void> _ensureLoaded() async {
    if (_allAssets != null) return;
    final jsonStr = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> map = json.decode(jsonStr);
    _allAssets = {for (final k in map.keys) k: true};
  }

  static Future<String?> firstExisting(List<String> candidates) async {
    await _ensureLoaded();
    final assets = _allAssets!;
    for (final p in candidates) {
      if (assets.containsKey(p)) return p;
    }
    return null;
  }
}

class _SmartTileIcon extends StatefulWidget {
  final String categoryId;
  final String primaryPath;

  const _SmartTileIcon({required this.categoryId, required this.primaryPath});

  @override
  State<_SmartTileIcon> createState() => _SmartTileIconState();
}

class _SmartTileIconState extends State<_SmartTileIcon> {
  late final List<String> _candidates;
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _candidates = _buildCandidates(widget.categoryId, widget.primaryPath);
    _resolve();
  }

  List<String> _buildCandidates(String categoryId, String primary) {
    final List<String> c = [primary];
    if (categoryId.toLowerCase() == 'generalsports') {
      c.addAll([
        'assets/images/1.png',
        'assets/generalsports/logo.png',
      ]);
    } else {
      c.add('assets/${categoryId.toLowerCase()}/logo.png');
    }
    return c.toSet().toList();
  }

  Future<void> _resolve() async {
    final path = await _AssetPathResolver.firstExisting(_candidates);
    if (!mounted) return;
    setState(() => _resolved = path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved != null) {
      precacheImage(AssetImage(_resolved!), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return const Icon(Icons.live_tv, size: 48, color: Colors.white);
    }
    return Image.asset(
      _resolved!,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}

class _SmartAssetLogo extends StatefulWidget {
  final List<String> candidates;
  const _SmartAssetLogo({required this.candidates});

  @override
  State<_SmartAssetLogo> createState() => _SmartAssetLogoState();
}

class _SmartAssetLogoState extends State<_SmartAssetLogo> {
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final path = await _AssetPathResolver.firstExisting(widget.candidates);
    if (!mounted) return;
    setState(() => _resolved = path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_resolved != null) {
      precacheImage(AssetImage(_resolved!), context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return const Icon(Icons.tv, color: Colors.white, size: 48);
    }
    return Image.asset(
      _resolved!,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const _PressableScale({required this.child, required this.onPressed});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1.0;
  void _down(_) => setState(() => _scale = 0.98);
  void _up(_) => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: (d) => _up(d),
      onTapCancel: () => _up(null),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
