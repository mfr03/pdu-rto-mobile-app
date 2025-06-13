import 'package:shared_preferences/shared_preferences.dart';

/// A service to manage global chart settings that are not specific to a single well.
class ChartSettingsService {
  static const _keyTraversalMinutes = 'chart_traversal_minutes';
  static const _keyDefaultStartDepth = 'chart_default_start_depth';

  static SharedPreferences? _sharedPrefs;

  static Future<SharedPreferences> get _prefs async =>
      _sharedPrefs ??= await SharedPreferences.getInstance();

  /// Saves the time unit (in minutes) for chart traversal.
  static Future<void> saveTraversalUnit(int minutes) async {
    final p = await _prefs;
    await p.setInt(_keyTraversalMinutes, minutes);
  }

  /// Loads the saved time unit for chart traversal.
  ///
  /// Defaults to 5 minutes if no value is saved.
  static Future<int> loadTraversalUnit() async {
    final p = await _prefs;
    return p.getInt(_keyTraversalMinutes) ?? 5; // Default 5 minutes
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