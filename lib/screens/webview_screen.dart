import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/service.dart';
import '../services/auto_login_service.dart';

class WebViewScreen extends StatefulWidget {
  final ServiceModel service;
  const WebViewScreen({super.key, required this.service});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _hasError = false;
  bool _showLoginButton = false;
  String _currentUrl = '';
  int _loginAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080818))
      // Fix clipboard freeze : handler JavaScript pour paste
      ..addJavaScriptChannel(
        'FlutterClipboard',
        onMessageReceived: (msg) async {
          // Gérer le paste depuis Flutter sans bloquer le WebView
          final data = await Clipboard.getData(Clipboard.kTextPlain);
          if (data?.text != null) {
            await _controller.runJavaScript(
              'document.activeElement.value += ${jsonEncodeStr(data!.text!)};'
            );
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) => setState(() => _progress = p / 100),
        onPageStarted: (url) => setState(() {
          _hasError = false;
          _currentUrl = url;
          _showLoginButton = false;
          // Reset attempts pour les nouvelles pages
          if (!url.contains(_currentUrl.split('/').take(3).join('/'))) {
            _loginAttempts = 0;
          }
        }),
        onPageFinished: (url) async {
          setState(() {
            _progress = 1;
            _currentUrl = url;
          });
          // Auto-login : plus de flag global, on tente à chaque page
          // La détection se fait côté JS (cherche input[type=password])
          if (_loginAttempts < 3) {
            _loginAttempts++;
            await autoLoginService.performLogin(
              service: widget.service,
              controller: _controller,
              currentUrl: url,
            );
          }
          // Afficher bouton login manuel si toujours sur une page avec password field
          await Future.delayed(const Duration(seconds: 3));
          final hasLoginForm = await _controller.runJavaScriptReturningResult(
            'document.querySelector("input[type=password]") !== null'
          );
          if (mounted) {
            setState(() {
              _showLoginButton = hasLoginForm.toString() == 'true';
            });
          }
        },
        onWebResourceError: (err) {
          if (err.isForMainFrame == true) setState(() => _hasError = true);
        },
        onSslAuthError: (SslAuthError error) async => error.proceed(),
      ))
      ..loadRequest(Uri.parse(widget.service.url));
  }

  String jsonEncodeStr(String s) =>
      '"${s.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';

  @override
  Widget build(BuildContext context) {
    final color = widget.service.color;

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () async {
            final nav = Navigator.of(context);
            if (await _controller.canGoBack()) {
              _controller.goBack();
            } else {
              nav.pop();
            }
          },
        ),
        title: Row(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
              ),
              child: Icon(widget.service.icon, color: color, size: 14),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.service.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          // Bouton login manuel (apparaît si auto-login n'a pas marché)
          if (_showLoginButton)
            IconButton(
              icon: const Icon(Icons.login_rounded, size: 20, color: Color(0xFF00D4FF)),
              onPressed: _triggerManualLogin,
              tooltip: 'Se connecter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () {
              setState(() => _loginAttempts = 0);
              _controller.reload();
            },
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            onPressed: _openExternal,
            tooltip: 'Ouvrir dans le navigateur',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: AnimatedOpacity(
            opacity: _progress < 1 ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white10,
              color: color, minHeight: 2,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _hasError ? _buildErrorPage() : WebViewWidget(controller: _controller),
          // Banner si le login manuel est disponible
          if (_showLoginButton)
            Positioned(
              bottom: 16, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00D4FF).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: Color(0xFF00D4FF)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Auto-login en attente…',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _triggerManualLogin,
                      child: const Text('Se connecter',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _triggerManualLogin() async {
    setState(() {
      _showLoginButton = false;
      _loginAttempts = 0;
    });
    await autoLoginService.performLogin(
      service: widget.service,
      controller: _controller,
      currentUrl: _currentUrl,
    );
  }

  Widget _buildErrorPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 72, color: Colors.white.withValues(alpha: 0.15)),
            const SizedBox(height: 24),
            Text(
              'Impossible de joindre\n${widget.service.name}',
              style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.service.url.isEmpty
                    ? 'URL non configurée — allez dans Settings'
                    : 'Vérifiez l\'URL et votre connexion réseau',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: FilledButton.styleFrom(
                backgroundColor: widget.service.color.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternal() async {
    if (widget.service.url.isEmpty) return;
    final url = Uri.parse(widget.service.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
