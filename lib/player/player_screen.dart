import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'stream_resolver.dart';

class PlayerScreen extends StatefulWidget {
  final String rawLink; // يدعم http أو varplayer:// أو payload
  const PlayerScreen({super.key, required this.rawLink});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _ctrl;

  // UI state
  String _status = 'Opening Player...';
  bool _showUi = true;
  bool _fitCover = true;
  bool _isRestarting = false;
  double _volume = 1.0;

  // retry
  int _epoch = 0;
  int _retryCount = 0;
  Timer? _retryTimer;
  Duration _retryDelay = const Duration(seconds: 3);
  static const _retryDelayMax = Duration(seconds: 15);
  static const _retryMax = 8;

  String? _url;
  Map<String, String> _headers = const {};

  // on-screen logs
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
    _ctrl?.dispose();
    WidgetsBinding.instance.removeObserver(this);

    () async {
      try {
        await WakelockPlus.disable();
      } catch (_) {}
      try {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } catch (_) {}
      try {
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      } catch (_) {}
    }();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _ctrl?.pause();
      () async {
        try {
          await WakelockPlus.disable();
        } catch (_) {}
      }();
    } else if (s == AppLifecycleState.resumed) {
      () async {
        try {
          await WakelockPlus.enable();
        } catch (_) {}
      }();
    }
  }

  // ---------- Core open ----------
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

    await _openResolved(url, _headers, preferHls: Platform.isIOS);
  }

  Future<void> _openResolved(
    String url,
    Map<String, String> headers, {
    required bool preferHls,
  }) async {
    final myEpoch = ++_epoch;
    _retryTimer?.cancel();

    setState(() {
      _status = 'Resolving...';
      _isRestarting = true;
    });
    _log('Resolving... preferHls=$preferHls');

    try {
      final res = await StreamResolver.resolve(
        url,
        headers: headers,
        preferHls: preferHls,
      );
      if (!mounted || myEpoch != _epoch) return;

      _log('Resolved URL: ${res.url}');
      _url = res.url;
      _headers = res.headers;

      await _openController(res.url, res.headers, myEpoch);
    } catch (e) {
      _log('resolve failed: $e');
      _scheduleRetry(url, myEpoch, headers, forceResolve: true);
    }
  }

  Future<void> _openController(String url, Map<String, String> headers, int myEpoch) async {
    final old = _ctrl;

    setState(() {
      _status = 'Initializing player...';
      _isRestarting = true;
    });
    _log('Creating VideoPlayerController...');

    final ctrl = VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: headers,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _ctrl = ctrl;

    try {
      await ctrl.initialize();
      if (!mounted || myEpoch != _epoch) return;

      await ctrl.setLooping(true);
      await ctrl.setVolume(_volume);

      ctrl.addListener(() {
        final v = ctrl.value;
        if (!mounted || myEpoch != _epoch) return;

        if (v.hasError) {
          final err = (v.errorDescription ?? '').toLowerCase();
          _log('Player error: ${v.errorDescription}');

          // ✅ iOS AVPlayer: إذا خطأ byte-range/content-length نحاول نعيد Resolve مع تفضيل HLS
          final looksLikeRangeIssue =
              err.contains('coremediaerrordomain') ||
              err.contains('-12939') ||
              err.contains('byte range') ||
              err.contains('content length');

          if (Platform.isIOS && looksLikeRangeIssue) {
            _log('iOS range/content-length issue detected -> retry with HLS preference');
            _openResolved(_url ?? url, _headers, preferHls: true);
            return;
          }

          _scheduleRetry(url, myEpoch, headers);
        }
      });

      await ctrl.play();
      try {
        await old?.dispose();
      } catch (_) {}

      setState(() {
        _status = 'Playing';
        _isRestarting = false;
        _retryCount = 0;
      });
      _log('Playing OK ✅');
      _kickAutoHide();
    } catch (e) {
      _log('initialize/play failed: $e');
      if (mounted && myEpoch == _epoch) _scheduleRetry(url, myEpoch, headers);
    }
  }

  // ---------- Retry ----------
  Duration _withJitter(Duration base) {
    final ms = base.inMilliseconds;
    final j = (ms * 0.2).toInt();
    final out = ms + ((DateTime.now().microsecond % (j * 2)) - j);
    return Duration(milliseconds: out.clamp(500, _retryDelayMax.inMilliseconds));
  }

  void _scheduleRetry(
    String url,
    int myEpoch,
    Map<String, String> headers, {
    bool forceResolve = false,
  }) {
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
        await _openResolved(url, headers, preferHls: Platform.isIOS);
      } else {
        await _openController(_url ?? url, _headers, myEpoch);
      }
    });
  }

  // ---------- UI helpers ----------
  void _kickAutoHide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUi = false);
    });
  }

  bool get _isVod {
    final v = _ctrl?.value;
    final d = v?.duration;
    final u = (_url ?? '').toLowerCase();
    if (d != null && d > Duration.zero) return true;
    if (u.contains('.mp4') || u.contains('.mpd')) return true;
    return false;
  }

  Future<void> _jumpToLiveEdge() async {
    final c = _ctrl;
    if (c == null) return;

    final ranges = c.value.buffered;
    if (ranges.isEmpty) return;

    final end = ranges.last.end;
    if (end <= Duration.zero) return;

    await c.seekTo(end);
    if (!c.value.isPlaying) await c.play();
    setState(() => _isRestarting = false);
    _kickAutoHide();
  }

  @override
  Widget build(BuildContext context) {
    final v = _ctrl?.value;
    final initialized = v?.isInitialized == true;
    final playing = v?.isPlaying == true;
    final buffering = v?.isBuffering == true;

    final aspect = (v?.aspectRatio ?? 0) == 0 ? 16 / 9 : v!.aspectRatio;

    final duration = v?.duration ?? Duration.zero;
    final position = v?.position ?? Duration.zero;
    final buffered = v?.buffered ?? const <DurationRange>[];

    Widget videoArea() {
      if (!initialized || _ctrl == null) {
        return Text(_status, style: const TextStyle(color: Colors.white70));
      }
      return FittedBox(
        fit: _fitCover ? BoxFit.cover : BoxFit.contain,
        child: SizedBox(
          width: 1280,
          height: 720,
          child: AspectRatio(
            aspectRatio: aspect,
            child: VideoPlayer(_ctrl!),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _showUi = !_showUi);
        if (_showUi) _kickAutoHide();
      },
      onDoubleTapDown: (d) {
        if (!_isVod || _ctrl == null) return;
        final w = MediaQuery.of(context).size.width;
        final back = d.localPosition.dx < w / 2;
        final delta = const Duration(seconds: 10);
        final newPos = back ? position - delta : position + delta;
        _ctrl!.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
        setState(() => _showUi = true);
        _kickAutoHide();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: Center(child: videoArea())),

            if (initialized && (buffering || _isRestarting))
              const Positioned.fill(child: IgnorePointer(child: Center(child: CircularProgressIndicator()))),

            // ✅ زر رجوع واضح (دائم)
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

            // Controls overlay
            if (initialized && _showUi)
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
                              child: Text(_isVod ? 'VOD' : 'LIVE',
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _jumpToLiveEdge,
                                  child: const Text('LIVE',
                                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
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
                                  onPressed: _url == null ? null : () => _openResolved(_url!, _headers, preferHls: Platform.isIOS),
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
                            onPressed: () async {
                              if (_ctrl == null) return;
                              if (playing) {
                                await _ctrl!.pause();
                              } else {
                                await _ctrl!.play();
                              }
                              setState(() {});
                              _kickAutoHide();
                            },
                            icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                          ),
                        ],
                      ),

                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isVod)
                                _BufferedBar(
                                  duration: duration,
                                  position: position,
                                  ranges: buffered,
                                  onSeek: (to) => _ctrl?.seekTo(to),
                                )
                              else
                                const LinearProgressIndicator(value: null, backgroundColor: Colors.white24, minHeight: 3),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(_isVod ? _fmt(position) : 'LIVE',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const Spacer(),
                                  if (_isVod)
                                    Text(_fmt(duration),
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.volume_up, size: 18, color: Colors.white70),
                                  SizedBox(
                                    width: 140,
                                    child: Slider(
                                      min: 0,
                                      max: 1,
                                      value: _volume,
                                      onChanged: (v) => setState(() => _volume = v),
                                      onChangeEnd: (v) async {
                                        await _ctrl?.setVolume(v);
                                        _kickAutoHide();
                                      },
                                    ),
                                  ),
                                ],
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

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours, m = d.inMinutes.remainder(60), s = d.inSeconds.remainder(60);
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}

class _BufferedBar extends StatelessWidget {
  final Duration duration, position;
  final List<DurationRange> ranges;
  final ValueChanged<Duration> onSeek;

  const _BufferedBar({
    required this.duration,
    required this.position,
    required this.ranges,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final totalMs = duration.inMilliseconds.clamp(1, 1 << 31);
    final playedMs = position.inMilliseconds.clamp(0, totalMs);

    return LayoutBuilder(
      builder: (_, cons) {
        final w = cons.maxWidth;
        double msToPx(int ms) => (ms / totalMs) * w;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) {
            final r = (d.localPosition.dx / w).clamp(0.0, 1.0);
            onSeek(Duration(milliseconds: (totalMs * r).round()));
          },
          onHorizontalDragUpdate: (d) {
            final r = (d.localPosition.dx / w).clamp(0.0, 1.0);
            onSeek(Duration(milliseconds: (totalMs * r).round()));
          },
          child: SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(height: 3, color: Colors.white24),
                ...ranges.map((r) {
                  final left = msToPx(r.start.inMilliseconds);
                  final right = msToPx(r.end.inMilliseconds);
                  return Positioned(
                    left: left.clamp(0.0, w),
                    width: (right - left).clamp(0.0, w),
                    top: 0,
                    bottom: 0,
                    child: Container(height: 3, color: Colors.white54),
                  );
                }),
                Positioned(
                  left: 0,
                  width: msToPx(playedMs),
                  top: 0,
                  bottom: 0,
                  child: Container(height: 3, color: Colors.white),
                ),
                Positioned(
                  left: (msToPx(playedMs) - 6).clamp(0.0, w - 12),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
