import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_unit.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_variable.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'dart:convert';
import 'model/drilling_data.dart';
import 'model/well_active.dart';

class PduApi {

  static const String _baseUrl = "pdumitradome.id";
  static const String _wellActiveEndpoint = "/dome_api/wells-active";
  static const String _realtimeDataEndpoint = "/dome_api/realtime-data";
  static const String _depthDataEndPoint = "/dome_api/realtime-data-depthbased";

  /// Fetch the list of active wells
  Future<List<WellActive>> fetchActiveWells() async {
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

  Future<List<DrillingData>> fetchRealtimeDataIncrement({
    required WellActive wellActive,
    int maxIterations = 500,}) async
  {
    final rawStartDate = DateTime.parse(wellActive.startDate);

    late DateTime currentStartTime;
    if (wellActive.timeStart.contains(' ')) {
      currentStartTime = DateTime.parse(wellActive.timeStart);
    } else {
      final parts = wellActive.timeStart.split(':').map(int.parse).toList();
      currentStartTime = DateTime(
        rawStartDate.year,
        rawStartDate.month,
        rawStartDate.day,
        parts[0], parts[1], parts[2],
      );
    }

    final rawEndDate = DateTime.parse(wellActive.endDate);
    const step = Duration(minutes: 15);

    while (maxIterations-- > 0 && currentStartTime.isBefore(rawEndDate)) {
      final windowEnd    = currentStartTime.add(step);
      final timeStartStr = CFormatter.formatDateTime(currentStartTime);
      final timeEndStr   = CFormatter.formatDateTime(windowEnd);

      debugPrint(timeStartStr);
      debugPrint(timeEndStr);
      final dataList = await fetchRealtimeDataOnce(
        token:     wellActive.isApiToken,
        timeStart: timeStartStr,
        timeEnd:   timeEndStr,
      );

      if (dataList.isNotEmpty) {
        wellActive.updateTimeRange(timeStartStr, timeEndStr);
        return dataList;
      }

      currentStartTime = windowEnd;
    }

    // if we exit the loop with no data:
    debugPrint("No data found after maxIterations or passed endDate.");
    return <DrillingData>[];
  }

  Future<List<DrillingData>> fetchRealtimeDataOnce({
    required String token,
    required String timeStart,
    required String timeEnd,
  }) async
  {
    final uri = Uri.https(_baseUrl, _realtimeDataEndpoint);

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
          return results.map((item) => DrillingData.fromJson(item as Map<String, dynamic>)).toList();
        } else {
          return <DrillingData>[];
        }
      } else {
        // e.g. 404 or 400
        debugPrint(request.body);
        debugPrint("Status ${response.statusCode}: ${response.body}");
        return <DrillingData>[];
      }
    } catch (e) {
      debugPrint("Exception in _fetchRealtimeDataOnce: $e");
      return <DrillingData>[];
    }
  }

  Future<List<DrillingData>> fetchMoreData({
    required String token,
    required DateTime referenceTime,
    required bool forward,
    int count = 15,
  }) async
  {
    DateTime start, end;
    if (forward) {
      start = referenceTime;
      end = referenceTime.add(Duration(minutes: count));
    } else {
      start = referenceTime.subtract(Duration(minutes: count));
      end = referenceTime;
    }

    final timeStartStr = CFormatter.formatDateTime(start);
    final timeEndStr   = CFormatter.formatDateTime(end);

    final dataList = await fetchRealtimeDataOnce(
      token: token,
      timeStart: timeStartStr,
      timeEnd: timeEndStr,
    );
    return dataList;
  }

  Future<List<DepthDrillingData>> fetchDepthBasedData({
    required String token,
    required String timeStart,
    required String timeEnd,
    required double depthStart,
    required double depthEnd,
    required bool first,
  }) async
  {
    final uri = Uri.https(_baseUrl, _depthDataEndPoint);
    final resp = http.Request("GET", uri)
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode({
        "token":      token,
        "timeStart":  timeStart,
        "timeEnd":    timeEnd,
        "depthStart": depthStart,
        "depthEnd":   depthEnd,
        "first":      first,
      });

    final streamed = await resp.send();
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode != 200) {
      debugPrint("Depth API error ${r.statusCode}: ${r.body}");
      return [];
    }
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    final List<dynamic> results = body["result"] ?? [];
    return results
        .cast<Map<String, dynamic>>()
        .map((j) => DepthDrillingData.fromJson(j))
        .toList();
  }

  Future<List<Variable>> fetchVariables() async {
    final uri = Uri.https(_baseUrl, '/dome_api/variable');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(resp.body);
      final List<dynamic> results = body['result'] ?? [];
      return results
          .cast<Map<String,dynamic>>()
          .map((j) => Variable.fromJson(j))
          .toList();
    }
    throw Exception('Failed to load variables (${resp.statusCode})');
  }

  Future<List<Unit>> fetchUnits() async {
    final uri  = Uri.https(_baseUrl, '/dome_api/units');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final Map<String, dynamic> body    = jsonDecode(resp.body);
      final List<dynamic> results        = body['result'] ?? [];
      return results
          .cast<Map<String, dynamic>>()
          .map((j) => Unit.fromJson(j))
          .toList();
    }
    throw Exception('Failed to load units (${resp.statusCode})');
  }
}
