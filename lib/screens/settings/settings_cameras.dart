import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/camera_config.dart';
import '../../providers/cameras_provider.dart';

class SettingsCamerasScreen extends ConsumerWidget {
  const SettingsCamerasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameras = ref.watch(camerasProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Caméras'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (cameras.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F2A),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: cameras.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cam = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(height: 1, color: Color(0x0FFFFFFF)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cam.color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(cam.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ),
                            Switch(
                              value: cam.enabled,
                              onChanged: (_) => ref
                                  .read(camerasProvider.notifier)
                                  .updateCamera(
                                      cam.copyWith(enabled: !cam.enabled),
                                      null),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16, color: Colors.white38),
                              onPressed: () =>
                                  _editCamera(context, ref, cam),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFFF4D6D)),
                              onPressed: () =>
                                  _deleteCamera(context, ref, cam.id),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCameraDialog(context, ref, null, null),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ajouter une caméra',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF00D4FF), width: 0.5),
                foregroundColor: const Color(0xFF00D4FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCamera(
      BuildContext context, WidgetRef ref, CameraConfig cam) async {
    final url =
        await ref.read(camerasProvider.notifier).getStreamUrl(cam.id);
    if (context.mounted) {
      await _showCameraDialog(context, ref, cam, url);
    }
  }

  Future<void> _deleteCamera(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F2A),
        title: const Text('Supprimer la caméra',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
            'Cette caméra sera supprimée définitivement.',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Color(0xFFFF4D6D)))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(camerasProvider.notifier).removeCamera(id);
    }
  }

  Future<void> _showCameraDialog(BuildContext context, WidgetRef ref,
      CameraConfig? existing, String? existingUrl) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existingUrl ?? '');
    Color selectedColor = existing?.color ?? const Color(0xFF00D4FF);
    String? dialogError;

    const presetColors = [
      Color(0xFF00D4FF),
      Color(0xFF7C3AED),
      Color(0xFFFF6B35),
      Color(0xFF5CDD8B),
      Color(0xFFFF4D6D),
      Color(0xFFFFB74D),
    ];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: const Color(0xFF0F0F2A),
          title: Text(
            existing == null ? 'Ajouter une caméra' : 'Modifier',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.videocam_rounded, size: 16),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL RTSP',
                    hintText: 'rtsp://...',
                    prefixIcon: Icon(Icons.link_rounded, size: 16),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Couleur',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: presetColors
                            .map((c) => GestureDetector(
                                  onTap: () =>
                                      setDlg(() => selectedColor = c),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: c,
                                      border: Border.all(
                                        color: selectedColor == c
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 8),
                  Text(dialogError!,
                      style: const TextStyle(
                          color: Color(0xFFFF4D6D), fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final url = urlCtrl.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  setDlg(() => dialogError = 'Tous les champs sont requis');
                  return;
                }
                if (existing == null) {
                  final id =
                      DateTime.now().millisecondsSinceEpoch.toString();
                  await ref.read(camerasProvider.notifier).addCamera(
                        CameraConfig(
                            id: id,
                            name: name,
                            color: selectedColor,
                            enabled: true),
                        url,
                      );
                } else {
                  await ref.read(camerasProvider.notifier).updateCamera(
                        existing.copyWith(name: name, color: selectedColor),
                        url,
                      );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(
                existing == null ? 'Ajouter' : 'Enregistrer',
                style: const TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    urlCtrl.dispose();
  }
}
