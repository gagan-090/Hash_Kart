import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  
  ThemeProvider() {
    _loadThemePreference();
  }
  
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveThemePreference();
    notifyListeners();
  }
  
  Future<void> setTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _saveThemePreference();
    notifyListeners();
  }
  
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
}
