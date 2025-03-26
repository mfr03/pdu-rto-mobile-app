import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';

import '../../controller/chart_drilling_controller.dart';
import '../../model/chart_drilling_data.dart';

class SingleDepthChartPage extends StatefulWidget {
  final String title;
  final Map<String, num Function(DrillingData)> variableMap;
  final DrillingController controller;
  final Map<String, Color> colorMap;

  const SingleDepthChartPage({
    Key? key,
    required this.title,
    required this.variableMap,
    required this.controller,
    required this.colorMap,
  }) : super(key: key);

  @override
  _SingleDepthChartPageState createState() => _SingleDepthChartPageState();
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
      return Container(
        padding: const EdgeInsets.all(8),
        child: _buildDepthChart(dataList),
      );
    });
  }

  Widget _buildDepthChart(List<DrillingData> dataList) {
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

      // NumericAxis for depth
      primaryXAxis: NumericAxis(
        isVisible: true,
        isInversed: true, // so deeper depths appear lower or "further along"
        title: AxisTitle(text: 'Depth (m)'),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
      ),

      trackballBehavior: trackballBehavior,
      zoomPanBehavior: ZoomPanBehavior(),

      // Each entry in variableMap yields one line
      series: widget.variableMap.entries.map((entry) {
        return LineSeries<DrillingData, num>(
          color: widget.colorMap[entry.key],
          name: entry.key,
          dataSource: dataList,
          xValueMapper: (d, _) => d.bitDepth,
          yValueMapper: (d, _) => entry.value(d),
          markerSettings: const MarkerSettings(isVisible: false),
          onRendererCreated: (ctl) {
            // Optionally store the controller for dynamic updates
            widget.controller.storeSeriesController(widget.title, ctl);
          },
        );
      }).toList(),
    );
  }
}