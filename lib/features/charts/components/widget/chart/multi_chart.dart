import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/single_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/chart/single_depth_chart.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/dialog/add_track_dialog.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/chart_control_buttons.dart';
import 'package:pdu_mobile_rto_app/features/charts/components/widget/miscellaneous/parameter_dashboard.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/depth_chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';

class MultiChart extends StatelessWidget {

  final List<String> tracks;
  final DrillingController? controller;
  final DepthDrillingController? depthController;
  final PageController pageController;
  final ValueNotifier<int> pageNotifier;
  final String mode;
  final Box<ParameterItem> parameterBox;
  final bool isDashboardVisible;
  final List<String> trackTypes;
  final WellActive wellActive;
  final OnFieldChanged onFieldChanged;
  final bool hideToolbar;
  final bool hideXAxis;

  const MultiChart({super.key,
    required this.tracks,
    required this.pageController,
    required this.pageNotifier,
    required this.mode,
    required this.parameterBox,
    required this.isDashboardVisible,
    required this.trackTypes,
    required this.wellActive,
    required this.onFieldChanged,
    this.controller,
    this.depthController,
    this.hideToolbar = false,
    this.hideXAxis = false,
  });


  List<ParameterItem> _dashboardItems(String track, int pageIdx) {
    if(mode == "time" && controller != null) {
      List<DrillingData> data = controller!.displayedData;
      if (data.isEmpty) return [];
      final last = data.last;
      return parameterBox.values
          .where((p) => p.trackType == track && p.isVisible)
          .map((p) {
        final raw = last.rawDataOriginal[p.jsonKey]?.toString() ?? '0';
        final v = double.tryParse(raw) ?? 0.0;
        return p.copyWith(
          value: v.toStringAsFixed(1),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } else  {
      List<DepthDrillingData> data = depthController!.displayedDataDepth;
      if (data.isEmpty) return [];
      final last = data.last;
      return parameterBox.values
          .where((p) => p.trackType == track && p.isVisible)
          .map((p) {
        final raw = last.rawDataOriginal[p.jsonKey]?.toString() ?? '0';
        final v = double.tryParse(raw) ?? 0.0;
        return p.copyWith(
          value: v.toStringAsFixed(1),
          updatedAt: DateTime.now(),
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {

    final pages = tracks.map((t) {
      final varMap = <String, num Function(DrillingData)>{
        for (var p in parameterBox.values.where((p) => p.trackType == t && p.isVisible)) p.name: (d) => d.value(p.jsonKey),
      };

      final varMapDepth = <String, num Function(DepthDrillingData)>{
        for (var p in parameterBox.values.where((p) => p.trackType == t && p.isVisible)) p.name: (d) => d.value(p.jsonKey),
      };

      final colorMap = {
        for (var p in parameterBox.values.where((p) => p.trackType == t)) p.name: p.color,
      };
      if (mode == 'time') {
        return SingleChart(
          key: ValueKey('multi-$mode-$t'),
          title: CFormatter.capitalize(t),
          mapString: t,
          variableMap: varMap,
          controller: controller!,
          colorMap: colorMap,
          showXAxisLabel: !hideXAxis,
          parameterBox: parameterBox,
        );
      } else {
        return SingleDepthChart(
          key: ValueKey('multi-$mode-$t'),
          title: CFormatter.capitalize(t),
          trackType: t,
          variableMap: varMapDepth,
          controller: depthController!,
          colorMap: colorMap,
          parameterBox: parameterBox,
        );
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: isDashboardVisible ? 6 : 9,
          child: Stack(
            children: [
              PageView(controller: pageController, children: pages),
              if (!hideToolbar) ChartControlButtons(
                parentContext: context,
                controller: pageController,
                pageNotifier: pageNotifier,
                trackTypes: trackTypes,
                drillingController: controller!,
                wellActive: wellActive,
                parameterBox: parameterBox,
                onFieldChanged: onFieldChanged,
                mode: mode,
              )
            ],
          ),
        ),

        if (isDashboardVisible)
          Expanded(
            flex: 4,
            child: ValueListenableBuilder<int>(
              valueListenable: pageNotifier,
              builder: (_, idx, __) {
                final track = tracks[idx % tracks.length];
                return ParameterDashboard(
                  parameterAmount: pages.length,
                  activeIndex: idx + 1,
                  parameters: _dashboardItems(track, idx),
                  parameterBox: parameterBox,
                  onCardTap: (i) {
                    final count = tracks.length;        // use the passed-in list
                    if (i == count + 1) {
                      // “+” tapped → open AddTrackDialog
                      showDialog(
                        context: context,
                        builder: (_) => AddTrackDialog(
                          parameterBox: parameterBox,
                          wellActive: wellActive,
                        ),
                      ).then((_) => onFieldChanged("", null));
                    } else {
                      // number tapped → jump that page
                      final newPage = i - 1;
                      pageController.jumpToPage(newPage);
                      pageNotifier.value = newPage;
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

}