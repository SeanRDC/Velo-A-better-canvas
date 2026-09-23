// Global Application State and Preferences
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;
  
  bool _isOffline;
  ThemeMode _themeMode;

  AppState(this._prefs) 
      : _isOffline = _prefs.getBool('isOffline') ?? false,
        _themeMode = _prefs.getString('theme') == 'dark' 
            ? ThemeMode.dark 
            : ThemeMode.light;

  bool get isOffline => _isOffline;
  ThemeMode get themeMode => _themeMode;

  void toggleOffline() {
    _isOffline = !_isOffline;
    _prefs.setBool('isOffline', _isOffline);
    notifyListeners();
  }

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString('theme', mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}