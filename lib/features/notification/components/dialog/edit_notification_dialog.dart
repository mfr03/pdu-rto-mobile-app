// lib/features/notifications/ui/edit_notification_setting_dialog.dart
import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';

class EditNotificationSettingDialog extends StatefulWidget {
  final ParameterNotificationSetting setting;
  // final VoidCallback onSave; // Not strictly needed if Hive listener updates UI
  // final VoidCallback onDelete; // Not strictly needed

  const EditNotificationSettingDialog({
    Key? key,
    required this.setting,
    // required this.onSave,
    // required this.onDelete,
  }) : super(key: key);

  @override
  _EditNotificationSettingDialogState createState() =>
      _EditNotificationSettingDialogState();
}

class _EditNotificationSettingDialogState
    extends State<EditNotificationSettingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _thresholdController;
  late String _selectedCondition;
  // isEnabled is managed by the Switch on the list screen directly

  @override
  void initState() {
    super.initState();
    _thresholdController =
        TextEditingController(text: widget.setting.thresholdValue.toString());
    _selectedCondition = widget.setting.condition;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final thresholdValue = double.tryParse(_thresholdController.text);
      if (thresholdValue == null) return;

      // Use copyWith on the original setting to preserve all fields not being edited
      final updatedSetting = widget.setting.copyWith(
        thresholdValue: thresholdValue,
        condition: _selectedCondition,
        // If isEnabled is part of this dialog, set it here too.
        // serverId is already part of widget.setting and will be preserved by copyWith
      );

      // Call HiveService.saveNotificationSetting for Hive update and server sync
      await HiveService.saveNotificationSetting(updatedSetting);
      if(mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.setting.parameterName} alert updated & syncing!')),
        );
      }
    }
  }

  Future<void> _deleteSetting() async {
    // Show confirmation dialog before deleting
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Alert?'),
          content: Text('Are you sure you want to delete the alert for ${widget.setting.parameterName}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await HiveService.deleteNotificationSetting( // This is already correct
        widget.setting.wellApiToken,
        widget.setting.parameterJsonKey,
      );
      if(mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.setting.parameterName} alert deleted & syncing!')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Alert: ${widget.setting.parameterName}"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _thresholdController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Threshold Value", // Unit can be inferred from param name
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
              // Switch for isEnabled is on the main list screen for quick toggling
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text("Delete", style: TextStyle(color: Colors.red)),
          onPressed: _deleteSetting,
        ),
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text("Save Changes"),
          onPressed: _saveChanges,
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
