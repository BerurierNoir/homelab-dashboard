class HaEntity {
  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final DateTime lastChanged;

  const HaEntity({
    required this.entityId,
    required this.state,
    required this.attributes,
    required this.lastChanged,
  });

  String get domain => entityId.split('.').first;
  String get objectId => entityId.split('.').last;
  String get friendlyName =>
      (attributes['friendly_name'] as String?) ?? objectId;

  bool get isOn =>
      state == 'on' ||
      state == 'open' ||
      state == 'home' ||
      state == 'playing' ||
      state == 'armed_home' ||
      state == 'armed_away' ||
      state == 'armed_night';

  bool get isUnavailable =>
      state == 'unavailable' || state == 'unknown';

  double? get temperature =>
      (attributes['temperature'] as num?)?.toDouble() ??
      (attributes['current_temperature'] as num?)?.toDouble();

  double? get humidity =>
      (attributes['humidity'] as num?)?.toDouble();

  String? get icon => attributes['icon'] as String?;

  factory HaEntity.fromJson(Map<String, dynamic> json) {
    return HaEntity(
      entityId: json['entity_id'] as String,
      state: json['state'] as String,
      attributes: Map<String, dynamic>.from(
          (json['attributes'] as Map?) ?? {}),
      lastChanged: DateTime.tryParse(
              json['last_changed'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  HaEntity copyWith({String? state, Map<String, dynamic>? attributes}) {
    return HaEntity(
      entityId: entityId,
      state: state ?? this.state,
      attributes: attributes ?? this.attributes,
      lastChanged: DateTime.now(),
    );
  }
}

// Entités préconfigurées pour le homelab de Renaud
class HaEntities {
  static const presenceRenaud = 'person.renaud';
  static const presenceGaelle = 'person.gaelle';
  static const alarme = 'alarm_control_panel.alarmo';
  static const portailGarage = 'cover.portail_garage';
  static const portailExt = 'cover.portail';
  static const priseTV = 'switch.smart_plug_socket_1';
  static const lumiereCamera = 'light.cam_exterieur_projecteur';
  static const ledTV = 'light.housseled_strip_led';
  static const lumiereEtabli = 'light.lumiere_garage_etabli';
  static const fenetreGarage = 'binary_sensor.fenetre_garage_porte';
  static const porteCellier = 'binary_sensor.porte_cellier_contact';
  static const camera = 'camera.cam_exterieur_fluent';
  static const tempExt = 'sensor.aurec_sur_loire_temperature';
  static const conditionMeteo = 'sensor.aurec_sur_loire_original_condition';
  static const humidite = 'sensor.aurec_sur_loire_humidity';
  static const ventVitesse = 'sensor.aurec_sur_loire_wind_speed';
  static const uv = 'sensor.aurec_sur_loire_uv';
  static const steam = 'sensor.steam_76561198017780006';
  static const xbox = 'binary_sensor.beruriernoir672';
  static const epicGames = 'calendar.epic_games_store_jeux_gratuits';
  static const imprimante3D = 'switch.prise_imprimante_3d_prise_1';
  static const printTimeLeft = 'sensor.ender3v2wap_print_time_left_2';
  static const googleHome = 'media_player.googlehome7806';

  static const List<String> allEntities = [
    presenceRenaud,
    presenceGaelle,
    alarme,
    portailGarage,
    portailExt,
    priseTV,
    lumiereCamera,
    ledTV,
    lumiereEtabli,
    fenetreGarage,
    porteCellier,
    tempExt,
    conditionMeteo,
    humidite,
    ventVitesse,
    uv,
    steam,
    xbox,
    epicGames,
    imprimante3D,
    printTimeLeft,
    googleHome,
  ];
}
