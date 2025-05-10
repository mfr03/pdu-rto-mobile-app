import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/multi_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/single_depth_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/add_track_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/chart_control_buttons.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';


class ChartDepthPage extends StatelessWidget {

  final String? multiMode;
  final List<String> trackTypes;
  final DrillingController controller;
  final PageController multiCtrl1, multiCtrl2, depthCtrl;
  final ValueNotifier<int> multiNotifier1, multiNotifier2, depthNotifier;
  final Box<ParameterItem>? parameterBox;
  final bool isDashboardVisible;
  final WellActive wellActive;
  final OnFieldChanged onFieldChanged;

  const ChartDepthPage({super.key,
    this.multiMode,
    required this.trackTypes,
    required this.controller,
    required this.multiCtrl1,
    required this.multiCtrl2,
    required this.depthCtrl,
    required this.multiNotifier1,
    required this.multiNotifier2,
    required this.depthNotifier,
    required this.parameterBox,
    required this.isDashboardVisible,
    required this.wellActive,
    required this.onFieldChanged});

  Map<String, num Function(DepthDrillingData)> _variableMap(String trackType) {
    return {
      for (var p in parameterBox!.values
          .where((p) => p.trackType == trackType && p.isVisible))
        p.name: (d) => d.value(p.jsonKey),
    };
  }

  List<Widget> get _depthChartPages => trackTypes
      .map((t) => SingleDepthChart(
    key: ValueKey('depth-$t'),
    title: '${CFormatter.capitalize(t)} Depth Track',
    trackType: t,
    variableMap: _variableMap(t),
    controller: controller,
    colorMap: {
      for (var p in parameterBox!.values.where((p) => p.trackType == t))
        p.name: p.color
    },
  ))
      .toList();

  List<ParameterItem> _buildDashboardParams(int pageIndex) {
    final data = controller.displayedDataDepth;
    if (data.isEmpty) return [];
    final last = data.last;
    final track = trackTypes[pageIndex];
    return parameterBox!.values
        .where((p) => p.trackType == track && p.isVisible)
        .map((p) {
      final raw = last.rawData[p.jsonKey]?.toString() ?? '0';
      final v = double.tryParse(raw) ?? 0.0;
      return p.copyWith(
        value: v.toStringAsFixed(1),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }



  @override
  Widget build(BuildContext context) {

    final maxPageIndex = trackTypes.isEmpty ? 0 : trackTypes.length - 1;

    if (depthNotifier.value > maxPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        depthCtrl.jumpToPage(maxPageIndex);
        depthNotifier.value = maxPageIndex;
      });
    }

    if (multiMode == 'depth') {
      final all = trackTypes;
      final half = (all.length / 2).ceil();
      final leftTracks = all.sublist(0, half);
      final rightTracks = (half < all.length) ? all.sublist(half) : <String>[];

      return Row(
        children: [
          Expanded(
            child: MultiChart(
              tracks: leftTracks,
              controller: controller,
              pageController: multiCtrl1,
              pageNotifier: multiNotifier1,
              mode: multiMode!,
              parameterBox: parameterBox!,
              isDashboardVisible: isDashboardVisible,
              trackTypes: trackTypes,
              wellActive: wellActive,
              onFieldChanged: onFieldChanged,
              hideToolbar: true,
              hideXAxis: false,
            ),
          ),
          Expanded(
            child: MultiChart(
              tracks: rightTracks,
              controller: controller,
              pageController: multiCtrl2,
              pageNotifier: multiNotifier2,
              mode: multiMode!,
              parameterBox: parameterBox!,
              isDashboardVisible: isDashboardVisible,
              trackTypes: trackTypes,
              wellActive: wellActive,
              onFieldChanged: onFieldChanged,
              hideToolbar: false,
              hideXAxis: true,
            ),
          ),
        ],
      );
    } else {
      return SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: isDashboardVisible ? 6 : 9,
              child: Stack(
                children: [
                  PageView(
                    controller: depthCtrl,
                    children: _depthChartPages,
                  ),
                  ChartControlButtons(
                      parentContext: context,
                      controller: depthCtrl,
                      pageNotifier: depthNotifier,
                      trackTypes: trackTypes,
                      drillingController: controller,
                      wellActive: wellActive,
                      parameterBox: parameterBox!,
                      onFieldChanged: onFieldChanged,
                    mode: 'depth',
                  ),
                ],
              ),
            ),
            if (isDashboardVisible)
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<int>(
                  valueListenable: depthNotifier,
                  builder: (_, idx, __) {
                        final clampedIdx = idx.clamp(0, maxPageIndex);
                        if (clampedIdx != idx) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            depthCtrl.jumpToPage(clampedIdx);
                            depthNotifier.value = clampedIdx;
                          });
                        }
                        return ParameterDashboard(
                            parameterAmount: _depthChartPages.length,
                            activeIndex: clampedIdx + 1,
                            parameters: _buildDashboardParams(clampedIdx),
                            parameterBox: parameterBox!,
                            onCardTap: (i) {
                              final count =
                                  trackTypes.length; // dynamic number of cards
                              if (i == count + 1) {
                                // plus card tapped
                                showDialog(
                                  context: context,
                                  builder: (_) => AddTrackDialog(
                                    parameterBox: parameterBox!,
                                    controller: controller,
                                    wellActive: wellActive,
                                  ),
                                );
                              } else {
                                final newPage = i - 1;
                                depthCtrl.jumpToPage(newPage);
                                depthNotifier.value = newPage;
                              }
                            },
                          );
                  }
                ),
              ),
          ],
        ),
      );
    }
  }

}
