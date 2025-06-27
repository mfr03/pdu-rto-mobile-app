import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/common/components/circle.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/depth_chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SingleDepthChart extends StatefulWidget {
  final String title;
  final String trackType;
  final Map<String, num Function(DepthDrillingData)> variableMap;
  final DepthDrillingController controller;
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
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.longPress,
      lineType: TrackballLineType.vertical,
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
      markerSettings: const TrackballMarkerSettings(
        markerVisibility: TrackballVisibilityMode.hidden
      ),
      builder: (BuildContext context, TrackballDetails trackballDetails) {
        final int? pointIndex = trackballDetails.pointIndex;

        if (pointIndex == null ||
            pointIndex < 0 ||
            pointIndex >= widget.controller.displayedDataDepth.length) {
          return const SizedBox.shrink();
        }

        final DepthDrillingData drillData =
        widget.controller.displayedDataDepth[pointIndex];
        final String formattedDateTime =
        CFormatter.formatDateTime(drillData.dateTime);

        List<Widget> children = [];

        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              formattedDateTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        for (final entry in widget.variableMap.entries) {
          final String seriesName = entry.key;
          final num yValue = entry.value(drillData);
          final Color color = widget.colorMap[seriesName] ?? Colors.grey;

          children.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Circle(color, 6),
                  const SizedBox(width: 6),
                  Text(
                    '$seriesName: ${yValue.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }

  Widget _depthChart(List<DepthDrillingData> data) {
    final paramNames = widget.variableMap.keys.toList();
    late final NumericAxis primaryAxis;
    final additionalAxes = <NumericAxis>[];

    if (paramNames.isNotEmpty) {
      final firstParamName = paramNames.first;

      final ParameterItem? firstParamItem = widget.parameterBox.values.firstWhere(
            (p) => p.name == firstParamName && p.trackType == widget.trackType,
      );

      if (firstParamItem == null) {
        primaryAxis =
            NumericAxis(title: const AxisTitle(text: 'Error: Param not found'));
      } else {
        final double firstMin = firstParamItem.scaleStart.toDouble();
        final double firstMax = firstParamItem.scaleEnd.toDouble();

        primaryAxis = NumericAxis(
          name: firstParamName,
          minimum: firstMin,
          maximum: firstMax,
          opposedPosition: true,
          axisLine: const AxisLine(width: 0),
          majorGridLines: const MajorGridLines(width: 2, dashArray: [4, 3]),
          isVisible: true,
          labelStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
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
                majorGridLines: const MajorGridLines(width: -5, dashArray: [4, 3]),
                isVisible: false,
              ),
            );
          }
        }
      }
    } else {
      primaryAxis = NumericAxis();
      return Center(
          child: Text("No parameters configured for '${widget.title}'"));
    }

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
        isInversed: true, // deeper depth further “down”
        // --- THIS IS THE FIX ---
        // Bind the axis range to our new reactive variables in the controller.
        // The Obx wrapper will handle updates automatically.
        minimum: widget.controller.depthAxisMin.value,
        maximum: widget.controller.depthAxisMax.value,
        // --- END FIX ---
      ),
      primaryYAxis: primaryAxis,
      axes: additionalAxes,
      trackballBehavior: _trackballBehavior,
      zoomPanBehavior: ZoomPanBehavior(),
      legend: Legend(isVisible: false),
      series: widget.variableMap.entries.map((e) {
        return LineSeries<DepthDrillingData, num>(
          name: e.key,
          color: widget.colorMap[e.key],
          yAxisName: e.key,
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // The Obx wrapper will now listen for changes to the nice axis range
    // in addition to the data itself.
    return Obx(() {
      final dataList = widget.controller.displayedDataDepth.toList();

      if (dataList.isEmpty) {
        // 2. If it's empty, show a placeholder instead of the chart.
        //    This prevents the trackball from being initialized with no data.
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Loading Depth Data..."),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(8),
        child: _depthChart(dataList),
      );
    });
  }


}