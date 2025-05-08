import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';

import '../../../../../data/services/pdu_api/model/drilling_data.dart';
import '../../../controller/chart_drilling_controller.dart';

class SingleChart extends StatefulWidget {
  final String title;
  final String mapString;
  final Map<String, num Function(DrillingData)> variableMap;
  final DrillingController controller;
  final Map<String, Color> colorMap;
  final bool showXAxisLabel;

  const SingleChart({
    super.key,
    required this.title,
    required this.mapString,
    required this.variableMap,
    required this.controller,
    required this.colorMap,
    this.showXAxisLabel = true,
  });

  @override
  _SingleChartState createState() => _SingleChartState();
}

class _SingleChartState extends State<SingleChart>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final dataList = widget.controller.displayedData.toList();
      return Container(
        padding: const EdgeInsets.all(8),
        child: _buildTrackChart(dataList),
      );
    });
  }

  Widget _buildTrackChart(List<DrillingData> dataList) {
    final Box<ParameterItem> parameterBox =
        Hive.box<ParameterItem>('user_parameters');

    final List<String> parameterNames = widget.variableMap.keys.toList();

    NumericAxis primaryNumericAxis;
    final List<NumericAxis> additionalAxes = [];

    if (parameterNames.isNotEmpty) {
      final String firstParamName = parameterNames.first;
      final ParameterItem? firstParam =
          parameterBox.values.firstWhere((p) => p.name == firstParamName);
      final double firstMin = firstParam?.scaleStart.toDouble() ?? 0.0;
      final double firstMax = firstParam?.scaleEnd.toDouble() ?? 100.0;

      primaryNumericAxis = NumericAxis(
        name: firstParamName,
        minimum: firstMin,
        maximum: firstMax,
        opposedPosition: true,
        axisLine: const AxisLine(width: 0),
        majorGridLines: const MajorGridLines(width: 2, dashArray: [4, 3]),
        // If you want the first axis visible, you can omit isVisible or set it to true
        isVisible: true,
        labelStyle: const TextStyle(
            color: Colors.transparent,
            fontSize: 0), // <--- set this to true if you want to see it
      );

      // For each remaining parameter, create an additional axis with a unique name
      for (final name in parameterNames.skip(1)) {
        final ParameterItem? param =
            parameterBox.values.firstWhere((p) => p.name == name);
        final double min = param?.scaleStart.toDouble() ?? 0.0;
        final double max = param?.scaleEnd.toDouble() ?? 100.0;

        additionalAxes.add(
          NumericAxis(
            name:
                name, // This must match the yAxisName you'll set on the series
            minimum: min,
            maximum: max,
            opposedPosition: true,
            axisLine: const AxisLine(width: 0),
            majorGridLines: const MajorGridLines(width: 3, dashArray: [4, 3]),
            // If you actually want to see each axis's labels:
            isVisible: false, // <--- set this to true if you want to see it
          ),
        );
      }
    } else {
      // Fallback if no parameters
      primaryNumericAxis = NumericAxis();
    }

    // 2) Assign each series to its corresponding axis via yAxisName
    final trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        textStyle: const TextStyle(fontSize: 9),
      ),
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      activationMode: ActivationMode.singleTap,
    );

    return SfCartesianChart(
      key: ValueKey(
        'chart-${widget.mapString}-${widget.variableMap.keys.join(",")}',
      ),
      isTransposed: true,
      title: ChartTitle(
        text: widget.title,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      plotAreaBorderWidth: 1,
      plotAreaBorderColor: Colors.grey,
      primaryXAxis: DateTimeAxis(
        isVisible: true,
        isInversed: true,
        dateFormat: DateFormat("HH:mm"),
        axisLabelFormatter: (AxisLabelRenderDetails args) {
          final dt = DateTime.fromMillisecondsSinceEpoch(args.value.toInt(),
              isUtc: false);
          return ChartAxisLabel(
              DateFormat("HH:mm").format(dt), const TextStyle());
        },
        labelStyle: TextStyle(
            color: widget.showXAxisLabel ? Colors.black : Colors.transparent,
            fontSize: widget.showXAxisLabel ? 12 : 0),
      ),
      primaryYAxis: primaryNumericAxis,
      axes: additionalAxes,
      trackballBehavior: trackballBehavior,
      zoomPanBehavior: ZoomPanBehavior(),
      legend: Legend(isVisible: false),
      series: widget.variableMap.entries
          .map<LineSeries<DrillingData, DateTime>>((entry) {
        return LineSeries<DrillingData, DateTime>(
          name: entry.key,
          color: widget.colorMap[entry.key],
          yAxisName: entry.key,
          dataSource: dataList,
          xValueMapper: (d, _) => d.dateTime,
          yValueMapper: (d, _) => entry.value(d),
          markerSettings: const MarkerSettings(isVisible: false),
          animationDuration: 0,
          animationDelay: 0,
          onRendererCreated: (ctl) {
            widget.controller.storeSeriesController(widget.mapString, ctl);
          },
        );
      }).toList(),
    );
  }
}
