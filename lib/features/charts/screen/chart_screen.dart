import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';
import '../../../features/charts/controller/chart_controller.dart';
import '../../../features/charts/model/chart_data.dart';
import '../../../utils/constants/text_string.dart';

class ChartScreen extends StatelessWidget {
  final ChartController chartService = Get.put(ChartController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Syncfusion Chart with GetX')),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              return SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                trackballBehavior: TrackballBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  tooltipSettings: InteractiveTooltip(enable: true)
                ),
                series: <CartesianSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: chartService.displayedData.toList(),
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                    markerSettings: MarkerSettings(isVisible: true),
                  ),
                ],
              );
            }),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  onPressed: chartService.moveBackward,
                  child: const Text(CText.backwards)
              ),
              ElevatedButton(
                  onPressed: chartService.reset,
                  child: const Text(CText.reset)
              ),
              ElevatedButton(
                  onPressed: chartService.fastForward,
                  child: const Text(CText.forwards)
              )
            ],
          )


        ],
      ),
    );
  }
}
