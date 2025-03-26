import 'package:flutter/cupertino.dart';

import '../../../features/charts/model/chart_drilling_data.dart';
import 'package:http/http.dart' as http;
import 'model/well_active.dart';
import 'dart:convert';


class PduApi {

  static const String _baseUrl = "pdumitradome.id";
  static const String _wellActiveEndpoint = "/dome_api/wells-active";
  static const String _realtimeDataEndpoint = "/dome_api/realtime-data";


  static Future<List<WellActive>> fetchActiveWells() async {
    final url = Uri.http(_baseUrl, _wellActiveEndpoint);

    try {
      final response = await http.get(url);

      debugPrint(response.body);

      if (response.statusCode == 200) {
        // Decode the response body
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Check if the response contains the 'result' list
        if (data["result"] != null) {
          final List<dynamic> results = data["result"];
          // Map each element in `results` to a `WellActive` instance
          return results.map((json) => WellActive.fromJson(json)).toList();
        } else {
          // The JSON structure is unexpected
          throw Exception("Key 'result' not found in JSON.");
        }
      } else {
        // The server did not return a 200 OK response
        throw Exception("Failed to load wells. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // Rethrow any errors
      throw Exception(e.toString());
    }
  }

  static Future<void> fetchRealtimeData({
    required String token,
    required String timeStart,
    required String timeEnd,
}) async {

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
          // For now, just print the response
          debugPrint("Realtime Data (Success): ${response.body}");
        } else {
          debugPrint("Realtime Data (Error): ${response.statusCode}, ${response.body}");
        }
      } catch (e) {
        debugPrint("Realtime Data (Exception): $e");
      }
    }

  DateTime? _lastGeneratedTime;
  static double alwaysPlus = 0;
  /// Generates data forward or backward in time based on direction
  Future<List<DrillingData>> fetchDrillingData({
    required int count,
    required bool forward,
    DateTime? referenceTime,
  }) async {
    final List<DrillingData> data = [];
    final baseTime = referenceTime ?? DateTime.now();
    final timeIncrement = forward ? 1 : -1;

    for (int i = 0; i < count; i++) {
      final time = baseTime.add(Duration(minutes: (i + 1) * timeIncrement));
      data.add(_generateDataPoint(time, i));
    }

    _lastGeneratedTime = forward ? data.last.dateTime : data.first.dateTime;
    return forward ? data : data.reversed.toList();
  }

  DrillingData _generateDataPoint(DateTime time, int index) {
    alwaysPlus += index * 5;
    return DrillingData(
      dateTime: time,
      bitDepth: alwaysPlus,
      scfm: 50 + index.toDouble(),
      mudCondIn: 1000 + (index * 5).toDouble(),
      blockPos: (index * 1.2),
      wob: 10 + index.toDouble(),
      ropi: 20 + (index * 0.5),
      bvDepth: (index * 2.2),
      mudCondOut: 900 + (index * 5).toDouble(),
      torque: 5 + (index * 0.25),
      rpm: 100 + (index % 5),
      hkld: 15 + index.toDouble(),
      logDepth: (index * 5).toDouble(),
      h2s_1: index.toDouble(),
      mudFlowOutp: 150.0 + index,
      totSPM: 30.0 + index,
      spPress: 800 + index.toDouble() * 2,
      mudFlowIn: 200.0 + index,
      co2_1: 0.5 + (index * 0.01),
      gas: 1.0 + (index * 0.02),
      mudTempIn: 30 + index * 0.1,
      mudTempOut: 40 + index * 0.1,
      tankVolTot: 500 + (index * 10),
    );
  }
}