import 'package:flutter/material.dart';
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
  bool _autoLoginDone = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF080818))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p / 100),
          onPageStarted: (_) => setState(() {
            _hasError = false;
            _autoLoginDone = false;
          }),
          onPageFinished: (url) async {
            setState(() => _progress = 1);
            if (!_autoLoginDone) {
              _autoLoginDone = true;
              await autoLoginService.performLogin(
                service: widget.service,
                controller: _controller,
                currentUrl: url,
              );
            }
          },
          onWebResourceError: (err) {
            if (err.isForMainFrame == true) {
              setState(() {
                _hasError = true;
              });
            }
          },
          onSslAuthError: (SslAuthError error) async {
            // Accept self-signed certificates (required for Proxmox VE)
            await error.proceed();
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.service.url));
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.service.color;

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F2A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: () => _controller.reload(),
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
              color: color,
              minHeight: 2,
            ),
          ),
        ),
      ),
      body: _hasError ? _buildErrorPage() : WebViewWidget(controller: _controller),
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
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_rounded, size: 14, color: Colors.white38),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Vérifiez que Tailscale est actif et l\'URL configurée',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
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
    final url = Uri.parse(widget.service.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
