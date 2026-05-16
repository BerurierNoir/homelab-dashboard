import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/camera_config.dart';
import '../models/service.dart';
import '../models/shortcut.dart';
import '../providers/services_provider.dart';
import '../providers/health_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/settings_provider.dart';
import '../services/credential_service.dart';
import '../providers/beszel_provider.dart';
import '../providers/cameras_provider.dart';
import '../providers/quick_actions_provider.dart';
import '../models/quick_action.dart';
import '../widgets/service_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/shortcut_card.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/camera_feed_card.dart';
import 'webview_screen.dart';
import 'settings_screen.dart';
import 'status_screen.dart';

const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 3,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  childAspectRatio: 0.82,
);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Map<String, bool> _hasCredentials = {};
  final Map<String, String> _streamUrls = {};

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadStreamUrls();
  }

  Future<void> _loadCredentials() async {
    final services = ref.read(servicesProvider).services;
    final results = await Future.wait(
      services.map((s) async {
        final has = await credentialService.hasCredentials(s.id);
        return MapEntry(s.id, has);
      }),
    );
    if (mounted) {
      setState(() {
        for (final e in results) {
          _hasCredentials[e.key] = e.value;
        }
      });
    }
  }

  Future<void> _loadStreamUrls() async {
    final cameras = ref.read(camerasProvider);
    if (cameras.isEmpty) return;
    final results = await Future.wait(
      cameras.map((c) async {
        final url =
            await ref.read(camerasProvider.notifier).getStreamUrl(c.id);
        return MapEntry(c.id, url ?? '');
      }),
    );
    if (mounted) {
      setState(() {
        for (final e in results) {
          if (e.value.isNotEmpty) _streamUrls[e.key] = e.value;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(healthProvider.notifier).checkAll();
    await _loadCredentials();
    await _loadStreamUrls();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(enabledServicesProvider);
    final shortcuts = ref.watch(enabledShortcutsProvider);
    final health = ref.watch(healthProvider);
    final settings = ref.watch(settingsProvider);
        final beszel = ref.watch(beszelProvider);
    final cameras = ref.watch(enabledCamerasProvider);
    final quickActions = ref.watch(enabledQuickActionsProvider);
    final tailscale = ref.watch(tailscaleProvider);

    // Reload stream URLs whenever the camera list changes
    ref.listen<List<CameraConfig>>(camerasProvider, (_, __) => _loadStreamUrls());

    Widget body = Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xFF00D4FF),
            backgroundColor: const Color(0xFF13132E),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(tailscale),
                // ── Stats Beszel ─────────────────────────────────
                if (beszel.configured && beszel.stats != null)
                  SliverToBoxAdapter(
                    child: StatsCard(
                      stats: beszel.stats!,
                      errorMessage: beszel.lastError,
                      onRetry: () =>
                          ref.read(beszelProvider.notifier).refresh(),
                    ),
                  ),
                // ── Actions rapides ───────────────────────────────
                if (quickActions.isNotEmpty) ...[
                  SliverToBoxAdapter(
                      child: _sectionHeader('ACTIONS RAPIDES')),
                  SliverToBoxAdapter(
                      child: _buildQuickActionsRow(quickActions)),
                ],
                // ── Caméras ──────────────────────────────────────
                if (cameras.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildCameraSection(cameras),
                  ),
                // ── Services ─────────────────────────────────────
                if (beszel.configured || cameras.isNotEmpty ||
                    quickActions.isNotEmpty)
                  SliverToBoxAdapter(
                      child: _sectionHeader('SERVICES')),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  sliver: health.isChecking && health.statuses.isEmpty
                      ? _buildShimmerGrid(enabled.isEmpty ? 6 : enabled.length)
                      : _buildServiceSliver(enabled, health),
                ),
                if (shortcuts.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _sectionHeader('RACCOURCIS')),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 32),
                    sliver: _buildShortcutSliver(shortcuts),
                  ),
                ] else
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ],
    );

    if (settings.wallpaperPath != null) {
      body = Stack(
        children: [
          Positioned.fill(
            child: Image.file(
              File(settings.wallpaperPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          Positioned.fill(
            child: Container(
                color: Colors.black.withValues(alpha: 0.65)),
          ),
          body,
        ],
      );
    }

    return Scaffold(
      backgroundColor: settings.wallpaperPath != null
          ? Colors.transparent
          : const Color(0xFF080818),
      body: body,
    );
  }

  Widget _sectionHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
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

        final color =
        isLocal ? const Color(0xFF1976D2) : const Color(0xFF7B1FA2);
    return Container(
      height: 24,
      width: double.infinity,
      color: color.withValues(alpha: 0.13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLocal ? Icons.home_rounded : Icons.lock_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isLocal ? 'Réseau local' : 'Tailscale',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(TailscaleStatus tailscale) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 110,
      backgroundColor: const Color(0xFF080818),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  Color(0xFF00D4FF),
                  Color(0xFF7C3AED),
                ]),
              ),
              child: const Icon(Icons.hub_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'HomeLab',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        background: _buildStarField(),
      ),
      actions: [
        _buildTailscaleButton(tailscale),
        IconButton(
          icon: const Icon(Icons.monitor_heart_outlined,
              color: Color(0xFF00D4FF)),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const StatusScreen())),
          tooltip: 'Statuts',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined,
              color: Colors.white60),
          onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SettingsScreen())),
          tooltip: 'Paramètres',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTailscaleButton(TailscaleStatus status) {
    final Color iconColor;
    final Color dotColor;
    final String tooltip;

    switch (status) {
      case TailscaleStatus.connected:
        iconColor = const Color(0xFF5CDD8B);
        dotColor = const Color(0xFF5CDD8B);
        tooltip = 'Tailscale connecté';
      case TailscaleStatus.disconnected:
        iconColor = Colors.white38;
        dotColor = const Color(0xFFFF4D6D);
        tooltip = 'Tailscale déconnecté — appuyer pour ouvrir';
      case TailscaleStatus.unknown:
        iconColor = Colors.white24;
        dotColor = Colors.white24;
        tooltip = 'Tailscale';
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => launchUrl(
          Uri.parse(
            'intent:#Intent;package=com.tailscale.ipn.android'
            ';action=android.intent.action.MAIN'
            ';category=android.intent.category.LAUNCHER;end',
          ),
          mode: LaunchMode.externalApplication,
        ).catchError((_) => false),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.vpn_lock_rounded, color: iconColor, size: 24),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                        color: const Color(0xFF080818), width: 1.5),
                    boxShadow: status == TailscaleStatus.connected
                        ? [BoxShadow(
                            color: dotColor.withValues(alpha: 0.6),
                            blurRadius: 4)]
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarField() {
    final rng = math.Random(42);
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A0A20), Color(0xFF080818)],
            ),
          ),
        ),
        ...List.generate(30, (i) {
          final x = rng.nextDouble();
          final y = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 0.5;
          final opacity = rng.nextDouble() * 0.6 + 0.1;
          return Align(
            alignment: Alignment(x * 2 - 1, y * 2 - 1),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: opacity),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickActionsRow(List<QuickAction> actions) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 4, 8),
        itemCount: actions.length,
        itemBuilder: (_, i) => QuickActionButton(action: actions[i]),
      ),
    );
  }

  Widget _buildCameraSection(List<CameraConfig> cameras) {
    final visible =
        cameras.where((c) => _streamUrls.containsKey(c.id)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      children: visible
          .map((c) => CameraFeedCard(config: c, streamUrl: _streamUrls[c.id]!))
          .toList(),
    );
  }

  Widget _buildShimmerGrid(int count) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (_, __) => const ShimmerCard(),
        childCount: count,
      ),
      gridDelegate: _gridDelegate,
    );
  }

  // Shuffled animation order so tiles fall in a random column-mixing sequence.
  // Seed 42 = deterministic but visually random (left/right/middle interleaved).
  static List<int> _shuffledOrder(int count) {
    final rng = math.Random(42);
    final list = List.generate(count, (i) => i)..shuffle(rng);
    final pos = List.filled(count, 0);
    for (int j = 0; j < list.length; j++) { pos[list[j]] = j; }
    return pos;
  }

  Widget _buildServiceSliver(
      List<ServiceModel> services, HealthState health) {
    if (services.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.rocket_launch_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: 16),
                Text(
                  'Aucun service activé',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                  child: const Text('Configurer les services'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final animPos = _shuffledOrder(services.length);
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final service = services[i];
          final row = i ~/ 3;
          final fallOffset = -(270.0 + row * 140.0);
          return AnimationConfiguration.staggeredList(
            position: animPos[i],
            duration: const Duration(milliseconds: 420),
            delay: const Duration(milliseconds: 75),
            child: SlideAnimation(
              verticalOffset: fallOffset,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                curve: Curves.easeOut,
                child: ServiceCard(
                  service: service,
                  status: health.statusFor(service.id),
                  hasCredentials:
                      _hasCredentials[service.id] ?? false,
                  onTap: () => _openService(service),
                ),
              ),
            ),
          );
        },
        childCount: services.length,
      ),
      gridDelegate: _gridDelegate,
    );
  }

  Widget _buildShortcutSliver(List<AppShortcut> shortcuts) {
    final animPos = _shuffledOrder(shortcuts.length);
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final shortcut = shortcuts[i];
          final row = i ~/ 3;
          final fallOffset = -(270.0 + row * 140.0);
          return AnimationConfiguration.staggeredList(
            position: animPos[i],
            duration: const Duration(milliseconds: 420),
            delay: const Duration(milliseconds: 75),
            child: SlideAnimation(
              verticalOffset: fallOffset,
              curve: Curves.easeOutCubic,
              child: FadeInAnimation(
                curve: Curves.easeOut,
                child: ShortcutCard(
                  shortcut: shortcut,
                  onTap: () => _openShortcut(shortcut),
                ),
              ),
            ),
          );
        },
        childCount: shortcuts.length,
      ),
      gridDelegate: _gridDelegate,
    );
  }

  Future<void> _openService(ServiceModel service) async {
    final pkg = service.androidPackage;
    if (pkg != null) {
      try {
        final launched = await launchUrl(
          Uri.parse('android-app://$pkg'),
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebViewScreen(service: service)),
    );
  }

  Future<void> _openShortcut(AppShortcut shortcut) async {
    try {
      final launched = await launchUrl(
        Uri.parse('android-app://${shortcut.androidPackage}'),
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}
    try {
      await launchUrl(
        Uri.parse(shortcut.webFallbackUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
