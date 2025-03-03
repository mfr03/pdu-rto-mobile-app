import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_data.dart';

class ChartController extends GetxController {

  List<ChartData> chartData = [
    ChartData("A", 30),
    ChartData("B", 40),
    ChartData("C", 35),
  ];

  void addData(String category, double value) {

    chartData.add(
      ChartData(category, value)
    );
    update();
  }

  void updateData() {
    chartData = [
      ChartData("A", 45),
      ChartData("B", 25),
      ChartData("C", 55),
    ];
  }

}