import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  // Get stored authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get stored refresh token
  Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  // Store authentication tokens
  Future<void> storeTokens(String token, String refreshToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_refreshTokenKey, refreshToken);
    } catch (e) {
      print('Error storing tokens: $e');
    }
  }

  // Store user data
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(userData));
    } catch (e) {
      print('Error storing user data: $e');
    }
  }

  // Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null) {
        return json.decode(userDataString);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Store tokens and user data
        await storeTokens(
          data['data']['access_token'],
          data['data']['refresh_token'],
        );
        await storeUserData(data['data']['user']);

        return {
          'success': true,
          'message': 'Login successful',
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Register user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Registration successful',
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Refresh authentication token
  Future<bool> refreshAuthToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'refresh': refreshToken,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await storeTokens(
          data['data']['access_token'],
          refreshToken, // Keep the same refresh token
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Call logout API
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Error during logout API call: $e');
    } finally {
      // Clear local storage regardless of API call result
      await clearAuthData();
    }
  }

  // Clear authentication data
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      print('Error clearing auth data: $e');
    }
  }

  // Make authenticated HTTP request
  Future<http.Response> authenticatedRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    String? token = await getToken();
    
    // If no token, throw exception
    if (token == null) {
      throw Exception('No authentication token available');
    }

    final requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    http.Response response;

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: requestHeaders);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          Uri.parse(url),
          headers: requestHeaders,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: requestHeaders);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    // If token expired, try to refresh
    if (response.statusCode == 401) {
      final refreshed = await refreshAuthToken();
      if (refreshed) {
        // Retry the request with new token
        token = await getToken();
        requestHeaders['Authorization'] = 'Bearer $token';
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(Uri.parse(url), headers: requestHeaders);
            break;
          case 'POST':
            response = await http.post(
              Uri.parse(url),
              headers: requestHeaders,
              body: body != null ? json.encode(body) : null,
            );
            break;
          case 'PUT':
            response = await http.put(
              Uri.parse(url),
              headers: requestHeaders,
              body: body != null ? json.encode(body) : null,
            );
            break;
          case 'DELETE':
            response = await http.delete(Uri.parse(url), headers: requestHeaders);
            break;
        }
      }
    }

    return response;
  }

  // Initialize auth service
  Future<void> initialize() async {
    // Check if user is authenticated and refresh token if needed
    if (await isAuthenticated()) {
      await refreshAuthToken();
    }
  }
}