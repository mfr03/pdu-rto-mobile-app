import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';


// lib/models/parameter_item.dart

@HiveType(typeId: 1)
class ParameterItem extends HiveObject {
  @HiveField(0)
  final String name;      // what you show in the UI

  @HiveField(1)
  final String jsonKey;   // the actual field in rawData[]

  @HiveField(2)
  final String? unit;
  @HiveField(3)
  final int colorValue;
  @HiveField(4)
  final int scaleStart;
  @HiveField(5)
  final int scaleEnd;
  @HiveField(6)
  final DateTime createdAt;
  @HiveField(7)
  final DateTime updatedAt;
  @HiveField(8)
  final String trackType;
  @HiveField(9)
  final String value;

  Color get color => Color(colorValue);

  ParameterItem({
    required this.name,
    required this.jsonKey,        // ← new
    this.unit,
    required Color color,
    required this.scaleStart,
    required this.scaleEnd,
    required this.createdAt,
    required this.updatedAt,
    required this.trackType,
    required this.value,
  }) : colorValue = color.value;

  ParameterItem copyWith({
    String? name,
    String? jsonKey,             // ← allow updating too
    String? unit,
    Color? color,
    int? scaleStart,
    int? scaleEnd,
    DateTime? updatedAt,
    String? value,
  }) {
    return ParameterItem(
      name: name ?? this.name,
      jsonKey: jsonKey ?? this.jsonKey,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      scaleStart: scaleStart ?? this.scaleStart,
      scaleEnd: scaleEnd ?? this.scaleEnd,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackType: trackType,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ParameterItem &&
              name == other.name &&
              jsonKey == other.jsonKey &&
              trackType == other.trackType;

  @override
  int get hashCode => name.hashCode ^ jsonKey.hashCode ^ trackType.hashCode;
}
