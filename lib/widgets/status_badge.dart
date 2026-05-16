import 'package:flutter/material.dart';
import '../models/service.dart';

class StatusBadge extends StatefulWidget {
  final ServiceStatus? status;

  const StatusBadge({super.key, this.status});

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUp = widget.status?.isUp;

    Color dotColor;
    bool animate = false;
    if (isUp == null) {
      dotColor = Colors.white24;
    } else if (isUp) {
      dotColor = const Color(0xFF5CDD8B);
      animate = true;
    } else {
      dotColor = const Color(0xFFFF4D6D);
    }

    if (animate) {
      return AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, _) => _buildDot(dotColor, _pulseAnim.value),
      );
    }
    return _buildDot(dotColor, 1.0);
  }

  Widget _buildDot(Color color, double opacity) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.status?.isUp == true)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: opacity * 0.3),
            ),
          ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: widget.status?.isUp == true
                ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)]
                : null,
          ),
        ),
      ],
    );
  }
}
