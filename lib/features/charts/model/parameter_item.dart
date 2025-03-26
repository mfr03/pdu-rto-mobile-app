import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';


class ParameterItem extends HiveObject {
  final String name;
  final String? unit;
  // final String? value;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String trackType;
  Color get color => Color(colorValue);

  final String value;

  ParameterItem({
    required this.name,
    this.unit,
    required Color color,
    required this.createdAt,
    required this.updatedAt,
    required this.trackType,
    required this.value
  }) : colorValue = color.value;

  ParameterItem copyWith({
    String? name,
    String? unit,
    Color? color,
    DateTime? updatedAt,
    String? value, // Added 'value' parameter
  }) {
    return ParameterItem(
      name: name ?? this.name,
      unit: unit ?? this.unit,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackType: trackType,
      value: value ?? this.value, // Use new value or current
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ParameterItem &&
              name == other.name &&
              trackType == other.trackType;

  @override
  int get hashCode => name.hashCode ^ trackType.hashCode;


}