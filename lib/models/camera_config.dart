import 'dart:convert';
import 'package:flutter/material.dart';

class CameraConfig {
  final String id;
  final String name;
  final Color color;
  final bool enabled;

  const CameraConfig({
    required this.id,
    required this.name,
    this.color = const Color(0xFF00D4FF),
    this.enabled = true,
  });

  CameraConfig copyWith({String? name, Color? color, bool? enabled}) =>
      CameraConfig(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'enabled': enabled,
      };

  factory CameraConfig.fromJson(Map<String, dynamic> j) => CameraConfig(
        id: j['id'] as String,
        name: j['name'] as String,
        color: Color(j['color'] as int),
        enabled: j['enabled'] as bool? ?? true,
      );

  static List<CameraConfig> listFromJson(String raw) {
    final list = jsonDecode(raw) as List;
    return list.map((e) => CameraConfig.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<CameraConfig> cameras) =>
      jsonEncode(cameras.map((c) => c.toJson()).toList());
}
