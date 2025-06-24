

import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/well_active.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/pdu_api.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_depth_service.dart';
import 'package:pdu_mobile_rto_app/data/services/shared_preferences/chart_settings_service.dart';
import 'package:pdu_mobile_rto_app/features/notification/model/snackbar_notification.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;

class DepthDrillingController extends GetxController {
  final PduApi api = Get.find<PduApi>();

  final RxList<DepthDrillingData> displayedDataDepth = <DepthDrillingData>[].obs;
  final RxList<DepthDrillingData> depthData = <DepthDrillingData>[].obs;
  final RxMap<String, ChartSeriesController?> depthSeriesControllers = <String, ChartSeriesController?>{}.obs;
  final Rx<double?> niceDepthAxisMin = Rx<double?>(null);
  final Rx<double?> niceDepthAxisMax = Rx<double?>(null);

  final int displayedDataPoints = 12 * 15;
  final int depthChartBlockSize = 15;
  var depthChartCurrentIndex = 0.obs;

  bool _depthFirstCall = true;
  var isHomeScreenLoading = false.obs;

  final Rx<SnackbarNotification?> transientNotification = Rx<SnackbarNotification?>(null);

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

  Map<String, double> calculateNiceAxisRange(double dataMin, double dataMax) {
    // Handle the edge case where there's no data or only one point.
    if (dataMin == dataMax) {
      return {'min': dataMin - 50, 'max': dataMax + 50}; // Provide some padding
    }

    final double range = dataMax - dataMin;

    // Calculate a "nice" step value. This is a common algorithm.
    // It finds a power of 10 (like 10, 100, 1000) that is close to the range.
    final double tempStep = math.pow(10, (math.log(range) / math.log(10)).floor()).toDouble();

    // Calculate the new, rounded minimum and maximum.
    final double newMin = (dataMin / tempStep).floor() * tempStep;
    final double newMax = (dataMax / tempStep).ceil() * tempStep;

    return {'min': newMin, 'max': newMax};
  }

  Future<void> searchDataByTimeRange({
    required WellActive wellActive,
    required DateTime startTime,
    required DateTime endTime,
    required String mode,
  }) async
  {
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

    depthData.assignAll(searchResult);

    depthData.refresh();

    depthChartCurrentIndex.value = 0;
    updateDisplayedDepthChartData();

    // 4. Notify the user of success.
    transientNotification.value = SnackbarNotification(
      title: 'Success',
      message: 'Data loaded for the selected time range.',
    );

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

      final double minDepth = data.map((d) => d.md).reduce(math.min);
      final double maxDepth = data.map((d) => d.md).reduce(math.max);

      // 2. Calculate the "nice" range using our helper
      final niceRange = calculateNiceAxisRange(minDepth, maxDepth);

      // 3. Update the state variables
      niceDepthAxisMin.value = niceRange['min'];
      niceDepthAxisMax.value = niceRange['max'];




    } else {
      _depthFirstCall = false;
    }
    depthChartCurrentIndex.value = 0;
    updateDisplayedDepthChartData();
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
    depthSeriesControllers[key] = ctl;
  }

  void deleteData() {
    depthData.clear();
    displayedDataDepth.clear();
    depthChartCurrentIndex.value = 0;
    _depthFirstCall = true;
  }

}