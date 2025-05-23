import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:pdu_mobile_rto_app/data/services/hive/hive_service.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/parameter_notification_setting.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/app_notification_info.dart';
import 'package:pdu_mobile_rto_app/features/notification/service/local_notification_service.dart';
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
    // ... (rest of your existing depth data fetching logic)
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);
    final ts = wellActive.timeStart;
    final te = wellActive.timeEnd;
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

  Future<void> fetchAndUpdateLatestLiveTimeData(
      {
        required WellActive wellActive,
        bool shouldAutoScrollTimeChart = false
      }) async
  {

    if(isWellCompleted(wellActive: wellActive)) {
      return;
    }

    final DateTime now = DateTime.now();
    DateTime startTimeQuery;

    DateTime? lastHistoricalTime = historicalTimeData.isNotEmpty ? historicalTimeData.last.dateTime : null;
    DateTime? lastLiveTime = liveTimeData.isNotEmpty ? liveTimeData.last.dateTime : null;

    if(lastHistoricalTime != null && (lastLiveTime == null || lastHistoricalTime.isAfter(lastLiveTime))) {
      startTimeQuery = lastHistoricalTime;
    } else if (lastLiveTime != null){
      startTimeQuery = lastLiveTime;
    } else {
      startTimeQuery = now.subtract(const Duration(minutes: 2));
    }

    if(startTimeQuery.isAfter(now)) {
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
        if (liveTimeData.isNotEmpty || newPoint.dateTime.isAfter(liveTimeData.last.dateTime)) {
          liveTimeData.add(newPoint);
          addedToLiveSpecific = true;
        }
      }
      if (addedToLiveSpecific && liveTimeData.length > _maxLiveTimeDataPoints) {
        liveTimeData.removeRange(0, liveTimeData.length - _maxLiveTimeDataPoints);
      }
      if(liveTimeData.isNotEmpty) {
        latestLiveTimeDataPoint.value = liveTimeData.last;

        if (_currentActiveWell != null) {
          _checkParameterThresholds(latestLiveTimeDataPoint.value!, _currentActiveWell!.isApiToken);
        }

      }

      bool addedToHistorical = false;
      for (var newPoint in newData) {
        if (historicalTimeData.isEmpty || newPoint.dateTime.isAfter(historicalTimeData.last.dateTime)) {
          historicalTimeData.add(newPoint);
          addedToHistorical = true;
        }
      }

      if (addedToHistorical) {
        if (historicalTimeData.length > _maxHistoricalLivePointsToKeep) {
          historicalTimeData.removeRange(0, historicalTimeData.length - _maxHistoricalLivePointsToKeep);
          if (timeChartCurrentIndex.value > 0) {
            int newMaxPossibleIndexStart = historicalTimeData.length - displayedDataPoints;
            if (newMaxPossibleIndexStart < 0) newMaxPossibleIndexStart = 0;
            if (timeChartCurrentIndex.value > newMaxPossibleIndexStart && shouldAutoScrollTimeChart) {
              timeChartCurrentIndex.value = math.min(timeChartCurrentIndex.value, newMaxPossibleIndexStart);
            } else if (timeChartCurrentIndex.value > newMaxPossibleIndexStart && !shouldAutoScrollTimeChart){
              timeChartCurrentIndex.value = newMaxPossibleIndexStart; // Adjust to new valid range
            }
          }
        }
        if (shouldAutoScrollTimeChart) {
          // Scroll the chart to show the latest data
          timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints)
              ? historicalTimeData.length - displayedDataPoints
              : 0;
        }
        updateDisplayedTimeChartData(); // This will refresh the chart's view window
      }
    }

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


  void updateDisplayedTimeChartData() {
    if (historicalTimeData.isEmpty) {
      displayedData.clear();
      return;
    }
    // Ensure timeChartCurrentIndex is valid
    if (timeChartCurrentIndex.value >= historicalTimeData.length) {
      timeChartCurrentIndex.value = (historicalTimeData.length > displayedDataPoints) ? historicalTimeData.length - displayedDataPoints : 0;
    }
    if (timeChartCurrentIndex.value < 0) timeChartCurrentIndex.value = 0;

    final int endIndex = timeChartCurrentIndex.value + displayedDataPoints;
    if (endIndex > historicalTimeData.length) {
      displayedData.assignAll(historicalTimeData.sublist(timeChartCurrentIndex.value));
    } else {
      displayedData.assignAll(historicalTimeData.sublist(timeChartCurrentIndex.value, endIndex));
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
    if (timeChartCurrentIndex.value + displayedDataPoints < historicalTimeData.length) {
      timeChartCurrentIndex.value += 12; // Or some block size
      updateDisplayedTimeChartData();
      return true;
    }
    // Try to fetch more historical data
    if (historicalTimeData.isEmpty) return false; // Cannot fetch more if base is empty
    final DateTime refTime = historicalTimeData.last.dateTime;
    final List<DrillingData> newData = await api.fetchMoreData( // fetchMoreData should be for historical
      token: wellActive.isApiToken,
      referenceTime: refTime,
      forward: true,
      count: 15, // Or displayedDataPoints
    );
    if (newData.isEmpty) return false;

    historicalTimeData.addAll(newData);
    timeChartCurrentIndex.value += 12; // Or block size
    updateDisplayedTimeChartData();
    return true;
  }

  Future<bool> moveBackwardTimeChart({required WellActive wellActive}) async {
    final int blockSize = 12; // Or some block size
    if (timeChartCurrentIndex.value >= blockSize) {
      timeChartCurrentIndex.value -= blockSize;
      updateDisplayedTimeChartData();
      return true;
    } else if (historicalTimeData.isNotEmpty) {
      // At the beginning, try to fetch older data
      final DateTime referenceTime = historicalTimeData.first.dateTime;
      final List<DrillingData> olderData = await api.fetchMoreData(
        token: wellActive.isApiToken,
        referenceTime: referenceTime, // Fetch data *before* this time
        forward: false,
        count: displayedDataPoints, // Fetch a full window
      );
      if (olderData.isEmpty) {
        timeChartCurrentIndex.value = 0; // Go to very start if no older data
        updateDisplayedTimeChartData();
        return false; // No more older data
      }
      historicalTimeData.insertAll(0, olderData);
      // Current index remains 0 (or you could adjust if you want to keep relative position)
      timeChartCurrentIndex.value = 0; // stay at the new beginning
      updateDisplayedTimeChartData();
      return true;
    }
    return false; // Already at the beginning and cannot fetch more
  }

  void resetHistoricalTimeData() {
    historicalTimeData.clear();
    timeChartCurrentIndex.value = 0;
    updateDisplayedTimeChartData();
    // This might trigger a new call to initializeHistoricalTimeData if user navigates to chart
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
  }

  // Future<bool> fastForwardDepth({required WellActive wellActive}) async {
  //   if (depthData.isEmpty) return false;
  //
  //   final lastTime = depthData.last.dateTime;
  //   final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);
  //
  //   final newData = await api.fetchDepthBasedData(
  //       token: wellActive.isApiToken,
  //       timeStart: CFormatter.formatDateTime(lastTime),
  //       timeEnd: CFormatter.formatDateTime(lastTime.add(Duration(minutes: 15))),
  //       depthStart: cfg.start,
  //       depthEnd: cfg.end,
  //       first: false
  //   );
  //   if (newData.isEmpty) return false;
  //
  //   depthData.addAll(newData);
  //   updateDisplayedData(mode: CText.depth); // Update the displayed data for depth mode
  //   return true;
  // }

  Future<bool> moveBackward({required WellActive wellActive, required String mode}) async {
    // const int blockSize = 15;
    //
    // List<DrillingData> dataToMove = mode == CText.time ? timeData : depthData;
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
    for (var setting in _currentWellEnabledSettings) {
      final num currentValue = currentData.value(setting.parameterJsonKey); // Uses rawDataOriginal
      bool breached = false;

      if (setting.condition == "above" && currentValue > setting.thresholdValue) {
        breached = true;
      } else if (setting.condition == "below" && currentValue < setting.thresholdValue) {
        breached = true;
      }

      if (breached) {
        DateTime now = DateTime.now();
        if (setting.lastNotificationTime == null ||
            now.difference(setting.lastNotificationTime!).inMinutes >= notificationCooldownMinutes) {

          String title = "Alert: ${setting.parameterName}";
          String message = "${setting.parameterName} (${currentValue.toStringAsFixed(2)}) is ${setting.condition} your threshold (${setting.thresholdValue.toStringAsFixed(2)}).";

          print("LOCAL NOTIFICATION TRIGGERED: $message");

          LocalNotificationService.showNotification(
            title: title,
            body: message,
            payload: "well_id=${setting.wellApiToken}&param=${setting.parameterJsonKey}",
          );

          setting.lastNotificationTime = now;
          HiveService.saveNotificationSetting(setting);
        } else {
          // print("Cooldown active for ${setting.parameterName}");
        }
      }
    }
  }

}