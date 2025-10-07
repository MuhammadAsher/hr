import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';

class AuthService {
  static const String _userKey = 'current_user';
  
  // Mock credentials for demo purposes
  // In production, this would connect to a real backend API
  final Map<String, Map<String, dynamic>> _mockUsers = {
    'admin@hr.com': {
      'password': 'admin123',
      'id': '1',
      'name': 'Admin User',
      'role': UserRole.admin,
    },
    'employee@hr.com': {
      'password': 'employee123',
      'id': '2',
      'name': 'Employee User',
      'role': UserRole.employee,
    },
  };

  Future<User?> login(String email, String password, UserRole role) async {
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
        );
        
        // Save user to local storage
        await _saveUser(user);
        return user;
      }
    }
    
    return null; // Login failed
  }

  Future<void> logout() async {
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

