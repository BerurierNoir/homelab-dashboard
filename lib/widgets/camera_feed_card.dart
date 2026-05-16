import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/camera_config.dart';
import '../screens/camera_fullscreen.dart';

class CameraFeedCard extends StatefulWidget {
  final CameraConfig config;
  final String streamUrl;

  const CameraFeedCard({
    super.key,
    required this.config,
    required this.streamUrl,
  });

  @override
  State<CameraFeedCard> createState() => _CameraFeedCardState();
}

class _CameraFeedCardState extends State<CameraFeedCard>
    with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;

  bool _hasError = false;
  // Suppresses the error listener while we're intentionally reconnecting,
  // preventing the race where open() generates a transition error that
  // immediately overwrites our hasError=false reset.
  bool _ignoreErrors = false;

  StreamSubscription<String>? _errorSub;
  Timer? _retryTimer;
  Timer? _watchdog;
  int _retryCount = 0;
  bool _stoppedIntentionally = false;

  static const _maxRetries = 8;
  static const _retryDelay = Duration(seconds: 4);
  static const _watchdogInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = Player();
    _controller = VideoController(_player);
    _errorSub = _player.stream.error.listen((err) {
      if (mounted && err.isNotEmpty && !_ignoreErrors) {
        _scheduleRetry();
      }
    });
    _startStream();
  }

  void _startStream() {
    _retryTimer?.cancel();
    _retryCount = 0;
    _stoppedIntentionally = false;
    _ignoreErrors = true;
    if (mounted) setState(() => _hasError = false);
    _player.open(Media(widget.streamUrl), play: true);
    // Allow error reporting again once the player has settled
    Future.delayed(const Duration(seconds: 2), () { if (mounted) _ignoreErrors = false; });
    _resetWatchdog();
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      if (mounted) setState(() => _hasError = true);
      return;
    }
    _retryCount++;
    _retryTimer = Timer(_retryDelay, () {
      if (mounted && !_stoppedIntentionally) _reconnect();
    });
  }

  void _reconnect() {
    _ignoreErrors = true;
    _player.open(Media(widget.streamUrl), play: true);
    Future.delayed(const Duration(seconds: 2), () { if (mounted) _ignoreErrors = false; });
    _resetWatchdog();
  }

  void _resetWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(_watchdogInterval, (_) {
      if (!mounted || _stoppedIntentionally || _hasError) return;
      if (!_player.state.playing && !_ignoreErrors) {
        _scheduleRetry();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startStream();
    } else if (state == AppLifecycleState.paused) {
      _stoppedIntentionally = true;
      _retryTimer?.cancel();
      _watchdog?.cancel();
      // stop() fully closes the RTSP connection so the camera
      // doesn't hold a dangling half-open session.
      _player.stop();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _watchdog?.cancel();
    _errorSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.config.color;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CameraFullscreen(
            config: widget.config,
            streamUrl: widget.streamUrl,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF13132E), Color(0xFF0F0F26)],
          ),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.videocam_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      widget.config.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.fullscreen_rounded,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ),
              ),
              SizedBox(
                height: 200,
                width: double.infinity,
                child: _hasError ? _buildOffline() : _buildVideo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideo() {
    return Stack(
      children: [
        Video(
          controller: _controller,
          controls: NoVideoControls,
          fit: BoxFit.cover,
        ),
        StreamBuilder<bool>(
          stream: _player.stream.playing,
          builder: (context, snap) {
            final playing = snap.data ?? false;
            return AnimatedOpacity(
              opacity: playing ? 0 : 1,
              duration: const Duration(milliseconds: 500),
              child: Container(
                color: const Color(0xFF0F0F26),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.config.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _retryCount > 0
                            ? 'Reconnexion…'
                            : 'Connexion…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOffline() {
    return Container(
      color: const Color(0xFF0F0F26),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_rounded,
                size: 36, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 8),
            Text(
              'Hors ligne',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _startStream,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label:
                  const Text('Réessayer', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: widget.config.color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
