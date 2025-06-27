// lib/features/notifications/model/parameter_notification_setting.dart
import 'package:hive_ce/hive.dart';

part 'parameter_notification_setting.g.dart'; // To be generated

@HiveType(typeId: 3) // Ensure this typeId is unique across your Hive models
class ParameterNotificationSetting extends HiveObject {
  @HiveField(0)
  String wellApiToken; // Links setting to a specific well

  @HiveField(1)
  final String wellName; // <-- ADD THIS FIELD

  @HiveField(2)
  String parameterJsonKey; // e.g., "ropi", "bitdepth"

  @HiveField(3)
  String parameterName; // e.g., "ROP Inst (m/hr)", "Bit Depth (m)" for display

  @HiveField(4)
  double thresholdValue;

  @HiveField(5)
  String condition; // "above", "below" (can be an enum later)

  @HiveField(6)
  bool isEnabled;

  @HiveField(7)
  DateTime? lastNotificationTime; // To prevent spamming

  @HiveField(8)
  String? notes; // Optional user notes for the alert

  @HiveField(9)
  int? serverId;

  ParameterNotificationSetting({
    required this.wellApiToken,
    required this.wellName,
    required this.parameterJsonKey,
    required this.parameterName,
    required this.thresholdValue,
    required this.condition,
    this.isEnabled = true,
    this.lastNotificationTime,
    this.notes,
    this.serverId
  });


  ParameterNotificationSetting copyWith({
    bool? isEnabled,
    double? thresholdValue,
    String? condition,
    DateTime? lastNotificationTime, // Allow clearing it
    String? notes,
    int? serverId,
  }) {
    return ParameterNotificationSetting(
      wellApiToken: wellApiToken,
      wellName: wellName,
      parameterJsonKey: parameterJsonKey,
      parameterName: parameterName,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      condition: condition ?? this.condition,
      isEnabled: isEnabled ?? this.isEnabled,
      lastNotificationTime: lastNotificationTime, // Handle explicit null for clearing
      notes: notes ?? this.notes,
      serverId: serverId ?? this.serverId,
    );
  }
}