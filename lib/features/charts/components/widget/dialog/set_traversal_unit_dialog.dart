import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';

class SetTraversalUnitDialog extends StatefulWidget {
  // --- NEW: Add a 'mode' to distinguish between time and depth ---
  final String mode;
  final int currentValue;

  const SetTraversalUnitDialog({
    super.key,
    required this.mode,
    required this.currentValue,
  });

  @override
  State<SetTraversalUnitDialog> createState() => _SetTraversalUnitDialogState();
}

class _SetTraversalUnitDialogState extends State<SetTraversalUnitDialog> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  // --- NEW: A helper to handle saving based on the mode ---
  Future<void> _onSave() async {
    if (widget.mode == 'time') {
      await ChartSettingsService.saveTimeTraversalUnit(_selectedValue);
    } else { // mode == 'depth'
      await ChartSettingsService.saveDepthTraversalUnit(_selectedValue);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Traversal Unit (Minutes)'),
      content: DropdownButton<int>(
        value: _selectedValue,
        items: [960, 480, 240, 120, 60, 30, 15, 5]
            .map((t) => DropdownMenuItem(value: t, child: Text('$t minutes')))
            .toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedValue = val);
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: CColors.primaryColor)),
        ),
        ElevatedButton(
          onPressed: _onSave, // Call the new save helper
          child: const Text('Save'),
        ),
      ],
    );
  }
}