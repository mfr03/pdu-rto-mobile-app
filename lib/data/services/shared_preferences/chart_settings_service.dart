import 'package:shared_preferences/shared_preferences.dart';

/// A service to manage global chart settings that are not specific to a single well.
class ChartSettingsService {
  static const String _timeTraversalUnitKey = 'time_traversal_unit';
  static const String _depthTraversalUnitKey = 'depth_traversal_unit';
  static const _keyDefaultStartDepth = 'chart_default_start_depth';

  static SharedPreferences? _sharedPrefs;

  static Future<SharedPreferences> get _prefs async =>
      _sharedPrefs ??= await SharedPreferences.getInstance();

  // --- ALTERATION: Renamed for clarity ---
  static Future<void> saveTimeTraversalUnit(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timeTraversalUnitKey, minutes);
  }

  // --- ALTERATION: Renamed for clarity ---
  static Future<int> loadTimeTraversalUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timeTraversalUnitKey) ?? 15; // Default to 15 mins
  }

  // --- NEW: Methods for depth traversal unit ---
  static Future<void> saveDepthTraversalUnit(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_depthTraversalUnitKey, minutes);
  }

  static Future<int> loadDepthTraversalUnit() async {
    final prefs = await SharedPreferences.getInstance();
    // A different default might be suitable for depth chart's time-based traversal
    return prefs.getInt(_depthTraversalUnitKey) ?? 30; // Default to 30 mins
  }

  /// Saves the default starting depth for the depth chart.
  static Future<void> saveDefaultStartDepth(double depth) async {
    final p = await _prefs;
    await p.setDouble(_keyDefaultStartDepth, depth);
  }

  /// Loads the default starting depth for the depth chart.
  ///
  /// Defaults to 10.0 if no value is saved.
  static Future<double> loadDefaultStartDepth() async {
    final p = await _prefs;
    return p.getDouble(_keyDefaultStartDepth) ?? 10.0; // Default 10.0
  }
}