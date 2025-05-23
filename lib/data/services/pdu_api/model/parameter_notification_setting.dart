// lib/features/notifications/model/parameter_notification_setting.dart
import 'package:hive_ce/hive.dart';

part 'parameter_notification_setting.g.dart'; // To be generated

@HiveType(typeId: 3) // Ensure this typeId is unique across your Hive models
class ParameterNotificationSetting extends HiveObject {
  @HiveField(0)
  String wellApiToken; // Links setting to a specific well

  @HiveField(1)
  String parameterJsonKey; // e.g., "ropi", "bitdepth"

  @HiveField(2)
  String parameterName; // e.g., "ROP Inst (m/hr)", "Bit Depth (m)" for display

  @HiveField(3)
  double thresholdValue;

  @HiveField(4)
  String condition; // "above", "below" (can be an enum later)

  @HiveField(5)
  bool isEnabled;

  @HiveField(6)
  DateTime? lastNotificationTime; // To prevent spamming

  @HiveField(7)
  String? notes; // Optional user notes for the alert

  ParameterNotificationSetting({
    required this.wellApiToken,
    required this.parameterJsonKey,
    required this.parameterName,
    required this.thresholdValue,
    required this.condition,
    this.isEnabled = true,
    this.lastNotificationTime,
    this.notes,
  });


  ParameterNotificationSetting copyWith({
    bool? isEnabled,
    double? thresholdValue,
    String? condition,
    DateTime? lastNotificationTime, // Allow clearing it
    String? notes,
  }) {
    return ParameterNotificationSetting(
      wellApiToken: wellApiToken,
      parameterJsonKey: parameterJsonKey,
      parameterName: parameterName,
      thresholdValue: thresholdValue ?? this.thresholdValue,
      condition: condition ?? this.condition,
      isEnabled: isEnabled ?? this.isEnabled,
      lastNotificationTime: lastNotificationTime, // Handle explicit null for clearing
      notes: notes ?? this.notes,
    );
  }
}