import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/service.dart';
import '../providers/services_provider.dart';
import '../providers/health_provider.dart';

class StatusScreen extends ConsumerWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider).services;
    final health = ref.watch(healthProvider);
    final enabled = services.where((s) => s.enabled).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Statuts'),
        actions: [
          IconButton(
            icon: AnimatedRotation(
              turns: health.isChecking ? 1 : 0,
              duration: const Duration(milliseconds: 600),
              child: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4FF)),
            ),
            onPressed: () => ref.read(healthProvider.notifier).checkAll(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSummaryBanner(enabled, health),
          const SizedBox(height: 4),
          ...enabled.map((s) => _buildStatusRow(s, health.statusFor(s.id))),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(List<ServiceModel> enabled, HealthState health) {
    final total = enabled.length;
    final up = enabled.where((s) => health.statusFor(s.id)?.isUp == true).length;
    final down = enabled.where((s) => health.statusFor(s.id)?.isUp == false).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F0F2A), Color(0xFF13132E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statBox('TOTAL', '$total', Colors.white54),
          _statBox('EN LIGNE', '$up', const Color(0xFF5CDD8B)),
          _statBox('HORS LIGNE', '$down', const Color(0xFFFF4D6D)),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white38, fontSize: 10, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildStatusRow(ServiceModel s, ServiceStatus? status) {
    final isUp = status?.isUp;
    final Color dotColor = isUp == null
        ? Colors.white24
        : isUp
            ? const Color(0xFF5CDD8B)
            : const Color(0xFFFF4D6D);

    String lastCheckedStr = '--';
    if (status?.lastChecked != null) {
      final diff = DateTime.now().difference(status!.lastChecked!);
      if (diff.inSeconds < 60) {
        lastCheckedStr = 'il y a ${diff.inSeconds}s';
      } else if (diff.inMinutes < 60) {
        lastCheckedStr = 'il y a ${diff.inMinutes}min';
      } else {
        lastCheckedStr = DateFormat('HH:mm').format(status.lastChecked!);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.color.withValues(alpha: 0.12),
            ),
            child: Icon(s.icon, color: s.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  s.url,
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      boxShadow: isUp == true
                          ? [BoxShadow(color: dotColor.withValues(alpha: 0.5), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUp == null ? 'Inconnu' : isUp ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                        color: dotColor, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                status?.responseTimeMs != null
                    ? '${status!.responseTimeMs}ms · $lastCheckedStr'
                    : lastCheckedStr,
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
