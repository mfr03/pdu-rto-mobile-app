import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChartDepthService {

  static const _prefix = 'depth_config_';

  static String _keyStart(String wellId)    => '$_prefix${wellId}_start';
  static String _keyEnd(String wellId)      => '$_prefix${wellId}_end';
  static String _keyDisabled(String wellId) => '$_prefix${wellId}_disabled';


  static Future<SharedPreferences> get _prefs async =>
      _sharedPrefs ??= await SharedPreferences.getInstance();

  static SharedPreferences? _sharedPrefs;

  static Future<DepthConfig> loadConfig(String token) async {
    final p = await _prefs;
    final s = p.getDouble(_keyStart(token))    ?? 0.0;
    final e = p.getDouble(_keyEnd(token))      ?? 100.0;
    final d = p.getBool(_keyDisabled(token))   ?? false;
    return DepthConfig(start: s, end: e, disabled: d);
  }

  static Future<void> saveRange(
      String token,
      double start,
      double end
      ) async {
    final p = await _prefs;
    await p.setDouble(_keyStart(token), start);
    await p.setDouble(_keyEnd(token), end);
  }

  static Future<void> disableDialog(String wellId) async {
    final p = await _prefs;
    await p.setBool(_keyDisabled(wellId), true);
  }



}