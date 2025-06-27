import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/api_client.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/client_id_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_registrar.g.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {

  static const _userWells = 'user_wells';
  static const _userParameters= 'user_parameters';
  static const _userParametersDepth = 'user_parameters_depth';
  static const _parameterNotificationSettings = 'parameter_notification_settings';

  static final ApiClient _apiClient = ApiClient();

  static Future<String> _getUserId() async {
    return await ClientIdService.getPersistentClientId();
  }

  static Future<void> initializeHive() async {
        final appDocumentDir = await getApplicationDocumentsDirectory();
        Hive
          ..init(appDocumentDir.path)
          ..registerAdapters();
    }

  static Future<Box<ParameterItem>> openParameterBox() async {
    return await Hive.openBox<ParameterItem>(_userParameters);
  }

  static Future<Box<ParameterItem>> openDepthParameterBox() async {
    return await Hive.openBox<ParameterItem>(_userParametersDepth);
  }

  static Future<Box<ParameterNotificationSetting>> openParameterNotificationSettings(
      {required String userId}) async {
    final userSpecificBoxName = '${_parameterNotificationSettings}_$userId';
    return Hive.openBox<ParameterNotificationSetting>(userSpecificBoxName);
  }

  static String getParameterNotificationBoxName() {
    return _parameterNotificationSettings;
  }

  static Future<Box<WellActive>> openSavedWells() {
    return Hive.openBox<WellActive>(_userWells);
  }

  static Future<void> saveSelectedWell(WellActive well) async {
    debugPrint("opening box");
    final box = await openSavedWells();
    debugPrint("done box");
    await box.put(well.isApiToken, well);
  }

  static Future<WellActive?> loadSavedWell(String token) async {
    final box = await openSavedWells();
    return box.get(token);
  }

  static String _getNotificationSettingKey(String wellApiToken, String parameterJsonKey) {
    return "${wellApiToken}_$parameterJsonKey";
  }

  static Future<void> saveNotificationSetting(ParameterNotificationSetting setting, {bool syncToServer = true}) async {
    final userId = await _getUserId();
    final box = await openParameterNotificationSettings(userId: userId);
    final key = _getNotificationSettingKey(setting.wellApiToken, setting.parameterJsonKey);

    // Save to Hive first
    await box.put(key, setting);
    if (kDebugMode) {
      print('Saved notification setting to Hive (key: $key, serverId: ${setting.serverId}, enabled: ${setting.isEnabled})');
    }

    if (!syncToServer) {
      return;
    }

    try {
      bool success = false;
      int? returnedServerId;

      if (setting.serverId == null) { // New rule, create on server
        if (kDebugMode) {
          print('Attempting to CREATE rule on server for $key. Data: well=${setting.wellApiToken}, param=${setting.parameterJsonKey}, enabled=${setting.isEnabled}');
        }
        returnedServerId = await _apiClient.createNotificationRule(
          wellApiToken: setting.wellApiToken,
          wellName: setting.wellName,
          parameterJsonKey: setting.parameterJsonKey,
          parameterName: setting.parameterName,
          thresholdValue: setting.thresholdValue,
          condition: setting.condition,
          isEnabled: setting.isEnabled,
          notes: setting.notes,
        );
        if (returnedServerId != null) {
          success = true;
          setting.serverId = returnedServerId;
          await box.put(key, setting); // Update Hive object with the new serverId
          if (kDebugMode) {
            print('Rule CREATED on server (new serverId: ${setting.serverId}), updated Hive for $key.');
          }
        } else {
          if (kDebugMode) {
            print('FAILED to create rule on server for $key. Server returned null ID.');
          }
        }
      } else { // Existing rule, update on server
        if (kDebugMode) {
          print('Attempting to UPDATE rule on server (serverId: ${setting.serverId}) for $key. Data: enabled=${setting.isEnabled}');
        }
        success = await _apiClient.updateNotificationRule(
          serverRuleId: setting.serverId!,
          wellApiToken: setting.wellApiToken,
          wellName: setting.wellName,
          parameterJsonKey: setting.parameterJsonKey,
          parameterName: setting.parameterName,
          thresholdValue: setting.thresholdValue,
          condition: setting.condition,
          isEnabled: setting.isEnabled,
          notes: setting.notes,
        );
        if (success && kDebugMode) {
          print('Rule UPDATED on server (serverId: ${setting.serverId}) for $key.');
        } else if (!success && kDebugMode) {
          print('FAILED to update rule on server (serverId: ${setting.serverId}) for $key.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing notification setting for $key to server: $e');
      }
    }
  }

  static Future<ParameterNotificationSetting?> getNotificationSetting(String wellApiToken, String parameterJsonKey) async {
    final box = await openParameterNotificationSettings(userId: await _getUserId());
    final key = _getNotificationSettingKey(wellApiToken, parameterJsonKey);
    return box.get(key);
  }

  static Future<List<ParameterNotificationSetting>> getEnabledSettingsForWell(String wellApiToken) async {
    final box = await openParameterNotificationSettings(userId: await _getUserId());
    // Since keys are composite, filter values. If many settings, consider well-specific boxes or indexing.
    return box.values.where((s) => s.wellApiToken == wellApiToken && s.isEnabled).toList();
  }

  static Future<void> deleteNotificationSetting(String wellApiToken, String parameterJsonKey, {bool syncToServer = true}) async {
    final box = await openParameterNotificationSettings(userId: await _getUserId());
    final key = _getNotificationSettingKey(wellApiToken, parameterJsonKey);

    ParameterNotificationSetting? settingToDelete = box.get(key);
    int? serverIdToDelete = settingToDelete?.serverId;

    await box.delete(key); // Delete from Hive first
    if (kDebugMode) {
      print("Deleted notification setting from Hive for key: $key (original serverId: $serverIdToDelete)");
    }

    if (!syncToServer || serverIdToDelete == null) {
      if (syncToServer && serverIdToDelete == null && kDebugMode) {
        print("Skipping server delete for $key because serverId was null (rule likely never synced or sync failed).");
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('Attempting to DELETE rule on server (serverId: $serverIdToDelete) for $key');
      }
      bool success = await _apiClient.deleteNotificationRule(serverRuleId: serverIdToDelete);
      if (success && kDebugMode) {
        print('Rule DELETED on server (serverId: $serverIdToDelete) for $key.');
      } else if (!success && kDebugMode) {
        print('FAILED to delete rule on server (serverId: $serverIdToDelete) for $key.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting notification setting for $key from server: $e');
      }
    }
  }



      static Future<void> initializeDefaultData(Box<ParameterItem> box) async {
        await box.addAll(
          [
            // Mechanical track parameters
            ParameterItem(
              name: 'BitDepth (m)',
              jsonKey: 'bitdepth',
              color: Colors.green,
              scaleStart: 0,
              scaleEnd: 5000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
              value: '0'
            ),
            ParameterItem(
              name: 'WOB (klb)',
              jsonKey: 'woba',
              color: Colors.purple,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Torque (klb.ft)',
              jsonKey: 'torqa',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'RPM',
              jsonKey: 'rpm',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 5000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),
            ParameterItem(
              name: 'Hkld (klb)',
              jsonKey: 'hklda',
              color: Colors.teal,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mechanical',
                value: '0'
            ),

            // Mud track parameters
            ParameterItem(
              name: 'MudFlowIn (gpm)',
              jsonKey: 'mudflowin',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 1000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudFlowOutp (gpm)',
              jsonKey: 'mudflowoutp',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondIn (mmho)',
              jsonKey: 'mudcondin',
              color: Colors.green,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'MudCondOut (mmho)',
              jsonKey: 'mudcondout',
              color: Colors.purple,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'SpPress (Psi)',
              jsonKey: 'totspm',
              color: Colors.orange,
                scaleStart: 0,
                scaleEnd: 1000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),
            ParameterItem(
              name: 'TankVolTot (bbl)',
              jsonKey: 'tankvoltot',
              color: Colors.brown,
                scaleStart: 0,
                scaleEnd: 2000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'mud',
                value: '0'
            ),

            // Gas track parameters
            ParameterItem(
              name: 'H2S_1 (ppm)',
                jsonKey: 'h2s1',
                scaleStart: 0,
                scaleEnd: 2000,
              color: Colors.deepOrange,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'CO2_1 (%)',
              jsonKey: 'co21',
              color: Colors.green,
                scaleStart: 0,
                scaleEnd: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),
            ParameterItem(
              name: 'Gas (%)',
              jsonKey: 'gas',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 100,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'gas',
                value: '0'
            ),

            // Temperature track parameters
            ParameterItem(
              name: 'MudTempIn (C)',
              jsonKey: 'mudtempin',
              color: Colors.blue,
                scaleStart: 0,
                scaleEnd: 400,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
            ParameterItem(
              name: 'MudTempOut (C)',
              jsonKey: 'mudtempout',
              color: Colors.red,
                scaleStart: 0,
                scaleEnd: 400,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              trackType: 'temperature',
                value: '0'
            ),
          ]
        );
      }

      static Future<void> initializeDefaultDepthData(Box<ParameterItem> box) async {
        await box.addAll([

          ParameterItem(
            name: 'Measured Depth (m)',
            jsonKey: 'md', // Key from DepthDrillingData
            color: Colors.blue,
            scaleStart: 0,
            scaleEnd: 6000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            trackType: 'Primary', // Example track type for depth
            value: '0',
            apiName: 'Measured Depth', // Optional: API name if different
          ),

          ParameterItem(
            name: 'TVD (m)',
            jsonKey: 'tvd', // Key from DepthDrillingData
            color: Colors.green,
            scaleStart: 0,
            scaleEnd: 6000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            trackType: 'Primary',
            value: '0',
            apiName: 'True Vertical Depth',
          ),

          ParameterItem(
            name: 'ROP Inst (m/hr)',
            jsonKey: 'ropi', // Key from DepthDrillingData
            color: Colors.orange,
            scaleStart: 0,
            scaleEnd: 200,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            trackType: 'Performance',
            value: '0',
            apiName: 'Rate of Penetration Inst.',
          ),

          ParameterItem(
            name: 'WOB Avg (klbf)',
            jsonKey: 'woba', // Key from DepthDrillingData
            color: Colors.purple,
            scaleStart: 0,
            scaleEnd: 100,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            trackType: 'Mechanical',
            value: '0',
            apiName: 'Weight on Bit Avg.',
          ),

          ParameterItem(
            name: 'ECD (sg)',
            jsonKey: 'ecda', // Key from DepthDrillingData
            color: Colors.teal,
            scaleStart: 0,
            scaleEnd: 3,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            trackType: 'Mud',
            value: '0',
            apiName: 'Equivalent Circulating Density',
          ),
        ]);
      }
}