import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';

import '../../../../data/services/pdu_api/model/drilling_data.dart';
import '../../controller/chart_drilling_controller.dart';
import '../../model/parameter_item.dart';


class SingleDepthChartPage extends StatefulWidget {
  final String title;
  final String trackType;                    //  <-- NEW
  final Map<String, num Function(DrillingData)> variableMap;
  final DrillingController controller;
  final Map<String, Color> colorMap;

  const SingleDepthChartPage({
    super.key,
    required this.title,
    required this.trackType,
    required this.variableMap,
    required this.controller,
    required this.colorMap,
  });

  @override
  State<SingleDepthChartPage> createState() => _SingleDepthChartPageState();
}

class _SingleDepthChartPageState extends State<SingleDepthChartPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final dataList = widget.controller.displayedData.toList();
      return Padding(
        padding: const EdgeInsets.all(8),
        child: _depthChart(dataList),
      );
    });
  }

  /// identical idea to the time‑based chart, just with a NumericAxis on X
  Widget _depthChart(List<DrillingData> data) {
    //---------------------------------------------------------------
    // 1. Build a separate numeric Y‑axis for every parameter
    //---------------------------------------------------------------
    final paramNames = widget.variableMap.keys.toList();
    late final NumericAxis primaryAxis;
    final additionalAxes = <NumericAxis>[];

    if (paramNames.isNotEmpty) {
      final first = paramNames.first;
      final firstMin =
      Hive.box<ParameterItem>('user_parameters')
          .values
          .firstWhere((p) => p.name == first)
          .scaleStart
          .toDouble();
      final firstMax =
      Hive.box<ParameterItem>('user_parameters')
          .values
          .firstWhere((p) => p.name == first)
          .scaleEnd
          .toDouble();

      primaryAxis = NumericAxis(
        name: first,
        minimum: firstMin,
        maximum: firstMax,
        opposedPosition: true,
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 2, dashArray: [4,3]),
        isVisible: true,
        labelStyle: const TextStyle(color: Colors.transparent, fontSize: 0),// <--- set this to true if you want to see it
      );

      for (final name in paramNames.skip(1)) {
        final item = Hive.box<ParameterItem>('user_parameters')
            .values
            .firstWhere((p) => p.name == name);
        additionalAxes.add(
          NumericAxis(
            name: name,
            minimum: item.scaleStart.toDouble(),
            maximum: item.scaleEnd.toDouble(),
            opposedPosition: true,
            axisLine: const AxisLine(width: 0),
            majorGridLines: const MajorGridLines(width: -5, dashArray: [4,3]),
            isVisible: false,
          ),
        );
      }
    } else {
      primaryAxis = NumericAxis();
    }

    //---------------------------------------------------------------
    // 2. Trackball & chart definition
    //---------------------------------------------------------------
    return SfCartesianChart(
      isTransposed: true,
      title: ChartTitle(
        text: widget.title,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      plotAreaBorderWidth: 1,
      plotAreaBorderColor: Colors.grey,
      primaryXAxis: NumericAxis(
        name: 'Depth',
        isInversed: true,            // deeper depth further “down”
      ),
      primaryYAxis: primaryAxis,
      axes: additionalAxes,
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,    // ← gesture that follows the drag
        shouldAlwaysShow: true,                      // ← keep it on while moving
        hideDelay: 2000,                             // ← fade‑out delay (optional)
        lineType: TrackballLineType.vertical,        // only vertical or none exist
        tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
        tooltipSettings: const InteractiveTooltip(enable: true),
      ),
      zoomPanBehavior: ZoomPanBehavior(),
      legend: Legend(isVisible: false),

      //-------------------------------------------------------------
      // 3. One LineSeries per parameter → bound to its axis by name
      //-------------------------------------------------------------
      series: widget.variableMap.entries.map((e) {
        return LineSeries<DrillingData, num>(
          name: e.key,
          color: widget.colorMap[e.key],
          yAxisName: e.key,                  //  <-- key point
          dataSource: data,
          xValueMapper: (d, _) => d.bitDepth,
          yValueMapper: (d, _) => e.value(d),
          markerSettings: const MarkerSettings(isVisible: false),
          onRendererCreated: (ctl) =>
              widget.controller.storeSeriesController(widget.trackType, ctl),
        );
      }).toList(),
    );
  }
}
