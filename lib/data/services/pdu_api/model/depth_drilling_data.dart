import 'package:json_annotation/json_annotation.dart';

part 'depth_drilling_data.g.dart';


DateTime _dateTimeFromJson(String dateString) {
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

double _toDoubleSafe(dynamic val, [double defaultValue = 0.0]) {
  if (val == null || val.toString().isEmpty) return defaultValue;
  final parsedValue = double.tryParse(val.toString());
  if (parsedValue == null) {
    return defaultValue;
  }
  return parsedValue;
}

@JsonSerializable(explicitToJson: true, createToJson: true)
class DepthDrillingData {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final Map<String, dynamic> rawDataOriginal;

  @JsonKey(name: 'dt', fromJson: _dateTimeFromJson)
  final DateTime dateTime;

  @JsonKey(fromJson: _toDoubleSafe)
  final double md;         // Measured Depth

  @JsonKey(fromJson: _toDoubleSafe)
  final double tvd;        // True Vertical Depth

  @JsonKey(fromJson: _toDoubleSafe)
  final double ropi;       // Rate of Penetration (Instantaneous)

  @JsonKey(fromJson: _toDoubleSafe)
  final double hkla;       // Hook Load Average

  @JsonKey(fromJson: _toDoubleSafe)
  final double woba;       // Weight on Bit Average

  @JsonKey(fromJson: _toDoubleSafe)
  final double sppa;       // Standpipe Pressure Average

  @JsonKey(fromJson: _toDoubleSafe)
  final double torqa;      // Torque Average

  @JsonKey(fromJson: _toDoubleSafe)
  final double rpm;        // Rotary RPM

  @JsonKey(fromJson: _toDoubleSafe)
  final double mudDensin;  // Mud Density In

  @JsonKey(fromJson: _toDoubleSafe)
  final double ecda;        // Equivalent Circulating Density

  DepthDrillingData({
    Map<String, dynamic>? rawDataOriginal,
    required this.dateTime,
    required this.md,
    required this.tvd,
    required this.ropi,
    required this.hkla,
    required this.woba,
    required this.sppa,
    required this.torqa,
    required this.rpm,
    required this.mudDensin,
    required this.ecda,
  }) : rawDataOriginal = rawDataOriginal ?? const {};

  factory DepthDrillingData.fromJson(Map<String, dynamic> json) {


    final instance = _$DepthDrillingDataFromJson(json);


    return DepthDrillingData(
      rawDataOriginal: json,
      dateTime: instance.dateTime,
      md: instance.md,
      tvd: instance.tvd,
      ropi: instance.ropi,
      hkla: instance.hkla,
      woba: instance.woba,
      sppa: instance.sppa,
      torqa: instance.torqa,
      rpm: instance.rpm,
      mudDensin: instance.mudDensin,
      ecda: instance.ecda,
    );
  }

  Map<String, dynamic> toJson() => _$DepthDrillingDataToJson(this);


  num value(String key, [double defaultValue = 0.0]) {
    final val = rawDataOriginal[key];
    if (val == null) return defaultValue;
    return double.tryParse(val.toString()) ?? defaultValue;
  }

}