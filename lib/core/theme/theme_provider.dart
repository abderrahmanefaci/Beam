import 'package:flutter/material.dart';

/// Theme provider for managing light/dark mode
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Toggle between light and dark mode
  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  /// Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// Set to light mode
  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  /// Set to dark mode
  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }

  /// Set to system default
  void setSystemMode() {
    _themeMode = ThemeMode.system;
    notifyListeners();
  }
}
