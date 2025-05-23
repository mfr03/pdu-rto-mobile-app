import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/multi_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/single_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/add_track_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/chart_control_buttons.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:pdu_mobile_rto_app/utils/well_utils.dart';

class ChartTimePage extends StatelessWidget {

  final String? multiMode;
  final List<String> trackTypes;
  final DrillingController controller;
  final PageController multiCtrl1, multiCtrl2, timeCtrl;
  final ValueNotifier<int> multiNotifier1, multiNotifier2, timeNotifier;
  final Box<ParameterItem>? parameterBox;
  final bool isDashboardVisible;
  final WellActive wellActive;
  final OnFieldChanged onFieldChanged;

  const ChartTimePage({super.key,
    required this.multiMode,
    required this.trackTypes,
    required this.controller,
    required this.multiCtrl1,
    required this.multiCtrl2,
    required this.timeCtrl,
    required this.multiNotifier1,
    required this.multiNotifier2,
    required this.timeNotifier,
    required this.parameterBox,
    required this.isDashboardVisible,
    required this.wellActive,
    required this.onFieldChanged});

  Map<String, num Function(DrillingData)> _variableMap(String trackType) {
    return {
      for (var p in parameterBox!.values
          .where((p) => p.trackType == trackType && p.isVisible))
        p.name: (d) => d.value(p.jsonKey),
    };
  }

  List<Widget> get _timeChartPages => trackTypes
      .map((t) => SingleChart(
    key: ValueKey('time-$t'),
    title: '${CFormatter.capitalize(t)} Track',
    mapString: t,
    variableMap: _variableMap(t),
    controller: controller,
    colorMap: {
      for (var p in parameterBox!.values.where((p) => p.trackType == t))
        p.name: p.color
    },
  ))
      .toList();


  List<ParameterItem> _buildDashboardParams(int pageIndex) {

    DrillingData? dataPointForDashboard;

    bool isCurrentlyLive = isWellCompleted(wellActive: wellActive);

    if (isCurrentlyLive) {
      dataPointForDashboard = controller.latestLiveTimeDataPoint.value;
    } else {
      dataPointForDashboard = controller.displayedData.isNotEmpty
          ? controller.displayedData.last
          : (controller.historicalTimeData.isNotEmpty ? controller.historicalTimeData.last : null);
    }

    if (dataPointForDashboard == null || trackTypes.isEmpty || pageIndex < 0 || pageIndex >= trackTypes.length) {
      return [];
    }

    final currentTrackType = trackTypes[pageIndex];

    return parameterBox!.values
        .where((p) => p.trackType == currentTrackType && p.isVisible)
        .map((p) {
          final num val = dataPointForDashboard!.value(p.jsonKey);
          return p.copyWith(
            value: val.toStringAsFixed(2),
            updatedAt: DateTime.now()
          );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {


    final maxPageIndex = trackTypes.isEmpty ? 0 : trackTypes.length - 1;

    if (timeNotifier.value > maxPageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        timeCtrl.jumpToPage(maxPageIndex);
        timeNotifier.value = maxPageIndex;
      });
    }

    if (multiMode == 'time') {
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
                    controller: timeCtrl,
                    children: _timeChartPages,
                  ),
                  ChartControlButtons(
                      parentContext: context,
                      controller: timeCtrl,
                      pageNotifier: timeNotifier,
                      trackTypes: trackTypes,
                      drillingController: controller,
                      wellActive: wellActive,
                      parameterBox: parameterBox!,
                      onFieldChanged: onFieldChanged,
                    mode: 'time',
                  ),
                ],
              ),
            ),
            if (isDashboardVisible)
              Expanded(
                flex: 4,
                child: ValueListenableBuilder<int>(
                  valueListenable: timeNotifier,
                  builder: (_, idx, __) {

                    final clampedIdx = idx.clamp(0, maxPageIndex);

                    // ④ Another safeguard: if idx was out of range, schedule the fix
                    if (clampedIdx != idx) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        timeCtrl.jumpToPage(clampedIdx);
                        timeNotifier.value = clampedIdx;
                      });
                    }

                    return Obx(() {

                      if(!isDashboardVisible) {
                        return const SizedBox.shrink();
                      }

                      return ParameterDashboard(
                        parameterAmount: _timeChartPages.length,
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
                            timeCtrl.jumpToPage(newPage);
                            timeNotifier.value = newPage;
                          }
                        },
                      );
                    });
                  }
                ),
              ),
            const SizedBox(height: 16)
          ],
        ),
      );
    }



  }

}