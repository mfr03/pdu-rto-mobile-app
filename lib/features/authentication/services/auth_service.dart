import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kDebugMode and defaultTargetPlatform
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/app_user_model.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/company.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // TODO: Adjust the baseUrl based on your testing environment (emulator/physical device)
  // For Android Emulator accessing host machine's localhost:
  static final String _authBaseUrl =
  kDebugMode && defaultTargetPlatform == TargetPlatform.android
      ? "http://10.0.2.2:3001/api"
      : "http://localhost:3001/api";

  final _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'auth_employee_id';
  static const String _roleKey = 'auth_role';
  static const String _companyIdKey = 'auth_company_id';
  static const String _emailKey = 'auth_email';


  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$_authBaseUrl/employee/login');
    if (kDebugMode) {
      print('Attempting login to: $url');
      print('Email: $email');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Login Response Status: ${response.statusCode}');
        print('Login Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data']['token'] != null) {
          final String token = responseData['data']['token'];
          final String employeeId = responseData['data']['employeeId'];
          final String role = responseData['data']['role'];
          final String companyId = responseData['data']['companyId'];

          await _secureStorage.write(key: _tokenKey, value: token);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_employeeIdKey, employeeId);
          await prefs.setString(_roleKey, role);
          await prefs.setString(_companyIdKey, companyId);
          await prefs.setString(_emailKey, email); // Store email if needed later

          if (kDebugMode) {
            print('Token stored: $token');
            print('Employee ID: $employeeId, Role: $role, Company ID: $companyId');
          }
          return responseData['data']; // Return the user data part
        } else {
          // Handle cases where token or data is missing in a 200 response
          throw Exception('Login successful but token/data missing in response.');
        }
      } else {
        // Handle other status codes (e.g., 401 Unauthorized, 400 Bad Request)
        // final errorData = jsonDecode(response.body);
        // throw Exception(errorData['message'] ?? 'Login failed');
        // For simplicity, just throwing a generic message for non-200.
        // You might want to parse specific error messages from response.body.
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      rethrow; // Rethrow the exception to be caught by the UI
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_employeeIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_companyIdKey);
    await prefs.remove(_emailKey);
    if (kDebugMode) {
      print('User logged out, token and user data cleared.');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  Future<String?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyIdKey);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<List<AppUser>> getAllUsers() async {
    final token = await getToken(); // Get the stored Bearer token
    if (token == null) {
      throw Exception('Not authenticated. Cannot fetch users.');
    }

    final url = Uri.parse('$_authBaseUrl/employee'); // Uses the same base URL as login
    if (kDebugMode) {
      print('Attempting to fetch all users from: $url');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send the token
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Get All Users Response Status: ${response.statusCode}');
        print('Get All Users Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'] is List) {
          final List<dynamic> usersData = responseData['data'];
          return usersData.map((userData) => AppUser.fromJson(userData)).toList();
        } else {
          throw Exception('User data is not in the expected format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching users: $e');
      }
      rethrow;
    }
  }


  Future<List<Company>> getCompanies() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated. Cannot fetch companies.');
    }

    final url = Uri.parse('$_authBaseUrl/company');
    if (kDebugMode) {
      print('Attempting to fetch companies from: $url');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Get Companies Response Status: ${response.statusCode}');
        print('Get Companies Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null && responseData['data'] is List) {
          final List<dynamic> companiesData = responseData['data'];
          return companiesData.map((companyData) => Company.fromJson(companyData)).toList();
        } else {
          throw Exception('Company data is not in the expected format.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch companies: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching companies: $e');
      }
      rethrow;
    }
  }

  Future<bool> addEmployee({
    required String companyId,
    required String name,
    required String email,
    required String role, // e.g., "USER" or "ADMIN"
    required String password,
  }) async
  {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated. Cannot add employee.');
    }

    final url = Uri.parse('$_authBaseUrl/employee');
    if (kDebugMode) {
      print('Attempting to add employee to: $url');
    }

    final requestBody = {
      "companyId": companyId,
      "employee": [
        {
          "name": name,
          "email": email,
          "role": role.toUpperCase(), // Ensure role is uppercase if API expects it
          "password": password
        }
      ]
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Add Employee Response Status: ${response.statusCode}');
        print('Add Employee Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) { // Typically 201 for created
        // final responseData = jsonDecode(response.body);
        // print(responseData['message']); // "employee created successfully."
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add employee: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding employee: $e');
      }
      rethrow;
    }
  }

  Future<bool> changePassword({
    required String employeeId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Not authenticated. Cannot change password.');
    }

    // Construct the URL with the employeeId
    final url = Uri.parse('$_authBaseUrl/employee/$employeeId/change-password');
    if (kDebugMode) {
      print('Attempting to change password for employee $employeeId at: $url');
    }

    final requestBody = {
      "oldPassword": oldPassword,
      "newPassword": newPassword,
    };

    try {

      final response = await http.put( // Or http.post if that's what the API expects
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('Change Password Response Status: ${response.statusCode}');
        print('Change Password Response Body: ${response.body}');
      }

      // Assuming 200 or 204 No Content for successful password change
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        // Try to get a meaningful error message from common structures
        String errorMessage = 'Failed to change password';
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        } else if (errorData is Map && errorData.containsKey('detail')) {
          if (errorData['detail'] is List && errorData['detail'].isNotEmpty && errorData['detail'][0] is Map && errorData['detail'][0].containsKey('msg')) {
            errorMessage = errorData['detail'][0]['msg'];
          } else if (errorData['detail'] is String) {
            errorMessage = errorData['detail'];
          }
        } else if (response.body.isNotEmpty) {
          errorMessage = response.body; // Fallback to full body if specific message not found
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      rethrow; // Rethrow to be caught by the UI
    }
  }
}