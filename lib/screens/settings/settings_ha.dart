import '../../utils/url_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ha_provider.dart';
import '../../services/ha_service.dart';

class SettingsHaScreen extends ConsumerStatefulWidget {
  const SettingsHaScreen({super.key});

  @override
  ConsumerState<SettingsHaScreen> createState() => _SettingsHaScreenState();
}

class _SettingsHaScreenState extends ConsumerState<SettingsHaScreen> {
  late TextEditingController _urlCtrl;
  late TextEditingController _tokenCtrl;
  bool _obscureToken = true;
  bool _testing = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    final config = ref.read(haConfigProvider);
    _urlCtrl = TextEditingController(text: config.url);
    _tokenCtrl = TextEditingController(text: config.token);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testResult = null;
      _testSuccess = null;
    });
    final svc = HaService(
      baseUrl: cleanUrl(_urlCtrl.text),
      token: _tokenCtrl.text.trim(),
    );
    final error = await svc.testConnectionDetailed();
    setState(() {
      _testing = false;
      _testSuccess = error == null;
      _testResult = error == null
          ? '✅ Connexion réussie !'
          : '❌ \$error';
    });
  }


  Future<void> _save() async {
    final cleanUrl = cleanUrl(_urlCtrl.text);
    _urlCtrl.text = cleanUrl; // Mettre à jour le champ
    await ref.read(haConfigProvider.notifier).save(
          url: cleanUrl,
          token: _tokenCtrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration sauvegardée'),
          backgroundColor: Color(0xFF5CDD8B),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060614),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Home Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('URL de votre instance'),
            const SizedBox(height: 8),
            _field(
              controller: _urlCtrl,
              hint: 'https://xxxxx.ui.nabu.casa  ou  http://192.168.1.x:8123',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 4),
            Text(
              'Nabu Casa : copier depuis app.nabu.casa → Remote UI\nLocal : http://192.168.1.x:8123 · Tailscale : http://100.x.x.x:8123',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 20),
            _label('Token d\'accès longue durée'),
            const SizedBox(height: 8),
            _tokenField(),
            const SizedBox(height: 4),
            Text(
              'Profil HA → Sécurité → Créer un token longue durée',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 28),

            // Résultat test
            if (_testResult != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: (_testSuccess == true
                          ? const Color(0xFF5CDD8B)
                          : const Color(0xFFFF4D6D))
                      .withValues(alpha: 0.1),
                  border: Border.all(
                    color: (_testSuccess == true
                            ? const Color(0xFF5CDD8B)
                            : const Color(0xFFFF4D6D))
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testSuccess == true
                        ? const Color(0xFF5CDD8B)
                        : const Color(0xFFFF4D6D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            Row(
              children: [
                // Tester
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _test,
                    icon: _testing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00D4FF),
                            ),
                          )
                        : const Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: Text(_testing ? 'Test…' : 'Tester'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00D4FF),
                      side: const BorderSide(
                        color: Color(0xFF00D4FF),
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sauvegarder
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        prefixIcon: Icon(icon, color: const Color(0xFF00D4FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF13132E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00D4FF)),
        ),
      ),
    );
  }

  Widget _tokenField() {
    return TextField(
      controller: _tokenCtrl,
      obscureText: _obscureToken,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      maxLines: 1,
      decoration: InputDecoration(
        hintText: 'eyJhbGciOiJIUzI1NiIs...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        prefixIcon: const Icon(Icons.key_rounded, color: Color(0xFF00D4FF), size: 18),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureToken ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            color: Colors.white38,
            size: 18,
          ),
          onPressed: () => setState(() => _obscureToken = !_obscureToken),
        ),
        filled: true,
        fillColor: const Color(0xFF13132E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00D4FF)),
        ),
      ),
    );
  }
}
