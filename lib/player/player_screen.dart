import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'stream_resolver.dart';

enum _Backend { videoPlayer, vlc }

class PlayerScreen extends StatefulWidget {
  final String rawLink;
  const PlayerScreen({super.key, required this.rawLink});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _vp;
  VlcPlayerController? _vlc;
  _Backend? _backend;

  String _status = 'Opening Player...';
  bool _showUi = true;
  bool _fitCover = true;
  bool _isRestarting = false;
  double _volume = 1.0;

  int _epoch = 0;
  int _retryCount = 0;
  Timer? _retryTimer;
  Duration _retryDelay = const Duration(seconds: 3);
  static const _retryDelayMax = Duration(seconds: 15);
  static const _retryMax = 8;

  String? _url;
  Map<String, String> _headers = const {};

  final List<String> _logs = [];
  void _log(String s) {
    dev.log(s, name: 'VarPlayer');
    if (!mounted) return;
    setState(() {
      _logs.add(s);
      if (_logs.length > 25) _logs.removeAt(0);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _safeSetupUi();
      await _openFromRaw(widget.rawLink);
    });
  }

  Future<void> _safeSetupUi() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      _log('UI mode + landscape OK');
    } catch (e) {
      _log('UI setup error: $e');
    }

    try {
      await WakelockPlus.enable();
      _log('Wakelock enabled OK');
    } catch (e) {
      _log('Wakelock error: $e');
    }
  }

  @override
  void dispose() {
    _epoch++;
    _retryTimer?.cancel();

    _vp?.dispose();
    _vlc?.dispose();

    WidgetsBinding.instance.removeObserver(this);

    () async {
      try { await WakelockPlus.disable(); } catch (_) {}
      try { await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); } catch (_) {}
      try { await SystemChrome.setPreferredOrientations(DeviceOrientation.values); } catch (_) {}
    }();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _vp?.pause();
      _vlc?.pause();
      () async { try { await WakelockPlus.disable(); } catch (_) {} }();
    } else if (s == AppLifecycleState.resumed) {
      () async { try { await WakelockPlus.enable(); } catch (_) {} }();
    }
  }

  Future<void> _openFromRaw(String raw) async {
    _log('Incoming rawLink length=${raw.length}');
    final parsed = StreamResolver.parseIncoming(raw);
    final url = parsed.url;
    if (url == null) {
      setState(() => _status = 'Bad link');
      _log('Bad link (parseIncoming returned null)');
      return;
    }

    _url = url;
    _headers = parsed.headers;
    _retryCount = 0;
    _retryDelay = const Duration(seconds: 3);

    _log('Parsed URL: $url');
    _log('Headers count: ${_headers.length}');

    await _openResolved(url, _headers);
  }

  Future<void> _openResolved(String url, Map<String, String> headers) async {
    final myEpoch = ++_epoch;
    _retryTimer?.cancel();
    setState(() {
      _status = 'Resolving...';
      _isRestarting = true;
    });
    _log('Resolving...');

    try {
      final res = await StreamResolver.resolve(
        url,
        headers: headers,
        preferHls: Platform.isIOS,
      );

      if (!mounted || myEpoch != _epoch) return;

      _log('Resolved URL: ${res.url}');
      _url = res.url;
      _headers = res.headers;

      await _openBackend(res.url, res.headers, myEpoch);
    } catch (e) {
      _log('resolve failed: $e');
      _scheduleRetry(url, myEpoch, headers, forceResolve: true);
    }
  }

  _Backend _pickBackend(String url) {
    if (Platform.isIOS) return _Backend.vlc;
    return _Backend.videoPlayer;
  }

  Future<void> _openBackend(String url, Map<String, String> headers, int myEpoch) async {
    final backend = _pickBackend(url);
    _backend = backend;

    if (backend == _Backend.vlc) {
      await _openVlc(url, headers, myEpoch);
    } else {
      await _openVideoPlayer(url, headers, myEpoch);
    }
  }

  Future<void> _openVideoPlayer(String url, Map<String, String> headers, int myEpoch) async {
    final old = _vp;

    setState(() {
      _status = 'Initializing player...';
      _isRestarting = true;
    });
    _log('Using backend: video_player');

    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _vp = ctrl;

    try {
      await ctrl.initialize();
      if (!mounted || myEpoch != _epoch) return;

      await ctrl.setLooping(true);
      await ctrl.setVolume(_volume);

      ctrl.addListener(() {
        final v = ctrl.value;
        if (v.hasError && mounted && myEpoch == _epoch) {
          _log('VP error: ${v.errorDescription}');
          _scheduleRetry(url, myEpoch, headers);
        }
      });

      await ctrl.play();
      try { await old?.dispose(); } catch (_) {}

      setState(() {
        _status = 'Playing';
        _isRestarting = false;
        _retryCount = 0;
      });
      _log('Playing OK ✅ (video_player)');
      _kickAutoHide();
    } catch (e) {
      _log('VP initialize/play failed: $e');

      if (Platform.isIOS && mounted && myEpoch == _epoch) {
        _log('Switching to VLC fallback on iOS...');
        await _openVlc(url, headers, myEpoch);
        return;
      }

      if (mounted && myEpoch == _epoch) _scheduleRetry(url, myEpoch, headers);
    }
  }

  Future<void> _openVlc(String url, Map<String, String> headers, int myEpoch) async {
    final old = _vlc;

    setState(() {
      _status = 'Initializing VLC...';
      _isRestarting = true;
    });
    _log('Using backend: VLC');

    try { await old?.stop(); } catch (_) {}
    try { await old?.dispose(); } catch (_) {}

    final ua = headers['User-Agent'];
    final ref = headers['Referer'] ?? headers['Referrer'];

    final httpArgs = <String>[
      if (ua != null && ua.isNotEmpty) VlcHttpOptions.httpUserAgent(ua),
      if (ref != null && ref.isNotEmpty) VlcHttpOptions.httpReferrer(ref),
      VlcHttpOptions.httpReconnect(true),
      VlcHttpOptions.httpForwardCookies(true),
    ];

    final opts = VlcPlayerOptions(
      http: httpArgs.isEmpty ? null : VlcHttpOptions(httpArgs),
      // extras: [':network-caching=1500'], // إذا تحب تزيد البفر
    );

    final ctrl = VlcPlayerController.network(
      url,
      // على iOS إذا تشوف black screen جرّب disabled (مهم)
      hwAcc: Platform.isIOS ? HwAcc.disabled : HwAcc.auto,
      autoPlay: true,
      options: opts,
    );

    _vlc = ctrl;

    // ✅ مهم: initialize حسب الدوكمنتشن
    try {
      await ctrl.initialize();
    } catch (e) {
      _log('VLC initialize failed: $e');
      _scheduleRetry(url, myEpoch, headers);
      return;
    }

    try { await ctrl.setVolume((_volume * 100).round()); } catch (_) {}

    ctrl.addListener(() {
      final v = ctrl.value;
      if (!mounted || myEpoch != _epoch) return;

      if (v.hasError) {
        _log('VLC error: ${v.errorDescription}');
        _scheduleRetry(url, myEpoch, headers);
      }
    });

    // انتظر لحد ما يصير playing فعلاً
    final start = DateTime.now();
    while (mounted && myEpoch == _epoch && DateTime.now().difference(start).inSeconds < 6) {
      if (_vlc?.value.isPlaying == true) break;
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!mounted || myEpoch != _epoch) return;

    setState(() {
      _status = (_vlc?.value.isPlaying == true) ? 'Playing' : 'Buffering...';
      _isRestarting = false;
      _retryCount = 0;
    });

    _log('VLC state isPlaying=${_vlc?.value.isPlaying}');
    _kickAutoHide();
  }

  Duration _withJitter(Duration base) {
    final ms = base.inMilliseconds;
    final j = (ms * 0.2).toInt().clamp(1, 1 << 30);
    final out = ms + ((DateTime.now().microsecond % (j * 2)) - j);
    return Duration(milliseconds: out.clamp(500, _retryDelayMax.inMilliseconds));
  }

  void _scheduleRetry(String url, int myEpoch, Map<String, String> headers, {bool forceResolve = false}) {
    if (!mounted || myEpoch != _epoch) return;

    setState(() {
      _status = 'Reconnecting...';
      _isRestarting = true;
    });

    _retryCount = (_retryCount >= _retryMax) ? 0 : (_retryCount + 1);
    final next = (_retryDelay * 2) > _retryDelayMax ? _retryDelayMax : (_retryDelay * 2);
    _retryDelay = _withJitter(next);

    _log('Retry #$_retryCount in ${_retryDelay.inSeconds}s');

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () async {
      if (!mounted || myEpoch != _epoch) return;

      if (forceResolve) {
        await _openResolved(url, headers);
      } else {
        final u = _url ?? url;
        final h = _headers;
        await _openBackend(u, h, myEpoch);
      }
    });
  }

  void _kickAutoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUi = false);
    });
  }

  Future<void> _togglePlay() async {
    if (_backend == _Backend.vlc) {
      final c = _vlc;
      if (c == null) return;
      if (c.value.isPlaying == true) {
        await c.pause();
      } else {
        await c.play();
      }
      setState(() {});
      _kickAutoHide();
      return;
    }

    final c = _vp;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      await c.play();
    }
    setState(() {});
    _kickAutoHide();
  }

  Future<void> _applyVolume(double v) async {
    _volume = v;
    if (_backend == _Backend.vlc) {
      try { await _vlc?.setVolume((v * 100).round()); } catch (_) {}
    } else {
      try { await _vp?.setVolume(v); } catch (_) {}
    }
    if (mounted) setState(() {});
    _kickAutoHide();
  }

  bool get _initialized {
    if (_backend == _Backend.vlc) return _vlc?.value.isInitialized == true;
    return _vp?.value.isInitialized == true;
  }

  bool get _playing {
    if (_backend == _Backend.vlc) return _vlc?.value.isPlaying == true;
    return _vp?.value.isPlaying == true;
  }

  @override
  Widget build(BuildContext context) {
    Widget videoArea() {
      if (_backend == _Backend.vlc) {
        if (_vlc == null) return Text(_status, style: const TextStyle(color: Colors.white70));

        final ar = (_vlc!.value.aspectRatio == 0) ? 16 / 9 : _vlc!.value.aspectRatio;

        return VlcPlayer(
          controller: _vlc!,
          aspectRatio: ar,
          placeholder: Center(
            child: Text(_status, style: const TextStyle(color: Colors.white70)),
          ),
        );
      }

      final v = _vp?.value;
      final initialized = v?.isInitialized == true;
      if (!initialized || _vp == null) {
        return Text(_status, style: const TextStyle(color: Colors.white70));
      }

      final aspect = (v?.aspectRatio ?? 0) == 0 ? 16 / 9 : v!.aspectRatio;

      return FittedBox(
        fit: _fitCover ? BoxFit.cover : BoxFit.contain,
        child: SizedBox(
          width: 1280,
          height: 720,
          child: AspectRatio(
            aspectRatio: aspect,
            child: VideoPlayer(_vp!),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _showUi = !_showUi);
        if (_showUi) _kickAutoHide();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Center(child: videoArea())),

            if (_initialized && _isRestarting)
              const Positioned.fill(child: IgnorePointer(child: Center(child: CircularProgressIndicator()))),

            // ✅ زر رجوع واضح
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    color: Colors.black.withOpacity(0.45),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'رجوع',
                    ),
                  ),
                ),
              ),
            ),

            if (_initialized && _showUi)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 56),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
                              child: Text(
                                _backend == _Backend.vlc ? 'VLC' : 'VP',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: _fitCover ? 'Contain' : 'Cover',
                                  onPressed: () {
                                    setState(() => _fitCover = !_fitCover);
                                    _kickAutoHide();
                                  },
                                  icon: const Icon(Icons.fit_screen, color: Colors.white),
                                ),
                                IconButton(
                                  tooltip: 'Reload',
                                  onPressed: _url == null ? null : () => _openResolved(_url!, _headers),
                                  icon: const Icon(Icons.refresh, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 64,
                            color: Colors.white,
                            onPressed: _togglePlay,
                            icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
                          ),
                        ],
                      ),

                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.volume_up, size: 18, color: Colors.white70),
                              SizedBox(
                                width: 140,
                                child: Slider(
                                  min: 0,
                                  max: 1,
                                  value: _volume,
                                  onChanged: (v) => setState(() => _volume = v),
                                  onChangeEnd: (v) => _applyVolume(v),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // debug log panel
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.75,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      _logs.join('\n'),
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
