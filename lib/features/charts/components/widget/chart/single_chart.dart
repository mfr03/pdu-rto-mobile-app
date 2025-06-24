import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdu_mobile_rto_app/common/components/circle.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/parameter_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
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
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      lineType: TrackballLineType.vertical,
      builder: (BuildContext context, TrackballDetails trackballDetails) {
        final int? pointIndex = trackballDetails.pointIndex;

        if (pointIndex == null ||
            pointIndex < 0 ||
            pointIndex >= widget.controller.displayedData.length) {
          return const SizedBox.shrink();
        }

        // Use the correct data model and list for the time chart
        final DrillingData drillData =
        widget.controller.displayedData[pointIndex];
        final String formattedDateTime =
        CFormatter.formatDateTime(drillData.dateTime);

        List<Widget> children = [];

        // Add the DateTime as a header.
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              formattedDateTime,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

        // Manually build the info for each series
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
                    style: const TextStyle(color: Colors.white, fontSize: 10),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final dataList = widget.controller.displayedData.toList();


      if (dataList.isEmpty) { // Add a check for empty data
        return Center(
          child: Text(
            "No data available for '${widget.title}'",
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      }


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

    final DateTime? chartMin = widget.controller.currentChunkStart.value;
    final DateTime? chartMax = widget.controller.currentChunkEnd.value;

    if (chartMin == null || chartMax == null) {
      return const Center(child: CircularProgressIndicator());
    }


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
        minimum: chartMin,
        maximum: chartMax,
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
      trackballBehavior: _trackballBehavior,
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
