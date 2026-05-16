import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/service.dart';
import 'status_badge.dart';

class ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final ServiceStatus? status;
  final bool hasCredentials;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.status,
    this.hasCredentials = false,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.service.color;
    final isPrinting = widget.service.id == 'klipper' &&
        (widget.status?.isPrinting ?? false);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF13132E), Color(0xFF0F0F26)],
                ),
                border: Border.all(
                  color: color.withValues(alpha: isPrinting ? 0.5 : 0.18),
                  width: isPrinting ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isPrinting ? 0.25 : 0.10),
                    blurRadius: isPrinting ? 20 : 14,
                    spreadRadius: 0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  top: -14,
                  right: -14,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(
                              alpha: isPrinting ? 0.25 : 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                ..._buildStars(color),
                Positioned.fill(
                  child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.12),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(widget.service.icon,
                            color: color, size: 20),
                      ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.service.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: isPrinting
                      ? _buildPrintingBadge()
                      : StatusBadge(status: widget.status),
                ),
                if (widget.hasCredentials)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Icon(
                      Icons.key_rounded,
                      size: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                if (widget.service.isCloudService)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18BCF2)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFF18BCF2)
                              .withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text('☁',
                          style: TextStyle(fontSize: 8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrintingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withValues(alpha: 0.15),
        border: Border.all(color: const Color(0xFFFF6B35), width: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('🖨️', style: TextStyle(fontSize: 8)),
    );
  }

  List<Widget> _buildStars(Color color) {
    final rng = math.Random(widget.service.id.hashCode);
    return List.generate(4, (i) {
      final x = rng.nextDouble() * 80;
      final y = rng.nextDouble() * 80;
      final size = rng.nextDouble() * 1.5 + 0.5;
      return Positioned(
        left: x,
        top: y,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white
                .withValues(alpha: rng.nextDouble() * 0.3 + 0.05),
          ),
        ),
      );
    });
  }
}
