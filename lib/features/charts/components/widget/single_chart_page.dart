import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';

import '../../controller/chart_drilling_controller.dart';
import '../../model/chart_drilling_data.dart';


class SingleChartPage extends StatefulWidget {
  final String title;
  final String mapString;
  final Map<String, num Function(DrillingData)> variableMap;
  final DrillingController controller;

  const SingleChartPage({
    super.key,
    required this.title,
    required this.mapString,
    required this.variableMap,
    required this.controller,
  });

  @override
  _SingleChartPageState createState() => _SingleChartPageState();
}

class _SingleChartPageState extends State<SingleChartPage>
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
    final trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(enable: true),
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      activationMode: ActivationMode.singleTap,
    );

    return SfCartesianChart(
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
          title: AxisTitle(text: 'Time')
      ),
      primaryYAxis: NumericAxis(opposedPosition: true),
      trackballBehavior: trackballBehavior,
      zoomPanBehavior: ZoomPanBehavior(),
      series: widget.variableMap.entries.map<LineSeries<DrillingData, DateTime>>((entry) {
        return LineSeries<DrillingData, DateTime>(
          name: entry.key,
          dataSource: dataList,
          xValueMapper: (d, _) => d.dateTime,
          yValueMapper: (d, _) => entry.value(d),
          markerSettings: const MarkerSettings(isVisible: false),
          onRendererCreated: (ctl) {
            widget.controller.storeSeriesController(widget.mapString, ctl);
          },
        );
      }).toList(),
    );
  }
}
