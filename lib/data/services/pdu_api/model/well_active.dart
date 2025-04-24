class WellActive {
  final String wid;
  final String cid;
  final String wellName;
  final String isApiToken;
  final String wellType;
  final String companyName;
  final String timeZone;
  final String startDate;
  final String endDate;

  String timeStart;
  String timeEnd;

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
    this.timeEnd = "00:15:00",
  });

  factory WellActive.fromJson(Map<String, dynamic> json) {
    return WellActive(
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
  }

  void updateTimeRange(String newTimeStart, String newTimeEnd) {
    timeStart = newTimeStart;
    timeEnd = newTimeEnd;
  }
}
