import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
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

  // Form state variables
  String? _trackType;
  String? _displayName;
  String? _unit;
  Color _color = Colors.blue;
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();

  // State for fetching, filtering, and selection
  bool _isLoading = true;
  String? _errorMsg;
  List<DrillVariable> _allVariables = [];
  List<DrillVariable> _filteredVariables = [];
  DrillVariable? _selectedVar;
  bool _isTimeSelected = false;
  bool _isDepthSelected = false;

  // State for the units dropdown
  List<Unit> _availableUnits = [];
  Unit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    _trackType = widget.initialTrackType;
    _loadVariables();
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVariables() async {
    final PduApi api = Get.find<PduApi>();
    try {
      // Fetch both sets of data concurrently for better performance.
      final results = await Future.wait([
        api.fetchAvailableVariables(),
        api.fetchUnits(), // Re-add the call to fetch units
      ]);

      // Ensure the widget is still mounted before setting state.
      if (mounted) {
        setState(() {
          _allVariables = results[0] as List<DrillVariable>;
          _availableUnits = results[1] as List<Unit>; // Populate the units list
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          debugPrint(e.toString());
          _errorMsg = 'Failed to load variables or units';
          _isLoading = false;
        });
      }
    }
  }

  void _filterVariables() {
    setState(() {
      _filteredVariables = _allVariables.where((variable) {
        if (_isTimeSelected && variable.kdRecord == '01') return true;
        if (_isDepthSelected && variable.kdRecord == '02') return true;
        return false;
      }).toList();
      // Reset selection if it's no longer in the filtered list
      if (_selectedVar != null && !_filteredVariables.contains(_selectedVar)) {
        _selectedVar = null;
      }
    });
  }

  List<String> get _trackTypes {
    return widget.parameterBox.values.map((p) => p.trackType).toSet().toList();
  }

  bool get _canSave =>
      _formKey.currentState?.validate() == true &&
          _selectedVar != null &&
          _selectedUnit != null;

  void _save() {
    if (!_canSave) return;
    final param = ParameterItem(
      name: _displayName!,
      jsonKey: _selectedVar!.field,
      unit: _unit,
      color: _color,
      scaleStart: int.parse(_startCtrl.text),
      scaleEnd: int.parse(_endCtrl.text),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      trackType: _trackType!,
      apiName: _selectedVar!.name,
      value: '0',
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
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK')),
        ],
      ),
    );
    setState(() => _color = picked);
  }

  Widget _buildFilterCheckboxes() {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withAlpha(200),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text("Filter:", style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Checkbox(
              value: _isTimeSelected,
              onChanged: (value) {
                setState(() => _isTimeSelected = value!);
                _filterVariables();
              },
            ),
            const Text("Time"),
            Checkbox(
              value: _isDepthSelected,
              onChanged: (value) {
                setState(() => _isDepthSelected = value!);
                _filterVariables();
              },
            ),
            const Text("Depth"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Loading..."),
              ],
            ),
          ));
    }
    if (_errorMsg != null) {
      return AlertDialog(
        title: const Text('Error'),
        content: Text(_errorMsg!),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      );
    }

    final bool isFilterSelected = _isTimeSelected || _isDepthSelected;

    return AlertDialog(
      title: const Text(
        'Add Parameter',
        style: TextStyle(color: CColors.primaryColor),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.initialTrackType != null)
                  TextFormField(
                    initialValue: widget.initialTrackType,
                    decoration: const InputDecoration(
                        labelText: 'Track Type', border: OutlineInputBorder()),
                    enabled: false,
                  )
                else
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'Track Type', border: OutlineInputBorder()),
                    items: _trackTypes
                        .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t[0].toUpperCase() + t.substring(1)),
                    ))
                        .toList(),
                    value: _trackType,
                    validator: (_) => _trackType == null ? 'Required' : null,
                    onChanged: (v) => setState(() => _trackType = v),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Display Name', border: OutlineInputBorder()),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                  onChanged: (v) => _displayName = v.trim(),
                ),
                const SizedBox(height: 16),
                _buildFilterCheckboxes(),
                const SizedBox(height: 12),
                IgnorePointer(
                  ignoring: !isFilterSelected,
                  child: Opacity(
                    opacity: isFilterSelected ? 1.0 : 0.5,
                    child: DropdownButtonFormField<DrillVariable>(
                      decoration: InputDecoration(
                        labelText: 'Variable',
                        border: const OutlineInputBorder(),
                        hintText: !isFilterSelected ? 'Select a filter first' : null,
                      ),
                      isExpanded: true,
                      items: _filteredVariables.map((v) {
                        return DropdownMenuItem(
                          value: v,
                          child: Text(v.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      value: _selectedVar,
                      validator: (_) => _selectedVar == null ? 'Required' : null,
                      onChanged: (v) => setState(() => _selectedVar = v),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
                    _unit = u?.unitabv;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Scale Start', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    return int.tryParse(v) == null ? 'Must be an integer' : null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _endCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Scale End', border: OutlineInputBorder()),
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
        ElevatedButton(
          onPressed: _canSave ? _save : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}