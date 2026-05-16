import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HaCameraCard extends StatefulWidget {
  final String baseUrl;
  final String token;
  final String entityId;
  final Duration refreshInterval;

  const HaCameraCard({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.entityId,
    this.refreshInterval = const Duration(seconds: 3),
  });

  @override
  State<HaCameraCard> createState() => _HaCameraCardState();
}

class _HaCameraCardState extends State<HaCameraCard> {
  Uint8List? _imageBytes;
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchSnapshot();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _fetchSnapshot());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSnapshot() async {
    try {
      final url = '${widget.baseUrl}/api/camera_proxy/${widget.entityId}';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 && mounted) {
        setState(() {
          _imageBytes = res.bodyBytes;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted && _imageBytes == null) {
        setState(() {
          _loading = false;
          _error = 'Caméra indisponible';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF0A0A1E),
        border: Border.all(
          color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.06),
            blurRadius: 20,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image
          if (_imageBytes != null)
            Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          else if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00D4FF),
                strokeWidth: 2,
              ),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.videocam_off_rounded,
                      color: Colors.white24, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _error ?? 'Caméra indisponible',
                    style: const TextStyle(color: Colors.white30, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Overlay gradient bas + label
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xCC000000), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFF4D6D),
                      boxShadow: [BoxShadow(
                        color: Color(0x99FF4D6D), blurRadius: 6,
                      )],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Caméra extérieure',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
