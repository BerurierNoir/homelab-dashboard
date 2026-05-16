import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/service.dart';
import '../../providers/services_provider.dart';
import '../../services/credential_service.dart';
import '../../services/health_check_service.dart';

class SettingsServicesScreen extends ConsumerStatefulWidget {
  const SettingsServicesScreen({super.key});

  @override
  ConsumerState<SettingsServicesScreen> createState() =>
      _SettingsServicesScreenState();
}

class _SettingsServicesScreenState
    extends ConsumerState<SettingsServicesScreen> {
  final Map<String, TextEditingController> _urlControllers = {};
  final Map<String, TextEditingController> _userControllers = {};
  final Map<String, TextEditingController> _passControllers = {};
  final Map<String, TextEditingController> _tokenControllers = {};
  final Map<String, bool> _passVisible = {};
  final Map<String, bool> _expanded = {};
  final Map<String, String?> _testResults = {};
  final _checker = HealthCheckService();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    final services = ref.read(servicesProvider).services;
    for (final s in services) {
      _urlControllers[s.id] = TextEditingController(text: s.url);
      _userControllers[s.id] = TextEditingController(
          text: await credentialService.getUsername(s.id) ?? '');
      _passControllers[s.id] = TextEditingController(
          text: await credentialService.getPassword(s.id) ?? '');
      _tokenControllers[s.id] = TextEditingController(
          text: await credentialService.getToken(s.id) ?? '');
      _passVisible[s.id] = false;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _checker.close();
    for (final c in [
      ..._urlControllers.values,
      ..._userControllers.values,
      ..._passControllers.values,
      ..._tokenControllers.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicesProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: state.services
            .map((s) => _buildServiceTile(s, state))
            .toList(),
      ),
    );
  }

  Widget _buildServiceTile(ServiceModel s, ServicesState state) {
    final isExp = _expanded[s.id] ?? false;
    final hasUser = s.autoLoginMethod != AutoLoginMethod.none;
    final hasToken = s.autoLoginMethod == AutoLoginMethod.apiToken;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: s.color.withValues(alpha: 0.12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 18),
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
                              fontSize: 14)),
                      Text(s.description,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: s.enabled,
                  onChanged: (_) =>
                      ref.read(servicesProvider.notifier).toggleEnabled(s.id),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: isExp ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: Colors.white38),
                  ),
                  onPressed: () =>
                      setState(() => _expanded[s.id] = !isExp),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (isExp) ...[
            const Divider(height: 1, color: Color(0x0FFFFFFF)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _urlControllers[s.id],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            prefixIcon:
                                Icon(Icons.link_rounded, size: 16),
                            isDense: true,
                          ),
                          onChanged: (v) => ref
                              .read(servicesProvider.notifier)
                              .updateUrl(s.id, v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _testButton(s),
                    ],
                  ),
                  if (_testResults[s.id] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _testResults[s.id]!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testResults[s.id]!.contains('✓')
                              ? const Color(0xFF5CDD8B)
                              : const Color(0xFFFF4D6D),
                        ),
                      ),
                    ),
                  if (hasUser) ...[
                    const SizedBox(height: 12),
                    const Text('IDENTIFIANTS',
                        style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _userControllers[s.id],
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Utilisateur',
                        prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 16),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          credentialService.saveUsername(s.id, v),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passControllers[s.id],
                      obscureText: !(_passVisible[s.id] ?? false),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 16),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            (_passVisible[s.id] ?? false)
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 16,
                          ),
                          onPressed: () => setState(() =>
                              _passVisible[s.id] =
                                  !(_passVisible[s.id] ?? false)),
                        ),
                      ),
                      onChanged: (v) =>
                          credentialService.savePassword(s.id, v),
                    ),
                  ],
                  if (hasToken) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tokenControllers[s.id],
                      obscureText: true,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'API Token',
                        prefixIcon:
                            Icon(Icons.key_rounded, size: 16),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          credentialService.saveToken(s.id, v),
                    ),
                  ],
                  if (hasUser) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        await credentialService.clearCredentials(s.id);
                        _userControllers[s.id]?.clear();
                        _passControllers[s.id]?.clear();
                        _tokenControllers[s.id]?.clear();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Identifiants effacés'),
                                backgroundColor: Color(0xFF13132E)),
                          );
                        }
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 14, color: Color(0xFFFF4D6D)),
                      label: const Text('Effacer les identifiants',
                          style: TextStyle(
                              color: Color(0xFFFF4D6D), fontSize: 12)),
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _testButton(ServiceModel s) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: () async {
          setState(() => _testResults[s.id] = '...');
          final result = await _checker.check(s);
          setState(() {
            _testResults[s.id] = result.isUp == true
                ? '✓ ${result.responseTimeMs}ms'
                : '✗ ${result.errorMessage ?? 'Erreur'}';
          });
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(
              color: const Color(0xFF00D4FF).withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Tester',
            style: TextStyle(fontSize: 12, color: Color(0xFF00D4FF))),
      ),
    );
  }
}
