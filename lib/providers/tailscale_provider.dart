import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TailscaleStatus { unknown, connected, disconnected }

class TailscaleNotifier extends StateNotifier<TailscaleStatus>
    with WidgetsBindingObserver {
  TailscaleNotifier() : super(TailscaleStatus.unknown) {
    WidgetsBinding.instance.addObserver(this);
    _check();
    _startPolling();
  }

  Timer? _timer;

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
  }

  Future<void> _check() async {
    try {
      // 100.100.100.100 is Tailscale's MagicDNS — only reachable when the VPN is active
      final socket = await Socket.connect(
        '100.100.100.100',
        53,
        timeout: const Duration(seconds: 2),
      );
      socket.destroy();
      if (mounted) state = TailscaleStatus.connected;
    } catch (_) {
      if (mounted) state = TailscaleStatus.disconnected;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}

final tailscaleProvider =
    StateNotifierProvider<TailscaleNotifier, TailscaleStatus>(
        (_) => TailscaleNotifier());
