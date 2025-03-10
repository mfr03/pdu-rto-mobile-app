import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_data.dart';

class ChartController extends GetxController {

  final RxList<ChartData> fullData = <ChartData>[].obs;

  final RxList<ChartData> displayedData = <ChartData>[].obs;

  var currentIndex = 0.obs;

  final int displayedDataPoints = 3;

  ChartController() {

    fullData.addAll([
      ChartData("T1", 30),
      ChartData("T2", 40),
      ChartData("T3", 35),
      ChartData("T4", 45),
      ChartData("T5", 25),
      ChartData("T6", 55),
    ]);
    updateDisplayedData();
  }


  void updateDisplayedData() {
    int endIndex = currentIndex.value + displayedDataPoints;

    if (endIndex > fullData.length) {
      endIndex = fullData.length;
    }
    displayedData.assignAll(
      fullData.sublist(currentIndex.value, endIndex)
    );

  }

  void fastForward() {
    if(currentIndex.value + displayedDataPoints < fullData.length) {
      currentIndex++;
      updateDisplayedData();
    }
  }

  void moveBackward() {
    if(currentIndex.value > 0) {
      currentIndex.value--;
      updateDisplayedData();
    }
  }

  void reset() {
    currentIndex.value = 0;
    updateDisplayedData();
  }

}