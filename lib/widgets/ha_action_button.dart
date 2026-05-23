import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HaActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isOn;
  final bool isUnavailable;
  final Color activeColor;
  final VoidCallback? onTap;

  const HaActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isOn,
    this.isUnavailable = false,
    this.activeColor = const Color(0xFF00D4FF),
    this.onTap,
  });

  @override
  State<HaActionButton> createState() => _HaActionButtonState();
}

class _HaActionButtonState extends State<HaActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isUnavailable || widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _pressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _pressed = false);
    });
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isUnavailable
        ? Colors.white24
        : widget.isOn
            ? widget.activeColor
            : Colors.white38;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 82,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: widget.isOn && !widget.isUnavailable
                ? widget.activeColor.withValues(alpha: 0.1)
                : const Color(0xFF13132E),
            border: Border.all(
              color: widget.isOn && !widget.isUnavailable
                  ? widget.activeColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
            boxShadow: widget.isOn && !widget.isUnavailable
                ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 1,
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                    )
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec glow animé si ON
              widget.isOn && !widget.isUnavailable
                  ? AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor
                                  .withValues(alpha: _pulse.value * 0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Icon(widget.icon, color: color, size: 28),
                      ),
                    )
                  : Icon(widget.icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Indicateur d'état compact
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isUnavailable
                      ? Colors.white24
                      : widget.isOn
                          ? widget.activeColor
                          : Colors.white24,
                  boxShadow: widget.isOn && !widget.isUnavailable ? [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.7),
                      blurRadius: 6,
                    )
                  ] : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
