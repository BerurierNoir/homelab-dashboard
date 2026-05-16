import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quick_action.dart';
import '../../providers/quick_actions_provider.dart';

class SettingsQuickActionsScreen extends ConsumerWidget {
  const SettingsQuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(quickActionsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Actions Rapides'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (actions.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F2A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: actions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final action = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        const Divider(
                            height: 1, color: Color(0x0FFFFFFF)),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: action.color
                                    .withValues(alpha: 0.15),
                              ),
                              child: Icon(action.icon,
                                  color: action.color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(action.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  Text(
                                    action.isWol
                                        ? 'WoL · ${action.wolMac ?? ''}'
                                        : '${action.method}  ${action.url}',
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: action.enabled,
                              onChanged: (_) => ref
                                  .read(quickActionsProvider.notifier)
                                  .toggleEnabled(action.id),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded,
                                  size: 16, color: Colors.white38),
                              onPressed: () =>
                                  _editAction(context, ref, action),
                              visualDensity: VisualDensity.compact,
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFFF4D6D)),
                              onPressed: () =>
                                  _deleteAction(context, ref, action.id),
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
              onPressed: () => _showDialog(context, ref, null, null),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Ajouter une action',
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

  Future<void> _editAction(
      BuildContext context, WidgetRef ref, QuickAction action) async {
    final auth = await ref
        .read(quickActionsProvider.notifier)
        .getAuthorization(action.id);
    if (context.mounted) await _showDialog(context, ref, action, auth);
  }

  Future<void> _deleteAction(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F2A),
        title: const Text("Supprimer l'action",
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
            'Cette action sera supprimée définitivement.',
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
      await ref.read(quickActionsProvider.notifier).removeAction(id);
    }
  }

  Future<void> _showDialog(BuildContext context, WidgetRef ref,
      QuickAction? existing, String? existingAuth) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final authCtrl = TextEditingController(text: existingAuth ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final macCtrl = TextEditingController(text: existing?.wolMac ?? '');
    final broadcastCtrl = TextEditingController(
        text: existing?.wolBroadcast ?? '255.255.255.255');

    Color selectedColor = existing?.color ?? const Color(0xFF00D4FF);
    int selectedIconCode =
        existing?.iconCode ?? kQuickActionIcons.first.icon.codePoint;
    String selectedMethod = existing?.method ?? 'POST';
    QuickActionType selectedType =
        existing?.type ?? QuickActionType.http;
    bool authVisible = false;
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
            existing == null ? 'Nouvelle action' : "Modifier l'action",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _typeChip('HTTP', QuickActionType.http, selectedType,
                        (t) => setDlg(() => selectedType = t)),
                    const SizedBox(width: 8),
                    _typeChip('Wake on LAN', QuickActionType.wol,
                        selectedType,
                        (t) => setDlg(() => selectedType = t)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Nom du bouton',
                    prefixIcon: Icon(Icons.label_rounded, size: 16),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Icône',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kQuickActionIcons.map((entry) {
                    final code = entry.icon.codePoint;
                    final sel = selectedIconCode == code;
                    return GestureDetector(
                      onTap: () => setDlg(() => selectedIconCode = code),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: sel
                              ? selectedColor.withValues(alpha: 0.2)
                              : const Color(0xFF080818),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: sel
                                ? selectedColor
                                : Colors.white.withValues(alpha: 0.08),
                            width: sel ? 1.5 : 0.5,
                          ),
                        ),
                        child: Icon(entry.icon,
                            size: 18,
                            color:
                                sel ? selectedColor : Colors.white38),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Couleur',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: presetColors
                            .map((c) => GestureDetector(
                                  onTap: () =>
                                      setDlg(() => selectedColor = c),
                                  child: Container(
                                    width: 22,
                                    height: 22,
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
                const SizedBox(height: 14),
                if (selectedType == QuickActionType.http) ...[
                  Row(
                    children: [
                      const Text('Méthode',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 12),
                      _methodChip('POST', selectedMethod,
                          (v) => setDlg(() => selectedMethod = v)),
                      const SizedBox(width: 8),
                      _methodChip('GET', selectedMethod,
                          (v) => setDlg(() => selectedMethod = v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'http://192.168.1.x/api/webhook/...',
                      prefixIcon: Icon(Icons.link_rounded, size: 16),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (_, setAuth) => TextField(
                      controller: authCtrl,
                      obscureText: !authVisible,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Authorization (optionnel)',
                        hintText: 'Bearer TOKEN',
                        prefixIcon:
                            const Icon(Icons.key_rounded, size: 16),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            authVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                          ),
                          onPressed: () {
                            authVisible = !authVisible;
                            setAuth(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                  if (selectedMethod == 'POST') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Corps JSON (optionnel)',
                        hintText: '{"key": "value"}',
                        prefixIcon:
                            Icon(Icons.data_object_rounded, size: 16),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ],
                if (selectedType == QuickActionType.wol) ...[
                  TextField(
                    controller: macCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Adresse MAC',
                      hintText: 'AA:BB:CC:DD:EE:FF',
                      prefixIcon:
                          Icon(Icons.computer_rounded, size: 16),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: broadcastCtrl,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'IP de broadcast',
                      hintText: '255.255.255.255',
                      prefixIcon: Icon(Icons.router_rounded, size: 16),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Port UDP 9 — paquet magique envoyé en broadcast sur le réseau local.',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10),
                  ),
                ],
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
                if (name.isEmpty) {
                  setDlg(() => dialogError = 'Nom requis');
                  return;
                }
                if (selectedType == QuickActionType.http &&
                    urlCtrl.text.trim().isEmpty) {
                  setDlg(() => dialogError = 'URL requise');
                  return;
                }
                if (selectedType == QuickActionType.wol) {
                  final parts =
                      macCtrl.text.trim().split(RegExp(r'[:\-]'));
                  final validMac = parts.length == 6 &&
                      parts.every((p) {
                        final byte = int.tryParse(p, radix: 16);
                        return byte != null && byte >= 0 && byte <= 255;
                      });
                  if (!validMac) {
                    setDlg(() => dialogError =
                        'Format MAC invalide (AA:BB:CC:DD:EE:FF)');
                    return;
                  }
                }

                final auth = authCtrl.text.trim();
                final body = bodyCtrl.text.trim();
                final id = existing?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString();

                final action = QuickAction(
                  id: id,
                  name: name,
                  iconCode: selectedIconCode,
                  colorValue: selectedColor.toARGB32(),
                  type: selectedType,
                  method: selectedMethod,
                  url: urlCtrl.text.trim(),
                  body: body.isEmpty ? null : body,
                  wolMac: macCtrl.text.trim().isEmpty
                      ? null
                      : macCtrl.text.trim(),
                  wolBroadcast: broadcastCtrl.text.trim().isEmpty
                      ? '255.255.255.255'
                      : broadcastCtrl.text.trim(),
                );

                if (existing == null) {
                  await ref
                      .read(quickActionsProvider.notifier)
                      .addAction(action,
                          authorization: auth.isEmpty ? null : auth);
                } else {
                  await ref
                      .read(quickActionsProvider.notifier)
                      .updateAction(action, authorization: auth);
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
    authCtrl.dispose();
    bodyCtrl.dispose();
    macCtrl.dispose();
    broadcastCtrl.dispose();
  }

  Widget _typeChip(String label, QuickActionType type,
      QuickActionType current, void Function(QuickActionType) onTap) {
    final sel = type == current;
    return GestureDetector(
      onTap: () => onTap(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF7C3AED).withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.12),
            width: sel ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: sel ? const Color(0xFF7C3AED) : Colors.white38,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _methodChip(
      String label, String current, void Function(String) onTap) {
    final sel = label == current;
    return GestureDetector(
      onTap: () => onTap(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF00D4FF).withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: sel
                ? const Color(0xFF00D4FF)
                : Colors.white.withValues(alpha: 0.12),
            width: sel ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: sel ? const Color(0xFF00D4FF) : Colors.white38,
            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
