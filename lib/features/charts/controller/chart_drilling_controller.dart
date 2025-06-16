import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/app_notification_info.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/snackbar_notification.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:pdu_mobile_rto_app/utils/well_utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import '../../../data/services/pdu_api/model/well_active.dart';

class DrillingController extends GetxController {

  final PduApi api = GetIt.I<PduApi>();
  final RxList<DrillingData> displayedData = <DrillingData>[].obs;
  final RxList<DepthDrillingData> displayedDataDepth = <DepthDrillingData>[].obs;

  final RxList<DrillingData> liveTimeData = <DrillingData>[].obs;
  final RxList<DrillingData> historicalTimeData = <DrillingData>[].obs;
  final RxList<DepthDrillingData> depthData = <DepthDrillingData>[].obs;

  final Rx<DrillingData?> latestLiveTimeDataPoint = Rx<DrillingData?>(null);

  final RxMap<String, ChartSeriesController?> seriesControllers = <String, ChartSeriesController?>{}.obs;

  final int displayedDataPoints = 12 * 15;
  final int depthChartBlockSize = 15;

  var timeChartCurrentIndex = 0.obs;
  var depthChartCurrentIndex = 0.obs;
  static const int _maxLiveTimeDataPoints = 240;
  static const int _maxHistoricalLivePointsToKeep = 1000;

  WellActive? _currentActiveWell;

  Box<ParameterNotificationSetting>? _notificationSettingsBox;
  final Rx<AppNotificationInfo?> latestAppNotification = Rx<AppNotificationInfo?>(null);

  final Rx<SnackbarNotification?> transientNotification = Rx<SnackbarNotification?>(null);

  List<ParameterNotificationSetting> _currentWellEnabledSettings = [];
  final int notificationCooldownMinutes = 0; // Cooldown period

  Timer? _realtimeHomeTimer;

  var currentIndex = 0.obs;

  bool _depthFirstCall = true;
  var isTimeChartLive = true.obs;

  // State for when live data fetch fails.
  var liveDataFetchFailed = false.obs;
  // REVISED: A single loading flag for any data fetch on the home screen.
  var isHomeScreenLoading = false.obs;

  void _setLiveMode(bool isLive, {String source = 'Unknown'})
  {
    if (isTimeChartLive.value != isLive) {
      debugPrint(
          "CONTROLLER: Live mode changing to $isLive from source: $source");
      isTimeChartLive.value = isLive;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // This listener will activate whenever 'timeChartCurrentIndex' changes.
    timeChartCurrentIndex.listen((newIndex) {
      // This will print to the console every time the index changes.
      debugPrint(
          "--- INDEX LISTENER: timeChartCurrentIndex changed to $newIndex ---");

      // This will print the "call stack" - the sequence of functions
      // that led to the index changing. This will show us the culprit.
      debugPrintStack(label: 'Call Stack:', maxFrames: 15);

      debugPrint("--- END OF STACK TRACE ---");
    });
  }

  @override
  void onClose() { // <-- ADD THIS LIFECYCLE METHOD
    stopLiveUpdates();
    super.onClose();
  }

  void startLiveUpdates({required WellActive wellActive}) {
    stopLiveUpdates(); // Stop any existing timer first
    _realtimeHomeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      print("TIMER TICK: Fetching latest live data...");
      fetchAndUpdateLatestLiveTimeData(wellActive: wellActive);
    });
  }

  void stopLiveUpdates() {
    _realtimeHomeTimer?.cancel();
    _realtimeHomeTimer = null;
    print("TIMER STOPPED");
  }

  Future<void> initializeData({
    required WellActive wellActive,
  }) async
  {
    // Path A: For a LIVE well, if historicalTimeData already has points (likely from timer appends)
    if (historicalTimeData.isNotEmpty && !isWellCompleted(wellActive: wellActive)) {
      print("CONTROLLER: initializeData - Live well, historicalTimeData already has ${historicalTimeData.length} points. Updating display.");
      updateDisplayedTimeChartData(); // This should populate displayedData
      return;
    }
    // Path B: For a COMPLETED well, if historicalTimeData already has points
    if (historicalTimeData.isNotEmpty && isWellCompleted(wellActive: wellActive)) {
      print("CONTROLLER: initializeData - Completed well, historicalTimeData already has ${historicalTimeData.length} points. Updating display.");
      updateDisplayedTimeChartData(); // This should populate displayedData
      return;
    }

    // Path C: historicalTimeData is EMPTY (or conditions above not met), so fetch initial historical block.
    print("CONTROLLER: initializeData - historicalTimeData is empty or forced fetch. Fetching with fetchRealtimeDataIncrement for ${wellActive.wellName}");
    final data = await api.fetchRealtimeDataIncrement(wellActive: wellActive);
    print("CONTROLLER: initializeData - Data fetched by fetchRealtimeDataIncrement. Count: ${data.length}");

    historicalTimeData.assignAll(data);
    print("CONTROLLER: initializeData - historicalTimeData assigned. Length: ${historicalTimeData.length}");

    if (historicalTimeData.isNotEmpty) {
      timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints)
          ? historicalTimeData.length - displayedDataPoints // Show latest part
          : 0;
    } else {
      timeChartCurrentIndex.value = 0;
    }
    print("CONTROLLER: initializeData - timeChartCurrentIndex set to: ${timeChartCurrentIndex.value}");
    updateDisplayedTimeChartData(); // This populates displayedData
  }

  Future<void> initializeDepthData({
    required WellActive wellActive,
  }) async
  {
    if (depthData.isNotEmpty) {
      updateDisplayedDepthChartData();
      _depthFirstCall = false;
      return;
    }

    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);
    final ts = wellActive.timeStart;
    final te = wellActive.timeEnd;
    final ds = cfg.start;
    final de = cfg.end;

    print("DEBUG: Fetching depth data for well: ${wellActive.wellName}, Token: ${wellActive.isApiToken}");
    print("DEBUG: Time Range: Start = $ts, End = $te");
    print("DEBUG: Depth Range: Start = $ds, End = $de");
    print("DEBUG: First Call: $_depthFirstCall");


    final data = await api.fetchDepthBasedData(
      token: wellActive.isApiToken,
      timeStart: ts, timeEnd: te,
      depthStart: cfg.start, depthEnd: cfg.end,
      first: _depthFirstCall,
    );





    if (data.isNotEmpty) {
      _depthFirstCall = false;
      depthData.assignAll(data);
    } else {
      _depthFirstCall = false;
    }
    depthChartCurrentIndex.value = 0;
    updateDisplayedDepthChartData();
  }


  Future<void> initializeLiveTimeData({required WellActive wellActive}) async {
    isHomeScreenLoading.value = true; // Set loading to true
    try {
      // Reset state before fetching
      liveDataFetchFailed.value = false;
      liveTimeData.clear();
      historicalTimeData.clear();
      latestLiveTimeDataPoint.value = null;

      final DateTime now = DateTime.now();
      final DateTime startTime = now.subtract(const Duration(minutes: 15));
      final String timeStartStr = CFormatter.formatDateTime(startTime);
      final String timeEndStr = CFormatter.formatDateTime(now);

      print("CONTROLLER: initializeLiveTimeData - Attempting to fetch initial LIVE window.");
      final data = await api.fetchRealtimeDataOnce(
          token: wellActive.isApiToken,
          timeStart: timeStartStr,
          timeEnd: timeEndStr
      );

      if (data.isNotEmpty) {
        print("CONTROLLER: initializeLiveTimeData - SUCCESS, found ${data.length} live data points.");
        liveTimeData.assignAll(data);
        latestLiveTimeDataPoint.value = liveTimeData.last;

        historicalTimeData.assignAll(data);
        if (historicalTimeData.length > displayedDataPoints) {
          timeChartCurrentIndex.value = historicalTimeData.length - displayedDataPoints;
        } else {
          timeChartCurrentIndex.value = 0;
        }
        updateDisplayedTimeChartData();
        _setLiveMode(true, source: 'initializeLiveTimeData');
        startLiveUpdates(wellActive: wellActive);
      } else {
        print("CONTROLLER: initializeLiveTimeData - FAILED, no live data found.");
        liveDataFetchFailed.value = true;
        _setLiveMode(false, source: 'initializeLiveTimeData - failed');
        stopLiveUpdates(); // <-- STOP THE TIMER ON FAILURE
      }
    } finally {
      isHomeScreenLoading.value = false; // Set loading to false
    }
  }

  Future<void> loadHistoricalData({required WellActive wellActive}) async {
    isHomeScreenLoading.value = true; // Set loading to true
    try {
      stopLiveUpdates();
      liveDataFetchFailed.value = false;
      liveTimeData.clear();
      latestLiveTimeDataPoint.value = null;

      print("CONTROLLER: loadHistoricalData - User initiated historical data load.");

      final data = await api.fetchRealtimeDataIncrement(wellActive: wellActive);

      if (data.isNotEmpty) {
        print("CONTROLLER: loadHistoricalData - SUCCESS, found ${data.length} historical points.");
        historicalTimeData.assignAll(data);
        if (historicalTimeData.length > displayedDataPoints) {
          timeChartCurrentIndex.value = historicalTimeData.length - displayedDataPoints;
        } else {
          timeChartCurrentIndex.value = 0;
        }

        final lastChunk = historicalTimeData.sublist(
            math.max(0, historicalTimeData.length - _maxLiveTimeDataPoints)
        );
        liveTimeData.assignAll(lastChunk);
        if (liveTimeData.isNotEmpty) {
          latestLiveTimeDataPoint.value = liveTimeData.last;
        }

      } else {
        print("CONTROLLER: loadHistoricalData - FAILED, no historical data found either.");
        historicalTimeData.clear();
        liveTimeData.clear();
        latestLiveTimeDataPoint.value = null;
      }

      updateDisplayedTimeChartData();
      _setLiveMode(false, source: 'loadHistoricalData');
    } finally {
      isHomeScreenLoading.value = false; // Set loading to false
    }
  }

  Future<void> searchDataByTimeRange({
    required WellActive wellActive,
    required DateTime startTime,
    required DateTime endTime,
    required String mode,
  }) async
  {
    if (mode == 'time') {
      final searchResult = await api.fetchAbsoluteTimeRangeData(
        token: wellActive.isApiToken,
        startTime: startTime,
        endTime: endTime,
      );

      // This logic will now correctly show the snackbar on an empty result.
      if (searchResult.isEmpty) {
        transientNotification.value = SnackbarNotification(
            title: 'No Data',
            message: 'No time-based data found for the selected range.'
        );
        return;
      }

      if (historicalTimeData.any((p) => p.dateTime == searchResult.first.dateTime)) {
        transientNotification.value = SnackbarNotification(
          title: 'Data Exists',
          message: 'The requested data is already loaded.',
        );
        return;
      }

      historicalTimeData.assignAll(searchResult);
      timeChartCurrentIndex.value = 0;
      _setLiveMode(false, source: 'searchDataByTimeRange');
      updateDisplayedTimeChartData();

      transientNotification.value = SnackbarNotification(
        title: 'Success',
        message: 'Data loaded for the selected time range.',
      );

    } else { // mode == 'depth'
      final searchResult = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: CFormatter.formatDateTime(startTime),
        timeEnd: CFormatter.formatDateTime(endTime),
        depthStart: 0,
        depthEnd: 99999,
        first: false,
      );

      // This logic will now correctly show the snackbar on an empty result.
      if (searchResult.isEmpty) {
        transientNotification.value = SnackbarNotification(
          title: 'No Data',
          message: 'No depth-based data found for the selected range.',
        );
        return;
      }

      if (depthData.any((p) => p.dateTime == searchResult.first.dateTime)) {

        transientNotification.value = SnackbarNotification(
          title: 'Data Exists',
          message: 'The requested data is already loaded.',
        );

        return;
      }

      // --- THIS IS THE FIX ---

      // 1. Replace the contents of the depthData list with the search results.
      depthData.assignAll(searchResult);

      // 2. Force the reactive system to acknowledge the change.
      depthData.refresh();

      // 3. Reset the chart view to the beginning of the new data.
      depthChartCurrentIndex.value = 0;
      updateDisplayedDepthChartData();

      // 4. Notify the user of success.
      transientNotification.value = SnackbarNotification(
        title: 'Success',
        message: 'Data loaded for the selected time range.',
      );
    }
  }

  Future<void> fetchAndUpdateLatestLiveTimeData(
      {required WellActive wellActive}) async {
    if (!isTimeChartLive.value) {
      print("TIMER SKIPPED: Not in live mode.");
      return;
    }

    final DateTime now = DateTime.now();
    DateTime startTimeQuery;

    if (historicalTimeData.isNotEmpty) {
      startTimeQuery = historicalTimeData.last.dateTime;
    } else {
      startTimeQuery = now.subtract(const Duration(minutes: 2));
    }

    if (startTimeQuery.isAfter(now)) {
      startTimeQuery = now.subtract(const Duration(seconds: 30));
    }

    final String timeStartStr = CFormatter.formatDateTime(startTimeQuery);
    final String timeEndStr = CFormatter.formatDateTime(now);

    final newData = await api.fetchRealtimeDataOnce(
      token: wellActive.isApiToken,
      timeStart: timeStartStr,
      timeEnd: timeEndStr,
    );

    if (newData.isNotEmpty) {
      print("DATA REFRESH: Found ${newData.length} new data points.");

      final currentDataMap = { for (var p in historicalTimeData) p.dateTime: p };
      for (var newPoint in newData) {
        currentDataMap[newPoint.dateTime] = newPoint;
      }

      final fullNewList = currentDataMap.values.toList();
      fullNewList.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      historicalTimeData.assignAll(fullNewList);

      final liveChunk = (fullNewList.length > _maxLiveTimeDataPoints)
          ? fullNewList.sublist(fullNewList.length - _maxLiveTimeDataPoints)
          : fullNewList;

      liveTimeData.assignAll(liveChunk);

      // Update the reactive variable
      latestLiveTimeDataPoint.value = liveTimeData.last;

      // --- THIS IS THE FIX ---
      // Force all widgets listening to 'latestLiveTimeDataPoint' to rebuild.
      // This bypasses the faulty '==' check on the DrillingData object.
      latestLiveTimeDataPoint.refresh();

      // Update the chart if we are in live mode
      if (isTimeChartLive.value) {
        timeChartCurrentIndex.value =
        (historicalTimeData.length > displayedDataPoints)
            ? historicalTimeData.length - displayedDataPoints
            : 0;
        updateDisplayedTimeChartData();
      }
    } else {
      print("DATA REFRESH: No new data points found.");
    }
  }

  void updateDisplayedTimeChartData() {
    if (historicalTimeData.isEmpty) {
      displayedData.clear();
      return;
    }

    // This is the only check we need for the lower bound.
    if (timeChartCurrentIndex.value < 0) {
      timeChartCurrentIndex.value = 0;
    }

    // --- THIS IS THE CRUCIAL FIX ---
    // Previously, there was a check here that would wrongly jump to the end.
    // Now, if the index is ever invalid (which shouldn't happen, but as a failsafe),
    // we simply log it and do nothing. This PREVENTS the unwanted scroll.
    if (timeChartCurrentIndex.value >= historicalTimeData.length) {
      debugPrint(
          "DrillingController: Warning - Attempted to update chart with an invalid index (${timeChartCurrentIndex.value}). Preventing update to stop unwanted scroll.");
      return; // Do not update the chart, preserving the user's view.
    }
    // ---------------------------------

    final int startIndex = timeChartCurrentIndex.value;
    int endIndex = startIndex + displayedDataPoints;

    // A final, safe check on the end index before creating the sublist.
    if (endIndex > historicalTimeData.length) {
      endIndex = historicalTimeData.length;
    }

    displayedData.assignAll(historicalTimeData.sublist(startIndex, endIndex));
  }

  void updateDisplayedDepthChartData() {
    if (depthData.isEmpty) {
      displayedDataDepth.clear();
      return;
    }
    // Ensure depthChartCurrentIndex is valid
    if (depthChartCurrentIndex.value >= depthData.length) {
      depthChartCurrentIndex.value = (depthData.length > displayedDataPoints) ? depthData.length - displayedDataPoints : 0;
    }
    if (depthChartCurrentIndex.value < 0) depthChartCurrentIndex.value = 0;

    final int endIndex = depthChartCurrentIndex.value + displayedDataPoints;
    if (endIndex > depthData.length) {
      displayedDataDepth.assignAll(depthData.sublist(depthChartCurrentIndex.value));
    } else {
      displayedDataDepth.assignAll(depthData.sublist(depthChartCurrentIndex.value, endIndex));
    }
  }


  Future<bool> fastForwardTimeChart({required WellActive wellActive}) async {
    if (historicalTimeData.isEmpty) return false;

    final maxIndex = math.max(0, historicalTimeData.length - displayedDataPoints);

    if (timeChartCurrentIndex.value < maxIndex) {
      final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
      final currentViewStartTime =
          historicalTimeData[timeChartCurrentIndex.value].dateTime;
      final targetStartTime =
      currentViewStartTime.add(Duration(minutes: traversalMinutes));

      final newIndex =
      historicalTimeData.indexWhere((p) => p.dateTime.isAfter(targetStartTime));

      if (newIndex != -1) {
        final onePageForward = timeChartCurrentIndex.value + displayedDataPoints;
        final cappedNewIndex = math.min(newIndex, onePageForward);
        timeChartCurrentIndex.value = math.min(cappedNewIndex, maxIndex);
        updateDisplayedTimeChartData();

        // --- THIS IS THE FIX ---
        // After moving forward, check if we have landed on the last page.
        // If so, re-enable live mode automatically.
        if (timeChartCurrentIndex.value == maxIndex) {
          _setLiveMode(true, source: 'fastForwardTimeChart - reached end of loaded data');
          // We can also trigger a notification to inform the user.
          transientNotification.value = SnackbarNotification(
              title: 'Live Mode Re-engaged',
              message: 'You have reached the end of the loaded data.'
          );
        }
        // -----------------------

        return true;
      }
    }


    final apiFetchMinutes = math.min(await ChartSettingsService.loadTraversalUnit(), 15);
    final DateTime refTime = historicalTimeData.last.dateTime;

    final List<DrillingData> newData = await api.fetchMoreData(
      token: wellActive.isApiToken,
      referenceTime: refTime,
      forward: true,
      count: apiFetchMinutes,
    );

    if (newData.isEmpty) {
      _setLiveMode(true, source: 'fastForwardTimeChart - API returned no new data');
      transientNotification.value = SnackbarNotification(
          title: 'All Data Loaded',
          message: 'You have reached the latest available data.'
      );
      return false;
    }

    historicalTimeData.addAll(newData);
    final newMaxIndex = math.max(0, historicalTimeData.length - displayedDataPoints);
    timeChartCurrentIndex.value = math.min(historicalTimeData.length - newData.length, newMaxIndex);
    updateDisplayedTimeChartData();
    return true;
  }

  Future<bool> moveBackwardTimeChart({required WellActive wellActive}) async {
    _setLiveMode(false, source: 'moveBackwardTimeChart');
    stopLiveUpdates();

    if (timeChartCurrentIndex.value > 0) {
      final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
      final currentViewStartTime =
          historicalTimeData[timeChartCurrentIndex.value].dateTime;
      final targetStartTime =
      currentViewStartTime.subtract(Duration(minutes: traversalMinutes));

      final newIndex = historicalTimeData
          .lastIndexWhere((p) => !p.dateTime.isAfter(targetStartTime));

      if (newIndex != -1) {
        timeChartCurrentIndex.value = newIndex;
        updateDisplayedTimeChartData();
        return true;
      } else {
        timeChartCurrentIndex.value = 0;
        updateDisplayedTimeChartData();
      }
    }

    if (historicalTimeData.isEmpty) return false;

    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final apiFetchMinutes = math.min(traversalMinutes, 15);

    final DateTime referenceTime = historicalTimeData.first.dateTime;
    final List<DrillingData> olderData = await api.fetchMoreData(
      token: wellActive.isApiToken,
      referenceTime: referenceTime,
      forward: false,
      count: apiFetchMinutes,
    );

    if (olderData.isEmpty) {
      return false;
    }

    historicalTimeData.insertAll(0, olderData);
    timeChartCurrentIndex.value = 0;
    updateDisplayedTimeChartData();
    return true;
  }

  void resetHistoricalTimeData() {
    // This now directly jumps to the latest "live" view without clearing data
    if (historicalTimeData.isNotEmpty) {
      timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints)
          ? historicalTimeData.length - displayedDataPoints
          : 0;
      isTimeChartLive.value = true; // Re-enable live mode
      updateDisplayedTimeChartData();
    }
  }

  void deleteData() {
    liveTimeData.clear();
    latestLiveTimeDataPoint.value = null;
    historicalTimeData.clear();
    depthData.clear();
    displayedData.clear();
    displayedDataDepth.clear();
    timeChartCurrentIndex.value = 0;
    depthChartCurrentIndex.value = 0;
    liveDataFetchFailed.value = false; // Reset the state on delete
    isHomeScreenLoading.value = false; // Also reset here
    _depthFirstCall = true;
    stopLiveUpdates();
  }

  Future<void> resetDepthChart({required WellActive wellActive}) async {
    depthData.clear();
    _depthFirstCall = true; // Ensure the next fetch is a 'first' call
    depthChartCurrentIndex.value = 0;
    await initializeDepthData(wellActive: wellActive);
  }

  Future<bool> fastForwardDepthChart({required WellActive wellActive}) async {
    // 1. First, try to traverse locally
    final nextIndex = depthChartCurrentIndex.value + depthChartBlockSize;
    if (nextIndex < depthData.length) {
      depthChartCurrentIndex.value = nextIndex;
      updateDisplayedDepthChartData();
      return true;
    }

    // 2. If at the edge, fetch new data from the API
    if (depthData.isEmpty) return false;

    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);
    final lastTime = depthData.last.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    // Define the time range for the request
    final timeStart = CFormatter.formatDateTime(lastTime);
    final timeEnd = CFormatter.formatDateTime(lastTime.add(amount));

    final newData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: timeStart,
        timeEnd: timeEnd,
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false);

    if (newData.isEmpty) {
      transientNotification.value = SnackbarNotification(
        title: 'All Data Loaded',
        message: 'You have reached the latest available data.',
      );
      return false;
    }

    if (depthData.any((p) => p.dateTime.millisecondsSinceEpoch == newData.first.dateTime.millisecondsSinceEpoch)) {
      final startTimeString = DateFormat('HH:mm:ss').format(lastTime);
      final endTimeString = DateFormat('HH:mm:ss').format(lastTime.add(amount));
      transientNotification.value = SnackbarNotification(
        title: 'Data Loaded',
        message: 'Data for range $startTimeString - $endTimeString is already present.',
      );
      return false;
    }

    // 3. Add new data and move the view to the new end
    depthData.addAll(newData);
    depthChartCurrentIndex.value = (depthData.length > displayedDataPoints)
        ? depthData.length - displayedDataPoints
        : 0;
    updateDisplayedDepthChartData();
    return true;
  }

  Future<bool> moveBackwardDepthChart({required WellActive wellActive}) async {
    // 1. First, try to traverse locally
    if (depthChartCurrentIndex.value > 0) {
      depthChartCurrentIndex.value = math.max(0, depthChartCurrentIndex.value - depthChartBlockSize);
      updateDisplayedDepthChartData();
      return true;
    }

    // 2. If at the start, fetch older data from the API
    if (depthData.isEmpty) return false;

    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);
    final firstTime = depthData.first.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    // Define the time range for the request
    final timeStart = CFormatter.formatDateTime(firstTime.subtract(amount));
    final timeEnd = CFormatter.formatDateTime(firstTime);

    final olderData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: timeStart,
        timeEnd: timeEnd,
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false);

    if (olderData.isEmpty) {
      transientNotification.value = SnackbarNotification(
        title: 'All Data Loaded',
        message: 'You have reached the beginning of the available data.',
      );
      return false;
    }

    if (depthData.any((p) => p.dateTime.millisecondsSinceEpoch == olderData.last.dateTime.millisecondsSinceEpoch)) {
      final startTimeString = DateFormat('HH:mm:ss').format(firstTime.subtract(amount));
      final endTimeString = DateFormat('HH:mm:ss').format(firstTime);
      transientNotification.value = SnackbarNotification(
        title: 'Data Loaded',
        message: 'Data for range $startTimeString - $endTimeString is already present.',
      );
      return false;
    }

    // 3. Prepend new data and keep the view at the new beginning
    depthData.insertAll(0, olderData);
    depthChartCurrentIndex.value = 0;
    updateDisplayedDepthChartData();
    return true;
  }

  void storeSeriesController(String key, ChartSeriesController ctl) {
    seriesControllers[key] = ctl;
  }

  Future<void> setActiveWellForNotifications(WellActive well) async {
    _currentActiveWell = well;
    _notificationSettingsBox = await HiveService.openParameterNotificationSettings();
    if (_notificationSettingsBox != null && _currentActiveWell != null) {
      _loadEnabledSettingsForCurrentWell();
      _notificationSettingsBox!.watch().listen((event) { // Listen for changes to settings
        print("Notification settings box changed, reloading enabled settings.");
        _loadEnabledSettingsForCurrentWell();
      });
    }
  }

  void _loadEnabledSettingsForCurrentWell() {
    if (_currentActiveWell != null && _notificationSettingsBox != null) {
      _currentWellEnabledSettings = _notificationSettingsBox!.values
          .where((s) => s.wellApiToken == _currentActiveWell!.isApiToken && s.isEnabled)
          .toList();
      print("Loaded ${_currentWellEnabledSettings.length} enabled notification settings for well ${_currentActiveWell!.isApiToken}");
    }
  }

  void _checkParameterThresholds(DrillingData currentData, String wellApiToken) {
    if (_notificationSettingsBox == null || _currentActiveWell == null || _currentActiveWell!.isApiToken != wellApiToken) {
      // print("Notification check skipped: Box null or well mismatch.");
      return;
    }
  }

}