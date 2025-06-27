import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kDebugMode and defaultTargetPlatform
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/app_user_model.dart';
import 'package:pdu_mobile_rto_app/features/admin/models/company.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';

class AuthService {
  static final String _authBaseUrl = "http://103.150.93.56:3001/api";

  final _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'auth_employee_id';
  static const String _roleKey = 'auth_role';
  static const String _companyIdKey = 'auth_company_id';
  static const String _emailKey = 'auth_email';
  static const String _userNameKey = 'auth_user_name';

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

          try {
            await fetchAndCacheUserName(employeeId); // Pass the employeeId just retrieved
          } catch (e) {
            if (kDebugMode) {
              print("AuthService: Failed to fetch/cache user name immediately after login: $e");
              // Non-critical error for login flow, name can be fetched later.
            }
          }


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

  Future<String?> fetchAndCacheUserName([String? existingEmployeeId]) async {
    final token = await getToken();
    if (token == null) {
      if (kDebugMode) print("AuthService: No token, cannot fetch user name.");
      return null; // Or throw Exception('Not authenticated.');
    }

    final employeeId = existingEmployeeId ?? await getEmployeeId();
    if (employeeId == null) {
      if (kDebugMode) print("AuthService: No employeeId, cannot fetch user name.");
      return null; // Or throw Exception('Employee ID not found.');
    }

    final url = Uri.parse('$_authBaseUrl/employee/$employeeId');
    if (kDebugMode) {
      print('AuthService: Fetching user details from: $url');
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('AuthService: Get User Details Response Status: ${response.statusCode}');
        print('AuthService: Get User Details Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Assuming the response structure is {"message": "...", "data": {"id": ..., "name": ..., ...}}
        if (responseData['data'] != null && responseData['data']['name'] != null) {
          final String userName = responseData['data']['name'];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_userNameKey, userName);
          if (kDebugMode) {
            print('AuthService: User name fetched and cached: "$userName"');
          }
          return userName;
        } else {
          if (kDebugMode) print('AuthService: "name" field not found in user details response data.');
          return null;
        }
      } else {
        // final errorData = jsonDecode(response.body);
        // throw Exception(errorData['message'] ?? 'Failed to fetch user details: ${response.statusCode}');
        if (kDebugMode) print('AuthService: Failed to fetch user details, status: ${response.statusCode}');
        return null; // Don't throw an exception that might break UI, allow fallback
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService: Error fetching user details: $e');
      }
      return null; // Gracefully return null on error
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_employeeIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_companyIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_userNameKey); // Clear stored name on logout
    if (kDebugMode) {
      print('User logged out, token and all user data cleared.');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<bool> isTokenExpired() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');

    if (token == null || token.isEmpty) {
      // If there's no token, we can consider it "expired" for the purpose of being logged in.
      return true;
    }

    try {
      // Decode the token to get its payload
      Map<String, dynamic> payload = Jwt.parseJwt(token);

      // JWT 'exp' claim is in seconds since epoch.
      final int expiryTimestamp = payload['exp'] as int;
      final int currentTimestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();

      // If the expiry time is in the past, the token is expired.
      return currentTimestamp > expiryTimestamp;
    } catch (e) {
      // If the token is malformed or can't be decoded, treat it as expired.
      print('Error decoding token: $e');
      return true;
    }
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

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString(_userNameKey);
    if (userName != null && userName.isNotEmpty) {
      if (kDebugMode) print('AuthService: Got user name from cache: "$userName"');
      return userName;
    }
    // If not in cache, try to fetch it (this will also cache it)
    if (kDebugMode) print('AuthService: User name not in cache, attempting to fetch...');
    return await fetchAndCacheUserName();
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
  }) async
  {
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