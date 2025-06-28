// lib/features/admin/models/company_model.dart
import 'package:flutter/foundation.dart';

class Company {
  final String id;
  final String name;
  final String address;

  Company({
    required this.id,
    required this.name,
    required this.address,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
    );
  }

  @override
  String toString() {
    return name; // Default display in dropdown will be the company name
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Company && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}