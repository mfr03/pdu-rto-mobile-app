// lib/data/services/notification_api/model/notification_rule_transfer_objects.dart
import 'package:flutter/foundation.dart';

class NotificationRulePayload {
  final String wellApiToken;
  final String parameterJsonKey;
  final String parameterName;
  final double thresholdValue;
  final String condition; // "above" or "below"
  final bool isEnabled;
  final String? notes;
  // The server assigns user_id based on the path parameter
  // The server assigns id, created_at, updated_at, last_notification_sent_at

  NotificationRulePayload({
    required this.wellApiToken,
    required this.parameterJsonKey,
    required this.parameterName,
    required this.thresholdValue,
    required this.condition,
    this.isEnabled = true,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'well_api_token': wellApiToken,
      'parameter_json_key': parameterJsonKey,
      'parameter_name': parameterName,
      'threshold_value': thresholdValue,
      'condition': condition,
      'is_enabled': isEnabled,
      if (notes != null) 'notes': notes,
    };
  }
}

class NotificationRuleResponse {
  final int id;
  final int userId;
  final String wellApiToken;
  final String parameterJsonKey;
  final String parameterName;
  final double thresholdValue;
  final String condition;
  final bool isEnabled;
  final String? notes;
  final DateTime? lastNotificationSentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationRuleResponse({
    required this.id,
    required this.userId,
    required this.wellApiToken,
    required this.parameterJsonKey,
    required this.parameterName,
    required this.thresholdValue,
    required this.condition,
    required this.isEnabled,
    this.notes,
    this.lastNotificationSentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationRuleResponse.fromJson(Map<String, dynamic> json) {
    return NotificationRuleResponse(
      id: json['id'],
      userId: json['user_id'],
      wellApiToken: json['well_api_token'],
      parameterJsonKey: json['parameter_json_key'],
      parameterName: json['parameter_name'],
      thresholdValue: (json['threshold_value'] as num).toDouble(),
      condition: json['condition'],
      isEnabled: json['is_enabled'],
      notes: json['notes'],
      lastNotificationSentAt: json['last_notification_sent_at'] != null
          ? DateTime.parse(json['last_notification_sent_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class NotificationRuleUpdatePayload {
  // All fields are optional for updates
  final String? wellApiToken;
  final String? parameterJsonKey;
  final String? parameterName;
  final double? thresholdValue;
  final String? condition; // "above" or "below"
  final bool? isEnabled;
  final String? notes;

  NotificationRuleUpdatePayload({
    this.wellApiToken,
    this.parameterJsonKey,
    this.parameterName,
    this.thresholdValue,
    this.condition,
    this.isEnabled,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (wellApiToken != null) data['well_api_token'] = wellApiToken;
    if (parameterJsonKey != null) data['parameter_json_key'] = parameterJsonKey;
    if (parameterName != null) data['parameter_name'] = parameterName;
    if (thresholdValue != null) data['threshold_value'] = thresholdValue;
    if (condition != null) data['condition'] = condition;
    if (isEnabled != null) data['is_enabled'] = isEnabled;
    if (notes != null) data['notes'] = notes;
    return data;
  }
}