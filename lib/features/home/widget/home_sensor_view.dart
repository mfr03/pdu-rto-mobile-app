import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';


class HomeSensorView extends StatelessWidget {
  final DrillingData? latest;
  final Box<ParameterItem>? parameterBox;

  const HomeSensorView({
    Key? key,
    required this.latest,
    required this.parameterBox,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1️⃣ If we have no parameters or no data, show a placeholder
    if (latest == null || parameterBox == null || parameterBox!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 100,
            alignment: Alignment.center,
            child: const Text(
              'No sensor data available',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // 2️⃣ Build a map of displayName → extractorFunction
    final sensors = <MapEntry<String, num Function(DrillingData)>>[
      for (final p in parameterBox!.values.where((p) => p.isVisible))
        MapEntry(p.name, (d) => d.value(p.jsonKey)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),

          // 3️⃣ Scrollable list of name + formatted value+unit
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sensors.length,
            itemBuilder: (_, i) {
              final name = sensors[i].key;
              final value = sensors[i].value(latest!);

              // Look up the matching ParameterItem to grab its saved unit
              final p = parameterBox!
                  .values
                  .firstWhere((p) => p.name == name);
              final unit = p.unit ?? '';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings, color: CColors.primaryColor),
                title: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Text(
                  '${value.toStringAsFixed(2)}$unit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CColors.primaryColor,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}