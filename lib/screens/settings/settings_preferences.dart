import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/health_provider.dart';

class SettingsPreferencesScreen extends ConsumerStatefulWidget {
  const SettingsPreferencesScreen({super.key});

  @override
  ConsumerState<SettingsPreferencesScreen> createState() =>
      _SettingsPreferencesScreenState();
}

class _SettingsPreferencesScreenState
    extends ConsumerState<SettingsPreferencesScreen> {
  final _auth = LocalAuthentication();

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Préférences'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _sectionLabel('AFFICHAGE'),
          _buildPrefsSection(settings),
          const SizedBox(height: 24),
          _sectionLabel('SÉCURITÉ'),
          _buildLockSection(settings),
          const SizedBox(height: 24),
          _sectionLabel("FOND D'ÉCRAN"),
          _buildWallpaperSection(settings),
          const SizedBox(height: 24),
          _buildSecurityNote(),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00D4FF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      );

  Widget _buildPrefsSection(AppSettings settings) {
    final intervals = [30, 60, 120, 300];
    final labels = ['30s', '1min', '2min', '5min'];
    final idx = intervals.indexOf(settings.refreshIntervalSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.dark_mode_outlined,
                  size: 18, color: Colors.white54),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Thème sombre',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14))),
              Switch(
                value: settings.isDarkTheme,
                onChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .setDarkTheme(v),
              ),
            ],
          ),
          const Divider(color: Color(0x0FFFFFFF)),
          const Text('Intervalle de refresh',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(intervals.length, (i) {
              final sel = i == (idx < 0 ? 1 : idx);
              return GestureDetector(
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .setRefreshInterval(intervals[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF00D4FF)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: sel
                          ? const Color(0xFF00D4FF)
                          : Colors.white38,
                      fontSize: 13,
                      fontWeight:
                          sel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
          const Divider(color: Color(0x0FFFFFFF)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(healthProvider.notifier).checkAll(),
                  icon: const Icon(Icons.wifi_find_rounded, size: 14),
                  label: const Text('Tester tout',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF00D4FF), width: 0.5),
                    foregroundColor: const Color(0xFF00D4FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // URLs vides par défaut — chaque service a déjà defaultUrl=''
                    final notifier = ref.read(servicesProvider.notifier);
                    final services = ref.read(servicesProvider).services;
                    for (final s in services) {
                      notifier.resetUrl(s.id);
                    }
                  },
                  icon: const Icon(Icons.restore_rounded, size: 14),
                  label: const Text('URLs défaut',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.5),
                    foregroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLockSection(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Protection à l'ouverture",
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          const Text(
            "Utilise l'empreinte, la reconnaissance faciale ou le code du téléphone.",
            style: TextStyle(color: Colors.white24, fontSize: 11),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _lockChip(
                  label: 'Aucune',
                  icon: Icons.lock_open_rounded,
                  type: LockType.none,
                  current: settings.lockType),
              const SizedBox(width: 8),
              _lockChip(
                  label: 'Sécurité Android',
                  icon: Icons.fingerprint_rounded,
                  type: LockType.biometric,
                  current: settings.lockType),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lockChip(
      {required String label,
      required IconData icon,
      required LockType type,
      required LockType current}) {
    final sel = type == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectLock(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel
                ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: sel
                  ? const Color(0xFF7C3AED)
                  : Colors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: sel ? const Color(0xFF7C3AED) : Colors.white38),
              const SizedBox(height: 4),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10,
                      color: sel
                          ? const Color(0xFF7C3AED)
                          : Colors.white38,
                      fontWeight: sel
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectLock(LockType type) async {
    if (type == LockType.biometric) {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Authentification non disponible sur cet appareil'),
            backgroundColor: Color(0xFF13132E),
          ),
        );
        return;
      }
    }
    await ref.read(settingsProvider.notifier).setLockType(type);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lockLabel(type)),
          backgroundColor: const Color(0xFF13132E),
        ),
      );
    }
  }

  String _lockLabel(LockType t) => switch (t) {
        LockType.none => 'Protection désactivée',
        LockType.biometric => 'Sécurité Android activée',
      };

  Widget _buildWallpaperSection(AppSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (settings.wallpaperPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(settings.wallpaperPath!),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickWallpaper,
                  icon: const Icon(Icons.image_outlined, size: 14),
                  label: const Text('Choisir une image',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF00D4FF), width: 0.5),
                    foregroundColor: const Color(0xFF00D4FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (settings.wallpaperPath != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(settingsProvider.notifier)
                        .clearWallpaper(),
                    icon: const Icon(Icons.restore_rounded, size: 14),
                    label: const Text('Défaut',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5),
                      foregroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickWallpaper() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    await ref.read(settingsProvider.notifier).setWallpaper(file.path);
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined,
              size: 18, color: Color(0xFF7C3AED)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vos identifiants sont stockés chiffrés localement via Android Keystore. Ils ne quittent jamais cet appareil.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
