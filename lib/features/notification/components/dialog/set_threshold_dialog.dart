// lib/features/notifications/ui/set_threshold_dialog.dart
import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';

class SetThresholdDialog extends StatefulWidget {
  final ParameterItem parameterItem;
  final String wellApiToken;

  const SetThresholdDialog({
    Key? key,
    required this.parameterItem,
    required this.wellApiToken,
  }) : super(key: key);

  @override
  _SetThresholdDialogState createState() => _SetThresholdDialogState();
}

class _SetThresholdDialogState extends State<SetThresholdDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _thresholdController;
  String _selectedCondition = "above"; // "above", "below"
  bool _isEnabled = true;
  ParameterNotificationSetting? _existingSetting;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController();
    _loadExistingSetting();
  }

  Future<void> _loadExistingSetting() async {
    final setting = await HiveService.getNotificationSetting(
      widget.wellApiToken,
      widget.parameterItem.jsonKey,
    );
    if (setting != null) {
      _existingSetting = setting;
      _thresholdController.text = setting.thresholdValue.toString();
      _selectedCondition = setting.condition;
      _isEnabled = setting.isEnabled;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSetting() async {
    if (_formKey.currentState!.validate()) {
      final thresholdValue = double.tryParse(_thresholdController.text);
      if (thresholdValue == null) {
        // Show error, should be caught by validator
        return;
      }

      final newSetting = ParameterNotificationSetting(
        wellApiToken: widget.wellApiToken,
        parameterJsonKey: widget.parameterItem.jsonKey,
        parameterName: widget.parameterItem.name, // Store display name
        thresholdValue: thresholdValue,
        condition: _selectedCondition,
        isEnabled: _isEnabled,
        lastNotificationTime: _existingSetting?.lastNotificationTime, // Preserve last notification time unless explicitly reset
      );

      await HiveService.saveNotificationSetting(newSetting);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.parameterItem.name} notification saved!')),
      );
    }
  }

  Future<void> _deleteSetting() async {
    if (_existingSetting != null) {
      await HiveService.deleteNotificationSetting(
          widget.wellApiToken, widget.parameterItem.jsonKey);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.parameterItem.name} notification deleted!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(child: Center(child: CircularProgressIndicator()));
    }
    return AlertDialog(
        title: Text("Set Alert: ${widget.parameterItem.name}"),
    content: Form(
    key: _formKey,
    child: SingleChildScrollView(
    child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
    TextFormField(
    controller: _thresholdController,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
    labelText: "Threshold Value (${widget.parameterItem.unit ?? ''})",
    border: OutlineInputBorder(),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return "Please enter a threshold";
    }
    if (double.tryParse(value) == null) {
    return "Please enter a valid number";
    }
    return null;
    },
    ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: "Condition",
          border: OutlineInputBorder(),
        ),
        value: _selectedCondition,
        items: [
          DropdownMenuItem(value: "above", child: Text("Value is Above")),
          DropdownMenuItem(value: "below", child: Text("Value is Below")),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedCondition = value);
          }
        },
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: const Text("Enable Notification"),
        value: _isEnabled,
        onChanged: (value) {
          setState(() => _isEnabled = value);
        },
        activeColor: CColors.primaryColor,
      ),
    ],
    ),
    ),
    ),
      actions: <Widget>[
        if (_existingSetting != null)
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: _deleteSetting,
          ),
        TextButton(
          child: const Text("Cancel"),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text("Save"),
          onPressed: _saveSetting,
          style: ElevatedButton.styleFrom(backgroundColor: CColors.primaryColor, foregroundColor: Colors.white),
        ),
      ],
    );
  }
  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }
}