import 'package:json_annotation/json_annotation.dart';

part 'drilling_data.g.dart';

DateTime _dateTimeFromJson(String dateString) {
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    print('Error parsing DateTime "$dateString": $e');
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

double _toDoubleSafe(dynamic val, [double defaultValue = 0.0]) {
  if (val == null || val.toString().isEmpty) return defaultValue;
  final parsedValue = double.tryParse(val.toString());
  if (parsedValue == null) {
    print('Error parsing double for value: "$val". Using default: $defaultValue');
    return defaultValue;
  }
  return parsedValue;
}

@JsonSerializable(explicitToJson: true, createToJson: true)
class DrillingData {
  @JsonKey(includeFromJson: false, includeToJson: false)
  // It's final, but its value will be set by our custom fromJson logic
  final Map<String, dynamic> rawDataOriginal;

  @JsonKey(name: 'dt', fromJson: _dateTimeFromJson)
  final DateTime dateTime;

  // ... all your other fields remain the same ...
  @JsonKey(name: 'bitdepth', fromJson: _toDoubleSafe)
  final double bitDepth;

  @JsonKey(name: 'scfm', fromJson: _toDoubleSafe)
  final double scfm;

  @JsonKey(name: 'mudcondin', fromJson: _toDoubleSafe)
  final double mudCondIn;

  @JsonKey(name: 'blockpos', fromJson: _toDoubleSafe)
  final double blockPos;

  @JsonKey(name: 'woba', fromJson: _toDoubleSafe)
  final double wob;

  @JsonKey(name: 'ropi', fromJson: _toDoubleSafe)
  final double ropi;

  @JsonKey(name: 'deptbitv', fromJson: _toDoubleSafe)
  final double bvDepth;

  @JsonKey(name: 'mudcondout', fromJson: _toDoubleSafe)
  final double mudCondOut;

  @JsonKey(name: 'torqa', fromJson: _toDoubleSafe)
  final double torque;

  @JsonKey(fromJson: _toDoubleSafe)
  final double rpm;

  @JsonKey(name: 'hklda', fromJson: _toDoubleSafe)
  final double hkld;

  @JsonKey(name: 'logdepth', fromJson: _toDoubleSafe)
  final double logDepth;

  @JsonKey(name: 'h2s1', fromJson: _toDoubleSafe)
  final double h2s_1;

  @JsonKey(name: 'mudflowoutp', fromJson: _toDoubleSafe)
  final double mudFlowOutp;

  @JsonKey(name: 'totspm', fromJson: _toDoubleSafe)
  final double totSPM;

  @JsonKey(name: 'stppress', fromJson: _toDoubleSafe)
  final double spPress;

  @JsonKey(name: 'mudflowin', fromJson: _toDoubleSafe)
  final double mudFlowIn;

  @JsonKey(name: 'co21', fromJson: _toDoubleSafe)
  final double co2_1;

  @JsonKey(fromJson: _toDoubleSafe)
  final double gas;

  @JsonKey(name: 'mudtempin', fromJson: _toDoubleSafe)
  final double mudTempIn;

  @JsonKey(name: 'mudtempout', fromJson: _toDoubleSafe)
  final double mudTempOut;

  @JsonKey(name: 'tankvoltot', fromJson: _toDoubleSafe)
  final double tankVolTot;


  // MODIFICATION 1: Make rawDataOriginal non-required in THIS constructor
  // that the generator sees. It must have a value, so we'll ensure it's
  // provided in our factory.
  DrillingData({
    Map<String, dynamic>? rawDataOriginal, // Nullable here for the generator
    required this.dateTime,
    required this.bitDepth,
    required this.scfm,
    required this.mudCondIn,
    required this.blockPos,
    required this.wob,
    required this.ropi,
    required this.bvDepth,
    required this.mudCondOut,
    required this.torque,
    required this.rpm,
    required this.hkld,
    required this.logDepth,
    required this.h2s_1,
    required this.mudFlowOutp,
    required this.totSPM,
    required this.spPress,
    required this.mudFlowIn,
    required this.co2_1,
    required this.gas,
    required this.mudTempIn,
    required this.mudTempOut,
    required this.tankVolTot,
  }) : rawDataOriginal = rawDataOriginal ?? const {}; // Initialize if null, though our factory will always provide it.

  // MODIFICATION 2: The factory constructor will now correctly pass the json map.
  factory DrillingData.fromJson(Map<String, dynamic> json) {
    // The generated _$DrillingDataFromJson will correctly populate all fields
    // EXCEPT rawDataOriginal because of includeFromJson: false.
    // It will call the constructor above, passing null for rawDataOriginal.
    final instance = _$DrillingDataFromJson(json);

    // Now we create a new instance, copying all parsed fields from 'instance'
    // and explicitly setting rawDataOriginal.
    return DrillingData(
      rawDataOriginal: json, // Pass the original full JSON map here
      dateTime: instance.dateTime,
      bitDepth: instance.bitDepth,
      scfm: instance.scfm,
      mudCondIn: instance.mudCondIn,
      blockPos: instance.blockPos,
      wob: instance.wob,
      ropi: instance.ropi,
      bvDepth: instance.bvDepth,
      mudCondOut: instance.mudCondOut,
      torque: instance.torque,
      rpm: instance.rpm,
      hkld: instance.hkld,
      logDepth: instance.logDepth,
      h2s_1: instance.h2s_1,
      mudFlowOutp: instance.mudFlowOutp,
      totSPM: instance.totSPM,
      spPress: instance.spPress,
      mudFlowIn: instance.mudFlowIn,
      co2_1: instance.co2_1,
      gas: instance.gas,
      mudTempIn: instance.mudTempIn,
      mudTempOut: instance.mudTempOut,
      tankVolTot: instance.tankVolTot,
    );
  }

  Map<String, dynamic> toJson() => _$DrillingDataToJson(this);

  // The _copyWithManual method is no longer needed if we set rawDataOriginal
  // correctly in the factory fromJson. You can remove it.

  num value(String key, [double defaultValue = 0.0]) {
    final val = rawDataOriginal[key];
    if (val == null) return defaultValue;
    return double.tryParse(val.toString()) ?? defaultValue;
  }
}