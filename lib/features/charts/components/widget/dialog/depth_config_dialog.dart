import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/model/depth_config_result.dart';

class DepthConfigDialog extends StatefulWidget {
  final double initialStart;
  final double initialEnd;

  const DepthConfigDialog({
    Key? key,
    required this.initialStart,
    required this.initialEnd,
  }) : super(key: key);

  @override
  _DepthConfigDialogState createState() => _DepthConfigDialogState();
}

class _DepthConfigDialogState extends State<DepthConfigDialog> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  bool _doNotShow = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.initialStart.toString());
    _endCtrl   = TextEditingController(text: widget.initialEnd.toString());
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configure Depth Range'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _startCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Depth Start'),
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? 'Enter a valid number'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _endCtrl,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Depth End'),
              validator: (v) => (v == null || double.tryParse(v) == null)
                  ? 'Enter a valid number'
                  : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final s = double.parse(_startCtrl.text);
              final e = double.parse(_endCtrl.text);
              Navigator.of(context).pop(
                DepthConfigResult(
                  start: s,
                  end: e,
                  doNotShowAgain: _doNotShow,
                ),
              );
            }
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
