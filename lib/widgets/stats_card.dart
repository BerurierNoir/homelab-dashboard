import 'package:flutter/material.dart';
import '../models/beszel_stats.dart';

class StatsCard extends StatelessWidget {
  final BeszelStats stats;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const StatsCard({
    super.key,
    required this.stats,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00D4FF);

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF13132E), Color(0xFF0F0F26)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: !stats.available
          ? _buildUnavailable()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5CDD8B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      stats.systemName.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    if (stats.temp != null)
                      Row(
                        children: [
                          const Icon(Icons.thermostat_rounded,
                              size: 12, color: Colors.white38),
                          const SizedBox(width: 2),
                          Text(
                            '${stats.temp!.toStringAsFixed(0)}°C',
                            style: TextStyle(
                              color: _tempColor(stats.temp!),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _metric('CPU', stats.cpu, const Color(0xFF00D4FF))),
                    const SizedBox(width: 10),
                    Expanded(child: _metric('RAM', stats.mem, const Color(0xFF7C3AED))),
                    const SizedBox(width: 10),
                    Expanded(child: _metric('Disk', stats.disk, const Color(0xFFFF6B35))),
                  ],
                ),
                if (stats.networkSentMbs > 0 || stats.networkRecvMbs > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.arrow_upward_rounded,
                          size: 10, color: Color(0xFF5CDD8B)),
                      const SizedBox(width: 2),
                      Text(
                        _netLabel(stats.networkSentMbs),
                        style: const TextStyle(
                            color: Color(0xFF5CDD8B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.arrow_downward_rounded,
                          size: 10, color: Color(0xFF00D4FF)),
                      const SizedBox(width: 2),
                      Text(
                        _netLabel(stats.networkRecvMbs),
                        style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }

  Widget _metric(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: (percent / 100).clamp(0, 1),
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailable() {
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded,
            size: 14, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Beszel inaccessible',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(
                    color: const Color(0xFFFF4D6D).withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (onRetry != null)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Color(0xFF00D4FF), fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  String _netLabel(double mbs) {
    if (mbs < 1) return '${(mbs * 1024).toStringAsFixed(0)} KB/s';
    return '${mbs.toStringAsFixed(1)} MB/s';
  }

  Color _tempColor(double t) {
    if (t < 60) return const Color(0xFF5CDD8B);
    if (t < 75) return const Color(0xFFFFB74D);
    return const Color(0xFFFF4D6D);
  }
}
