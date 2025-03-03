import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';
import '../../../features/charts/controller/chart_controller.dart';
import '../../../features/charts/model/chart_data.dart';


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
                series: <CartesianSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: chartService.chartData,
                    xValueMapper: (ChartData data, _) => data.category,
                    yValueMapper: (ChartData data, _) => data.value,
                  ),
                ],
              );
            }),
          ),
          ElevatedButton(
            onPressed: () => chartService.updateData(),
            child: Text("Update Chart"),
          ),
        ],
      ),
    );
  }
}
