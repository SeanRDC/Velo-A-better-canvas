// Global Application State and Preferences
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  bool _isOffline;
  ThemeMode _themeMode;
  bool _pushEnabled;

  AppState(this._prefs)
      : _isOffline = _prefs.getBool('isOffline') ?? false,
        _themeMode = _prefs.getString('theme') == 'dark'
            ? ThemeMode.dark
            : ThemeMode.light,
        _pushEnabled = _prefs.getBool('pushEnabled') ?? false {
    _initNotifications();
  }

  bool get isOffline => _isOffline;
  ThemeMode get themeMode => _themeMode;
  bool get pushEnabled => _pushEnabled;

  Future<void> _initNotifications() async {
    // Skip native initialization if running in a web browser
    if (kIsWeb) return;

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings, 
      iOS: iosSettings
    );
    
    await _notificationsPlugin.initialize(settings: initSettings);
  }

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

  Future<void> togglePushNotifications() async {
    // Ask for native OS permissions only if turning it ON, and not on the web
    if (!_pushEnabled && !kIsWeb) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
      }
    }

    _pushEnabled = !_pushEnabled;
    _prefs.setBool('pushEnabled', _pushEnabled);
    notifyListeners();
  }
}