class DrillingData {
  final DateTime dateTime;

  final double bitDepth;      // (m)
  final double scfm;
  final double mudCondIn;     // (mmho)
  final double blockPos;      // (m)
  final double wob;           // (klb)
  final double ropi;          // (m/hr)
  final double bvDepth;       // (m)
  final double mudCondOut;    // (mmho)
  final double torque;        // (klb.ft)
  final double rpm;
  final double hkld;          // (klb)
  final double logDepth;      // (m)
  final double h2s_1;         // (ppm)
  final double mudFlowOutp;
  final double totSPM;
  final double spPress;       // (Psi)
  final double mudFlowIn;     // (gpm)
  final double co2_1;         // (%)
  final double gas;           // (%)
  final double mudTempIn;     // (C)
  final double mudTempOut;    // (C)
  final double tankVolTot;    // (bbl)

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
}