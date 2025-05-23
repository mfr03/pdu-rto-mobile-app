import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';


class SingleDepthChart extends StatefulWidget {
  final String title;
  final String trackType;
  final Map<String, num Function(DepthDrillingData)> variableMap;
  final DrillingController controller;
  final Map<String, Color> colorMap;
  final Box<ParameterItem> parameterBox;

  const SingleDepthChart({
    super.key,
    required this.title,
    required this.trackType,
    required this.variableMap,
    required this.controller,
    required this.colorMap,
    required this.parameterBox,
  });

  @override
  State<SingleDepthChart> createState() => _SingleDepthChartState();
}

class _SingleDepthChartState extends State<SingleDepthChart>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      final dataList = widget.controller.displayedDataDepth.toList();

      return Padding(
        padding: const EdgeInsets.all(8),
        child: _depthChart(dataList),
      );
    });
  }

  Widget _depthChart(List<DepthDrillingData> data) {
    final paramNames = widget.variableMap.keys.toList();
    late final NumericAxis primaryAxis;
    final additionalAxes = <NumericAxis>[];


    if (paramNames.isNotEmpty) {
      final firstParamName = paramNames.first;

      final ParameterItem? firstParamItem = widget.parameterBox.values
          .firstWhere(
            (p) => p.name == firstParamName && p.trackType == widget.trackType,
      );

      if (firstParamItem == null) {
        primaryAxis = NumericAxis(title: const AxisTitle(
            text: 'Error: Param not found'));
      } else {

        final double firstMin = firstParamItem.scaleStart.toDouble();
        final double firstMax = firstParamItem.scaleEnd.toDouble();

        primaryAxis = NumericAxis(
          name: firstParamName,
          minimum: firstMin,
          maximum: firstMax,
          opposedPosition: true,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 2, dashArray: [4,3]),
          isVisible: true,
          labelStyle: const TextStyle(color: Colors.transparent, fontSize: 0),//
        );

        for (final name in paramNames.skip(1)) {
          final ParameterItem? item = widget.parameterBox.values.firstWhere(
                (p) => p.name == name && p.trackType == widget.trackType,
          );
          if (item != null) {
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
        }
      }
    }  else {
      primaryAxis = NumericAxis();
      return Center(child: Text("No parameters configured for '${widget.title}'"));
    }

    //---------------------------------------------------------------
    // 2. Trackball & chart definition
    //---------------------------------------------------------------
    return SfCartesianChart(
      key: ValueKey(
        'depthchart-${widget.trackType}-${widget.variableMap.keys.join(",")}',
      ),
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





        return LineSeries<DepthDrillingData, num>(
          name: e.key,
          color: widget.colorMap[e.key],
          yAxisName: e.key,                  //  <-- key point
          dataSource: data,
          xValueMapper: (d, _) => d.md,
          yValueMapper: (d, _) => e.value(d),
          markerSettings: const MarkerSettings(isVisible: false),
          animationDuration: 0,
          animationDelay: 0,
          onRendererCreated: (ctl) =>
              widget.controller.storeSeriesController(widget.trackType, ctl),
        );
      }).toList(),
    );
  }
}
