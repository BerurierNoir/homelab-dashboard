import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service.dart';
import '../providers/services_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/cameras_provider.dart';
import '../providers/quick_actions_provider.dart';
import '../providers/beszel_provider.dart';
import '../providers/health_provider.dart';
import 'settings/settings_services.dart';
import 'settings/settings_shortcuts.dart';
import 'settings/settings_cameras.dart';
import 'settings/settings_quick_actions.dart';
import 'settings/settings_beszel.dart';
import 'settings/settings_preferences.dart';
import 'settings/settings_backup.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(servicesProvider);
    final shortcuts = ref.watch(shortcutsProvider).shortcuts;
    final cameras = ref.watch(camerasProvider);
    final quickActions = ref.watch(quickActionsProvider);
    final beszel = ref.watch(beszelProvider);

    final activeServices =
        servicesState.services.where((s) => s.enabled).length;
    final activeShortcuts = shortcuts.where((s) => s.enabled).length;
    final activeActions = quickActions.where((a) => a.enabled).length;
    final activeCameras = cameras.where((c) => c.enabled).length;

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ── Réseau ─────────────────────────────────────────────────
          const SizedBox(height: 24),

          // ── Menu ───────────────────────────────────────────────────
          _buildMenuCard(context, [
            _MenuItem(
              icon: Icons.dashboard_rounded,
              color: const Color(0xFF00D4FF),
              title: 'Services',
              subtitle: '$activeServices actifs sur '
                  '${servicesState.services.length}',
              onTap: () => _push(
                  context, const SettingsServicesScreen()),
            ),
            _MenuItem(
              icon: Icons.apps_rounded,
              color: const Color(0xFF7C3AED),
              title: 'Raccourcis',
              subtitle: '$activeShortcuts actifs sur '
                  '${shortcuts.length}',
              onTap: () => _push(
                  context, const SettingsShortcutsScreen()),
            ),
            _MenuItem(
              icon: Icons.bolt_rounded,
              color: const Color(0xFFFF6B35),
              title: 'Actions Rapides',
              subtitle: quickActions.isEmpty
                  ? 'Aucune action'
                  : '$activeActions actives sur '
                      '${quickActions.length}',
              onTap: () => _push(
                  context, const SettingsQuickActionsScreen()),
            ),
            _MenuItem(
              icon: Icons.videocam_rounded,
              color: const Color(0xFF5CDD8B),
              title: 'Caméras',
              subtitle: cameras.isEmpty
                  ? 'Aucune caméra'
                  : '$activeCameras actives sur '
                      '${cameras.length}',
              onTap: () => _push(
                  context, const SettingsCamerasScreen()),
            ),
            _MenuItem(
              icon: Icons.monitor_heart_rounded,
              color: const Color(0xFFFFB74D),
              title: 'Beszel',
              subtitle: beszel.configured
                  ? beszel.config?.systemName ?? 'Connecté'
                  : 'Non configuré',
              onTap: () => _push(
                  context, const SettingsBeszelScreen()),
            ),
            _MenuItem(
              icon: Icons.tune_rounded,
              color: Colors.white54,
              title: 'Préférences',
              subtitle: 'Thème, sécurité, fond d\'écran',
              onTap: () => _push(
                  context, const SettingsPreferencesScreen()),
            ),
            _MenuItem(
              icon: Icons.backup_rounded,
              color: const Color(0xFF26C6DA),
              title: 'Sauvegarde',
              subtitle: 'Exporter / Importer la configuration',
              onTap: () => _push(
                  context, const SettingsBackupScreen()),
              isLast: true,
            ),
          ]),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildMenuCard(BuildContext context, List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (i > 0)
                const Divider(height: 1, color: Color(0x0FFFFFFF)),
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(
                    item.isLast ? 18 : 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color.withValues(alpha: 0.12),
                        ),
                        child: Icon(item.icon,
                            color: item.color, size: 18),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(item.subtitle,
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white24, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }



}

class _MenuItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });
}
