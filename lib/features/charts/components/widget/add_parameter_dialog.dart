import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import '../../../../data/services/pdu_api/model/well_active.dart';
import '../../../../data/services/pdu_api/parameter_service.dart';
import '../../../../utils/constants/colors.dart';
import '../../model/parameter_item.dart';

class AddParameterDialog extends StatefulWidget {
  final WellActive wellActive;
  final Box<ParameterItem> parameterBox;
  final DrillingController controller;

  const AddParameterDialog({
    Key? key,
    required this.wellActive,
    required this.parameterBox,
    required this.controller,
  }) : super(key: key);

  @override
  _AddParameterDialogState createState() => _AddParameterDialogState();
}

class _AddParameterDialogState extends State<AddParameterDialog> {
  List<String> _available = [];
  String? _picked;
  final List<String> _trackTypes = ['mechanical','mud','gas','temperature'];
  String? _trackType;
  final TextEditingController _hexCtrl = TextEditingController(text: '#4700DE');
  Color _color = const Color(0xFF4700DE);
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl   = TextEditingController();
  final List<String> _units = ['m','klb','gpm','mmho','Psi','%','°C','bbl'];
  String? _unit;

  @override
  void initState() {
    super.initState();
    _loadAvailable();
    _hexCtrl.addListener(_onHexChanged);
  }

  Future<void> _loadAvailable() async {

    if (widget.controller.fullData.isNotEmpty) {
      final firstRaw = widget.controller.fullData.first.rawData;
      _available = firstRaw.keys
      // you can filter to numeric values only if needed:
          .where((k) => firstRaw[k] is num || double.tryParse(firstRaw[k].toString()) != null)
          .toList();
    }
    // 2) Otherwise fall back to your API-driven list:
    else {
      _available = await ParameterService.fetchAvailableParameters(
        wellActive: widget.wellActive,
      );
    }

    setState(() {});
  }

  void _onHexChanged() {
    final hex = _hexCtrl.text.replaceAll('#','');
    if (hex.length == 6) {
      setState(() {
        _color = Color(int.parse('0xFF$hex'));
      });
    }
  }

  void _save() {
    final name    = _picked!;        // use jsonKey also as display name
    final jsonKey = _picked!;
    final now     = DateTime.now();
    final start   = int.tryParse(_startCtrl.text) ?? 0;
    final end     = int.tryParse(_endCtrl.text)   ?? 0;

    // Put into Hive with jsonKey, name, trackType, etc.
    widget.parameterBox.put(
      jsonKey,
      ParameterItem(
        name:       name,
        jsonKey:    jsonKey,
        unit:       _unit,
        color:      _color,
        scaleStart: start,
        scaleEnd:   end,
        createdAt:  now,
        updatedAt:  now,
        trackType:  _trackType!,
        value:      '0',
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _hexCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
          'Custom Parameter',
        style: TextStyle(color: CColors.primaryColor),
      ),
      content: _available.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─ Track Type ───────────────────────────
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Track Type'),
            items: _trackTypes
                .map((t) => DropdownMenuItem(
              value: t,
              child: Text(
                t.isEmpty ? t : t[0].toUpperCase() + t.substring(1),
              ),
            ))
                .toList(),
            value: _trackType,
            onChanged: (v) => setState(() => _trackType = v),
          ),
          const SizedBox(height: 12),

          // ─ Parameter Key ────────────────────────
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Parameter'),
            items: _available
                .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                .toList(),
            value: _picked,
            onChanged: (v) => setState(() => _picked = v),
          ),
          const SizedBox(height: 12),

          // ─ Color Picker ─────────────────────────
          Row(children: [
            Container(width:24, height:24, color:_color),
            const SizedBox(width:8),
            Expanded(
              child: TextFormField(
                controller: _hexCtrl,
                decoration: const InputDecoration(labelText: 'Color'),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ─ Scale Range ──────────────────────────
          Row(children: [
            Expanded(
              child: TextFormField(
                controller: _startCtrl,
                decoration: const InputDecoration(labelText: 'Scale Start'),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _endCtrl,
                decoration: const InputDecoration(labelText: 'Scale End'),
                keyboardType: TextInputType.number,
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // ─ Unit Selector ────────────────────────
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Unit'),
            items: _units
                .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                .toList(),
            value: _unit,
            onChanged: (v) => setState(() => _unit = v),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: (_picked != null && _trackType != null && _unit != null)
              ? _save
              : null,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}