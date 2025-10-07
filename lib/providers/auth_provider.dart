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
    _checkAuthStatus();
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

