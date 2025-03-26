class DrillingData {
  final DateTime dateTime;
  final double bitDepth;
  final double scfm;
  final double mudCondIn;
  final double blockPos;
  final double wob;
  final double ropi;
  final double bvDepth;
  final double mudCondOut;
  final double torque;
  final double rpm;
  final double hkld;
  final double logDepth;
  final double h2s_1;
  final double mudFlowOutp;
  final double totSPM;
  final double spPress;
  final double mudFlowIn;
  final double co2_1;
  final double gas;
  final double mudTempIn;
  final double mudTempOut;
  final double tankVolTot;

  DrillingData({
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
  });

  factory DrillingData.fromJson(Map<String, dynamic> json) {
    // Safely parse each field, fallback to 0.0 if invalid
    // Convert "dt" to DateTime (assuming server uses "yyyy-MM-dd HH:mm:ss")
    final dateString = (json['dt'] ?? '') as String;

    return DrillingData(
      dateTime: DateTime.tryParse(dateString) ?? DateTime.now(),
      bitDepth: _toDouble(json['bitdepth']),
      scfm: _toDouble(json['scfm']), // If your API doesn't have scfm, default to 0
      mudCondIn: _toDouble(json['mudcondin']),
      blockPos: _toDouble(json['blockpos']),
      wob: _toDouble(json['woba']), // "woba" in JSON vs "wob" in code
      ropi: _toDouble(json['ropi']),
      bvDepth: _toDouble(json['deptbitv']),
      mudCondOut: _toDouble(json['mudcondout']),
      torque: _toDouble(json['torqa']), // "torqa" or "torqx"? Check your JSON
      rpm: _toDouble(json['rpm']),
      hkld: _toDouble(json['hklda']), // "hklda" in your sample
      logDepth: _toDouble(json['logdepth']),
      h2s_1: _toDouble(json['h2s1']),
      mudFlowOutp: _toDouble(json['mudflowoutp']),
      totSPM: _toDouble(json['totspm']),
      spPress: _toDouble(json['stppress']), // "stppress" in your sample
      mudFlowIn: _toDouble(json['mudflowin']),
      co2_1: _toDouble(json['co21']),
      gas: _toDouble(json['gas']),
      mudTempIn: _toDouble(json['mudtempin']),
      mudTempOut: _toDouble(json['mudtempout']),
      tankVolTot: _toDouble(json['tankvoltot']),
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }
}
