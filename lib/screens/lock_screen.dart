import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _auth = LocalAuthentication();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Déverrouillez HomeLab Dashboard',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        widget.onUnlocked();
      } else {
        setState(() {
          _loading = false;
          _error = 'Authentification annulée';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erreur d\'authentification';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                  ),
                ),
                child: const Icon(Icons.hub_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'HomeLab Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authentification requise',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 56),
              if (_loading)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: Color(0xFF00D4FF),
                    strokeWidth: 2.5,
                  ),
                )
              else
                GestureDetector(
                  onTap: _authenticate,
                  child: const Icon(
                    Icons.fingerprint_rounded,
                    size: 72,
                    color: Color(0xFF00D4FF),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Text(
                  _error!,
                  style: const TextStyle(
                      color: Color(0xFFFF4D6D), fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _authenticate,
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
