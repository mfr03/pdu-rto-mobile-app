// lib/data/services/api/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kDebugMode; // For debug prints

class ApiClient {
  // TODO: Replace with your actual backend URL.
  // For local development with Docker, if your PC's IP is 192.168.1.100 and Docker exposes port 8000:
  // static const String _baseUrl = "http://192.168.1.100:8000/api/v1";
  // If using Android emulator, it can typically access host's localhost via 10.0.2.2:
  // static const String _emulatorBaseUrl = "http://10.0.2.2:8000/api/v1";
  // For iOS simulator, localhost or 127.0.0.1 usually works directly if server is on same machine.
  // For physical devices on the same network, use your PC's local network IP.
  // For deployed server, use its public URL.
  static const String _localPcIp = "70.153.8.55"; // E.g., "192.168.1.5"
  static const String _devPort = "8000"; // Port mapped in docker-compose.yml for your API

  static String get baseUrl {
    if (kDebugMode) {
      // This logic might need adjustment based on your exact testing setup (emulator vs physical device)
      // For Android Emulator accessing host machine:
      // if (defaultTargetPlatform == TargetPlatform.android) return "http://10.0.2.2:$_devPort/api/v1";
      // For physical device testing on same local network:
      return "http://$_localPcIp:$_devPort/api/v1";
    } else {
      return "YOUR_PRODUCTION_BACKEND_URL/api/v1"; // Replace with your deployed URL
    }
  }

  Future<http.Response> _post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    if (kDebugMode) {
      print('POST Request to: $url');
      print('Request Body: ${jsonEncode(body)}');
    }
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20)); // Added timeout

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in POST $url: $e');
      }
      // Rethrow a more specific error or handle it
      rethrow;
    }
  }

  Future<http.Response> _get(String endpoint, {Map<String, String>? queryParams}) async {
    final url = Uri.parse('$baseUrl/$endpoint').replace(queryParameters: queryParams);
    if (kDebugMode) {
      print('GET Request to: $url');
    }
    try {
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 20)); // Added timeout

      if (kDebugMode) {
        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }
      return response;
    } catch (e) {
      if (kDebugMode) {
        print('Error in GET $url: $e');
      }
      rethrow;
    }
  }


  // --- Device Registration ---
  Future<bool> registerDevice({
    required String userId, // Or a unique device ID if not using user accounts yet
    required String fcmToken,
    String? platform, // Optional: "android" or "ios"
  }) async {
    try {
      final response = await _post('devices/register', { // Endpoint to be created in Step 12
        'user_id_from_request': userId,
        'fcm_token': fcmToken,
        'platform': platform ?? (defaultTargetPlatform == TargetPlatform.android ? 'android' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'unknown')),
      });
      return response.statusCode == 200 || response.statusCode == 201; // Assuming 200 OK or 201 Created
    } catch (e) {
      if (kDebugMode) {
        print('Failed to register device: $e');
      }
      return false;
    }
  }

  // --- Notification Settings CRUD ---
  Future<bool> createNotificationRule({
    required String userId, // Will come from auth later
    required String wellApiToken,
    required String parameterJsonKey,
    required String parameterName,
    required double thresholdValue,
    required String condition, // "above" or "below"
    bool isEnabled = true,
    String? notes,
  }) async {
    try {
      // The endpoint from Step 10 was /users/{user_id}/rules
      final response = await _post('notifications/users/$userId/rules', {
        'well_api_token': wellApiToken,
        'parameter_json_key': parameterJsonKey,
        'parameter_name': parameterName,
        'threshold_value': thresholdValue,
        'condition': condition,
        'is_enabled': isEnabled,
        'notes': notes,
      });
      return response.statusCode == 201; // Created
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create notification rule: $e');
      }
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationRules(String userId) async {
    try {
      final response = await _get('notifications/users/$userId/rules');
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => item as Map<String, dynamic>).toList();
      } else {
        if (kDebugMode) {
          print('Failed to get notification rules: ${response.statusCode} ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting notification rules: $e');
      }
      return [];
    }
  }

// TODO: Implement updateNotificationRule and deleteNotificationRule methods
// similar to createNotificationRule, using _put and _delete helper methods (which you'd also create)
// For PUT: final response = await _put('notifications/rules/$ruleId', { ... });
// For DELETE: final response = await _delete('notifications/rules/$ruleId');
}