import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/charts/controller/chart_drilling_controller.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_drilling_data.dart';


class DrillingChartScreen extends StatelessWidget {
  final DrillingController controller = Get.put(DrillingController());
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Single'),
      ),
      body: Stack(
        children: [
          Obx(() {

            final page1 = _buildSingleChartPage(
              title: 'Mechanical Track',
              mapString: 'mechanical',
              variableMap: _mechanicalVariables,
            );
            final page2 = _buildSingleChartPage(
              title: 'Mud/Fluid Track',
              mapString: 'mud',
              variableMap: _mudVariables,
            );
            final page3 = _buildSingleChartPage(
              title: 'Gas Track',
              mapString: 'gas',
              variableMap: _gasVariables,
            );
            final page4 = _buildSingleChartPage(
              title: 'Temperature Track',
              mapString: 'temperature',
              variableMap: _tempVariables,
            );

            return PageView(
              controller: _pageController,
              children: [page1, page2, page3, page4],
            );
          }),

          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.fast_rewind),
                    onPressed: controller.moveBackward,
                    tooltip: 'Backward',
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: controller.reset,
                    tooltip: 'Refresh',
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.fast_forward),
                    onPressed: controller.fastForward,
                    tooltip: 'Forward',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleChartPage({
    required String title,
    required String mapString,
    required Map<String, num Function(DrillingData)> variableMap,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: _buildTrackChart(
        title: title,
        mapString: mapString,
        variableMap: variableMap,
      ),
    );
  }

  Widget _buildTrackChart({
    required String title,
    required String mapString,
    required Map<String, num Function(DrillingData)> variableMap,
  }) {

    final TrackballBehavior trackballBehavior = TrackballBehavior(
      enable: true,
      tooltipSettings: const InteractiveTooltip(enable: true),
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      activationMode: ActivationMode.singleTap,
    );

    return SfCartesianChart(
      isTransposed: true, // rotate X=vertical, Y=horizontal
      title: ChartTitle(
        text: title,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
      legend: Legend(isVisible: true),
      plotAreaBorderWidth: 1,
      plotAreaBorderColor: Colors.grey,

      primaryXAxis: DateTimeAxis(
        isVisible: true,
        isInversed: true,
      ),

      primaryYAxis: NumericAxis(
        opposedPosition: true,
      ),

      trackballBehavior: trackballBehavior,
      zoomPanBehavior: ZoomPanBehavior(

      ),

      series: _generateSeriesList(
        controller.displayedData.toList(),
        variableMap,
        mapString,
      ),
    );
  }

  List<CartesianSeries<dynamic, dynamic>> _generateSeriesList(
      List<DrillingData> data,
      Map<String, num Function(DrillingData)> variableMap,
      String mapString,
      ) {
    return variableMap.entries
        .map<LineSeries<DrillingData, DateTime>>((entry) {
      return LineSeries<DrillingData, DateTime>(
        name: entry.key,
        dataSource: data,
        xValueMapper: (DrillingData d, _) => d.dateTime,
        yValueMapper: (DrillingData d, _) => entry.value(d),
        markerSettings: const MarkerSettings(isVisible: true),
        onRendererCreated: (ChartSeriesController ctl) {
          controller.storeSeriesController(mapString, ctl);
        },
      );
    }).toList();
  }

  Map<String, num Function(DrillingData)> get _mechanicalVariables => {
    'BitDepth (m)': (d) => d.bitDepth,
    'WOB (klb)': (d) => d.wob,
    'Torque (klb.ft)': (d) => d.torque,
    'RPM': (d) => d.rpm,
    'Hkld (klb)': (d) => d.hkld,
  };

  Map<String, num Function(DrillingData)> get _mudVariables => {
    'MudFlowIn (gpm)': (d) => d.mudFlowIn,
    'MudFlowOutp': (d) => d.mudFlowOutp,
    'MudCondIn (mmho)': (d) => d.mudCondIn,
    'MudCondOut (mmho)': (d) => d.mudCondOut,
    'SpPress (Psi)': (d) => d.spPress,
    'TankVolTot (bbl)': (d) => d.tankVolTot,
  };

  Map<String, num Function(DrillingData)> get _gasVariables => {
    'H2S_1 (ppm)': (d) => d.h2s_1,
    'CO2_1 (%)': (d) => d.co2_1,
    'Gas (%)': (d) => d.gas,
  };

  Map<String, num Function(DrillingData)> get _tempVariables => {
    'MudTempIn (C)': (d) => d.mudTempIn,
    'MudTempOut (C)': (d) => d.mudTempOut,
  };
}