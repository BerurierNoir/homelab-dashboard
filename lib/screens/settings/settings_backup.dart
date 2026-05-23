import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/beszel_provider.dart';
import '../../providers/cameras_provider.dart';
import '../../providers/quick_actions_provider.dart';
import '../../providers/services_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shortcuts_provider.dart';
import '../../services/backup_service.dart';
import '../../providers/ha_provider.dart';

class SettingsBackupScreen extends ConsumerStatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  ConsumerState<SettingsBackupScreen> createState() =>
      _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends ConsumerState<SettingsBackupScreen> {
  bool _exporting = false;
  bool _importing = false;

  Future<void> _export() async {
    final passphrase = await _showPassphraseDialog(confirm: true);
    if (passphrase == null) return;

    setState(() => _exporting = true);
    try {
      final backupContent = await BackupService.export(passphrase);
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final fileName = 'homelab-backup-$date.homelabbackup';

      // Utiliser le dossier temporaire + share sheet (fonctionne sans permission)
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(backupContent);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'HomeLab Backup $date',
          text: 'Sauvegardez ce fichier sur Pydio, clé USB, Drive...',
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur export : $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<String?> _showExportChoiceDialog() async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sauvegarder vers…',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _choiceButton(
              ctx,
              icon: Icons.folder_rounded,
              label: 'Téléphone (Téléchargements)',
              subtitle: 'Enregistré localement sans partage',
              value: 'local',
              color: const Color(0xFF5CDD8B),
            ),
            const SizedBox(height: 10),
            _choiceButton(
              ctx,
              icon: Icons.share_rounded,
              label: 'Partager',
              subtitle: 'Email, Drive, Nextcloud…',
              value: 'share',
              color: const Color(0xFF00D4FF),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }

  Widget _choiceButton(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required String subtitle,
    required String value,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pop(ctx, value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import() async {
    FilePickerResult? picked;
    try {
      picked = await FilePicker.platform.pickFiles(type: FileType.any);
    } catch (_) {}
    if (picked == null || picked.files.single.path == null) return;

    final passphrase = await _showPassphraseDialog(confirm: false);
    if (passphrase == null) return;

    setState(() => _importing = true);
    try {
      final content =
          await File(picked.files.single.path!).readAsString();
      await BackupService.importBackup(content, passphrase);

      // Recreate all providers so they reload from the restored data
      ref.invalidate(servicesProvider);
      ref.invalidate(shortcutsProvider);
      ref.invalidate(camerasProvider);
      ref.invalidate(quickActionsProvider);
      ref.invalidate(beszelProvider);
      ref.invalidate(settingsProvider);
      ref.invalidate(haConfigProvider);
      ref.invalidate(haProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration restaurée avec succès'),
            backgroundColor: Color(0xFF5CDD8B),
          ),
        );
      }
    } on FormatException catch (e) {
      if (mounted) _showError(e.message);
    } catch (e) {
      if (mounted) _showError('Erreur import : $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<String?> _showPassphraseDialog({required bool confirm}) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    String? error;

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F0F2A),
          title: Text(
            confirm ? 'Choisir une passphrase' : 'Entrer la passphrase',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl1,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Passphrase',
                  labelStyle: TextStyle(color: Colors.white54),
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl2,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirmer',
                    labelStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Retenez cette passphrase. Sans elle, la sauvegarde est irrécupérable.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  error!,
                  style: const TextStyle(
                      color: Color(0xFFFF4D6D), fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                if (ctrl1.text.isEmpty) {
                  setDialogState(
                      () => error = 'La passphrase ne peut pas être vide');
                  return;
                }
                if (confirm && ctrl1.text != ctrl2.text) {
                  setDialogState(
                      () => error = 'Les passphrases ne correspondent pas');
                  return;
                }
                Navigator.pop(ctx, ctrl1.text);
              },
              child: Text(
                confirm ? 'Exporter' : 'Importer',
                style: const TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFFF4D6D),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Sauvegarde'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.upload_rounded,
            color: const Color(0xFF26C6DA),
            title: 'Exporter la configuration',
            subtitle:
                'Génère un fichier chiffré avec toutes vos URLs et identifiants',
            buttonLabel: 'Exporter',
            loading: _exporting,
            onTap: _export,
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.download_rounded,
            color: const Color(0xFF5CDD8B),
            title: 'Restaurer une sauvegarde',
            subtitle:
                'Importe un fichier .homelabbackup et restaure votre configuration',
            buttonLabel: 'Importer',
            loading: _importing,
            onTap: _import,
          ),
          const SizedBox(height: 20),
          _buildWhatIsIncluded(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF26C6DA).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF26C6DA).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF26C6DA), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Le fichier exporté est chiffré avec votre passphrase. '
              'Vous le stockez vous-même où vous voulez (Pydio, clé USB, etc.). '
              'L\'import restaure toutes vos données depuis ce fichier.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                )
              : GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Text(buttonLabel,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildWhatIsIncluded() {
    const included = [
      'URLs des services (locales et Tailscale)',
      'Identifiants et tokens de chaque service',
      'Configuration Beszel (URL, email, mot de passe)',
      'Caméras (noms, URLs de flux)',
      'Actions rapides et headers d\'authentification',
      'Raccourcis activés',
      'Préférences (thème, intervalle, verrouillage)',
    ];
    const excluded = [
      'Fond d\'écran (fichier local, à remettre manuellement)',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Contenu de la sauvegarde',
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          ...included.map((s) => _bulletRow(s, const Color(0xFF5CDD8B))),
          const SizedBox(height: 6),
          ...excluded.map((s) => _bulletRow(s, Colors.white24, cross: true)),
        ],
      ),
    );
  }

  Widget _bulletRow(String text, Color color, {bool cross = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cross ? Icons.remove_rounded : Icons.check_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    color: cross
                        ? Colors.white24
                        : Colors.white.withValues(alpha: 0.6),
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
