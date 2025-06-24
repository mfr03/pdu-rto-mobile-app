import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_unit.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_variable.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import '../../../../../data/services/pdu_api/model/well_active.dart';
import '../../../../../utils/constants/colors.dart';
import '../../../model/parameter_item.dart';

class AddParameterDialog extends StatefulWidget {
  final WellActive wellActive;
  final Box<ParameterItem> parameterBox;
  final DrillingController controller;
  final String? initialTrackType;

  const AddParameterDialog({
    Key? key,
    required this.wellActive,
    required this.parameterBox,
    required this.controller,
    this.initialTrackType,
  }) : super(key: key);

  @override
  _AddParameterDialogState createState() => _AddParameterDialogState();
}

class _AddParameterDialogState extends State<AddParameterDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _trackType;
  String? _displayName;
  String? _unit;
  Color _color = Colors.blue;

  List<Variable> _availableVars = [];
  Variable?     _selectedVar;
  List<Unit> _availableUnits = [];
  Unit?      _selectedUnit;

  bool          _isLoading   = true;
  String?       _errorMsg;

  final _startCtrl = TextEditingController();
  final _endCtrl   = TextEditingController();


  @override
  void initState() {
    super.initState();
    _trackType = widget.initialTrackType;

    _loadVariables();
    
    
  }

  List<String> get _trackTypes {
    if (widget.parameterBox == null) return [];
    return widget.parameterBox
        .values
        .map((p) => p.trackType)
        .toSet()
        .toList();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _formKey.currentState?.validate() == true;

  void _save() {
    final param = ParameterItem(
      name:        _displayName!,
      jsonKey: _selectedVar!.field,
      unit:        _unit,
      color:       _color,
      scaleStart:  int.parse(_startCtrl.text),
      scaleEnd:    int.parse(_endCtrl.text),
      createdAt:   DateTime.now(),
      updatedAt:   DateTime.now(),
      trackType:   _trackType!,
      apiName: _selectedVar!.name,
      value:       '0',
    );
    widget.parameterBox.put(param.jsonKey, param);
    Navigator.of(context).pop();
  }

  Future<void> _pickColor() async {
    Color picked = _color;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _color,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
    setState(() => _color = picked);
  }

  Future<void> _loadVariables() async {
    final PduApi api = Get.find<PduApi>();
    try {
      final vars = await api.fetchVariables();
      final units = await api.fetchUnits();

      setState(() {
        _availableVars = vars;
        _availableUnits = units;
        _isLoading     = false;
      });
    } catch (e) {
      setState(() {
        debugPrint(e.toString());
        _errorMsg   = 'Failed to load variables';
        _isLoading  = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMsg != null) {
      return Center(child: Text(_errorMsg!));
    }

    return AlertDialog(
      title: Text(
          'Add Parameter',
        style: TextStyle(
            color: CColors.primaryColor
        ),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.7
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Track Type ─────────────────────────
                if (widget.initialTrackType != null)
                  TextFormField(
                    initialValue: widget.initialTrackType,
                    decoration: const InputDecoration(
                        labelText: 'Track Type',
                      border: OutlineInputBorder()
                    ),
                    enabled: false,
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Track Type',
                        border: OutlineInputBorder()),
                    items: _trackTypes.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1)),
                    )).toList(),
                    value: _trackType,
                    validator: (_) => _trackType == null ? 'Required' : null,
                    onChanged: (v) => setState(() => _trackType = v),
                  ),

                const SizedBox(height: 12),

                // ── Display Name ────────────────────────
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Name',
                      border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (v) => _displayName = v.trim(),
                ),

                const SizedBox(height: 12),

                // ── Variable ────────────────────────────

                DropdownButtonFormField<Variable>(
                  decoration: const InputDecoration(
                    labelText: 'Variable',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableVars.map((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Text(v.name),
                    );
                  }).toList(),
                  value: _selectedVar,
                  validator: (_) => _selectedVar == null ? 'Required' : null,
                  onChanged: (v) => setState(() => _selectedVar = v),
                ),

                const SizedBox(height: 12),

                // ── Unit ─────────────────────────────────

                DropdownButtonFormField<Unit>(
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: _availableUnits.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text('${u.unitabv} (${u.unitmne})'),
                    );
                  }).toList(),
                  value: _selectedUnit,
                  validator: (_) => _selectedUnit == null ? 'Required' : null,
                  onChanged: (u) => setState(() {
                    _selectedUnit = u;
                    _unit    = u?.unitabv; // use abbreviation in your model
                  }),
                ),




                const SizedBox(height: 12),

                // ── Scale Start / End ────────────────────
                TextFormField(
                  controller: _startCtrl,
                  decoration: const InputDecoration(labelText: 'Scale Start',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    return int.tryParse(v) == null ? 'Must be an integer' : null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _endCtrl,
                  decoration: const InputDecoration(labelText: 'Scale End',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    return int.tryParse(v) == null ? 'Must be an integer' : null;
                  },
                ),

                const SizedBox(height: 8),

                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: const Text('Parameter Color'),
                  trailing: GestureDetector(
                    onTap: _pickColor,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black38),
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}