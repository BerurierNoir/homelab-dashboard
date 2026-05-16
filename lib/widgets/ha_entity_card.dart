import 'package:flutter/material.dart';
import '../models/ha_entity.dart';

class HaEntityCard extends StatelessWidget {
  final HaEntity entity;
  final VoidCallback? onTap;
  final bool compact;

  const HaEntityCard({
    super.key,
    required this.entity,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = entity.isOn;
    final unavailable = entity.isUnavailable;
    final color = _entityColor();
    final icon = _entityIcon();

    return GestureDetector(
      onTap: unavailable ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF13132E),
          border: Border.all(
            color: isOn && !unavailable
                ? color.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: isOn && !unavailable
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                  )
                ],
        ),
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: compact ? _buildCompact(icon, color, isOn, unavailable)
            : _buildFull(icon, color, isOn, unavailable),
      ),
    );
  }

  Widget _buildFull(IconData icon, Color color, bool isOn, bool unavailable) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOn && !unavailable
                    ? color.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
              ),
              child: Icon(
                icon,
                color: unavailable
                    ? Colors.white24
                    : isOn
                        ? color
                        : Colors.white38,
                size: 20,
              ),
            ),
            const Spacer(),
            if (!unavailable)
              _stateChip(isOn, color),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          entity.friendlyName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          _stateLabel(),
          style: TextStyle(
            color: unavailable ? Colors.white24 : Colors.white38,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(IconData icon, Color color, bool isOn, bool unavailable) {
    return Row(
      children: [
        Icon(
          icon,
          color: unavailable ? Colors.white24 : isOn ? color : Colors.white38,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entity.friendlyName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _stateLabel(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (!unavailable) _stateChip(isOn, color),
      ],
    );
  }

  Widget _stateChip(bool isOn, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isOn ? color.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
      ),
      child: Text(
        isOn ? 'ON' : 'OFF',
        style: TextStyle(
          color: isOn ? color : Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _entityColor() {
    switch (entity.domain) {
      case 'light':
        return const Color(0xFFE8C000);
      case 'switch':
        return const Color(0xFF5CDD8B);
      case 'cover':
        return entity.isOn
            ? const Color(0xFFFF4D6D)
            : const Color(0xFF5CDD8B);
      case 'alarm_control_panel':
        return entity.isOn
            ? const Color(0xFFFF4D6D)
            : const Color(0xFF5CDD8B);
      case 'person':
        return entity.state == 'home'
            ? const Color(0xFF5CDD8B)
            : const Color(0xFFFF9800);
      case 'binary_sensor':
        return entity.isOn
            ? const Color(0xFFFF4D6D)
            : const Color(0xFF5CDD8B);
      case 'sensor':
        return const Color(0xFF00D4FF);
      case 'media_player':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF00D4FF);
    }
  }

  IconData _entityIcon() {
    switch (entity.domain) {
      case 'light':
        return entity.isOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded;
      case 'switch':
        return entity.isOn ? Icons.toggle_on_rounded : Icons.toggle_off_rounded;
      case 'cover':
        final id = entity.entityId;
        if (id.contains('garage')) return Icons.garage_rounded;
        if (id.contains('portail') || id.contains('gate')) return Icons.door_sliding_rounded;
        return Icons.blinds_rounded;
      case 'alarm_control_panel':
        return entity.isOn ? Icons.security_rounded : Icons.shield_outlined;
      case 'person':
        return entity.state == 'home' ? Icons.home_rounded : Icons.near_me_rounded;
      case 'binary_sensor':
        final id = entity.entityId;
        if (id.contains('fenetre') || id.contains('window')) {
          return entity.isOn ? Icons.window : Icons.window_outlined;
        }
        if (id.contains('porte') || id.contains('door')) {
          return entity.isOn ? Icons.door_front_door_rounded : Icons.door_front_door_outlined;
        }
        if (id.contains('motion') || id.contains('mouvement')) {
          return Icons.motion_photos_on_rounded;
        }
        return entity.isOn ? Icons.circle_rounded : Icons.circle_outlined;
      case 'sensor':
        final id = entity.entityId;
        if (id.contains('temperature') || id.contains('temp')) return Icons.thermostat_rounded;
        if (id.contains('humidity') || id.contains('humidi')) return Icons.water_drop_rounded;
        if (id.contains('steam')) return Icons.sports_esports_rounded;
        if (id.contains('print_time') || id.contains('temps')) return Icons.timer_rounded;
        if (id.contains('wind')) return Icons.air_rounded;
        if (id.contains('uv')) return Icons.wb_sunny_rounded;
        return Icons.sensors_rounded;
      case 'media_player':
        return Icons.speaker_rounded;
      case 'calendar':
        return Icons.calendar_month_rounded;
      default:
        return Icons.device_hub_rounded;
    }
  }

  String _stateLabel() {
    if (entity.isUnavailable) return 'Indisponible';
    switch (entity.domain) {
      case 'cover':
        switch (entity.state) {
          case 'open': return 'Ouvert';
          case 'closed': return 'Fermé';
          case 'opening': return 'En ouverture…';
          case 'closing': return 'En fermeture…';
          default: return entity.state;
        }
      case 'alarm_control_panel':
        switch (entity.state) {
          case 'disarmed': return 'Désactivée';
          case 'armed_home': return 'Armée (maison)';
          case 'armed_away': return 'Armée (absent)';
          case 'armed_night': return 'Armée (nuit)';
          case 'triggered': return '🚨 DÉCLENCHÉE';
          default: return entity.state;
        }
      case 'person':
        switch (entity.state) {
          case 'home': return 'À la maison';
          case 'not_home': return 'Absent';
          default: return entity.state;
        }
      case 'binary_sensor':
        return entity.isOn ? 'Ouvert / Actif' : 'Fermé / Inactif';
      case 'sensor':
        final unit = entity.attributes['unit_of_measurement'] as String? ?? '';
        return '${entity.state} $unit'.trim();
      case 'media_player':
        switch (entity.state) {
          case 'playing': return 'En lecture';
          case 'paused': return 'En pause';
          case 'idle': return 'Inactif';
          case 'off': return 'Éteint';
          default: return entity.state;
        }
      default:
        return entity.isOn ? 'Allumé' : 'Éteint';
    }
  }
}
