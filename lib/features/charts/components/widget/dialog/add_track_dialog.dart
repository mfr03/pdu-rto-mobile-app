import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/common/components/circle.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_unit.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_variable.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import '../../../../../data/services/pdu_api/model/well_active.dart';
import '../../../controller/chart_drilling_controller.dart';
import '../../../model/parameter_item.dart';


class AddTrackDialog extends StatefulWidget {
  final Box<ParameterItem> parameterBox;
  final WellActive wellActive;

  const AddTrackDialog({
    Key? key,
    required this.parameterBox,
    required this.wellActive,
  }) : super(key: key);

  @override
  _AddTrackDialogState createState() => _AddTrackDialogState();
}

class _AddTrackDialogState extends State<AddTrackDialog> {
  // Step 0 = picking track name + viewing params, Step 1 = filling new parameter
  int _step = 0;

  // Track form
  final TextEditingController _trackNameCtrl = TextEditingController();

  // Param form (only used in step 1)
  String? _paramName, _paramJsonKey, _paramUnit;
  Color _paramColor = Colors.blue;
  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl   = TextEditingController();


  List<Variable> _availableVars = [];
  Variable?     _selectedVar;
  List<Unit> _availableUnits = [];
  Unit?      _selectedUnit;
  bool          _isLoading   = true;
  String?       _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadVariables();
  }

  @override
  void dispose() {
    _trackNameCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  // Called when “Save Parameter” is tapped in step 1
  void _saveParameter() {
    final track = _trackNameCtrl.text.trim();
    if (track.isEmpty) return;

    final p = ParameterItem(
      name:       _paramName!,
      unit:       _paramUnit,
      color:      _paramColor,
      scaleStart: int.parse(_startCtrl.text),
      scaleEnd:   int.parse(_endCtrl.text),
      createdAt:  DateTime.now(),
      updatedAt:  DateTime.now(),
      trackType:  track,
      jsonKey:   _selectedVar!.field,
      apiName: _selectedVar!.name,
      value:      '0',
    );
    widget.parameterBox.put(p.jsonKey, p);

    // reset param fields and go back to track list
    _paramName = _paramJsonKey = _paramUnit = null;
    _selectedVar = null;
    _paramColor = Colors.blue;
    _startCtrl.clear();
    _endCtrl.clear();
    setState(() => _step = 0);
  }


  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height * 0.55;

    return AlertDialog(
      title: Text(_step == 0 ? 'Add New Track' : 'Add Parameter'),
      content: SizedBox(
        // FIXED height = 60% of screen
        height: maxH,
        width: double.maxFinite,
        child: _step == 0
            ? _buildTrackStep()
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _buildParamStep(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        if (_step == 0)
          TextButton(
            onPressed: (_trackNameCtrl.text.trim().isNotEmpty &&
                widget.parameterBox.values.any((p) => p.trackType == _trackNameCtrl.text.trim()))
                ? () => Navigator.pop(context)
                : null,
            child: const Text('Save'),
          )
        else
          TextButton(
            onPressed: (_paramName != null &&
                _selectedVar?.field != null &&
                _paramUnit != null &&
                _startCtrl.text.isNotEmpty &&
                _endCtrl.text.isNotEmpty)
                ? _saveParameter
                : null,
            child: const Text('Save'),
          ),
      ],
    );
  }

  Widget _buildTrackStep() {
    final track = _trackNameCtrl.text.trim();
    final params = track.isEmpty
        ? <ParameterItem>[]
        : widget.parameterBox.values.where((p) => p.trackType == track).toList();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        TextFormField(
          controller: _trackNameCtrl,
          decoration: const InputDecoration(labelText: 'Track Name', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}), // refresh list/save button
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Add Parameter'),
          onTap: track.isEmpty ? null : () => setState(() => _step = 1),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: params.isEmpty
              ? Center(child: Text(track.isEmpty ? 'Enter a track name' : 'No parameters yet'))
              : ListView.builder(
            itemCount: params.length,
            itemBuilder: (_, i) {
              final p = params[i];
              return ListTile(
                leading: Circle(p.color, 12),
                title: Text(p.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    p.delete();
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
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
        _errorMsg   = 'Failed to load variables';
        _isLoading  = false;
      });
    }
  }

  Widget _buildParamStep() {

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMsg != null) {
      return Center(child: Text(_errorMsg!));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Track name (read‐only)
        TextFormField(
          initialValue: _trackNameCtrl.text.trim(),
          decoration: const InputDecoration(labelText: 'Track',
              border: OutlineInputBorder()),
          enabled: false,
        ),
        const SizedBox(height: 12),

        // Display Name
        TextFormField(
          decoration: const InputDecoration(labelText: 'Name',
              border: OutlineInputBorder()),
          onChanged: (v) => setState(() => _paramName = v.trim().isEmpty ? null : v.trim()),
        ),
        const SizedBox(height: 12),

        // ── Variable ────────────────────────────

        DropdownButtonFormField<Variable>(
          decoration: const InputDecoration(
            labelText: 'Variable',
            border: OutlineInputBorder(),
          ),
          isExpanded: true,
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
            _paramUnit    = u?.unitabv; // use abbreviation in your model
          }),
        ),

        const SizedBox(height: 12),

        // Scale Start
        TextFormField(
          controller: _startCtrl,
          decoration: const InputDecoration(labelText: 'Scale Start',
              border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        // Scale End
        TextFormField(
          controller: _endCtrl,
          decoration: const InputDecoration(labelText: 'Scale End',
              border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),

        ListTile(

          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.color_lens),
          title: const Text('Parameter Color'),
          trailing: GestureDetector(
            onTap: () async {
              Color temp = _paramColor;
              await showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Pick a color'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: temp,
                    onColorChanged: (c) => temp = c,
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                  TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
                ],
              ),
              );
              setState(() => _paramColor = temp);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _paramColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black38),
              ),
            ),
          ),
        )

      ],
    );
  }
}
