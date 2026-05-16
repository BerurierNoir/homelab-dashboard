import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ha_entity.dart';
import '../providers/ha_provider.dart';
import '../widgets/ha_entity_card.dart';
import '../widgets/ha_action_button.dart';
import '../widgets/ha_camera_card.dart';
import 'settings/settings_ha.dart';

class HaScreen extends ConsumerWidget {
  const HaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final haState = ref.watch(haProvider);
    final config = ref.watch(haConfigProvider);

    if (!config.isConfigured) {
      return _buildSetupPrompt(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF060614),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () => ref.read(haProvider.notifier).refresh(),
              color: const Color(0xFF00D4FF),
              backgroundColor: const Color(0xFF13132E),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  _buildAppBar(context, haState),
                  if (haState.isLoading && haState.entities.isEmpty)
                    const SliverToBoxAdapter(child: _LoadingSection())
                  else if (haState.error != null && haState.entities.isEmpty)
                    SliverToBoxAdapter(child: _ErrorSection(error: haState.error!))
                  else ...[
                    // ── Présence & Alarme ──────────────────────
                    SliverToBoxAdapter(child: _buildPresenceSection(haState, ref, config)),
                    // ── Caméra ─────────────────────────────────
                    SliverToBoxAdapter(child: _buildCameraSection(config)),
                    // ── Météo ──────────────────────────────────
                    SliverToBoxAdapter(child: _buildMeteoSection(haState)),
                    // ── Actions rapides ────────────────────────
                    SliverToBoxAdapter(child: _buildActionsSection(haState, ref)),
                    // ── Sécurité portes/fenêtres ───────────────
                    SliverToBoxAdapter(child: _buildSecuritySection(haState)),
                    // ── Lumières ───────────────────────────────
                    SliverToBoxAdapter(child: _buildLightsSection(haState, ref)),
                    // ── Multimédia ─────────────────────────────
                    SliverToBoxAdapter(child: _buildMediaSection(haState, ref)),
                    // ── Gaming ─────────────────────────────────
                    SliverToBoxAdapter(child: _buildGamingSection(haState, ref, config)),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── BACKGROUND COSMOS ─────────────────────────────────────

  Widget _buildBackground() {
    final rng = math.Random(99);
    return Stack(
      children: [
        // Fond dégradé
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, -0.8),
              radius: 1.2,
              colors: [Color(0xFF0A0A28), Color(0xFF060614)],
            ),
          ),
        ),
        // Glow cyan haut-gauche
        Positioned(
          top: -100,
          left: -80,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00D4FF).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Glow violet bas-droit
        Positioned(
          bottom: -120,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.07),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Étoiles
        ...List.generate(40, (i) {
          final x = rng.nextDouble();
          final y = rng.nextDouble();
          final size = rng.nextDouble() * 1.8 + 0.4;
          final opacity = rng.nextDouble() * 0.5 + 0.1;
          return Positioned(
            left: x * MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.width,
            top: y * 800,
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

  // ── APP BAR ──────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, HaState haState) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF7C3AED)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.home_rounded, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Domotique',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            // Indicateur connexion
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: haState.isConnected
                    ? const Color(0xFF5CDD8B)
                    : const Color(0xFFFF4D6D),
                boxShadow: haState.isConnected
                    ? [BoxShadow(
                        color: const Color(0xFF5CDD8B).withValues(alpha: 0.6),
                        blurRadius: 6,
                      )]
                    : null,
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00D4FF)),
          onPressed: () {},
          tooltip: 'Actualiser',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white60),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsHaScreen()),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── PRÉSENCE & ALARME ─────────────────────────────────────

  Widget _buildPresenceSection(HaState s, WidgetRef ref, HaConfig config) {
    final renaud = s.entity(HaEntities.presenceRenaud);
    final gaelle = s.entity(HaEntities.presenceGaelle);
    final alarme = s.entity(HaEntities.alarme);

    return _Section(
      title: 'PRÉSENCE & SÉCURITÉ',
      titleColor: const Color(0xFF00D4FF),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: renaud != null
                    ? _PersonCard(entity: renaud)
                    : _PersonCardPlaceholder(name: 'Renaud'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: gaelle != null
                    ? _PersonCard(entity: gaelle)
                    : _PersonCardPlaceholder(name: 'Gaëlle'),
              ),
            ],
          ),
          if (alarme != null) ...[
            const SizedBox(height: 10),
            _AlarmCard(entity: alarme),
          ],
          // Visiophone
          Builder(builder: (ctx) {
            final visioMoniteur = s.entity(HaEntities.visiophoneMoniteur);
            if (visioMoniteur == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _VisioCard(entity: visioMoniteur, config: config),
            );
          }),
        ],
      ),
    );
  }

  // ── CAMÉRA ───────────────────────────────────────────────

  Widget _buildCameraSection(HaConfig config) {
    if (!config.isConfigured) return const SizedBox.shrink();
    return _Section(
      title: 'SURVEILLANCE',
      titleColor: const Color(0xFF00D4FF),
      child: HaCameraCard(
        baseUrl: config.url,
        token: config.token,
        entityId: HaEntities.camera,
      ),
    );
  }

  // ── MÉTÉO ─────────────────────────────────────────────────

  Widget _buildMeteoSection(HaState s) {
    final temp = s.entity(HaEntities.tempExt);
    final condition = s.entity(HaEntities.conditionMeteo);
    final humidity = s.entity(HaEntities.humidite);
    final wind = s.entity(HaEntities.ventVitesse);
    final uv = s.entity(HaEntities.uv);

    if (temp == null) return const SizedBox.shrink();

    return _Section(
      title: 'MÉTÉO — AUREC-SUR-LOIRE',
      titleColor: const Color(0xFF00D4FF),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00D4FF).withValues(alpha: 0.08),
              const Color(0xFF13132E),
              const Color(0xFF7C3AED).withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00D4FF).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Température principale
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp.state}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition?.state ?? '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Détails
            Expanded(
              child: Column(
                children: [
                  if (humidity != null)
                    _MeteoRow(Icons.water_drop_rounded, '${humidity.state}% humidité'),
                  if (wind != null)
                    _MeteoRow(Icons.air_rounded, '${wind.state} km/h vent'),
                  if (uv != null)
                    _MeteoRow(Icons.wb_sunny_rounded, 'UV ${uv.state}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ACTIONS RAPIDES ───────────────────────────────────────

  Widget _buildActionsSection(HaState s, WidgetRef ref) {
    final actions = [
      (HaEntities.portailGarage, 'Portail\ngarage', Icons.garage_rounded, const Color(0xFF00D4FF)),
      (HaEntities.portailExt, 'Portail\nextérieur', Icons.door_sliding_rounded, const Color(0xFF00D4FF)),
      (HaEntities.priseTV, 'Prise TV', Icons.tv_rounded, const Color(0xFF5CDD8B)),
      (HaEntities.lumiereCamera, 'Lumière\ncaméra', Icons.highlight_rounded, const Color(0xFFE8C000)),
      (HaEntities.ledTV, 'LED TV', Icons.color_lens_rounded, const Color(0xFFFF4D6D)),
      (HaEntities.lumiereEtabli, 'Établi\ngarage', Icons.lightbulb_rounded, const Color(0xFFE8C000)),
    ];
    // Capteurs d'ouverture (lecture seule)
    final capteurs = [
      (HaEntities.capteurPortailGarage, 'Portail garage'),
      (HaEntities.capteurPortailExt, 'Portail ext.'),
      (HaEntities.capteurPorteGarage, 'Porte garage'),
      (HaEntities.capteurFenetreGarage, 'Fenêtre garage'),
    ];

    return _Section(
      title: 'ACTIONS RAPIDES',
      titleColor: const Color(0xFF00D4FF),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: actions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final (entityId, label, icon, color) = actions[i];
            final entity = s.entity(entityId);
            return HaActionButton(
              label: label,
              icon: icon,
              isOn: entity?.isOn ?? false,
              isUnavailable: entity?.isUnavailable ?? true,
              activeColor: color,
              onTap: () => ref.read(haProvider.notifier).toggle(entityId),
            );
          },
        ),
      ),
      SizedBox(height: 10),
      // Capteurs d'ouverture
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: capteurs.map((c) {
          final (entityId, label) = c;
          final entity = s.entity(entityId);
          final isOpen = entity?.isOn ?? false;
          final color = isOpen ? const Color(0xFFFF4D6D) : const Color(0xFF5CDD8B);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: color, size: 13,
                ),
                const SizedBox(width: 5),
                Text(label,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text(
                  isOpen ? 'Ouvert' : 'Fermé',
                  style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── SÉCURITÉ PORTES ───────────────────────────────────────

  Widget _buildSecuritySection(HaState s) {
    final sensors = [
      HaEntities.fenetreGarage,
      HaEntities.porteCellier,
    ].map((id) => s.entity(id)).whereType<HaEntity>().toList();

    if (sensors.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'PORTES & FENÊTRES',
      titleColor: const Color(0xFFFF4D6D),
      child: Column(
        children: sensors.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HaEntityCard(entity: e, compact: true),
        )).toList(),
      ),
    );
  }

  // ── LUMIÈRES ─────────────────────────────────────────────

  Widget _buildLightsSection(HaState s, WidgetRef ref) {
    final lights = [
      HaEntities.ledTV,
      HaEntities.lumiereCamera,
      HaEntities.lumiereEtabli,
    ].map((id) => s.entity(id)).whereType<HaEntity>().toList();

    if (lights.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'LUMIÈRES',
      titleColor: const Color(0xFFE8C000),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
        ),
        itemCount: lights.length,
        itemBuilder: (_, i) => HaEntityCard(
          entity: lights[i],
          onTap: () => ref.read(haProvider.notifier).toggle(lights[i].entityId),
        ),
      ),
    );
  }

  // ── MULTIMÉDIA ────────────────────────────────────────────

  Widget _buildMediaSection(HaState s, WidgetRef ref) {
    final googleHome = s.entity(HaEntities.googleHome);
    if (googleHome == null) return const SizedBox.shrink();

    return _Section(
      title: 'MULTIMÉDIA',
      titleColor: const Color(0xFF7C3AED),
      child: _MediaCard(entity: googleHome, ref: ref),
    );
  }

  // ── GAMING ────────────────────────────────────────────────

  Widget _buildGamingSection(HaState s, WidgetRef ref, HaConfig config) {
    final steam = s.entity(HaEntities.steam);
    final xbox = s.entity(HaEntities.xbox);
    final epic = s.entity(HaEntities.epicGames);
    final printer = s.entity(HaEntities.imprimante3D);
    final printTime = s.entity(HaEntities.printTimeLeft);

    final entities = [steam, xbox, epic, printer]
        .whereType<HaEntity>()
        .toList();

    if (entities.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'GAMING & TECH',
      titleColor: const Color(0xFF7C3AED),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: entities.length,
            itemBuilder: (_, i) {
              final entity = entities[i];
              return HaEntityCard(
                entity: entity,
                onTap: entity.entityId == HaEntities.imprimante3D
                    ? () => ref.read(haProvider.notifier).toggle(entity.entityId)
                    : null,
              );
            },
          ),
          if (printer?.isOn == true && printTime != null) ...[
            const SizedBox(height: 10),
            _PrintProgressCard(entity: printTime),
          ],
          // Epic Deals
          Builder(builder: (_) {
            final deals = s.entity(HaEntities.epicDeals);
            if (deals == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: HaEntityCard(entity: deals, compact: true),
            );
          }),
          // Caméra imprimante (si allumée)
          Builder(builder: (_) {
            final printerOn = s.entity(HaEntities.imprimante3D)?.isOn ?? false;
            if (!printerOn || !config.isConfigured) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: HaCameraCard(
                baseUrl: config.url,
                token: config.token,
                entityId: HaEntities.cameraImprimante,
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── SETUP PROMPT ─────────────────────────────────────────

  Widget _buildSetupPrompt(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060614),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 48,
                  color: Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Home Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Configurez votre URL et votre token\npour accéder à votre domotique.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsHaScreen()),
                ),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Configurer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SOUS-WIDGETS ──────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Color titleColor;
  final Widget child;

  const _Section({
    required this.title,
    required this.titleColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final HaEntity entity;

  const _PersonCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isHome = entity.state == 'home';
    final color = isHome ? const Color(0xFF5CDD8B) : const Color(0xFFFF9800);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF13132E),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Text(
              entity.friendlyName[0].toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.friendlyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHome ? '🏠 Maison' : '🌍 Absent',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 6,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final HaEntity entity;

  const _AlarmCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    final isArmed = entity.state != 'disarmed';
    final isTriggered = entity.state == 'triggered';
    final color = isTriggered
        ? const Color(0xFFFF4D6D)
        : isArmed
            ? const Color(0xFFE8C000)
            : const Color(0xFF5CDD8B);

    String label;
    switch (entity.state) {
      case 'disarmed': label = '🛡 Désactivée'; break;
      case 'armed_home': label = '🏠 Armée — Maison'; break;
      case 'armed_away': label = '🔒 Armée — Absent'; break;
      case 'armed_night': label = '🌙 Armée — Nuit'; break;
      case 'triggered': label = '🚨 DÉCLENCHÉE !'; break;
      default: label = entity.state;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: isTriggered
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 20)]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isTriggered
                ? Icons.warning_rounded
                : isArmed
                    ? Icons.security_rounded
                    : Icons.shield_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            'Alarme',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeteoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MeteoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF00D4FF).withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final HaEntity entity;
  final WidgetRef ref;

  const _MediaCard({required this.entity, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isPlaying = entity.state == 'playing';
    final title = entity.attributes['media_title'] as String?;
    final artist = entity.attributes['media_artist'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF13132E),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            ),
            child: Icon(
              isPlaying ? Icons.music_note_rounded : Icons.speaker_rounded,
              color: const Color(0xFF7C3AED),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entity.friendlyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (title != null)
                  Text(
                    artist != null ? '$title — $artist' : title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    entity.state == 'playing'
                        ? 'En lecture'
                        : entity.state == 'paused'
                            ? 'En pause'
                            : 'Inactif',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                onPressed: () => ref.read(haProvider.notifier).callService(
                  'media_player',
                  isPlaying ? 'media_pause' : 'media_play',
                  entity.entityId,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrintProgressCard extends StatelessWidget {
  final HaEntity entity;

  const _PrintProgressCard({required this.entity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: Color(0xFF7C3AED), size: 18),
          const SizedBox(width: 10),
          Text(
            'Temps restant : ${entity.state}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00D4FF),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;

  const _ErrorSection({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFFF4D6D), size: 48),
          const SizedBox(height: 16),
          const Text(
            'Impossible de joindre Home Assistant',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PersonCardPlaceholder extends StatelessWidget {
  final String name;
  const _PersonCardPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF13132E),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            child: Text(
              name[0],
              style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
                const Text('Non configuré', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisioCard extends StatelessWidget {
  final HaEntity entity;
  final HaConfig config;

  const _VisioCard({required this.entity, required this.config});

  @override
  Widget build(BuildContext context) {
    final isActive = entity.isOn;
    final color = isActive ? const Color(0xFFFF4D6D) : const Color(0xFF5CDD8B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.videocam_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Visiophone',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                  entity.friendlyName,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.15),
            ),
            child: Text(
              isActive ? 'Actif' : 'Inactif',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
