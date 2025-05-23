class AppNotificationInfo {
  final String title;
  final String message;
  final String parameterName;
  final num currentValue;
  final num thresholdValue;
  final String condition;
  final DateTime timestamp;

  AppNotificationInfo({
    required this.title,
    required this.message,
    required this.parameterName,
    required this.currentValue,
    required this.thresholdValue,
    required this.condition,
    required this.timestamp,
  });
}