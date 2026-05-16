import 'package:flutter/material.dart';

enum AutoLoginMethod { none, jsInjection, apiToken }

enum NetworkMode { local, tailscale }

class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String localUrl;
  final String tailscaleUrl;
  final IconData icon;
  final Color color;
  final bool enabled;
  final AutoLoginMethod autoLoginMethod;
  final bool isCloudService;
  final bool isCustomUrl;
  final String currentUrl;
  final String? androidPackage;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.localUrl,
    required this.tailscaleUrl,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.autoLoginMethod = AutoLoginMethod.none,
    this.isCloudService = false,
    this.isCustomUrl = false,
    this.androidPackage,
    String? currentUrl,
  }) : currentUrl = currentUrl ?? localUrl;

  String urlForMode(NetworkMode mode) {
    if (isCloudService) return localUrl;
    return mode == NetworkMode.tailscale ? tailscaleUrl : localUrl;
  }

  ServiceModel copyWith({
    bool? enabled,
    String? currentUrl,
    bool? isCustomUrl,
  }) {
    return ServiceModel(
      id: id,
      name: name,
      description: description,
      localUrl: localUrl,
      tailscaleUrl: tailscaleUrl,
      icon: icon,
      color: color,
      enabled: enabled ?? this.enabled,
      autoLoginMethod: autoLoginMethod,
      isCloudService: isCloudService,
      isCustomUrl: isCustomUrl ?? this.isCustomUrl,
      androidPackage: androidPackage,
      currentUrl: currentUrl ?? this.currentUrl,
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
    localUrl: 'http://192.168.1.100:8096',
    tailscaleUrl: 'http://100.64.0.1:8096',
    icon: Icons.play_circle_fill,
    color: Color(0xFF00A4DC),
    autoLoginMethod: AutoLoginMethod.apiToken,
    androidPackage: 'org.jellyfin.mobile',
  ),
  ServiceModel(
    id: 'homeassistant',
    name: 'Home Assistant',
    description: 'Domotique & automatisation',
    localUrl: 'https://your-instance.ui.nabu.casa',
    tailscaleUrl: 'https://your-instance.ui.nabu.casa',
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
    localUrl: 'http://192.168.1.100:9925',
    tailscaleUrl: 'http://100.64.0.1:9925',
    icon: Icons.restaurant,
    color: Color(0xFFE58325),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'paperless',
    name: 'Paperless-ngx',
    description: 'Gestion de documents',
    localUrl: 'http://192.168.1.100:8000',
    tailscaleUrl: 'http://100.64.0.1:8000',
    icon: Icons.description,
    color: Color(0xFF17541F),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'immich',
    name: 'Immich',
    description: 'Photos & vidéos',
    localUrl: 'http://192.168.1.100:2283',
    tailscaleUrl: 'http://100.64.0.1:2283',
    icon: Icons.photo_library,
    color: Color(0xFF4250AF),
    autoLoginMethod: AutoLoginMethod.jsInjection,
    androidPackage: 'app.alextran.immich',
  ),
  ServiceModel(
    id: 'kavita',
    name: 'Kavita',
    description: 'Livres, mangas & BD',
    localUrl: 'http://192.168.1.100:5000',
    tailscaleUrl: 'http://100.64.0.1:5000',
    icon: Icons.menu_book,
    color: Color(0xFFE040FB),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'uptimekuma',
    name: 'Uptime Kuma',
    description: 'Surveillance des services',
    localUrl: 'http://192.168.1.100:3001',
    tailscaleUrl: 'http://100.64.0.1:3001',
    icon: Icons.monitor_heart,
    color: Color(0xFF5CDD8B),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'homepage',
    name: 'Homepage',
    description: 'Tableau de bord homelab',
    localUrl: 'http://192.168.1.100:3000',
    tailscaleUrl: 'http://100.64.0.1:3000',
    icon: Icons.dashboard,
    color: Color(0xFF6C72CB),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'jotty',
    name: 'Jotty',
    description: 'Notes rapides',
    localUrl: 'http://192.168.1.100:1122',
    tailscaleUrl: 'http://100.64.0.1:1122',
    icon: Icons.edit_note,
    color: Color(0xFFFFD600),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'proxmox',
    name: 'Proxmox VE',
    description: 'Virtualisation',
    localUrl: 'https://192.168.1.100:8006',
    tailscaleUrl: 'https://100.64.0.1:8006',
    icon: Icons.dns,
    color: Color(0xFFE57000),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'teamspeak6',
    name: 'TeamSpeak 6',
    description: 'Chat vocal',
    localUrl: 'http://192.168.1.100:9987',
    tailscaleUrl: 'http://100.64.0.1:9987',
    icon: Icons.headset_mic,
    color: Color(0xFF2580C3),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'whoogle',
    name: 'Whoogle Search',
    description: 'Recherche privée',
    localUrl: 'http://192.168.1.100:5001',
    tailscaleUrl: 'http://100.64.0.1:5001',
    icon: Icons.search,
    color: Color(0xFF4285F4),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'klipper',
    name: 'Klipper',
    description: 'Impression 3D',
    localUrl: 'http://192.168.1.100:80',
    tailscaleUrl: 'http://100.64.0.1:80',
    icon: Icons.precision_manufacturing,
    color: Color(0xFFFF6B35),
    autoLoginMethod: AutoLoginMethod.none,
  ),
  ServiceModel(
    id: 'pydio',
    name: 'Pydio Cells',
    description: 'Stockage de fichiers',
    localUrl: 'https://192.168.1.100:8082',
    tailscaleUrl: 'https://100.64.0.1:8082',
    icon: Icons.folder_shared,
    color: Color(0xFF00BCD4),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'beszel',
    name: 'Beszel',
    description: 'Monitoring système',
    localUrl: 'http://192.168.1.100:8090',
    tailscaleUrl: 'http://100.64.0.1:8090',
    icon: Icons.monitor,
    color: Color(0xFF00BFA5),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'linkding',
    name: 'Linkding',
    description: 'Gestion de bookmarks',
    localUrl: 'http://192.168.1.100:9090',
    tailscaleUrl: 'http://100.64.0.1:9090',
    icon: Icons.bookmark,
    color: Color(0xFFFF6D00),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'portainer',
    name: 'Portainer',
    description: 'Gestion Docker & containers',
    localUrl: 'https://192.168.1.100:9443',
    tailscaleUrl: 'https://100.64.0.1:9443',
    icon: Icons.widgets,
    color: Color(0xFF13BEF9),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'nextcloud',
    name: 'Nextcloud',
    description: 'Cloud personnel & fichiers',
    localUrl: 'http://192.168.1.100:8080',
    tailscaleUrl: 'http://100.64.0.1:8080',
    icon: Icons.cloud,
    color: Color(0xFF0082C9),
    autoLoginMethod: AutoLoginMethod.jsInjection,
    androidPackage: 'com.nextcloud.client',
  ),
  ServiceModel(
    id: 'vaultwarden',
    name: 'Vaultwarden',
    description: 'Gestionnaire de mots de passe',
    localUrl: 'http://192.168.1.100:8200',
    tailscaleUrl: 'http://100.64.0.1:8200',
    icon: Icons.lock,
    color: Color(0xFF175DDC),
    autoLoginMethod: AutoLoginMethod.none,
    androidPackage: 'com.x8bit.bitwarden',
  ),
  ServiceModel(
    id: 'grafana',
    name: 'Grafana',
    description: 'Tableaux de bord & métriques',
    localUrl: 'http://192.168.1.100:3000',
    tailscaleUrl: 'http://100.64.0.1:3000',
    icon: Icons.bar_chart,
    color: Color(0xFFF46800),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'forgejo',
    name: 'Forgejo',
    description: 'Hébergement Git',
    localUrl: 'http://192.168.1.100:3030',
    tailscaleUrl: 'http://100.64.0.1:3030',
    icon: Icons.code,
    color: Color(0xFF609926),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'jellyseerr',
    name: 'Jellyseerr',
    description: 'Demandes de médias',
    localUrl: 'http://192.168.1.100:5055',
    tailscaleUrl: 'http://100.64.0.1:5055',
    icon: Icons.add_to_queue,
    color: Color(0xFF6366F1),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'n8n',
    name: 'n8n',
    description: 'Automatisation de workflows',
    localUrl: 'http://192.168.1.100:5678',
    tailscaleUrl: 'http://100.64.0.1:5678',
    icon: Icons.account_tree,
    color: Color(0xFFEA4B71),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'adguard',
    name: 'AdGuard Home',
    description: 'Blocage publicités & DNS',
    localUrl: 'http://192.168.1.100:3000',
    tailscaleUrl: 'http://100.64.0.1:3000',
    icon: Icons.shield,
    color: Color(0xFF67B346),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
  ServiceModel(
    id: 'frigate',
    name: 'Frigate',
    description: 'Surveillance IA & détection',
    localUrl: 'http://192.168.1.100:5000',
    tailscaleUrl: 'http://100.64.0.1:5000',
    icon: Icons.camera_outdoor,
    color: Color(0xFF00BCD4),
    autoLoginMethod: AutoLoginMethod.jsInjection,
  ),
];
