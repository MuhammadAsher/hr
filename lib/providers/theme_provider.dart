import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _storageKey = 'app_theme_mode';

  ThemeMode _themeMode = ThemeMode.light;
  bool _initialized = false;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isInitialized => _initialized;

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _themeMode.name);
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_storageKey);
    if (storedMode != null) {
      try {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.name == storedMode,
          orElse: () => ThemeMode.light,
        );
      } catch (_) {
        _themeMode = ThemeMode.light;
      }
    }
    _initialized = true;
    notifyListeners();
  }
}
