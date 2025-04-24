import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model/drilling_data.dart';
import 'model/well_active.dart';

class PduApi {
  static const String _baseUrl = "pdumitradome.id";
  static const String _wellActiveEndpoint = "/dome_api/wells-active";
  static const String _realtimeDataEndpoint = "/dome_api/realtime-data";

  /// Fetch the list of active wells
  static Future<List<WellActive>> fetchActiveWells() async {
    final url = Uri.http(_baseUrl, _wellActiveEndpoint);

    try {
      final response = await http.get(url);
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["result"] != null) {
          final List<dynamic> results = data["result"];
          return results.map((json) => WellActive.fromJson(json)).toList();
        } else {
          throw Exception("Key 'result' not found in JSON.");
        }
      } else {
        throw Exception("Failed to load wells. Status code: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static Future<List<DrillingData>> fetchRealtimeDataIncrement({
    required WellActive wellActive,
  }) async {
    // 1) Parse the well’s start_date (e.g. "2023-12-01" -> DateTime(2023,12,1))
    final DateTime rawStartDate = DateTime.parse(wellActive.startDate);

    // Force time to 00:00:00 that day
    DateTime currentStartTime = DateTime(
      rawStartDate.year,
      rawStartDate.month,
      rawStartDate.day,
      0,
      0,
      0,
    );

    // Also parse end_date if you want to stop eventually
    final DateTime rawEndDate = DateTime.parse(wellActive.endDate);

    const Duration step = Duration(minutes: 15);
    int maxIterations = 500; // safety limit

    while (maxIterations > 0) {
      maxIterations--;

      final DateTime windowEnd = currentStartTime.add(step);

      // Build the EXACT strings "yyyy-MM-dd HH:mm:ss"
      final String timeStart = _formatDateTime(currentStartTime);
      final String timeEnd = _formatDateTime(windowEnd);

      debugPrint("Trying $timeStart -> $timeEnd");

      // Make a single request with these strings
      final List<DrillingData> dataList = await _fetchRealtimeDataOnce(
        token: wellActive.isApiToken,
        timeStart: timeStart,
        timeEnd: timeEnd,
      );

      // If we found data, update wellActive’s timeStart/timeEnd with these
      if (dataList.isNotEmpty) {
        debugPrint("Data found for $timeStart -> $timeEnd");
        wellActive.updateTimeRange(timeStart, timeEnd);
        return dataList;
      } else {
        debugPrint("No data for $timeStart -> $timeEnd");
      }

      // Increment to the next 15-minute window
      currentStartTime = windowEnd;

      // Stop if we passed the wellActive.endDate
      if (currentStartTime.isAfter(rawEndDate)) {
        debugPrint("Reached endDate, stopping search.");
        break;
      }
    }

    // No data found within loop constraints
    return <DrillingData>[];
  }

  /// Single GET request that sends JSON in the body with token/timeStart/timeEnd
  static Future<List<DrillingData>> _fetchRealtimeDataOnce({
    required String token,
    required String timeStart,
    required String timeEnd,
  }) async {
    final uri = Uri.https(_baseUrl, _realtimeDataEndpoint);

    // Non-standard GET with a JSON body
    final request = http.Request("GET", uri)
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode({
        "token": token,
        "timeStart": timeStart,
        "timeEnd": timeEnd,
      });

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);

        // Expecting: { "result": [ { "dt": "...", ...} ] }
        if (jsonMap is Map && jsonMap['result'] is List) {
          final List<dynamic> results = jsonMap['result'];
          return results.map((item) => DrillingData.fromJson(item)).toList();
        } else {
          return <DrillingData>[];
        }
      } else {
        // e.g. 404 or 400
        debugPrint("Status ${response.statusCode}: ${response.body}");
        return <DrillingData>[];
      }
    } catch (e) {
      debugPrint("Exception in _fetchRealtimeDataOnce: $e");
      return <DrillingData>[];
    }
  }

  static Future<List<DrillingData>> fetchMoreData({
    required String token,
    required DateTime referenceTime,
    required bool forward,
    int count = 15,
  }) async {
    DateTime start, end;
    if (forward) {
      start = referenceTime;
      end = referenceTime.add(Duration(minutes: count));
    } else {
      start = referenceTime.subtract(Duration(minutes: count));
      end = referenceTime;
    }

    final timeStartStr = _formatDateTime(start);
    final timeEndStr   = _formatDateTime(end);

    final dataList = await _fetchRealtimeDataOnce(
      token: token,
      timeStart: timeStartStr,
      timeEnd: timeEndStr,
    );
    return dataList;
  }

  /// Format "yyyy-MM-dd HH:mm:ss"
  static String _formatDateTime(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.day.toString().padLeft(2, '0')} "
        "${dt.hour.toString().padLeft(2, '0')}:"
        "${dt.minute.toString().padLeft(2, '0')}:"
        "${dt.second.toString().padLeft(2, '0')}";
  }
}
