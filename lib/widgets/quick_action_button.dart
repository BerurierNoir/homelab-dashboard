import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/quick_action.dart';
import '../providers/quick_actions_provider.dart';
import '../services/http_client_factory.dart';

enum _BtnState { idle, loading, success, error }

class QuickActionButton extends ConsumerStatefulWidget {
  final QuickAction action;
  const QuickActionButton({super.key, required this.action});

  @override
  ConsumerState<QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends ConsumerState<QuickActionButton>
    with SingleTickerProviderStateMixin {
  _BtnState _state = _BtnState.idle;
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = buildTrustingClient();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _client.close();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _trigger() async {
    if (_state == _BtnState.loading) return;
    setState(() => _state = _BtnState.loading);

    bool ok;
    try {
      if (widget.action.isWol) {
        ok = await _sendWol(
            widget.action.wolMac ?? '', widget.action.wolBroadcast);
      } else {
        ok = await _sendHttp();
      }
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _state = ok ? _BtnState.success : _BtnState.error);
    _pulse.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() => _state = _BtnState.idle);
      _pulse.reverse();
    }
  }

  Future<bool> _sendHttp() async {
    final scheme = Uri.tryParse(widget.action.url)?.scheme ?? '';
    if (scheme != 'http' && scheme != 'https') return false;

    final auth = await ref
        .read(quickActionsProvider.notifier)
        .getAuthorization(widget.action.id);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (auth != null && auth.isNotEmpty) 'Authorization': auth,
    };

    final uri = Uri.parse(widget.action.url);
    final res = widget.action.method == 'GET'
        ? await _client.get(uri, headers: headers).timeout(const Duration(seconds: 10))
        : await _client
            .post(uri, headers: headers, body: widget.action.body ?? '')
            .timeout(const Duration(seconds: 10));

    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<bool> _sendWol(String mac, String broadcastIp) async {
    // Parse MAC — accepts AA:BB:CC:DD:EE:FF or AA-BB-CC-DD-EE-FF
    final parts = mac.split(RegExp(r'[:\-]'));
    if (parts.length != 6) return false;
    final macBytes = <int>[];
    for (final part in parts) {
      final byte = int.tryParse(part, radix: 16);
      if (byte == null || byte < 0 || byte > 255) return false;
      macBytes.add(byte);
    }

    // Magic packet: 6× 0xFF then MAC repeated 16 times (102 bytes total)
    final packet = Uint8List(102);
    for (int i = 0; i < 6; i++) {
      packet[i] = 0xFF;
    }
    for (int i = 0; i < 16; i++) {
      packet.setRange(6 + i * 6, 6 + i * 6 + 6, macBytes);
    }

    final socket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    socket.send(packet, InternetAddress(broadcastIp), 9);
    socket.close();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    final baseColor = action.color;

    final Color tint = switch (_state) {
      _BtnState.success => const Color(0xFF4CAF50),
      _BtnState.error => const Color(0xFFFF4444),
      _ => baseColor,
    };

    final IconData ico = switch (_state) {
      _BtnState.success => Icons.check_rounded,
      _BtnState.error => Icons.close_rounded,
      _ => action.icon,
    };

    return GestureDetector(
      onTap: _trigger,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Container(
          width: 80,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF13132E), Color(0xFF0F0F26)],
            ),
            border: Border.all(
              color: tint.withValues(
                  alpha: _state == _BtnState.idle ? 0.3 : 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tint.withValues(
                  alpha: _state == _BtnState.idle
                      ? 0.12
                      : 0.4 * _pulseAnim.value,
                ),
                blurRadius: _state == _BtnState.idle ? 6 : 18,
                spreadRadius: _state == _BtnState.idle ? 0 : 2,
              ),
            ],
          ),
          child: child,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: _state == _BtnState.loading
                    ? CircularProgressIndicator(
                        strokeWidth: 2, color: baseColor)
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(ico,
                            key: ValueKey(_state), size: 26, color: tint),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                action.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
