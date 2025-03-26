class WellActive {
  final String wid;
  final String cid;
  final String wellName;
  final String isApiToken;
  final String wellType; // 1 = Geothermal, 2 = Oil & Gas
  final String companyName;
  final String timeZone;
  final String startDate;
  final String endDate;

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
}
