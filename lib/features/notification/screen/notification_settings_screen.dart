// lib/features/notifications/ui/notification_settings_screen.dart
import 'dart:async'; // Import for StreamSubscription
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/features/notification/components/dialog/edit_notification_dialog.dart';

import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final WellActive wellActive;

  const NotificationSettingsScreen({
    Key? key,
    required this.wellActive,
  }) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  Box<ParameterNotificationSetting>? _settingsBox;
  StreamSubscription<BoxEvent>? _boxSubscription;
  List<ParameterNotificationSetting> _wellSettings = []; // Local list to hold filtered settings

  @override
  void initState() {
    super.initState();
    _openBoxAndListen();
  }

  Future<void> _openBoxAndListen() async {
    // Ensure the box is open
    if (!Hive.isBoxOpen(HiveService.getParameterNotificationBoxName())) {
      _settingsBox = await HiveService.openParameterNotificationSettings();
    } else {
      _settingsBox = Hive.box<ParameterNotificationSetting>(
          HiveService.getParameterNotificationBoxName());
    }

    if (mounted && _settingsBox != null) {
      _loadSettings(); // Initial load
      _boxSubscription = _settingsBox!.watch().listen((event) {
        // When the box changes (put, delete), reload settings for this well
        print("Notification settings box event: key=${event.key}, value=${event.value}, deleted=${event.deleted}");
        _loadSettings();
      });
    }
    // No need for setState here as _loadSettings will call it if needed,
    // or the initial build will happen once _settingsBox is not null.
  }

  void _loadSettings() {
    if (_settingsBox == null || !mounted) return;
    final newSettings = _settingsBox!.values
        .where((s) => s.wellApiToken == widget.wellActive.isApiToken)
        .toList();
    // Sort for consistent order, e.g., by parameter name
    newSettings.sort((a, b) => a.parameterName.compareTo(b.parameterName));

    setState(() {
      _wellSettings = newSettings;
    });
  }


  void _showEditNotificationDialog(
      ParameterNotificationSetting settingToEdit) {
    showDialog(
      context: context,
      builder: (_) => EditNotificationSettingDialog(
        setting: settingToEdit,
        // No onSave/onDelete callbacks needed here as the box listener will handle UI updates
      ),
    );
  }

  @override
  void dispose() {
    _boxSubscription?.cancel(); // Important: Cancel the subscription
    // Hive boxes are typically kept open for the app's lifetime,
    // but if you were to close it: await _settingsBox?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsBox == null) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // The UI now directly uses the _wellSettings list,
    // which is updated by _loadSettings via setState when the box stream emits an event.

    if (_wellSettings.isEmpty) {
      return Scaffold( // Added Scaffold here for consistent structure
        appBar: null,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 60, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No notification alerts configured for ${widget.wellActive.wellName}.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  "You can set up alerts by tapping on a parameter in the Home screen's sensor list.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: null,
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _wellSettings.length,
        itemBuilder: (context, index) {
          final setting = _wellSettings[index];
          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              title: Text(
                setting.parameterName,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: CColors.primaryColor),
              ),
              subtitle: Text(
                "Alert if value is ${setting.condition} ${setting.thresholdValue.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.grey[700]),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: setting.isEnabled,
                    onChanged: (bool value) async {
                      final updatedSetting = setting.copyWith(isEnabled: value);
                      await HiveService.saveNotificationSetting(updatedSetting);

                    },
                    activeColor: CColors.primaryColor,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[300],
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: CColors.primaryColor.withOpacity(0.8)),
                    tooltip: "Edit Alert",
                    onPressed: () => _showEditNotificationDialog(setting),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
