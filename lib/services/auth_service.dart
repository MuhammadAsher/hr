import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'api_client.dart';

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
    try {
      // Try API login first
      final response = await _apiClient.login(email, password, role.name);

      if (response.isSuccess) {
        final userData = response.data['user'];
        final token = response.data['token'];
        final refreshToken = response.data['refreshToken'];

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
      }
    } catch (e) {
      print('API login failed, falling back to mock: $e');
    }

    // Fallback to mock login for development
    return _mockLogin(email, password, role);
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
}
