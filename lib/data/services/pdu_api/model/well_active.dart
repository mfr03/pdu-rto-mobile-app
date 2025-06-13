import 'package:hive_ce/hive.dart';

class WellActive extends HiveObject {
  @HiveField(0) final String wid;
  @HiveField(1) final String cid;
  @HiveField(2) final String wellName;
  @HiveField(3) final String isApiToken;
  @HiveField(4) final String wellType; // Keep this name for existing usage if needed, but the API sends 'well_tipe'
  @HiveField(5) final String companyName;
  @HiveField(6) final String timeZone;
  @HiveField(7) final String startDate;
  @HiveField(8) final String endDate;
  @HiveField(9) String timeStart;  // e.g. "00:00:00"
  @HiveField(10) String timeEnd;   // e.g. "00:15:00"
  @HiveField(11) final String wellActiveStatus; // New field for "well_active" from API
  @HiveField(12) final String wellStatus;       // New field for "well_status" from API


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
    required this.wellActiveStatus, // Add to constructor
    required this.wellStatus,       // Add to constructor
  });

  // Helper getter to determine if the well is truly active based on "Yes"
  bool get isActive => wellActiveStatus.toLowerCase() == 'yes';

  // Manual fromJson factory, updated to include new fields and correct "well_tipe" key
  factory WellActive.fromJson(Map<String, dynamic> json) => WellActive(
    wid: json["wid"] ?? "",
    cid: json["cid"] ?? "",
    wellName: json["well_name"] ?? "",
    isApiToken: json["is_api_token"] ?? "",
    wellType: json["well_tipe"] ?? "", // Corrected to 'well_tipe' to match API example
    companyName: json["company_name"] ?? "",
    timeZone: json["time_zone"] ?? "",
    startDate: json["start_date"] ?? "",
    endDate: json["end_date"] ?? "",
    // New fields from API response
    wellActiveStatus: json["well_active"] ?? "No", // Default to "No" if null
    wellStatus: json["well_status"] ?? "",
  );

  void updateTimeRange(String newTimeStart, String newTimeEnd) {
    timeStart = newTimeStart;
    timeEnd   = newTimeEnd;
    save(); // Call save() to persist changes if this is a HiveObject instance
  }
}
