import 'package:flutter/material.dart';

enum QuickActionType { http, wol }

class QuickAction {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final QuickActionType type;
  // HTTP fields
  final String method; // 'GET' | 'POST'
  final String url;
  final String? body;
  // Wake-on-LAN fields
  final String? wolMac;
  final String wolBroadcast;
  final bool enabled;

  QuickAction({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.type = QuickActionType.http,
    this.method = 'POST',
    this.url = '',
    this.body,
    this.wolMac,
    this.wolBroadcast = '255.255.255.255',
    this.enabled = true,
  });

  Color get color => Color(colorValue & 0xFFFFFFFF);
  IconData get icon => _iconFromCode(iconCode);
  
  static IconData _iconFromCode(int code) {
    // Cherche dans la liste des icônes disponibles
    for (final entry in kQuickActionIcons) {
      if (entry.icon.codePoint == code) return entry.icon;
    }
    // Fallback sur la première icône
    return kQuickActionIcons.first.icon;
  }
  bool get isWol => type == QuickActionType.wol;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': iconCode,
        'colorValue': colorValue,
        'type': type.name,
        'method': method,
        'url': url,
        if (body != null) 'body': body,
        if (wolMac != null) 'wolMac': wolMac,
        'wolBroadcast': wolBroadcast,
        'enabled': enabled,
      };

  factory QuickAction.fromJson(Map<String, dynamic> j) {
    final typeStr = j['type'] as String? ?? 'http';
    return QuickAction(
      id: j['id'] as String,
      name: j['name'] as String,
      iconCode: j['iconCode'] as int,
      colorValue: j['colorValue'] as int,
      type: QuickActionType.values.firstWhere((e) => e.name == typeStr,
          orElse: () => QuickActionType.http),
      method: j['method'] as String? ?? 'POST',
      url: j['url'] as String? ?? '',
      body: j['body'] as String?,
      wolMac: j['wolMac'] as String?,
      wolBroadcast: j['wolBroadcast'] as String? ?? '255.255.255.255',
      enabled: j['enabled'] as bool? ?? true,
    );
  }

  QuickAction copyWith({
    String? name,
    int? iconCode,
    int? colorValue,
    QuickActionType? type,
    String? method,
    String? url,
    String? body,
    String? wolMac,
    String? wolBroadcast,
    bool? enabled,
  }) =>
      QuickAction(
        id: id,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
        type: type ?? this.type,
        method: method ?? this.method,
        url: url ?? this.url,
        body: body ?? this.body,
        wolMac: wolMac ?? this.wolMac,
        wolBroadcast: wolBroadcast ?? this.wolBroadcast,
        enabled: enabled ?? this.enabled,
      );
}

// Icon picker list for the settings dialog
const kQuickActionIcons = <({IconData icon, String label})>[
  (icon: Icons.home_rounded, label: 'Maison'),
  (icon: Icons.door_sliding_rounded, label: 'Portail'),
  (icon: Icons.garage_rounded, label: 'Garage'),
  (icon: Icons.lock_open_rounded, label: 'Déverrou'),
  (icon: Icons.lock_rounded, label: 'Verrou'),
  (icon: Icons.lightbulb_rounded, label: 'Lumière'),
  (icon: Icons.power_settings_new_rounded, label: 'Power'),
  (icon: Icons.thermostat_rounded, label: 'Chauffage'),
  (icon: Icons.ac_unit_rounded, label: 'Clim'),
  (icon: Icons.local_fire_department_rounded, label: 'Feu'),
  (icon: Icons.water_drop_rounded, label: 'Arrosage'),
  (icon: Icons.air_rounded, label: 'Ventil'),
  (icon: Icons.bolt_rounded, label: 'Électricité'),
  (icon: Icons.wb_sunny_rounded, label: 'Soleil'),
  (icon: Icons.nightlight_rounded, label: 'Nuit'),
  (icon: Icons.security_rounded, label: 'Alarme'),
  (icon: Icons.notifications_rounded, label: 'Notif'),
  (icon: Icons.speaker_rounded, label: 'Audio'),
  (icon: Icons.tv_rounded, label: 'TV'),
  (icon: Icons.videocam_rounded, label: 'Caméra'),
  (icon: Icons.refresh_rounded, label: 'Relancer'),
  (icon: Icons.play_arrow_rounded, label: 'Play'),
  (icon: Icons.stop_rounded, label: 'Stop'),
  (icon: Icons.electric_car_rounded, label: 'Voiture'),
  (icon: Icons.computer_rounded, label: 'PC'),
  (icon: Icons.star_rounded, label: 'Favori'),
  (icon: Icons.alarm_rounded, label: 'Réveil'),
  (icon: Icons.restaurant_rounded, label: 'Cuisine'),
  (icon: Icons.pets_rounded, label: 'Animal'),
];
