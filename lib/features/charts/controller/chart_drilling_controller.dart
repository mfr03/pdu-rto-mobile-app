import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/app_notification_info.dart';
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
  List<ParameterNotificationSetting> _currentWellEnabledSettings = [];
  final int notificationCooldownMinutes = 0; // Cooldown period

  var currentIndex = 0.obs;

  bool _depthFirstCall = true;
  var isTimeChartLive = true.obs;

  void _setLiveMode(bool isLive, {String source = 'Unknown'}) {
    if (isTimeChartLive.value != isLive) {
      debugPrint(
          "CONTROLLER: Live mode changing to $isLive from source: $source");
      isTimeChartLive.value = isLive;
    }
  }
  String _getGuaranteedDateTimeString(String dateOrTimeString, String defaultDateStr) {
    if (dateOrTimeString.contains(' ')) {
      // It's already a full DateTime string (e.g., "2025-06-12 00:00:00")
      return dateOrTimeString;
    } else {
      // It's a time-only string (e.g., "00:15:00").
      // We take the date part from the well's default start/end date.
      try {
        final datePart = defaultDateStr.split(' ')[0];
        return '$datePart $dateOrTimeString';
      } catch (e) {
        debugPrint("Error parsing defaultDateStr: '$defaultDateStr'. Falling back.");
        // Fallback to today's date if the defaultDateStr is also invalid
        final datePart = CFormatter.formatDateTime(DateTime.now());
        return '$datePart $dateOrTimeString';
      }
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
    final DateTime now = DateTime.now();
    final DateTime startTime = now.subtract(const Duration(minutes: 15));
    final String timeStartStr = CFormatter.formatDateTime(startTime);
    final String timeEndStr = CFormatter.formatDateTime(now);

    print("CONTROLLER: initializeLiveTimeData - Fetching initial LIVE window: $timeStartStr to $timeEndStr");
    final data = await api.fetchRealtimeDataOnce(
        token: wellActive.isApiToken,
        timeStart: timeStartStr,
        timeEnd: timeEndStr
    );

    liveTimeData.assignAll(data);
    if (liveTimeData.isNotEmpty) {
      latestLiveTimeDataPoint.value = liveTimeData.last;
    } else {
      latestLiveTimeDataPoint.value = null;
    }

    // NEW: Also populate historicalTimeData with this initial live window
    // This ensures the Time Chart starts with live data if the well is live.
    historicalTimeData.assignAll(data);
    if (historicalTimeData.isNotEmpty) {
      timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints)
          ? historicalTimeData.length - displayedDataPoints
          : 0;
    } else {
      timeChartCurrentIndex.value = 0;
    }
    updateDisplayedTimeChartData(); // Populate displayedData
    print("CONTROLLER: initializeLiveTimeData - historicalTimeData and displayedData updated with live window. displayedData length: ${displayedData.length}");
  }

  Future<void> initializeHistoricalTimeDataForHome({required WellActive wellActive}) async {
    liveTimeData.clear(); // Clear any previous live data first
    latestLiveTimeDataPoint.value = null; // Reset

    DateTime effectiveEndDate;
    final parsedWellEndDate = CFormatter.formatStringToDateTime(wellActive.endDate);

    if (parsedWellEndDate != null) {
      effectiveEndDate = parsedWellEndDate;

    } else {

      await initializeData(wellActive: wellActive);
      if (historicalTimeData.isNotEmpty) {
        final lastChunk = historicalTimeData.sublist(
            math.max(0, historicalTimeData.length - _maxLiveTimeDataPoints)
        );
        liveTimeData.assignAll(lastChunk); // Populate 'liveTimeData' with this historical chunk
        if (liveTimeData.isNotEmpty) {
          latestLiveTimeDataPoint.value = liveTimeData.last;
        }
      }
      return;
    }

    final DateTime startTime = effectiveEndDate.subtract(const Duration(hours: 1));
    final String timeStartStr = CFormatter.formatDateTime(startTime);
    final String timeEndStr = CFormatter.formatDateTime(effectiveEndDate);

    final data = await api.fetchRealtimeDataOnce(
      token: wellActive.isApiToken,
      timeStart: timeStartStr,
      timeEnd: timeEndStr,
    );

    if (data.isNotEmpty) {
      liveTimeData.assignAll(data);
      latestLiveTimeDataPoint.value = liveTimeData.last;
    } else {
      await initializeData(wellActive: wellActive); // Populates historicalTimeData
      if (historicalTimeData.isNotEmpty) {
        final lastChunk = historicalTimeData.sublist(
            math.max(0, historicalTimeData.length - _maxLiveTimeDataPoints)
        );
        liveTimeData.assignAll(lastChunk);
        if (liveTimeData.isNotEmpty) {
          latestLiveTimeDataPoint.value = liveTimeData.last;
        }
      }
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
        Get.snackbar(
          'No Data',
          'No time-based data found for the selected range.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (historicalTimeData.any((p) => p.dateTime == searchResult.first.dateTime)) {
        Get.snackbar(
          'Data Exists',
          'The requested data is already loaded.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      historicalTimeData.assignAll(searchResult);
      timeChartCurrentIndex.value = 0;
      _setLiveMode(false, source: 'searchDataByTimeRange');
      updateDisplayedTimeChartData();
      Get.snackbar(
        'Success',
        'Data loaded for the selected time range.',
        snackPosition: SnackPosition.BOTTOM,
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
        Get.snackbar(
          'No Data',
          'No depth-based data found for the selected range.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      if (depthData.any((p) => p.dateTime == searchResult.first.dateTime)) {
        Get.snackbar(
          'Data Exists',
          'The requested data is already loaded.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      depthData.assignAll(searchResult);
      depthChartCurrentIndex.value = 0;
      updateDisplayedDepthChartData();
      Get.snackbar(
        'Success',
        'Data loaded for the selected time range.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchAndUpdateLatestLiveTimeData(
      {required WellActive wellActive}) async {
    // --- THIS IS THE DEFINITIVE TEST ---
    // If the chart is not in live mode, we will now stop the entire function.
    // This prevents any new data from being fetched and stops any modification
    // of the historicalData list, which should stop the unwanted scroll.
    if (!isTimeChartLive.value) {
      debugPrint("DrillingController: In historical mode, skipping live data update entirely.");
      return;
    }
    // ---------------------------------

    if (isWellCompleted(wellActive: wellActive)) {
      return;
    }

    final DateTime now = DateTime.now();
    DateTime startTimeQuery;

    DateTime? lastHistoricalTime =
    historicalTimeData.isNotEmpty ? historicalTimeData.last.dateTime : null;
    DateTime? lastLiveTime =
    liveTimeData.isNotEmpty ? liveTimeData.last.dateTime : null;

    if (lastHistoricalTime != null &&
        (lastLiveTime == null || lastHistoricalTime.isAfter(lastLiveTime))) {
      startTimeQuery = lastHistoricalTime;
    } else if (lastLiveTime != null) {
      startTimeQuery = lastLiveTime;
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
      bool addedToLiveSpecific = false;

      for (var newPoint in newData) {
        if (liveTimeData.isEmpty ||
            newPoint.dateTime.isAfter(liveTimeData.last.dateTime)) {
          liveTimeData.add(newPoint);
          addedToLiveSpecific = true;
        }
      }
      if (addedToLiveSpecific && liveTimeData.length > _maxLiveTimeDataPoints) {
        liveTimeData
            .removeRange(0, liveTimeData.length - _maxLiveTimeDataPoints);
      }
      if (liveTimeData.isNotEmpty) {
        latestLiveTimeDataPoint.value = liveTimeData.last;

        if (_currentActiveWell != null) {
          _checkParameterThresholds(
              latestLiveTimeDataPoint.value!, _currentActiveWell!.isApiToken);
        }
      }

      bool addedToHistorical = false;
      for (var newPoint in newData) {
        if (historicalTimeData.isEmpty ||
            newPoint.dateTime.isAfter(historicalTimeData.last.dateTime)) {
          historicalTimeData.add(newPoint);
          addedToHistorical = true;
        }
      }

      if (addedToHistorical) {
        // This block is now only reachable if isTimeChartLive is true,
        // so we don't need the extra checks inside.
        timeChartCurrentIndex.value =
        (historicalTimeData.length > displayedDataPoints)
            ? historicalTimeData.length - displayedDataPoints
            : 0;

        updateDisplayedTimeChartData();
      }
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
    // If there's no data, we can't do anything.
    if (historicalTimeData.isEmpty) return false;

    // --- 1. Attempt to traverse locally within the existing data ---
    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final currentViewStartTime =
        historicalTimeData[timeChartCurrentIndex.value].dateTime;
    final targetStartTime =
    currentViewStartTime.add(Duration(minutes: traversalMinutes));

    final newIndex =
    historicalTimeData.indexWhere((p) => p.dateTime.isAfter(targetStartTime));

    // If we found a point further in time within our loaded data, just jump to it.
    // We DO NOT change the live mode state here.
    if (newIndex != -1) {
      timeChartCurrentIndex.value = newIndex;
      updateDisplayedTimeChartData();
      return true;
    }

    // --- 2. If local traversal is not possible, fetch from the API ---

    // If the well is completed, there's no more data to fetch.
    if (isWellCompleted(wellActive: wellActive)) {
      // Since we are at the end of a completed well, we can consider it "live"
      // in the sense that there are no more updates.
      _setLiveMode(true, source: 'fastForwardTimeChart - end of completed well');
      return false;
    }

    final apiFetchMinutes = math.min(traversalMinutes, 15);
    final DateTime refTime = historicalTimeData.last.dateTime;

    final List<DrillingData> newData = await api.fetchMoreData(
      token: wellActive.isApiToken,
      referenceTime: refTime,
      forward: true,
      count: apiFetchMinutes,
    );

    // --- 3. Process the API result ---

    // THIS IS THE KEY: If the API returns no new data, it means we have
    // reached the true "live" edge. Now we can re-enable live mode.
    if (newData.isEmpty) {
      _setLiveMode(true, source: 'fastForwardTimeChart - API returned no new data');
      return false; // Return false because we didn't actually add new data.
    }

    // If we get here, it means we successfully fetched another historical chunk.
    // We add the data but KEEP live mode disabled.
    historicalTimeData.addAll(newData);
    // Move the view to the start of the new data we just fetched.
    timeChartCurrentIndex.value = (historicalTimeData.length - newData.length);
    updateDisplayedTimeChartData();
    return true;
  }

  Future<bool> moveBackwardTimeChart({required WellActive wellActive}) async {
    _setLiveMode(false, source: 'moveBackwardTimeChart');

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

    // ADDED: Reset the flag to ensure the next depth call is a "first" call.
    _depthFirstCall = true;
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

    // Load the user's custom traversal unit for the API call
    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);

    final lastTime = depthData.last.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    final ts = CFormatter.formatDateTime(lastTime);
    final te = CFormatter.formatDateTime(lastTime.add(amount));
    final ds = cfg.start;
    final de = cfg.end;

    print("DEBUG: Fetching depth data for well: ${wellActive.wellName}, Token: ${wellActive.isApiToken}");
    print("DEBUG: Time Range: Start = $ts, End = $te");
    print("DEBUG: Depth Range: Start = $ds, End = $de");
    print("DEBUG: First Call: $_depthFirstCall");

    final newData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: CFormatter.formatDateTime(lastTime),
        timeEnd: CFormatter.formatDateTime(lastTime.add(amount)),
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false);

    if (newData.isEmpty) {
      return false; // No more data available
    }

    // 3. Add new data and move the view to the new end
    depthData.addAll(newData);
    // Move index to show the newly fetched data at the end of the chart
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

    // Load the user's custom traversal unit for the API call
    final traversalMinutes = await ChartSettingsService.loadTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);

    final firstTime = depthData.first.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    final olderData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: CFormatter.formatDateTime(firstTime.subtract(amount)),
        timeEnd: CFormatter.formatDateTime(firstTime),
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: false);

    if (olderData.isEmpty) {
      return false; // No older data found
    }

    // 3. Prepend new data and keep the view at the new beginning
    depthData.insertAll(0, olderData);
    depthChartCurrentIndex.value = 0; // Stay at the new start
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

    // Use the pre-loaded _currentWellEnabledSettings for efficiency
    // for (var setting in _currentWellEnabledSettings) {
    //   final num currentValue = currentData.value(setting.parameterJsonKey); // Uses rawDataOriginal
    //   bool breached = false;
    //
    //   if (setting.condition == "above" && currentValue > setting.thresholdValue) {
    //     breached = true;
    //   } else if (setting.condition == "below" && currentValue < setting.thresholdValue) {
    //     breached = true;
    //   }
    //
    //   if (breached) {
    //     DateTime now = DateTime.now();
    //     if (setting.lastNotificationTime == null ||
    //         now.difference(setting.lastNotificationTime!).inMinutes >= notificationCooldownMinutes) {
    //
    //       String title = "Alert: ${setting.parameterName}";
    //       String message = "${setting.parameterName} (${currentValue.toStringAsFixed(2)}) is ${setting.condition} your threshold (${setting.thresholdValue.toStringAsFixed(2)}).";
    //
    //       print("LOCAL NOTIFICATION TRIGGERED: $message");
    //
    //       LocalNotificationService.showNotification(
    //         title: title,
    //         body: message,
    //         payload: "well_id=${setting.wellApiToken}&param=${setting.parameterJsonKey}",
    //       );
    //
    //       setting.lastNotificationTime = now;
    //       HiveService.saveNotificationSetting(setting);
    //     } else {
    //       // print("Cooldown active for ${setting.parameterName}");
    //     }
    //   }
    // }
  }

}