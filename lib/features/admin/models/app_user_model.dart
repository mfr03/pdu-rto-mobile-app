// lib/features/admin/models/app_user_model.dart
import 'package:flutter/foundation.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String companyId;
  // We don't store/use the password in the app

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.companyId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      companyId: json['companyId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AppUser && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}