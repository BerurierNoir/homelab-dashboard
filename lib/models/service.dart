import 'package:flutter/material.dart';

enum AutoLoginMethod { none, jsInjection, apiToken }

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String defaultUrl;   // URL par défaut (modifiable par l'utilisateur)
  final String url;          // URL courante (personnalisée ou par défaut)
  final IconData icon;
  final Color color;
  final bool enabled;
  final AutoLoginMethod autoLoginMethod;
  final bool isCloudService;
  final String? androidPackage;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultUrl,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.autoLoginMethod = AutoLoginMethod.none,
    this.isCloudService = false,
    this.androidPackage,
    String? url,
  }) : url = url ?? defaultUrl;

  ServiceModel copyWith({
    bool? enabled,
    String? url,
  }) {
    return ServiceModel(
      id: id,
      name: name,
      description: description,
      defaultUrl: defaultUrl,
      icon: icon,
      color: color,
      enabled: enabled ?? this.enabled,
      autoLoginMethod: autoLoginMethod,
      isCloudService: isCloudService,
      androidPackage: androidPackage,
      url: url ?? this.url,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ServiceStatus {
  final String serviceId;
  final bool? isUp;
  final int? responseTimeMs;
  final DateTime? lastChecked;
  final String? errorMessage;
  final bool isPrinting;

  const ServiceStatus({
    required this.serviceId,
    this.isUp,
    this.responseTimeMs,
    this.lastChecked,
    this.errorMessage,
    this.isPrinting = false,
  });

  ServiceStatus copyWith({
    bool? isUp,
    int? responseTimeMs,
    DateTime? lastChecked,
    String? errorMessage,
    bool? isPrinting,
  }) {
    return ServiceStatus(
      serviceId: serviceId,
      isUp: isUp ?? this.isUp,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
      isPrinting: isPrinting ?? this.isPrinting,
    );
  }
}

const List<ServiceModel> kDefaultServices = [
  ServiceModel(
    id: 'jellyfin',
    name: 'Jellyfin',
    description: 'Films, séries et musiques',
    defaultUrl: '',
    icon: Icons.play_circle_fill,
    color: Color(0xFF00A4DC),
    autoLoginMethod: AutoLoginMethod.apiToken,
    androidPackage: 'org.jellyfin.mobile',
  ),
  ServiceModel(
    id: 'homeassistant',
    name: 'Home Assistant',
    description: 'Domotique & automatisation',
    defaultUrl: '',
    icon: Icons.home,
    color: Color(0xFF18BCF2),
    autoLoginMethod: AutoLoginMethod.apiToken,
    isCloudService: true,
    androidPackage: 'io.homeassistant.companion.android',
  ),
  ServiceModel(
    id: 'mealie',
    name: 'Mealie',
    description: 'Recettes & planning repas',
    defaultUrl: '',
    icon: Icons.restaurant,
    color: Color(0xFFE58325),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'paperless',
    name: 'Paperless-ngx',
    description: 'Gestion de documents',
    defaultUrl: '',
    icon: Icons.description,
    color: Color(0xFF17541F),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'immich',
    name: 'Immich',
    description: 'Photos & vidéos',
    defaultUrl: '',
    icon: Icons.photo_library,
    color: Color(0xFF4250AF),
    autoLoginMethod: AutoLoginMethod.jsInjection,
    androidPackage: 'app.alextran.immich',
  ),
  ServiceModel(
    id: 'kavita',
    name: 'Kavita',
    description: 'Livres, mangas & BD',
    defaultUrl: '',
    icon: Icons.menu_book,
    color: Color(0xFFE040FB),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'uptimekuma',
    name: 'Uptime Kuma',
    description: 'Surveillance des services',
    defaultUrl: '',
    icon: Icons.monitor_heart,
    color: Color(0xFF5CDD8B),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'homepage',
    name: 'Homepage',
    description: 'Tableau de bord homelab',
    defaultUrl: '',
    icon: Icons.dashboard,
    color: Color(0xFF6C72CB),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'jotty',
    name: 'Jotty',
    description: 'Notes rapides',
    defaultUrl: '',
    icon: Icons.edit_note,
    color: Color(0xFFFFD600),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'proxmox',
    name: 'Proxmox VE',
    description: 'Virtualisation',
    defaultUrl: '',
    icon: Icons.dns,
    color: Color(0xFFE57000),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'teamspeak6',
    name: 'TeamSpeak 6',
    description: 'Chat vocal',
    defaultUrl: '',
    icon: Icons.headset_mic,
    color: Color(0xFF2580C3),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'whoogle',
    name: 'Whoogle Search',
    description: 'Recherche privée',
    defaultUrl: '',
    icon: Icons.search,
    color: Color(0xFF4285F4),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'klipper',
    name: 'Klipper',
    description: 'Impression 3D',
    defaultUrl: '',
    icon: Icons.precision_manufacturing,
    color: Color(0xFFFF6B35),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'beszel',
    name: 'Beszel',
    description: 'Monitoring système',
    defaultUrl: '',
    icon: Icons.monitor,
    color: Color(0xFF00BFA5),
    autoLoginMethod: AutoLoginMethod.apiToken,
  ),
  ServiceModel(
    id: 'immich_ext',
    name: 'Immich (externe)',
    description: 'Photos via Tailscale',
    defaultUrl: '',
    icon: Icons.photo_library_outlined,
    color: Color(0xFF4250AF),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'portainer',
    name: 'Portainer',
    description: 'Gestion Docker & containers',
    defaultUrl: '',
    icon: Icons.widgets,
    color: Color(0xFF13BEF9),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'vaultwarden',
    name: 'Vaultwarden',
    description: 'Gestionnaire de mots de passe',
    defaultUrl: '',
    icon: Icons.lock,
    color: Color(0xFF175DDC),
    autoLoginMethod: AutoLoginMethod.none,
    androidPackage: 'com.x8bit.bitwarden',
  ),
  ServiceModel(
    id: 'grafana',
    name: 'Grafana',
    description: 'Tableaux de bord & métriques',
    defaultUrl: '',
    icon: Icons.bar_chart,
    color: Color(0xFFF46800),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'pihole',
    name: 'Pi-hole',
    description: 'Blocage publicités & DNS',
    defaultUrl: '',
    icon: Icons.shield,
    color: Color(0xFF67B346),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'frigate',
    name: 'Frigate',
    description: 'Surveillance IA & détection',
    defaultUrl: '',
    icon: Icons.camera_outdoor,
    color: Color(0xFF00BCD4),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
];
