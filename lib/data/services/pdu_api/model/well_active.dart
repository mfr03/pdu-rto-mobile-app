import 'package:hive_ce/hive.dart';
// TODO( remove wid because the api has changed. use apitoken instead)
class WellActive extends HiveObject {
  @HiveField(0) final String wid;
  @HiveField(1) final String cid;
  @HiveField(2) final String wellName;
  @HiveField(3) final String isApiToken;
  @HiveField(4) final String wellType;
  @HiveField(5) final String companyName;
  @HiveField(6) final String timeZone;
  @HiveField(7) final String startDate;
  @HiveField(8) final String endDate;
  @HiveField(9) String timeStart;  // e.g. "00:00:00"
  @HiveField(10) String timeEnd;   // e.g. "00:15:00"

  WellActive({
    required this.wid,
    required this.cid,
    required this.wellName,
    required this.isApiToken,
    required this.wellType,
    required this.companyName,
    required this.timeZone,
    required this.startDate,
    required this.endDate,
    this.timeStart = "00:00:00",
    this.timeEnd   = "00:15:00",
  });

  factory WellActive.fromJson(Map<String, dynamic> json) => WellActive(
    wid: json["wid"] ?? "",
    cid: json["cid"] ?? "",
    wellName: json["well_name"] ?? "",
    isApiToken: json["is_api_token"] ?? "",
    wellType: json["well_type"] ?? "",
    companyName: json["company_name"] ?? "",
    timeZone: json["time_zone"] ?? "",
    startDate: json["start_date"] ?? "",
    endDate: json["end_date"] ?? "",
  );

  void updateTimeRange(String newTimeStart, String newTimeEnd) {
    timeStart = newTimeStart;
    timeEnd   = newTimeEnd;
    save();
  }



}
