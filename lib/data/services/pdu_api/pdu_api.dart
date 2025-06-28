import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/depth_drilling_data.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_unit.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/drill_variable.dart';
import 'package:pdu_mobile_rto_app/data/services/pdu_api/model/remark_item.dart';
import 'package:pdu_mobile_rto_app/utils/formatters/formatter.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'model/drilling_data.dart';
import 'model/well_active.dart';

class PduApi {

  static const String _baseUrl = "pdumitradome.id";
  static const String _wellActiveEndpoint = "/dome_api/wells-active";
  static const String _realtimeDataEndpoint = "/dome_api/realtime-data";
  static const String _depthDataEndPoint = "/dome_api/realtime-data-depthbased";
  static const String _realtimeRemarkEndpoint = "/dome_api/realtime-data-remark";

  Future<List<WellActive>> fetchActiveWells({
    String? userRole,
    String? userCompany,
  }) async {
    final url = Uri.http(_baseUrl, _wellActiveEndpoint);

    try {
      final response = await http.get(url);
      debugPrint(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["result"] != null) {
          final List<dynamic> results = data["result"];
          List<WellActive> allWells =
          results.map((json) => WellActive.fromJson(json)).toList();

          if (userRole?.toLowerCase() == 'admin') {
            debugPrint("User is admin, returning all wells.");
            return allWells;
          }

          if (userRole?.toLowerCase() == 'user' && userCompany != null) {
            debugPrint("User is a regular user, filtering for company: $userCompany");
            return allWells
                .where((well) =>
            well.companyName?.toLowerCase() == userCompany.toLowerCase())
                .toList();
          }

          return allWells;
        } else {
          throw Exception("Key 'result' not found in JSON.");
        }
      } else {
        throw Exception(
            "Failed to load wells. Status code: ${response.statusCode}");
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
    int count = 15, // Total minutes to fetch
  }) async
  {
    final List<DrillingData> combinedResults = [];
    int remainingMinutes = count;
    const int maxChunkMinutes = 15;

    if (forward) {
      DateTime currentStartTime = referenceTime;
      while (remainingMinutes > 0) {
        final int chunkMinutes = math.min(remainingMinutes, maxChunkMinutes);
        final DateTime currentEndTime = currentStartTime.add(Duration(minutes: chunkMinutes));

        final chunkResults = await fetchRealtimeDataOnce(
          token: token,
          timeStart: CFormatter.formatDateTime(currentStartTime),
          timeEnd: CFormatter.formatDateTime(currentEndTime),
        );
        combinedResults.addAll(chunkResults);

        currentStartTime = currentEndTime;
        remainingMinutes -= chunkMinutes;
      }
    } else { // backward
      DateTime currentEndTime = referenceTime;
      while (remainingMinutes > 0) {
        final int chunkMinutes = math.min(remainingMinutes, maxChunkMinutes);
        final DateTime currentStartTime = currentEndTime.subtract(Duration(minutes: chunkMinutes));

        final chunkResults = await fetchRealtimeDataOnce(
          token: token,
          timeStart: CFormatter.formatDateTime(currentStartTime),
          timeEnd: CFormatter.formatDateTime(currentEndTime),
        );
        // Prepend results to maintain chronological order
        combinedResults.insertAll(0, chunkResults);

        currentEndTime = currentStartTime;
        remainingMinutes -= chunkMinutes;
      }
    }
    return combinedResults;
  }

  Future<List<DepthDrillingData>> _fetchDepthDataOnce({
    required String token,
    required String timeStart,
    required String timeEnd,
    required double depthStart,
    required double depthEnd,
    required bool first,
  }) async
  {
    final uri = Uri.https(_baseUrl, _depthDataEndPoint);
    final request = http.Request("GET", uri)
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode({
        "token": token,
        "timeStart": timeStart,
        "timeEnd": timeEnd,
        "depthStart": depthStart,
        "depthEnd": depthEnd,
        "first": first,
      });

    debugPrint("PDU API [Depth Request Body]: ${jsonEncode(request.body)}");

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        debugPrint("Depth API error ${response.statusCode}: ${response.body}");
        return [];
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> results = body["result"] ?? [];
      return results
          .cast<Map<String, dynamic>>()
          .map((j) => DepthDrillingData.fromJson(j))
          .toList();
    } catch(e) {
      return [];
    }

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

    if (first) {
      return _fetchDepthDataOnce(
        token: token,
        timeStart: timeStart,
        timeEnd: timeEnd,
        depthStart: depthStart,
        depthEnd: depthEnd,
        first: true,
      );
    }

    // For subsequent time-based calls, implement chunking.
    final List<DepthDrillingData> combinedResults = [];
    final DateTime startTime = DateTime.parse(timeStart);
    final DateTime endTime = DateTime.parse(timeEnd);
    final int totalMinutes = endTime.difference(startTime).inMinutes;

    if (totalMinutes <= 0) return [];

    int remainingMinutes = totalMinutes;
    const int maxChunkMinutes = 15;
    DateTime currentStartTime = startTime;

    while (remainingMinutes > 0) {
      final int chunkMinutes = math.min(remainingMinutes, maxChunkMinutes);
      final DateTime currentEndTime = currentStartTime.add(Duration(minutes: chunkMinutes));

      final chunkResults = await _fetchDepthDataOnce(
        token: token,
        timeStart: CFormatter.formatDateTime(currentStartTime),
        timeEnd: CFormatter.formatDateTime(currentEndTime),
        depthStart: depthStart,
        depthEnd: depthEnd,
        first: false,
      );
      combinedResults.addAll(chunkResults);

      currentStartTime = currentEndTime;
      remainingMinutes -= chunkMinutes;
    }

    return combinedResults;
  }

  Future<List<DrillingData>> fetchAbsoluteTimeRangeData({
    required String token,
    required DateTime startTime,
    required DateTime endTime,
  }) async
  {
    final List<DrillingData> combinedResults = [];
    final int totalMinutes = endTime.difference(startTime).inMinutes;

    if (totalMinutes <= 0) return [];

    int remainingMinutes = totalMinutes;
    const int maxChunkMinutes = 15;
    DateTime currentStartTime = startTime;

    while (remainingMinutes > 0) {
      final int chunkMinutes = math.min(remainingMinutes, maxChunkMinutes);
      final DateTime currentEndTime = currentStartTime.add(Duration(minutes: chunkMinutes));

      final chunkResults = await fetchRealtimeDataOnce(
        token: token,
        timeStart: CFormatter.formatDateTime(currentStartTime),
        timeEnd: CFormatter.formatDateTime(currentEndTime),
      );
      combinedResults.addAll(chunkResults);

      currentStartTime = currentEndTime;
      remainingMinutes -= chunkMinutes;
    }

    return combinedResults;
  }

  Future<List<RemarkItem>> fetchRemarksData({
    required String token,
    required String timeStart,
    required String timeEnd,
  }) async
  {
    final uri = Uri.https(_baseUrl, _realtimeRemarkEndpoint);

    final Map<String, dynamic> requestBody = {
      "token": token,
      "timeStart": timeStart,
      "timeEnd": timeEnd,
    };

    final request = http.Request("GET", uri)
      ..headers["Content-Type"] = "application/json"
      ..body = jsonEncode(requestBody);

    // DEBUG STATEMENT ADDED HERE
    debugPrint("PDU API [Remarks] Request URL: $uri");
    debugPrint("PDU API [Remarks] Request Body: ${request.body}");

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["result"] != null) {
          final List<dynamic> results = data["result"];
          return results.map((json) => RemarkItem.fromJson(json)).toList();
        } else {
          debugPrint("PDU API [Remarks]: Key 'result' not found in JSON response.");
          return [];
        }
      } else {
        debugPrint("PDU API [Remarks]: Failed to load remarks. Status code: ${response.statusCode}, Body: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("PDU API [Remarks]: Exception fetching remarks: $e");
      return [];
    }
  }

  Future<List<DrillVariable>> fetchAvailableVariables() async
  {
    final uri = Uri.http(_baseUrl,'/dome_api/variable');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // 2. Decode the entire JSON object response.
        final Map<String, dynamic> responseData = json.decode(response.body);

        // 3. Check the status and extract the list from the 'result' key.
        if (responseData['status'] == 200 && responseData['result'] is List) {
          final List<dynamic> variableList = responseData['result'];

          // 4. Map the extracted list to your DrillVariable model.
          return variableList
              .map((json) => DrillVariable.fromJson(json))
              .toList();
        } else {
          if (kDebugMode) {
            print('API returned status ${responseData['status']} or result is not a list.');
          }
          return [];
        }
      } else {
        if (kDebugMode) {
          print('Failed to fetch variables. HTTP Status: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during fetchAvailableVariables: $e');
      }
      return [];
    }
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
