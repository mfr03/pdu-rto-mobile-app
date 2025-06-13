import 'package:flutter/material.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

class SearchByTimeDialog extends StatefulWidget {
  const SearchByTimeDialog({super.key});

  @override
  State<SearchByTimeDialog> createState() => _SearchByTimeDialogState();
}

class _SearchByTimeDialogState extends State<SearchByTimeDialog> {
  DateTime? _startTime;
  DateTime? _endTime;

  Future<void> _pickDateTime(bool isStartTime) async {
    final now = DateTime.now();
    final initialDate = isStartTime
        ? (_startTime ?? now)
        : (_endTime ?? _startTime ?? now);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null) return;

    final finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStartTime) {
        _startTime = finalDateTime;
        // Ensure end time is not before start time
        if (_endTime != null && _endTime!.isBefore(_startTime!)) {
          _endTime = _startTime!.add(const Duration(minutes: 15));
        }
      } else {
        _endTime = finalDateTime;
      }
    });
  }

  void _onSearch() {
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a start and end time.')),
      );
      return;
    }
    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be before start time.')),
      );
      return;
    }
    Navigator.of(context).pop({'start': _startTime!, 'end': _endTime!});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search by Time Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Start Time'),
            subtitle: Text(_startTime == null
                ? 'Not set'
                : CFormatter.formatDateTime(_startTime!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDateTime(true),
          ),
          ListTile(
            title: const Text('End Time'),
            subtitle: Text(_endTime == null
                ? 'Not set'
                : CFormatter.formatDateTime(_endTime!)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDateTime(false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSearch,
          child: const Text('Search'),
        ),
      ],
    );
  }
}