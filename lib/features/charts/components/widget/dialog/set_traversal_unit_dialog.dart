import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';

class SetTraversalUnitDialog extends StatefulWidget {
  const SetTraversalUnitDialog({super.key});

  @override
  State<SetTraversalUnitDialog> createState() => _SetTraversalUnitDialogState();
}

class _SetTraversalUnitDialogState extends State<SetTraversalUnitDialog> {
  final _textController = TextEditingController();
  bool _saveForNextSession = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final currentUnit = await ChartSettingsService.loadTraversalUnit();
    if (mounted) {
      setState(() {
        _textController.text = currentUnit.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _apply() {
    final minutes = int.tryParse(_textController.text);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number of minutes.")),
      );
      return;
    }
    if (_saveForNextSession) {
      ChartSettingsService.saveTraversalUnit(minutes);
    }
    Navigator.of(context).pop(minutes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Traversal Unit'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _textController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes to advance or go back',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Save for next session'),
            value: _saveForNextSession,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _saveForNextSession = value;
                });
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _apply,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}