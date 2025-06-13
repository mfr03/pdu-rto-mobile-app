import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';

class SetStartDepthDialog extends StatefulWidget {
  final String wellId;
  const SetStartDepthDialog({super.key, required this.wellId});

  @override
  State<SetStartDepthDialog> createState() => _SetStartDepthDialogState();
}

class _SetStartDepthDialogState extends State<SetStartDepthDialog> {
  final _textController = TextEditingController();
  bool _saveForNextSession = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialValue();
  }

  Future<void> _loadInitialValue() async {
    final config = await ChartDepthService.loadConfig(widget.wellId);
    if (mounted) {
      setState(() {
        _textController.text = config.start.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final depth = double.tryParse(_textController.text);
    if (depth == null || depth < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid depth.")),
      );
      return;
    }

    if (_saveForNextSession) {
      await ChartSettingsService.saveDefaultStartDepth(depth);
    }

    // Also update the current well's configuration
    final currentConfig = await ChartDepthService.loadConfig(widget.wellId);
    await ChartDepthService.saveRange(widget.wellId, depth, currentConfig.end);

    if (mounted) {
      Navigator.of(context).pop(depth);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Start Depth'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _textController,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Default starting depth',
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