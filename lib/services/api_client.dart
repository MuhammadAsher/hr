import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String _baseUrl = 'http://localhost:3000/api/v1';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String? _authToken;
  String? _refreshToken;

  // Initialize with stored tokens
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
  }

  // Set authentication tokens
  Future<void> setTokens(String authToken, String refreshToken) async {
    _authToken = authToken;
    _refreshToken = refreshToken;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, authToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  // Clear authentication tokens
  Future<void> clearTokens() async {
    _authToken = null;
    _refreshToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
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

  // Handle API response
  ApiResponse _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    try {
      final data = json.decode(response.body);
      
      if (statusCode >= 200 && statusCode < 300) {
        return ApiResponse.success(data);
      } else {
        return ApiResponse.error(
          statusCode: statusCode,
          message: data['message'] ?? 'Unknown error occurred',
          error: data['error'] ?? 'Error',
          details: data['details'],
        );
      }
    } catch (e) {
      return ApiResponse.error(
        statusCode: statusCode,
        message: 'Failed to parse response',
        error: 'Parse Error',
      );
    }
  }

  // Refresh authentication token
  Future<bool> _refreshAuthToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setTokens(data['token'], data['refreshToken']);
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
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
      // Build URL
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      // Prepare request
      late http.Response response;
      final headers = _getHeaders(includeAuth: requireAuth);
      final bodyJson = body != null ? json.encode(body) : null;

      // Make request based on method
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: bodyJson);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: bodyJson);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
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
              response = await http.post(uri, headers: newHeaders, body: bodyJson);
              break;
            case 'PUT':
              response = await http.put(uri, headers: newHeaders, body: bodyJson);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: newHeaders);
              break;
          }
        }
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error(
        statusCode: 0,
        message: 'No internet connection',
        error: 'Network Error',
      );
    } on HttpException {
      return ApiResponse.error(
        statusCode: 0,
        message: 'HTTP error occurred',
        error: 'HTTP Error',
      );
    } catch (e) {
      return ApiResponse.error(
        statusCode: 0,
        message: 'Unexpected error: $e',
        error: 'Unknown Error',
      );
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
      body: {
        'email': email,
        'password': password,
        'role': role,
      },
      requireAuth: false,
    );
  }

  Future<ApiResponse> logout() {
    return _makeRequest('POST', '/auth/logout');
  }

  Future<ApiResponse> getCurrentUser() {
    return _makeRequest('GET', '/auth/me');
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
    return ApiResponse._(
      isSuccess: true,
      statusCode: 200,
      data: data,
    );
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
