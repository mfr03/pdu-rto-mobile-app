import 'package:get/get.dart';
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


  final Rx<double?> depthAxisMin = Rx<double?>(null);
  final Rx<double?> depthAxisMax = Rx<double?>(null);

  // These store the original config to calculate sections from.
  double _originalDepthStart = 0.0;
  double _originalDepthEnd = 1000.0; // Default fallback
  double _sectionValue = 250.0;      // Default fallback

  var depthChartCurrentIndex = 0.obs;

  bool _depthFirstCall = true;
  var isHomeScreenLoading = false.obs;

  final Rx<SnackbarNotification?> transientNotification = Rx<SnackbarNotification?>(null);

  void updateDisplayedDepthChartData() {
    displayedDataDepth.assignAll(depthData);
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

    final double minDepth = searchResult.map((d) => d.md).reduce(math.min);
    final double maxDepth = searchResult.map((d) => d.md).reduce(math.max);

    // 2. Calculate a "nice" rounded axis range using our existing helper.
    final niceRange = calculateNiceAxisRange(minDepth, maxDepth);

    // 3. Update the controller's state for the chart's axis.
    depthAxisMin.value = niceRange['min'];
    depthAxisMax.value = niceRange['max'];

    // 4. Assign the new data to be displayed.
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

  Future<void> initializeDepthData({required WellActive wellActive}) async {
    if (depthData.isNotEmpty) {
      updateDisplayedDepthChartData();
      return;
    }

    isHomeScreenLoading.value = true;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    _originalDepthStart = cfg.start;
    _originalDepthEnd = cfg.end;
    _sectionValue = (_originalDepthEnd - _originalDepthStart) / 4;
    if (_sectionValue <= 0) _sectionValue = 250.0;

    depthAxisMin.value = _originalDepthStart;
    depthAxisMax.value = _originalDepthEnd;

    final data = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: wellActive.timeStart,
        timeEnd: wellActive.timeEnd,
        depthStart: cfg.start,
        depthEnd: cfg.end,
        first: _depthFirstCall);

    if (data.isNotEmpty) {
      _depthFirstCall = false;
      depthData.assignAll(data);
    } else {
      _depthFirstCall = false;
    }
    updateDisplayedDepthChartData();
    isHomeScreenLoading.value = false;
  }

  Future<void> resetDepthChart({required WellActive wellActive}) async {
    depthData.clear();
    _depthFirstCall = true; // Ensure the next fetch is a 'first' call
    depthChartCurrentIndex.value = 0;
    await initializeDepthData(wellActive: wellActive);
  }

  Future<bool> fastForwardDepthChart({required WellActive wellActive}) async {
    isHomeScreenLoading.value = true;

    final traversalMinutes = await ChartSettingsService.loadDepthTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);
    // Use the last known time or now if the list is empty
    final lastTime = depthData.isNotEmpty ? depthData.last.dateTime : DateTime.now();
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    // Fetch the next chunk of data based on time
    final timeStart = CFormatter.formatDateTime(lastTime);
    final timeEnd = CFormatter.formatDateTime(lastTime.add(amount));

    final newData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: timeStart,
        timeEnd: timeEnd,
        depthStart: cfg.start, // Always search the full original depth range
        depthEnd: cfg.end,
        first: false);

    if (newData.isNotEmpty) {
      // 1. Add the new data to our master list
      depthData.addAll(newData);

      // 2. Find the max depth in the NEW data chunk. This is efficient.
      final double maxInNewData = newData.map((d) => d.md).reduce(math.max);

      // 3. Apply the new rule: if the new max is outside the current view,
      //    jump the axis max to the new data point and add padding.
      if (maxInNewData > depthAxisMax.value!) {
        depthAxisMax.value = maxInNewData + _sectionValue;
      }

      transientNotification.value = SnackbarNotification(
          title: 'Data Successfully Loaded',
          message: ''
      );

      // 4. Update the UI
      updateDisplayedDepthChartData();

    } else {
      transientNotification.value = SnackbarNotification(
        title: 'All Data Loaded',
        message: 'You have reached the latest available data.',
      );
    }

    isHomeScreenLoading.value = false;
    return newData.isNotEmpty;
  }

  Future<bool> moveBackwardDepthChart({required WellActive wellActive}) async {
    if (depthData.isEmpty) return false;
    isHomeScreenLoading.value = true;

    final traversalMinutes = await ChartSettingsService.loadDepthTraversalUnit();
    final amount = Duration(minutes: traversalMinutes);
    final firstTime = depthData.first.dateTime;
    final cfg = await ChartDepthService.loadConfig(wellActive.isApiToken);

    final timeStart = CFormatter.formatDateTime(firstTime.subtract(amount));
    final timeEnd = CFormatter.formatDateTime(firstTime);

    final olderData = await api.fetchDepthBasedData(
        token: wellActive.isApiToken,
        timeStart: timeStart, timeEnd: timeEnd,
        depthStart: cfg.start, depthEnd: cfg.end,
        first: false);

    if (olderData.isNotEmpty) {
      depthData.insertAll(0, olderData); // Prepend the older data
      updateDisplayedDepthChartData();

    } else {
      transientNotification.value = SnackbarNotification(
        title: 'All Data Loaded', message: 'You have reached the beginning of the available data.',
      );
    }
    isHomeScreenLoading.value = false;
    return olderData.isNotEmpty;
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