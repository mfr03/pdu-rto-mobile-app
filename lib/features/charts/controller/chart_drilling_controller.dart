import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/notification_api/client_id_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/app_notification_info.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/snackbar_notification.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:pdu_mobile_rto_app/utils/well_utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import '../../../data/services/pdu_api/model/well_active.dart';

class DrillingController extends GetxController {

  final PduApi api = Get.find<PduApi>();
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

  final Rx<DateTime?> currentChunkStart = Rx<DateTime?>(null);
  final Rx<DateTime?> currentChunkEnd = Rx<DateTime?>(null);
  final int chunkWindowHours = 1;

  final Rx<double?> niceDepthAxisMin = Rx<double?>(null);
  final Rx<double?> niceDepthAxisMax = Rx<double?>(null);

  WellActive? _currentActiveWell;

  Box<ParameterNotificationSetting>? _notificationSettingsBox;
  final Rx<AppNotificationInfo?> latestAppNotification = Rx<AppNotificationInfo?>(null);

  final Rx<SnackbarNotification?> transientNotification = Rx<SnackbarNotification?>(null);

  List<ParameterNotificationSetting> _currentWellEnabledSettings = [];
  final int notificationCooldownMinutes = 0;

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

  void _updateLiveTimeDataFromHistorical() {
    if (historicalTimeData.length > _maxLiveTimeDataPoints) {
      // If we have more data than the max, take the most recent slice
      final liveChunk = historicalTimeData.sublist(historicalTimeData.length - _maxLiveTimeDataPoints);
      liveTimeData.assignAll(liveChunk);
    } else {
      // Otherwise, all the historical data we have is considered "live"
      liveTimeData.assignAll(historicalTimeData);
    }
    debugPrint("CONTROLLER SYNC: liveTimeData updated with ${liveTimeData.length} points.");
  }


  Future<void> _fetchDataForChunk({required DateTime anchorTime}) async {
    isHomeScreenLoading.value = true;

    // 1. Calculate the new chunk's boundaries
    final int hour = anchorTime.hour;
    final DateTime chunkStart = DateTime(anchorTime.year, anchorTime.month, anchorTime.day, hour);
    final DateTime chunkEnd = chunkStart.add(Duration(hours: chunkWindowHours));

    // 2. Update the UI-bound state variables
    currentChunkStart.value = chunkStart;
    currentChunkEnd.value = chunkEnd;

    // 3. Fetch data for this chunk.
    // We use fetchAbsoluteTimeRangeData as it's perfect for this task.
    // The end time is the anchorTime, so we only fill data up to that point.
    final List<DrillingData> chunkData = await api.fetchAbsoluteTimeRangeData(
      token: _currentActiveWell!.isApiToken, // Assuming _currentActiveWell is set
      startTime: chunkStart,
      endTime: anchorTime,
    );

    // 4. Replace the old data with the new chunk's data.
    historicalTimeData.assignAll(chunkData);

    _updateLiveTimeDataFromHistorical();

    // 5. Update the displayed data
    updateDisplayedTimeChartData();

    isHomeScreenLoading.value = false;
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
      debugPrint("TIMER TICK: Fetching latest live data...");
      fetchAndUpdateLatestLiveTimeData(wellActive: wellActive);
    });
  }

  void stopLiveUpdates() {
    _realtimeHomeTimer?.cancel();
    _realtimeHomeTimer = null;
    debugPrint("TIMER STOPPED");
  }

  Future<void> initializeData({
    required WellActive wellActive,
  }) async
  {
    // Path A: For a LIVE well, if historicalTimeData already has points (likely from timer appends)
    if (historicalTimeData.isNotEmpty && !isWellCompleted(wellActive: wellActive)) {
      debugPrint("CONTROLLER: initializeData - Live well, historicalTimeData already has ${historicalTimeData.length} points. Updating display.");
      updateDisplayedTimeChartData(); // This should populate displayedData
      return;
    }
    // Path B: For a COMPLETED well, if historicalTimeData already has points
    if (historicalTimeData.isNotEmpty && isWellCompleted(wellActive: wellActive)) {
      debugPrint("CONTROLLER: initializeData - Completed well, historicalTimeData already has ${historicalTimeData.length} points. Updating display.");
      updateDisplayedTimeChartData(); // This should populate displayedData
      return;
    }

    // Path C: historicalTimeData is EMPTY (or conditions above not met), so fetch initial historical block.
    debugPrint("CONTROLLER: initializeData - historicalTimeData is empty or forced fetch. Fetching with fetchRealtimeDataIncrement for ${wellActive.wellName}");
    final data = await api.fetchRealtimeDataIncrement(wellActive: wellActive);
    debugPrint("CONTROLLER: initializeData - Data fetched by fetchRealtimeDataIncrement. Count: ${data.length}");

    historicalTimeData.assignAll(data);
    debugPrint("CONTROLLER: initializeData - historicalTimeData assigned. Length: ${historicalTimeData.length}");

    if (historicalTimeData.isNotEmpty) {
      timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints)
          ? historicalTimeData.length - displayedDataPoints // Show latest part
          : 0;
    } else {
      timeChartCurrentIndex.value = 0;
    }
    debugPrint("CONTROLLER: initializeData - timeChartCurrentIndex set to: ${timeChartCurrentIndex.value}");
    updateDisplayedTimeChartData(); // This populates displayedData
  }

  Future<void> initializeLiveTimeData({required WellActive wellActive}) async {
    _currentActiveWell = wellActive; // Ensure we have the active well
    stopLiveUpdates();
    liveDataFetchFailed.value = false;
    _setLiveMode(true, source: 'initializeLiveTimeData');

    await _fetchDataForChunk(anchorTime: DateTime.now());

    if (historicalTimeData.isNotEmpty) {
      startLiveUpdates(wellActive: wellActive);
    } else {
      liveDataFetchFailed.value = true;
      stopLiveUpdates();
    }
  }

  Future<void> loadHistoricalData({required WellActive wellActive}) async {
    isHomeScreenLoading.value = true; // Set loading to true
    try {
      stopLiveUpdates();
      liveDataFetchFailed.value = false;
      liveTimeData.clear();
      latestLiveTimeDataPoint.value = null;

      debugPrint("CONTROLLER: loadHistoricalData - User initiated historical data load.");

      final data = await api.fetchRealtimeDataIncrement(wellActive: wellActive);

      if (data.isNotEmpty) {
        debugPrint("CONTROLLER: loadHistoricalData - SUCCESS, found ${data.length} historical points.");
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
        debugPrint("CONTROLLER: loadHistoricalData - FAILED, no historical data found either.");
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

      debugPrint("Start Time: $startTime \n End Time: $endTime \n");

      _setLiveMode(false, source: 'searchDataByTimeRange');

      final searchResult = await api.fetchAbsoluteTimeRangeData(
        token: wellActive.isApiToken,
        startTime: startTime,
        endTime: endTime,
      );

      if (searchResult.isEmpty) {
        _setLiveMode(true, source: 'searchDataByTimeRange');
        transientNotification.value = SnackbarNotification(
            title: 'No Data',
            message: 'No time-based data found for the selected range.'
        );
        return;
      }


      currentChunkStart.value = startTime;
      currentChunkEnd.value = endTime;

      if (historicalTimeData.any((p) => p.dateTime == searchResult.first.dateTime)) {
        _setLiveMode(true, source: 'searchDataByTimeRange');
        transientNotification.value = SnackbarNotification(
          title: 'Data Exists',
          message: 'The requested data is already loaded.',
        );
        return;
      }

      historicalTimeData.assignAll(searchResult);
      timeChartCurrentIndex.value = 0;

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

  Future<void> fetchAndUpdateLatestLiveTimeData({required WellActive wellActive}) async {
    if (!isTimeChartLive.value) {
      debugPrint("TIMER SKIPPED: Not in live mode.");
      return;
    }

    final now = DateTime.now();

    // Check if we have crossed into a new chunk (e.g., time moved from 10:59 to 11:00)
    if (now.hour != currentChunkStart.value?.hour) {
      debugPrint("CHUNK CHANGE DETECTED: Reloading for new hour.");
      await _fetchDataForChunk(anchorTime: now);
      return;
    }

    // If still in the same chunk, just fetch the delta.
    final startTimeQuery = historicalTimeData.isNotEmpty
        ? historicalTimeData.last.dateTime
        : currentChunkStart.value!;

    final newData = await api.fetchRealtimeDataOnce(
      token: wellActive.isApiToken,
      timeStart: CFormatter.formatDateTime(startTimeQuery),
      timeEnd: CFormatter.formatDateTime(now),
    );

    if (newData.isNotEmpty) {
      debugPrint("LIVE REFRESH: Found ${newData.length} new data points.");

      // Efficiently add new points without duplicates
      final existingTimestamps = historicalTimeData.map((p) => p.dateTime).toSet();
      final pointsToAdd = newData.where((p) => !existingTimestamps.contains(p.dateTime)).toList();

      if (pointsToAdd.isNotEmpty) {
        historicalTimeData.addAll(pointsToAdd);
        historicalTimeData.sort((a, b) => a.dateTime.compareTo(b.dateTime)); // Ensure order

        _updateLiveTimeDataFromHistorical();

        updateDisplayedTimeChartData();
      }
    } else {
      debugPrint("LIVE REFRESH: No new data points found.");
    }
  }

  void updateDisplayedTimeChartData() {
    displayedData.assignAll(historicalTimeData);

    // This is a good place to update the latest data point for other UI elements
    if (historicalTimeData.isNotEmpty) {
      latestLiveTimeDataPoint.value = historicalTimeData.last;
      latestLiveTimeDataPoint.refresh();
    } else {
      latestLiveTimeDataPoint.value = null;
    }
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
    if (isTimeChartLive.value) return false; // Already at the live edge

    final DateTime nextChunkStart = currentChunkStart.value!.add(Duration(hours: chunkWindowHours));
    final DateTime now = DateTime.now();
    final DateTime liveChunkStart = DateTime(now.year, now.month, now.day, now.hour);

    // Check if we are moving into the current live chunk
    if (!nextChunkStart.isBefore(liveChunkStart)) {
      _setLiveMode(true, source: 'fastForwardTimeChart');
      await initializeLiveTimeData(wellActive: wellActive); // Re-engage live mode
    } else {
      // Otherwise, fetch the next historical chunk.
      // The anchor time is the very end of that chunk to fetch all its data.
      final DateTime anchorTime = nextChunkStart.add(Duration(hours: chunkWindowHours)).subtract(const Duration(microseconds: 1));
      await _fetchDataForChunk(anchorTime: anchorTime);
    }
    return true;
  }

  Future<bool> moveBackwardTimeChart({required WellActive wellActive}) async {
    _setLiveMode(false, source: 'moveBackwardTimeChart');
    stopLiveUpdates();

    if (currentChunkStart.value == null) return false;

    // The anchor time is the very end of the PREVIOUS chunk.
    final DateTime anchorTime = currentChunkStart.value!.subtract(const Duration(microseconds: 1));
    await _fetchDataForChunk(anchorTime: anchorTime);

    return historicalTimeData.isNotEmpty;
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

  void storeSeriesController(String key, ChartSeriesController ctl) {
    seriesControllers[key] = ctl;
  }

  Future<void> setActiveWellForNotifications(WellActive well) async {

    _currentActiveWell = well;
    _notificationSettingsBox = await HiveService.openParameterNotificationSettings(
      userId: await ClientIdService.getPersistentClientId()
    );
    if (_notificationSettingsBox != null && _currentActiveWell != null) {
      _loadEnabledSettingsForCurrentWell();
      _notificationSettingsBox!.watch().listen((event) { // Listen for changes to settings
        debugPrint("Notification settings box changed, reloading enabled settings.");
        _loadEnabledSettingsForCurrentWell();
      });
    }
  }

  void _loadEnabledSettingsForCurrentWell() {
    if (_currentActiveWell != null && _notificationSettingsBox != null) {
      _currentWellEnabledSettings = _notificationSettingsBox!.values
          .where((s) => s.wellApiToken == _currentActiveWell!.isApiToken && s.isEnabled)
          .toList();
      debugPrint("Loaded ${_currentWellEnabledSettings.length} enabled notification settings for well ${_currentActiveWell!.isApiToken}");
    }
  }


}