import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/search_by_time_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/set_depth_dialog.dart';

import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/set_traversal_unit_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/constants/colors.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

typedef OnFieldChanged = void Function(String fieldName, dynamic newValue);

class ChartControlButtons extends StatefulWidget {
  final BuildContext parentContext;
  final PageController controller;
  final ValueNotifier<int> pageNotifier;
  final List<String> trackTypes;
  final DrillingController drillingController;
  final WellActive wellActive;
  final Box<ParameterItem> parameterBox;
  final OnFieldChanged onFieldChanged;
  final String mode;

  const ChartControlButtons({
    super.key,
    required this.parentContext,
    required this.controller,
    required this.pageNotifier,
    required this.trackTypes,
    required this.drillingController,
    required this.wellActive,
    required this.parameterBox,
    required this.onFieldChanged,
    required this.mode,
  });

  @override
  State<ChartControlButtons> createState() => _ChartControlButtonsState();
}

class _ChartControlButtonsState extends State<ChartControlButtons> {
  // State to control the visibility of the buttons
  bool _areControlsVisible = true;

  void _showTrackSettingsDialog(String trackType) async {
    showDialog(
      context: widget.parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text('${CFormatter.capitalize(trackType)} Track Settings'),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (ctx2, dialogSetState) {
                final all = widget.parameterBox.values
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
                              widget.onFieldChanged("", null);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            p.delete();
                            dialogSetState(() {});
                            widget.onFieldChanged("", null);
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
      context: widget.parentContext,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Delete "$trackType" Track?'),
          content: Text('This will permanently delete **all** parameters\n'
              'under the "$trackType" track.\n\n'
              'Are you sure you want to continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final toDelete = widget.parameterBox.values
                    .where((p) => p.trackType == trackType)
                    .toList();

                for (final p in toDelete) {
                  p.delete();
                }
                widget.onFieldChanged("", null);
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
    return ValueListenableBuilder<int>(
      valueListenable: widget.pageNotifier,
      builder: (_, pageIndex, __) {
        if (widget.trackTypes.isEmpty) {
          return const SizedBox.shrink();
        }

        final idx = pageIndex.clamp(0, widget.trackTypes.length - 1);
        final String? trackType =
        widget.trackTypes.isNotEmpty ? widget.trackTypes[idx] : null;

        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Conditionally display the control buttons based on state

                // This is the new button to toggle visibility
                if (_areControlsVisible) const SizedBox(height: 8),
                IconButton(
                  icon: Icon(_areControlsVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  color: CColors.primaryColor,
                  tooltip: _areControlsVisible ? 'Hide Controls' : 'Show Controls',
                  onPressed: () {
                    setState(() {
                      _areControlsVisible = !_areControlsVisible;
                    });
                  },
                ),


                if (_areControlsVisible) ...[
                  IconButton(
                    icon: const Icon(Icons.search),
                    color: CColors.primaryColor,
                    tooltip: 'Search by time range',
                    onPressed: () async {
                      final result = await showDialog<Map<String, DateTime>>(
                        context: widget.parentContext,
                        builder: (_) => const SearchByTimeDialog(),
                      );
                      if (result != null &&
                          result['start'] != null &&
                          result['end'] != null) {
                        widget.onFieldChanged("_isSearching", true);
                        await widget.drillingController.searchDataByTimeRange(
                          wellActive: widget.wellActive,
                          startTime: result['start']!,
                          endTime: result['end']!,
                          mode: widget.mode,
                        );
                        widget.onFieldChanged("_isSearching", false);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    color: CColors.primaryColor,
                    tooltip: 'Track Settings',
                    onPressed: trackType != null
                        ? () => _showTrackSettingsDialog(trackType)
                        : null,
                  ),
                  const SizedBox(height:4 ),
                  GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: widget.parentContext,
                        builder: (_) => const SetTraversalUnitDialog(),
                      );
                    },
                    child: IconButton(
                      icon: const Icon(Icons.fast_rewind),
                      color: CColors.primaryColor,
                      onPressed: () async {
                        widget.onFieldChanged("_isSearching", true);
                        if (widget.mode == 'time') {
                          await widget.drillingController.moveBackwardTimeChart(
                              wellActive: widget.wellActive);
                        } else {
                          final success = await widget.drillingController
                              .moveBackwardDepthChart(
                            wellActive: widget.wellActive,
                          );
                          if (!success && widget.parentContext.mounted) {
                            ScaffoldMessenger.of(widget.parentContext)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text("Already at the start.")),
                            );
                          }
                        }
                        widget.onFieldChanged("_isSearching", false);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: widget.mode == 'depth'
                        ? () {
                      showDialog(
                        context: widget.parentContext,
                        builder: (_) => SetStartDepthDialog(
                            wellId: widget.wellActive.isApiToken),
                      ).then((newDepth) async {
                        if (newDepth != null) {
                          widget.onFieldChanged("_isSearching", true);
                          await widget.drillingController.resetDepthChart(
                              wellActive: widget.wellActive);
                          widget.onFieldChanged("_isSearching", false);
                        }
                      });
                    }
                        : null,
                    child: IconButton(
                      icon: const Icon(Icons.refresh),
                      color: CColors.primaryColor,
                      tooltip:
                      widget.mode == 'depth' ? null : 'Reset to live data',
                      onPressed: () async {
                        widget.onFieldChanged("_isSearching", true);
                        if (widget.mode == 'time') {
                          widget.drillingController.resetHistoricalTimeData();
                        } else {
                          await widget.drillingController
                              .resetDepthChart(wellActive: widget.wellActive);
                        }
                        widget.onFieldChanged("", null);
                        widget.onFieldChanged("_isSearching", false);
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onLongPress: () {
                      showDialog(
                        context: widget.parentContext,
                        builder: (_) => const SetTraversalUnitDialog(),
                      );
                    },
                    child: IconButton(
                      icon: const Icon(Icons.fast_forward),
                      color: CColors.primaryColor,
                      onPressed: () async {
                        widget.onFieldChanged("_isSearching", true);
                        if (widget.mode == 'time') {
                          await widget.drillingController.fastForwardTimeChart(
                              wellActive: widget.wellActive);
                        } else {
                          final success = await widget.drillingController
                              .fastForwardDepthChart(
                            wellActive: widget.wellActive,
                          );
                          if (!success && widget.parentContext.mounted) {
                            ScaffoldMessenger.of(widget.parentContext)
                                .showSnackBar(
                              const SnackBar(
                                  content: Text("No newer data available.")),
                            );
                          }
                        }
                        widget.onFieldChanged("_isSearching", false);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_forever),
                    color: Colors.red,
                    tooltip: widget.trackTypes.length > 2
                        ? 'Delete Track'
                        : 'At least two tracks must remain',
                    onPressed: (trackType != null && widget.trackTypes.length > 2)
                        ? () => _showDeleteTrackConfirm(trackType)
                        : null,
                  ),
                ],

              ],
            ),
          ),
        );
      },
    );
  }
}