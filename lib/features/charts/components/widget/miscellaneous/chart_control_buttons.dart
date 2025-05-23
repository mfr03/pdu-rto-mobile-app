import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

typedef OnFieldChanged = void Function(String fieldName, dynamic newValue);

class ChartControlButtons extends StatelessWidget {

  final BuildContext parentContext;
  final PageController controller;
  final ValueNotifier<int> pageNotifier;
  final List<String> trackTypes;
  final DrillingController drillingController;
  final WellActive wellActive;
  final Box<ParameterItem> parameterBox;
  final OnFieldChanged onFieldChanged;
  final String mode;

  const ChartControlButtons({super.key,
    required this.parentContext,
    required this.controller,
    required this.pageNotifier,
    required this.trackTypes,
    required this.drillingController,
    required this.wellActive,
    required this.parameterBox,
    required this.onFieldChanged,
    required this.mode
  });

  void _showTrackSettingsDialog(String trackType) async {
    showDialog(
      context: parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${CFormatter.capitalize(trackType)} Track Settings'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (ctx2, dialogSetState) {
                final all = parameterBox!.values
                    .where((p) => p.trackType == trackType)
                    .toList();
                final seen = <String>{};
                final items = <ParameterItem>[];
                for (var p in all) {
                  if (seen.add(p.jsonKey)) items.add(p);
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: Text(p.name),
                            value: p.isVisible,
                            onChanged: (vis) {
                              p.isVisible = vis!;
                              p.save();
                              dialogSetState(() {});
                              onFieldChanged("", null);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            p.delete();
                            dialogSetState(() {});
                            onFieldChanged("", null);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteTrackConfirm(String trackType) async {
    showDialog(
      context: parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Delete "$trackType" Track?'),
          content: Text(
              'This will permanently delete **all** parameters\n'
                  'under the "$trackType" track.\n\n'
                  'Are you sure you want to continue?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {

                final toDelete = parameterBox.values
                .where((p) => p.trackType == trackType)
                .toList();

                for (final p in toDelete) {
                  p.delete();
                }
                onFieldChanged("", null);
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Listen to pageNotifier so our buttons (especially Settings) rebuild
    return ValueListenableBuilder<int>(
      valueListenable: pageNotifier,
      builder: (_, pageIndex, __) {
        // clamp to valid range

        if(trackTypes.isEmpty) {
          return const SizedBox.shrink();
        }

        final idx = pageIndex.clamp(0, trackTypes.length - 1);
        final String? trackType = trackTypes.isNotEmpty ? trackTypes[idx] : null;

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚙️ Settings button
                IconButton(
                  icon: const Icon(Icons.settings),
                  color: CColors.primaryColor,
                  tooltip: 'Track Settings',
                  onPressed: trackType != null
                      ? () => _showTrackSettingsDialog(trackType)
                      : null, // disabled if no trackType
                ),
                const SizedBox(height: 8),

                // ⏪ Rewind
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  color: CColors.primaryColor,
                  tooltip: 'Load older data',
                  onPressed: () async {
                    onFieldChanged("_isSearching", true);

                    if (mode == 'time') {
                      drillingController.moveBackward(wellActive: wellActive, mode: "time");
                    } else {
                      drillingController.moveBackward(wellActive: wellActive, mode: "depth");
                    }

                    onFieldChanged("_isSearching", false);
                  },
                ),
                const SizedBox(height: 8),

                // 🔄 Reset to live
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: CColors.primaryColor,
                  tooltip: 'Reset to live data',
                  onPressed: () {
                    drillingController.resetHistoricalTimeData();
                    onFieldChanged("", null);
                  },
                ),
                const SizedBox(height: 8),

                // ⏩ Forward
                IconButton(
                  icon: const Icon(Icons.fast_forward),
                  color: CColors.primaryColor,
                  tooltip: 'Load newer data',
                  onPressed: () async {
                    onFieldChanged("_isSearching", true);

                    if (mode == 'time') {
                      await drillingController.fastForwardTimeChart(wellActive: wellActive);
                    } else {
                      // await drillingController.(wellActive: wellActive);
                    }

                    onFieldChanged("_isSearching", false);
                  },
                ),

                IconButton(
                  icon: const Icon(Icons.delete_forever),
                  color: Colors.red,
                  tooltip: trackTypes.length > 2
                      ? 'Delete Track'
                      : 'At least two tracks must remain',
                  onPressed: (trackType != null && trackTypes.length > 2)
                      ? () => _showDeleteTrackConfirm(trackType)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }


}