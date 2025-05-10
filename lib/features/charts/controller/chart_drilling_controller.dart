import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../data/services/pdu_api/model/well_active.dart';

class DrillingController extends GetxController {
  // final RxList<DrillingData> fullData = <DrillingData>[].obs;

  final RxList<DrillingData> displayedData = <DrillingData>[].obs;
  final RxList<DepthDrillingData> displayedDataDepth = <DepthDrillingData>[].obs;

  final RxList<DrillingData> timeData = <DrillingData>[].obs;
  final RxList<DepthDrillingData> depthData = <DepthDrillingData>[].obs;

  final RxMap<String, ChartSeriesController?> seriesControllers = <String, ChartSeriesController?>{}.obs;

  final int displayedDataPoints = 12 * 15;

  var currentIndex = 0.obs;

  bool _depthFirstCall = true;

  Future<void> initializeData({
    required WellActive wellActive,
  }) async {
    if(timeData.isNotEmpty) {
      updateDisplayedData(mode: 'time');
    } else {
      final initialData = await PduApi.fetchRealtimeDataIncrement(wellActive: wellActive);
      // fullData.clear();
      // fullData.addAll(initialData);
      timeData.assignAll(initialData);  // Store in timeData
      updateDisplayedData(mode: 'time'); // Update the display for time data
    }

  }

  Future<void> initializeDepthData({
    required WellActive wellActive,
  }) async {
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);
    final ts = wellActive.timeStart;
    final te = wellActive.timeEnd;
    debugPrint(wellActive.timeStart);
    debugPrint(wellActive.timeEnd);
    final data = await PduApi.fetchDepthBasedData(
      token: wellActive.isApiToken,
      timeStart: ts,
      timeEnd: te,
      depthStart: cfg.start,
      depthEnd: cfg.end,
      first: true,
    );

    if (data.isNotEmpty) {
      _depthFirstCall = false;
      // fullData.clear();
      // fullData.addAll(data);
      depthData.assignAll(data);  // Store in depthData
    }
    updateDisplayedData(mode: 'depth'); // Update the display for depth data
  }

  void deleteData() {
    // fullData.clear();
    timeData.clear();
    depthData.clear();
    currentIndex = 0.obs;
  }

  void updateDisplayedData({required String mode}) {

    final endIndex = currentIndex.value + displayedDataPoints;

    if (mode == 'time') {
      if(endIndex > timeData.length) {
        displayedData.assignAll(timeData.sublist(currentIndex.value, timeData.length));
      } else {
        displayedData.assignAll(timeData.sublist(currentIndex.value, endIndex));
      }
    } else if (mode == 'depth') {
      if(endIndex > depthData.length) {
        displayedDataDepth.assignAll(depthData.sublist(currentIndex.value, depthData.length));
      } else {
        displayedDataDepth.assignAll(depthData.sublist(currentIndex.value, endIndex));
      }
    }
  }

  Future<bool> fastForwardTime({required WellActive wellActive}) async {
    if (currentIndex.value + displayedDataPoints < timeData.length) {
      currentIndex.value += 12;
      updateDisplayedData(mode: 'time'); // Update the displayed data for time mode
      return true;
    }

    final DateTime refTime = timeData.isNotEmpty ? timeData.last.dateTime : DateTime.now();
    final List<DrillingData> newData = await PduApi.fetchMoreData(
      token: wellActive.isApiToken,
      referenceTime: refTime,
      forward: true,
      count: 15,
    );

    if (newData.isEmpty) {
      return false;
    }
    timeData.addAll(newData);
    currentIndex.value += 12;
    updateDisplayedData(mode: 'time'); // Update the displayed data for time mode
    return true;
  }

  Future<bool> fastForwardDepth({required WellActive wellActive}) async {
    if (depthData.isEmpty) return false;

    final lastTime = depthData.last.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    final newData = await PduApi.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: CFormatter.formatDateTime(lastTime),
        timeEnd: CFormatter.formatDateTime(lastTime.add(Duration(minutes: 15))),
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false
    );
    if (newData.isEmpty) return false;

    depthData.addAll(newData);
    updateDisplayedData(mode: 'depth'); // Update the displayed data for depth mode
    return true;
  }

  Future<bool> moveBackward({required WellActive wellActive, required String mode}) async {
    // const int blockSize = 15;
    //
    // List<DrillingData> dataToMove = mode == 'time' ? timeData : depthData;
    //
    // if (currentIndex.value >= blockSize) {
    //   currentIndex.value -= blockSize;
    //   updateDisplayedData(mode: mode); // Update the displayed data
    //   return true;
    // } else {
    //   DateTime referenceTime = dataToMove.isNotEmpty
    //       ? dataToMove.first.dateTime
    //       : DateTime.now();
    //
    //   final List<DrillingData> olderData = await PduApi.fetchMoreData(
    //     token: wellActive.isApiToken,
    //     referenceTime: referenceTime.subtract(const Duration(minutes: 15)),
    //     forward: false,
    //     count: blockSize,
    //   );
    //
    //   if (olderData.isEmpty) {
    //     return false;
    //   }
    //
    //   // fullData.insertAll(0, olderData);
    //
    //   int newIndex = (currentIndex.value + olderData.length) - blockSize;
    //   if (newIndex < 0) newIndex = 0;
    //
    //   currentIndex.value = newIndex;
    //   updateDisplayedData(mode: mode); // Update the displayed data
    //   return true;
    // }
    return true;
  }

  void resetData() {
    timeData.clear();
    depthData.clear();
    currentIndex.value = 0;
    updateDisplayedData(mode: 'time'); // Default to time data when reset
  }

  void storeSeriesController(String key, ChartSeriesController ctl) {
    seriesControllers[key] = ctl;
  }
}