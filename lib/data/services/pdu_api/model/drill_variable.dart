import 'package:json_annotation/json_annotation.dart';

part 'drill_variable.g.dart'; // You will need to run the build_runner for this

@JsonSerializable()
class DrillVariable {
  final String id;

  @JsonKey(name: 'kd_record')
  final String kdRecord;

  @JsonKey(name: 'kd_wits')
  final String? kdWits;

  final String? param;
  final String name;
  final String field;
  final String? cluster;

  DrillVariable({
    required this.id,
    required this.kdRecord,
    this.kdWits,
    this.param,
    required this.name,
    required this.field,
    this.cluster,
  });

  factory DrillVariable.fromJson(Map<String, dynamic> json) =>
      _$DrillVariableFromJson(json);

  Map<String, dynamic> toJson() => _$DrillVariableToJson(this);
}