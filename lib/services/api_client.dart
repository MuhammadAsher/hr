import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'error_service.dart';

class ApiClient {
  // Dynamic base URL based on platform
  static String get _baseUrl {
    if (kIsWeb) {
      // Web development
      return 'http://localhost:3000/api/v1';
    } else if (Platform.isAndroid) {
      // Android emulator - use 10.0.2.2 to access host machine
      return 'http://10.0.2.2:3000/api/v1';
    } else if (Platform.isIOS) {
      // iOS simulator - localhost works
      return 'http://localhost:3000/api/v1';
    } else {
      // Default fallback
      return 'http://localhost:3000/api/v1';
    }
  }

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  String? _refreshToken;
  bool _initialized = false;
  Future<void>? _initializationFuture;

  // Initialize with stored tokens
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializationFuture != null) {
      return _initializationFuture;
    }
    
    _initializationFuture = _loadTokens();
    await _initializationFuture;
    _initialized = true;
  }

  // Load tokens from SharedPreferences
  Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    
    if (_authToken != null) {
      print('🔑 Loaded auth token from storage');
    }
  }

  // Ensure tokens are loaded (lazy loading)
  Future<void> _ensureInitialized() async {
    if (!_initialized || _authToken == null) {
      await _loadTokens();
      _initialized = true;
    }
  }

  // Set authentication tokens
  Future<void> setTokens(String authToken, String refreshToken) async {
    _authToken = authToken;
    _refreshToken = refreshToken;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    
    print('🔑 Auth tokens stored successfully');
  }

  // Clear authentication tokens
  Future<void> clearTokens() async {
    _authToken = null;
    _refreshToken = null;
    _initialized = false;
    _initializationFuture = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    
    print('🔑 Auth tokens cleared');
  }

  // Get headers with authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Get headers with authentication (async version that ensures tokens are loaded)
  Future<Map<String, String>> _getHeadersAsync({bool includeAuth = true}) async {
    if (includeAuth) {
      await _ensureInitialized();
    }
    return _getHeaders(includeAuth: includeAuth);
  }

  // Handle API response
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    // Handle 204 No Content (no response body)
    if (statusCode == 204) {
      print('✅ API Success: $statusCode (No Content)');
      return ApiResponse.success({'message': 'Operation completed successfully'});
    }

    // Handle empty body responses
    if (response.body.isEmpty || response.body.trim().isEmpty) {
      if (statusCode >= 200 && statusCode < 300) {
        print('✅ API Success: $statusCode (Empty body)');
        return ApiResponse.success({'message': 'Operation completed successfully'});
      } else {
        print('❌ API Error: $statusCode (Empty body)');
        return ApiResponse.error(
          statusCode: statusCode,
          message: 'Request failed with status $statusCode',
          error: 'HTTP Error',
        );
      }
    }

    try {
      final data = json.decode(response.body);

      if (statusCode >= 200 && statusCode < 300) {
        // Success response - no error alerts needed
        print('✅ API Success: $statusCode');
        return ApiResponse.success(data);
      } else {
        // Error response - only show alerts for actual errors, not for expected API responses
        print(
          '❌ API Error: $statusCode - ${data['message'] ?? 'Unknown error'}',
        );

        // Don't show automatic error alerts - let the calling services decide
        // This prevents premature error displays when the operation might still succeed
        // Services can check response.isSuccess and handle errors appropriately

        return ApiResponse.error(
          statusCode: statusCode,
          message: data['message'] ?? 'Unknown error occurred',
          error: data['error'] ?? 'Error',
          details: data['details'],
        );
      }
    } catch (e) {
      print('❌ JSON Parse Error: $e');
      // If parsing fails but status is success, return success with raw body
      if (statusCode >= 200 && statusCode < 300) {
        print('⚠️ Warning: Success status but JSON parse failed, returning raw response');
        return ApiResponse.success({'raw': response.body});
      }
      return ApiResponse.error(
        statusCode: statusCode,
        message: 'Failed to parse response',
        error: 'Parse Error',
      );
    }
  }

  // Refresh authentication token
  Future<bool> _refreshAuthToken() async {
    // Ensure tokens are loaded before attempting refresh
    await _ensureInitialized();
    
    if (_refreshToken == null) {
      print('⚠️ Cannot refresh token: refresh token is null');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['data']?['token'] ?? data['token'];
        final refreshToken = data['data']?['refreshToken'] ?? data['refreshToken'];
        
        if (token != null && refreshToken != null) {
          await setTokens(token, refreshToken);
          print('🔑 Token refreshed successfully');
          return true;
        }
      }
    } catch (e) {
      print('❌ Token refresh failed: $e');
    }

    return false;
  }

  // Make authenticated request with automatic token refresh
  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      // Ensure tokens are loaded before making authenticated requests
      if (requireAuth) {
        await _ensureInitialized();
      }

      // Build URL
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Debug logging
      print('🌐 API Request: $method $uri');
      if (body != null) {
        print('📤 Request Body: $body');
      }

      // Prepare request
      late http.Response response;
      final headers = _getHeaders(includeAuth: requireAuth);
      
      // Debug log if token is missing for authenticated requests
      if (requireAuth && _authToken == null) {
        print('⚠️ Warning: Making authenticated request without token');
      } else if (requireAuth && _authToken != null) {
        print('🔑 Using auth token for request');
      }
      
      final bodyJson = body != null ? json.encode(body) : null;

      // Make request based on method with timeout
      const timeout = Duration(seconds: 30);
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: bodyJson)
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: bodyJson)
              .timeout(timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Handle 401 (Unauthorized) - try to refresh token
      if (response.statusCode == 401 && requireAuth && _refreshToken != null) {
        final refreshed = await _refreshAuthToken();
        if (refreshed) {
          // Retry the request with new token
          final newHeaders = _getHeaders(includeAuth: true);
          switch (method.toUpperCase()) {
            case 'GET':
              response = await http.get(uri, headers: newHeaders);
              break;
            case 'POST':
              response = await http.post(
                uri,
                headers: newHeaders,
                body: bodyJson,
              );
              break;
            case 'PUT':
              response = await http.put(
                uri,
                headers: newHeaders,
                body: bodyJson,
              );
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: newHeaders);
              break;
          }
        }
      }

      // Debug logging
      final responsePreview = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      print('📥 API Response: ${response.statusCode} $responsePreview');

      return _handleResponse(response);
    } on SocketException catch (e) {
      print('❌ Socket Exception: $e');
      // Don't show automatic network error - let calling service handle it
      return ApiResponse.error(
        statusCode: 0,
        message: 'Network connection failed',
        error: 'Network Error',
      );
    } on HttpException catch (e) {
      print('❌ HTTP Exception: $e');
      // Don't show error alert for HTTP exceptions, let the response handler deal with it
      return ApiResponse.error(
        statusCode: 0,
        message: 'HTTP error: ${e.message}',
        error: 'HTTP Error',
      );
    } on TimeoutException catch (e) {
      print('❌ Timeout Exception: $e');
      // Don't show automatic timeout error - let calling service handle it
      return ApiResponse.error(
        statusCode: 0,
        message: 'Request timed out',
        error: 'Timeout Error',
      );
    } catch (e) {
      print('❌ Unexpected Error: $e');
      // Don't show automatic error alerts - let calling service handle it
      return ApiResponse.error(
        statusCode: 0,
        message: 'Unexpected error: $e',
        error: 'Unknown Error',
      );
    }
  }

  // Test connectivity to the backend server
  Future<bool> testConnectivity() async {
    try {
      print('🔍 Testing connectivity to: $_baseUrl');
      final response = await http
          .get(Uri.parse(_baseUrl.replaceAll('/api/v1', '/health')))
          .timeout(const Duration(seconds: 10));

      print('🔍 Connectivity test response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('🔍 Connectivity test failed: $e');
      return false;
    }
  }

  // HTTP method wrappers
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) {
    return _makeRequest('GET', endpoint, queryParams: queryParams);
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) {
    return _makeRequest('POST', endpoint, body: body);
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) {
    return _makeRequest('PUT', endpoint, body: body);
  }

  Future<ApiResponse> delete(String endpoint) {
    return _makeRequest('DELETE', endpoint);
  }

  // Public endpoints (no auth required)
  Future<ApiResponse> login(String email, String password, String role) {
    return _makeRequest(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password, 'role': role},
      requireAuth: false,
    );
  }

  Future<ApiResponse> register(
    String organizationName,
    String organizationEmail,
    String? organizationPhone,
    String? organizationAddress,
    String industry,
    String adminName,
    String adminEmail,
    String adminPassword,
    String confirmPassword,
  ) {
    final body = <String, dynamic>{
      'organizationName': organizationName,
      'organizationEmail': organizationEmail,
      'industry': industry,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'adminPassword': adminPassword,
      'confirmPassword': confirmPassword,
    };

    if (organizationPhone != null && organizationPhone.isNotEmpty) {
      body['organizationPhone'] = organizationPhone;
    }
    if (organizationAddress != null && organizationAddress.isNotEmpty) {
      body['organizationAddress'] = organizationAddress;
    }

    return _makeRequest(
      'POST',
      '/auth/register',
      body: body,
      requireAuth: false,
    );
  }

  Future<ApiResponse> logout() {
    return _makeRequest('POST', '/auth/logout');
  }

  Future<ApiResponse> getCurrentUser() {
    return _makeRequest('GET', '/auth/me');
  }

  // Request password reset (public endpoint)
  Future<ApiResponse> requestPasswordReset(String email) {
    return _makeRequest('POST', '/auth/forgot-password',
        body: {'email': email}, requireAuth: false);
  }

  // Reset password with token (public endpoint)
  Future<ApiResponse> resetPassword(String token, String newPassword, String confirmPassword) {
    return _makeRequest('POST', '/auth/reset-password',
        body: {
          'token': token,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        requireAuth: false);
  }

  // Change password (authenticated endpoint)
  Future<ApiResponse> changePassword(String currentPassword, String newPassword, String confirmPassword) {
    return _makeRequest('POST', '/auth/change-password',
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
        requireAuth: true);
  }

  // Check if client is authenticated
  bool get isAuthenticated => _authToken != null;

  // Get current auth token
  String? get authToken => _authToken;
}

// API Response wrapper class
class ApiResponse {
  final bool isSuccess;
  final int statusCode;
  final dynamic data;
  final String? message;
  final String? error;
  final dynamic details;

  ApiResponse._({
    required this.isSuccess,
    required this.statusCode,
    this.data,
    this.message,
    this.error,
    this.details,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(isSuccess: true, statusCode: 200, data: data);
  }

  factory ApiResponse.error({
    required int statusCode,
    required String message,
    required String error,
    dynamic details,
  }) {
    return ApiResponse._(
      isSuccess: false,
      statusCode: statusCode,
      message: message,
      error: error,
      details: details,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ApiResponse.success(data: $data)';
    } else {
      return 'ApiResponse.error(statusCode: $statusCode, error: $error, message: $message)';
    }
  }
}
