import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';

import '../../../../utils/constants/colors.dart';


class EditParameterDialog extends StatefulWidget {
  final ParameterItem parameter;
  final Box<ParameterItem> parameterBox;
  final VoidCallback onSaved;

  const EditParameterDialog({
    required this.parameter,
    required this.parameterBox,
    required this.onSaved,
  });

  @override
  _EditParameterDialogState createState() => _EditParameterDialogState();
}

class _EditParameterDialogState extends State<EditParameterDialog> {
  late TextEditingController _nameController;
  late TextEditingController _unitController;
  late TextEditingController _scaleStartController;
  late TextEditingController _scaleEndController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    final currentParam = widget.parameterBox.values.firstWhere(
          (p) => p.name == widget.parameter.name,
      orElse: () => widget.parameter,
    );

    _nameController = TextEditingController(text: currentParam.name);
    _unitController = TextEditingController(text: currentParam.unit);
    _scaleStartController = TextEditingController(text: currentParam.scaleStart.toString());
    _scaleEndController = TextEditingController(text: currentParam.scaleEnd.toString());
    _selectedColor = currentParam.color;
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => setState(() => _selectedColor = color),
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    final updatedParameter = widget.parameter.copyWith(
      name: _nameController.text,
      unit: _unitController.text,
      scaleStart: int.parse(_scaleStartController.text),
      scaleEnd: int.parse(_scaleEndController.text),
      color: _selectedColor,
      updatedAt: DateTime.now(),
    );

    final index = widget.parameterBox.values
        .toList()
        .indexWhere((p) => p.name == widget.parameter.name);

    if (index != -1) {
      widget.parameterBox.putAt(index, updatedParameter);
      widget.onSaved();
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
          'Edit Parameter',
        style: TextStyle(color: CColors.primaryColor),
      ),
      content: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Parameter Name',
          border: OutlineInputBorder(),
        ),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _unitController,
        decoration: const InputDecoration(
          labelText: 'Unit (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child:
            TextFormField(
              keyboardType: TextInputType.number,
              controller: _scaleStartController,
              decoration: const InputDecoration(
                labelText: 'Scale Start (num)',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
            Expanded(child:
            TextFormField(
              keyboardType: TextInputType.number,
              controller: _scaleEndController,
              decoration: const InputDecoration(
                labelText: 'Scale End (num)',
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      ),
          const SizedBox(height: 16),
      ListTile(
        leading: const Icon(Icons.color_lens),
        title: const Text('Parameter Color'),
        trailing: GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black38),
            ),
          ),
        ),
      ),
        ],
      ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              _saveChanges();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CColors.primaryColor,
            textStyle: TextStyle(color: Colors.white)
          ),
          child: const Text(
              'Save Changes',
          style: TextStyle(color: Colors.white),),
        ),
      ],
    );
  }
}