// codes/lib/data/services/notification_api/api_client.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kDebugMode;
import 'package:pdu_mobile_rto_app/features/authentication/services/auth_service.dart';

class ApiClient {
  static const String _localPcIp = "103.150.93.56"; // Replace with your VM's actual IP if different
  static const String _devPort = "8003";
  final AuthService _authService = Get.find<AuthService>();


  static String get baseUrl {
    return "http://$_localPcIp:$_devPort/api/v1";
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _authService.getToken();
    if (token == null) {
      debugPrint("Error: Auth token is null. Cannot make authenticated request.");
      return {"Content-Type": "application/json"};
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }


  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    if (kDebugMode) {
      debugPrint('POST Request to: $url');
      debugPrint('Request Body: ${jsonEncode(body)}');
    }
    final headers = await _getAuthHeaders();
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    if (kDebugMode) {
      debugPrint('POST Response Status: ${response.statusCode}');
      debugPrint('POST Response Body: ${response.body}');
    }
    return response;
  }

  Future<http.Response> _put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    if (kDebugMode) {
      debugPrint('PUT Request to: $url');
      debugPrint('Request Body: ${jsonEncode(body)}');
    }
    final headers = await _getAuthHeaders();
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 20));
    if (kDebugMode) {
      debugPrint('PUT Response Status: ${response.statusCode}');
      debugPrint('PUT Response Body: ${response.body}');
    }
    return response;
  }

  Future<http.Response> _delete(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    if (kDebugMode) {
      debugPrint('DELETE Request to: $url');
    }
    final headers = await _getAuthHeaders();
    final response = await http.delete(
      url,
      headers: headers,
    ).timeout(const Duration(seconds: 20));
    if (kDebugMode) {
      debugPrint('DELETE Response Status: ${response.statusCode}');
      debugPrint('DELETE Response Body: ${response.body}');
    }
    return response;
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final url = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);
    if (kDebugMode) {
      debugPrint('GET Request to: $url');
    }
    final headers = await _getAuthHeaders();
    final response = await http.get(
      url,
      headers: headers,
    ).timeout(const Duration(seconds: 20));
    if (kDebugMode) {
      debugPrint('GET Response Status: ${response.statusCode}');
      debugPrint('GET Response Body: ${response.body}');
    }
    return response;
  }


  // --- Device Registration ---
  Future<bool> registerDevice({
    required String fcmToken,
    String? platform,
  }) async {
    try {
      final response = await _post('devices/register', {
        'fcm_token': fcmToken,
        'platform': platform ?? (defaultTargetPlatform == TargetPlatform.android ? 'android' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown')),
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to register device: $e');
      }
      return false;
    }
  }

  // --- Notification Settings CRUD ---
  Future<int?> createNotificationRule({
    required String wellApiToken,
    required String wellName,
    required String parameterJsonKey,
    required String parameterName,
    required double thresholdValue,
    required String condition,
    bool isEnabled = true,
    String? notes,
  }) async {
    try {
      final response = await _post('notifications/rules', {
        'well_api_token': wellApiToken,
        'well_name': wellName,
        'parameter_json_key': parameterJsonKey,
        'parameter_name': parameterName,
        'threshold_value': thresholdValue,
        'condition': condition,
        'is_enabled': isEnabled,
        'notes': notes,
      });
      if (response.statusCode == 201) { // Created
        final responseBody = jsonDecode(response.body);
        return responseBody['id'] as int?; // Server returns the rule with its 'id'
      } else {
        if (kDebugMode) {
          debugPrint('Failed to create notification rule on server: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating notification rule via API: $e');
      }
      return null;
    }
  }

  Future<bool> updateNotificationRule({
    required int serverRuleId,
    required String wellApiToken,
    required String wellName,
    required String parameterJsonKey,
    required String parameterName,
    required double thresholdValue,
    required String condition,
    bool isEnabled = true,
    String? notes,
  }) async {
    try {
      final response = await _put('notifications/rules/$serverRuleId', {
        'well_api_token': wellApiToken,
        'well_name': wellName,
        'parameter_json_key': parameterJsonKey,
        'parameter_name': parameterName,
        'threshold_value': thresholdValue,
        'condition': condition,
        'is_enabled': isEnabled,
        'notes': notes,
      });
      return response.statusCode == 200; // OK
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating notification rule (ID $serverRuleId) via API: $e');
      }
      return false;
    }
  }

  Future<bool> deleteNotificationRule({
    required int serverRuleId,
  }) async {
    try {
      final response = await _delete('notifications/rules/$serverRuleId');
      return response.statusCode == 200; // OK
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting notification rule (ID $serverRuleId) via API: $e');
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationRules() async {
    try {
      final response = await _get('notifications/rules');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => item as Map<String, dynamic>).toList();
      } else {
        if (kDebugMode) {
          print('Failed to get notification rules from server: ${response.statusCode} ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification rules via API: $e');
      }
      return [];
    }
  }

  Future<bool> acknowledgeNotification(String ruleId) async {
    if (kDebugMode) {
      print('ApiClient: Sending acknowledgment for rule ID: $ruleId');
    }
    try {
      // Endpoint: POST /api/v1/notifications/rules/{rule_id}/acknowledge
      final response = await _post('notifications/rules/$ruleId/acknowledge', {}); // Empty body for this POST

      if (kDebugMode) {
        print('ApiClient: Acknowledge response for rule $ruleId: ${response.statusCode}');
      }
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('ApiClient: Error acknowledging notification for rule $ruleId: $e');
      }
      return false;
    }
  }
}