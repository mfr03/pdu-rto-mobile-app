class DepthDrillingData {
  final Map<String, dynamic> rawData;
  final DateTime dateTime;
  final double md;         // Measured Depth
  final double tvd;        // True Vertical Depth
  final double ropi;       // Rate of Penetration (Instantaneous)
  final double hkla;       // Hook Load Average
  final double woba;       // Weight on Bit Average
  final double sppa;       // Standpipe Pressure Average
  final double torqa;      // Torque Average
  final double rpm;        // Rotary RPM
  final double mudDensin;  // Mud Density In
  final double ecd;        // Equivalent Circulating Density

  DepthDrillingData({
    required this.rawData,
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
    required this.ecd,
  });

  factory DepthDrillingData.fromJson(Map<String, dynamic> json) {
    return DepthDrillingData(
      rawData: json,
      dateTime: _parseDateTime(json['dt']),
      md: _toDouble(json['md']),
      tvd: _toDouble(json['tvd']),
      ropi: _toDouble(json['ropi']),
      hkla: _toDouble(json['hkla']),
      woba: _toDouble(json['woba']),
      sppa: _toDouble(json['sppa']),
      torqa: _toDouble(json['torqa']),
      rpm: _toDouble(json['rpm']),
      mudDensin: _toDouble(json['muddensin']),
      ecd: _toDouble(json['ecda']),
    );
  }

  static DateTime _parseDateTime(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  static double _toDouble(dynamic val) =>
      val == null ? 0.0 : double.tryParse(val.toString()) ?? 0.0;

  num value(String key) =>
      rawData[key] != null ? _toDouble(rawData[key]) : 0.0;
}