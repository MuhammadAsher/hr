import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authService.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password, UserRole role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password, role);

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid credentials or role mismatch';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during login';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      final success = await _authService.changePassword(currentPassword, newPassword, confirmPassword);
      if (!success) {
        _errorMessage = 'Failed to change password. Please verify your details and try again.';
        notifyListeners();
      } else {
        _errorMessage = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Unable to change password at the moment.';
      notifyListeners();
      return false;
    }
  }

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerOrganization(
        organizationName: organizationName,
        organizationEmail: organizationEmail,
        organizationPhone: organizationPhone,
        organizationAddress: organizationAddress,
        industry: industry,
        adminName: adminName,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        confirmPassword: confirmPassword,
      );

      if (user != null) {
        // Don't automatically log in - user should login manually
        // Clear user so they go back to login screen
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return user; // Return user to indicate success, but don't set as current
      } else {
        _errorMessage = 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'An error occurred during registration';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
