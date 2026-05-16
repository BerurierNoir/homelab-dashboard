import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/beszel_provider.dart';

class SettingsBeszelScreen extends ConsumerStatefulWidget {
  const SettingsBeszelScreen({super.key});

  @override
  ConsumerState<SettingsBeszelScreen> createState() =>
      _SettingsBeszelScreenState();
}

class _SettingsBeszelScreenState extends ConsumerState<SettingsBeszelScreen> {
  final _urlCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _passVisible = false;
  bool _loading = false;
  String? _error;
  List<Map<String, String>> _systems = [];
  bool _showSystems = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beszel = ref.watch(beszelProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        title: const Text('Beszel'),
        backgroundColor: const Color(0xFF080818),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [_buildContent(beszel)],
      ),
    );
  }

  Widget _buildContent(BeszelState beszel) {
    if (beszel.configured && beszel.config != null) {
      final cfg = beszel.config!;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F2A),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF5CDD8B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cfg.systemName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  Text(cfg.url,
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  ref.read(beszelProvider.notifier).clearConfig(),
              icon: const Icon(Icons.link_off_rounded,
                  size: 14, color: Color(0xFFFF4D6D)),
              label: const Text('Déconnecter',
                  style:
                      TextStyle(color: Color(0xFFFF4D6D), fontSize: 12)),
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact),
            ),
          ],
        ),
      );
    }

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
          TextFormField(
            controller: _urlCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'URL Beszel',
              hintText: 'http://192.168.1.x:8090',
              prefixIcon: Icon(Icons.dns_rounded, size: 16),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon:
                  Icon(Icons.person_outline_rounded, size: 16),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: !_passVisible,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon:
                  const Icon(Icons.lock_outline_rounded, size: 16),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(
                  _passVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 16,
                ),
                onPressed: () =>
                    setState(() => _passVisible = !_passVisible),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: Color(0xFFFF4D6D), fontSize: 12)),
          ],
          if (_showSystems) ...[
            const SizedBox(height: 12),
            const Text('SYSTÈME',
                style: TextStyle(
                    color: Color(0xFF00D4FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const SizedBox(height: 4),
            if (_systems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Aucun système trouvé',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 12)),
              )
            else
              ..._systems.map((sys) => InkWell(
                    onTap: () => _selectSystem(sys),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.computer_rounded,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 8),
                          Text(sys['name']!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  )),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loading ? null : _connect,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                    color: Color(0xFF00D4FF), width: 0.5),
                foregroundColor: const Color(0xFF00D4FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF00D4FF)))
                  : const Text('Se connecter',
                      style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    final url = _urlCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (url.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Tous les champs sont requis');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _showSystems = false;
    });
    final ok = await ref
        .read(beszelProvider.notifier)
        .configure(url: url, email: email, password: password);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _loading = false;
        _error = 'Authentification échouée';
      });
      return;
    }
    final systems =
        await ref.read(beszelProvider.notifier).fetchSystems(url);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _systems = systems;
      _showSystems = true;
    });
  }

  Future<void> _selectSystem(Map<String, String> sys) async {
    final url = _urlCtrl.text.trim();
    await ref
        .read(beszelProvider.notifier)
        .selectSystem(url, sys['id']!, sys['name']!);
    if (!mounted) return;
    setState(() {
      _showSystems = false;
      _systems = [];
      _urlCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.clear();
    });
  }
}
