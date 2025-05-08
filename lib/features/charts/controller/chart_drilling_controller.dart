import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../data/services/pdu_api/model/well_active.dart';

class DrillingController extends GetxController {

  final RxList<DrillingData> fullData = <DrillingData>[].obs;

  final RxList<DrillingData> displayedData = <DrillingData>[].obs;

  final RxMap<String, ChartSeriesController?> seriesControllers = <
      String,
      ChartSeriesController?>{}.obs;

  final int displayedDataPoints = 12 * 15;

  var currentIndex = 0.obs;

  bool _depthFirstCall = true;

  Future<void> initializeData({
    required WellActive wellActive
  }) async {
    final initialData = await PduApi.fetchRealtimeDataIncrement(
        wellActive: wellActive
    );

    fullData.clear();
    fullData.addAll(initialData);
    updateDisplayedData();
  }

  Future<void> initializeDepthData({
    required WellActive wellActive
 }) async {
    debugPrint("aaaa");
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);
    
    final ts = wellActive.timeStart;
    final te = wellActive.timeEnd;
    
    final data = await PduApi.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: ts,
        timeEnd: te, 
        depthStart: cfg.start, 
        depthEnd: cfg.end, 
        first: _depthFirstCall
    );
    
    if(data.isNotEmpty) {
      _depthFirstCall = false;
      fullData.clear();
      fullData.addAll(data);
      for(var res in data) {

      }
      final fmtStart = CFormatter.formatDateTime(data.first.dateTime);
      final fmtEnd = CFormatter.formatDateTime(data.last.dateTime);

      wellActive.updateTimeRange(fmtStart, fmtEnd);
    }

    updateDisplayedData();
    
  }

  void deleteData() {
    fullData.clear();
    displayedData.clear();
    currentIndex = 0.obs;
  }


  void updateDisplayedData() {
    final endIndex = currentIndex.value + displayedDataPoints;
    if (endIndex > fullData.length) {
      displayedData.assignAll(
          fullData.sublist(currentIndex.value, fullData.length));
    } else {
      displayedData.assignAll(fullData.sublist(currentIndex.value, endIndex));
    }
    // displayedData.refresh();
  }

  Future<bool> fastForward({required WellActive wellActive}) async {

    if (currentIndex.value + displayedDataPoints < fullData.length) {
      // Move forward by one data point.
      currentIndex.value+=12;
      updateDisplayedData();
      return true;
    }
    // No extra data exists locally; fetch the next 15 minutes of data (15 data points).
    final DateTime refTime = displayedData.isNotEmpty
        ? displayedData.last.dateTime
        : DateTime.now();

    final List<DrillingData> newData = await PduApi.fetchMoreData(
      token: wellActive.isApiToken,
      referenceTime: refTime,
      forward: true,
      count: 15,
    );

    if (newData.isEmpty) {
      // No new data from API.
      return false;
    }

    fullData.addAll(newData);
    currentIndex.value+=12;
    updateDisplayedData();
    return true;
  }

  Future<bool> fastForwardDepth({ required WellActive wellActive }) async {
    if (fullData.isEmpty) return false;
    final lastTime = fullData.last.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    final newData = await PduApi.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: CFormatter.formatDateTime(lastTime),
        timeEnd: CFormatter.formatDateTime(lastTime.add(Duration(minutes:15))),
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false
    );
    if (newData.isEmpty) return false;
    fullData.addAll(newData);
    updateDisplayedData();
    return true;
  }


  Future<bool> moveBackward({required WellActive wellActive}) async {
    const int blockSize = 15;

    if (currentIndex.value >= blockSize) {
      currentIndex.value -= blockSize;
      updateDisplayedData();
      return true;
    } else {

      DateTime referenceTime = displayedData.isNotEmpty
          ? displayedData.first.dateTime
          : DateTime.now();

      final List<DrillingData> olderData = await PduApi.fetchMoreData(
        token: wellActive.isApiToken,
        referenceTime: referenceTime.subtract(const Duration(minutes: 15)),
        forward: false,
        count: blockSize,
      );

      if (olderData.isEmpty) {
        return false;
      }

      fullData.insertAll(0, olderData);

      int newIndex = (currentIndex.value + olderData.length) - blockSize;
      if (newIndex < 0) newIndex = 0;

      currentIndex.value = newIndex;
      updateDisplayedData();
      return true;
    }
  }

  void reset() {
    currentIndex.value = 0;
    updateDisplayedData();
  }

  void storeSeriesController(String key, ChartSeriesController ctl) {
    seriesControllers[key] = ctl;
  }
}