import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'api_client.dart';
import 'error_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  final ApiClient _apiClient = ApiClient();

  // Initialize API client
  Future<void> initialize() async {
    await _apiClient.initialize();
  }

  // Mock credentials for demo purposes (fallback)
  final Map<String, Map<String, dynamic>> _mockUsers = {
    // Super Admin (Platform Administrator)
    'superadmin@hrplatform.com': {
      'password': 'super123',
      'id': 'SUPER001',
      'name': 'Platform Admin',
      'role': UserRole.admin,
      'organizationId': '', // Super admin doesn't belong to any org
      'isSuperAdmin': true,
    },
    // Organization 1 Admin (Tech Solutions Inc.)
    'admin@hr.com': {
      'password': 'admin123',
      'id': '1',
      'name': 'Admin User',
      'role': UserRole.admin,
      'organizationId': 'ORG001',
      'isSuperAdmin': false,
    },
    // Organization 1 Employee
    'employee@hr.com': {
      'password': 'employee123',
      'id': '2',
      'name': 'Employee User',
      'role': UserRole.employee,
      'organizationId': 'ORG001',
      'isSuperAdmin': false,
    },
    // Organization 2 Admin (Global Marketing Agency)
    'admin@globalmarketing.com': {
      'password': 'admin123',
      'id': '3',
      'name': 'Marketing Admin',
      'role': UserRole.admin,
      'organizationId': 'ORG002',
      'isSuperAdmin': false,
    },
    // Organization 2 Employee
    'employee@globalmarketing.com': {
      'password': 'employee123',
      'id': '4',
      'name': 'Marketing Employee',
      'role': UserRole.employee,
      'organizationId': 'ORG002',
      'isSuperAdmin': false,
    },
  };

  Future<User?> login(String email, String password, UserRole role) async {
    // Test connectivity first for debugging
    print('🔍 Testing backend connectivity...');
    final isConnected = await _apiClient.testConnectivity();
    print(
      '🔍 Backend connectivity: ${isConnected ? "✅ Connected" : "❌ Failed"}',
    );

    // Try API login first
    final response = await _apiClient.login(email, password, role.name);

    if (response.isSuccess) {
      final responseData = response.data['data'];
      final userData = responseData['user'];
      final token = responseData['token'];
      final refreshToken = responseData['refreshToken'];

      // Store tokens
      await _apiClient.setTokens(token, refreshToken);

      // Create user object
      final user = User(
        id: userData['id'],
        email: userData['email'],
        name: userData['name'],
        role: UserRole.values.firstWhere(
          (e) => e.name == userData['role'],
          orElse: () => UserRole.employee,
        ),
        organizationId: userData['organizationId'] ?? '',
        isSuperAdmin: userData['isSuperAdmin'] ?? false,
      );

      // Save user to local storage
      await _saveUser(user);
      return user;
    } else {
      // API login failed - check if it's a network error or authentication error
      if (response.statusCode == 0) {
        // Network error - show appropriate message and try mock login
        print('Network error during login, falling back to mock login');
        return _mockLogin(email, password, role);
      } else if (response.statusCode == 401) {
        // Authentication failed - show error and don't fallback
        ErrorService.showErrorSnackbar(
          message: response.message ?? 'Invalid credentials',
          error: 'Login Failed',
        );
        return null;
      } else {
        // Other API error - show error and try mock login
        print(
          'API login failed (${response.statusCode}), falling back to mock: ${response.message}',
        );
        return _mockLogin(email, password, role);
      }
    }
  }

  // Mock login fallback
  Future<User?> _mockLogin(String email, String password, UserRole role) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Check if user exists and credentials match
    if (_mockUsers.containsKey(email)) {
      final userData = _mockUsers[email]!;

      if (userData['password'] == password && userData['role'] == role) {
        final user = User(
          id: userData['id'],
          email: email,
          name: userData['name'],
          role: userData['role'],
          organizationId: userData['organizationId'] ?? '',
          isSuperAdmin: userData['isSuperAdmin'] ?? false,
        );

        // Save user to local storage
        await _saveUser(user);
        return user;
      }
    }

    return null; // Login failed
  }

  Future<void> logout() async {
    try {
      // Try API logout
      await _apiClient.logout();
    } catch (e) {
      // Ignore API logout errors
    }

    // Clear tokens and local storage
    await _apiClient.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        return User.fromJson(userMap);
      } catch (e) {
        return null;
      }
    }

    return null;
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Register new organization with admin account
  Future<User?> registerOrganization({
    required String organizationName,
    required String organizationEmail,
    String? organizationPhone,
    String? organizationAddress,
    required String industry,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required String confirmPassword,
  }) async {
    try {
      final body = {
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

      // Register endpoint doesn't require auth
      final response = await _apiClient.register(
        organizationName,
        organizationEmail,
        organizationPhone,
        organizationAddress,
        industry,
        adminName,
        adminEmail,
        adminPassword,
        confirmPassword,
      );

      if (response.isSuccess) {
        final responseData = response.data['data'];
        final userData = responseData['user'];

        // Don't store tokens or user - user should login manually
        // Create user object just for return value (to indicate success)
        final user = User(
          id: userData['id'],
          email: userData['email'],
          name: userData['name'],
          role: UserRole.values.firstWhere(
            (e) => e.name == userData['role'],
            orElse: () => UserRole.admin,
          ),
          organizationId: userData['organizationId'] ?? '',
          isSuperAdmin: userData['isSuperAdmin'] ?? false,
        );

        // Don't save user or tokens - user needs to login manually
        return user;
      } else {
        ErrorService.showErrorSnackbar(
          message: response.message ?? 'Registration failed',
          error: 'Registration Error',
        );
        return null;
      }
    } catch (e) {
      print('Registration error: $e');
      ErrorService.showErrorSnackbar(
        message: 'Registration failed: ${e.toString()}',
        error: 'Registration Error',
      );
      return null;
    }
  }

  // Request password reset
  Future<bool> requestPasswordReset(String email) async {
    try {
      final response = await _apiClient.requestPasswordReset(email);
      if (response.isSuccess) {
        return true;
      } else {
        ErrorService.showErrorSnackbar(
          message: response.message ?? 'Failed to send password reset email',
          error: 'Password Reset Error',
        );
        return false;
      }
    } catch (e) {
      print('Request password reset error: $e');
      ErrorService.showErrorSnackbar(
        message: 'Failed to request password reset: ${e.toString()}',
        error: 'Password Reset Error',
      );
      return false;
    }
  }

  // Reset password with token
  Future<bool> resetPassword(String token, String newPassword, String confirmPassword) async {
    try {
      final response = await _apiClient.resetPassword(token, newPassword, confirmPassword);
      if (response.isSuccess) {
        return true;
      } else {
        ErrorService.showErrorSnackbar(
          message: response.message ?? 'Failed to reset password',
          error: 'Password Reset Error',
        );
        return false;
      }
    } catch (e) {
      print('Reset password error: $e');
      ErrorService.showErrorSnackbar(
        message: 'Failed to reset password: ${e.toString()}',
        error: 'Password Reset Error',
      );
      return false;
    }
  }

  // Change password (authenticated)
  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final response = await _apiClient.changePassword(currentPassword, newPassword, confirmPassword);
      if (response.isSuccess) {
        return true;
      } else {
        ErrorService.showErrorSnackbar(
          message: response.message ?? 'Failed to change password',
          error: 'Change Password Error',
        );
        return false;
      }
    } catch (e) {
      print('Change password error: $e');
      ErrorService.showErrorSnackbar(
        message: 'Failed to change password: ${e.toString()}',
        error: 'Change Password Error',
      );
      return false;
    }
  }
}
