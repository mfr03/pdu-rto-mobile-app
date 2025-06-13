import 'package:json_annotation/json_annotation.dart';

part 'remark_item.g.dart';

DateTime _dateTimeFromJson(String dateString) {
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    // Fallback for parsing errors, e.g., return a default DateTime
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

@JsonSerializable()
class RemarkItem {
  @JsonKey(name: 'dt', fromJson: _dateTimeFromJson)
  final DateTime dateTime;
  final String date;
  final String time;
  @JsonKey(name: 'comm_text')
  final String commText;

  RemarkItem({
    required this.dateTime,
    required this.date,
    required this.time,
    required this.commText,
  });

  factory RemarkItem.fromJson(Map<String, dynamic> json) => _$RemarkItemFromJson(json);
  Map<String, dynamic> toJson() => _$RemarkItemToJson(this);
}