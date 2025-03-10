import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/features/charts/model/chart_drilling_data.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DrillingController extends GetxController {

  final RxList<DrillingData> fullData = <DrillingData>[].obs;

  final RxList<DrillingData> displayedData = <DrillingData>[].obs;

  final RxMap<String, ChartSeriesController?> seriesControllers = <String, ChartSeriesController?>{}.obs;

  final int displayedDataPoints = 20;


  var currentIndex = 0.obs;

  DrillingController() {

    fullData.addAll(_generateDummyData());
    updateDisplayedData();
  }

  void updateDisplayedData() {
    int endIndex = currentIndex.value + displayedDataPoints;
    if (endIndex > fullData.length) {
      endIndex = fullData.length;
    }

    if (currentIndex.value < fullData.length) {
      displayedData.assignAll(
        fullData.sublist(currentIndex.value, endIndex),
      );
    }

  }

  void fastForward() {
    if (currentIndex.value + displayedDataPoints < fullData.length) {
      currentIndex.value++;
      updateDisplayedData();
    }
  }


  void moveBackward() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      updateDisplayedData();
    }
  }

  void reset() {
    currentIndex.value = 0;
    updateDisplayedData();
  }

  void storeSeriesController(String key, ChartSeriesController ctl) {
    seriesControllers[key] = ctl;
  }

  List<DrillingData> _generateDummyData() {
    final List<DrillingData> dummy = [];
    final now = DateTime.now();
    for (int i = 0; i < 100; i++) {
      dummy.add(DrillingData(
        dateTime: now.add(Duration(minutes: i)),
        bitDepth: (i * 5).toDouble(),
        scfm: 50 + i.toDouble(),
        mudCondIn: 1000 + (i * 5).toDouble(),
        blockPos: (i * 1.2),
        wob: 10 + i.toDouble(),
        ropi: 20 + (i * 0.5),
        bvDepth: (i * 2.2),
        mudCondOut: 900 + (i * 5).toDouble(),
        torque: 5 + (i * 0.25),
        rpm: 100 + (i % 5),
        hkld: 15 + i.toDouble(),
        logDepth: (i * 5).toDouble(),
        h2s_1: i.toDouble(),
        mudFlowOutp: 150.0 + i,
        totSPM: 30.0 + i,
        spPress: 800 + i.toDouble() * 2,
        mudFlowIn: 200.0 + i,
        co2_1: 0.5 + (i * 0.01),
        gas: 1.0 + (i * 0.02),
        mudTempIn: 30 + i * 0.1,
        mudTempOut: 40 + i * 0.1,
        tankVolTot: 500 + (i * 10),
      ));
    }
    return dummy;
  }


}
