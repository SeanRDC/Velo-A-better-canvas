// Global Application State and Preferences
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isOffline;
  ThemeMode _themeMode;
  bool _pushEnabled;
  bool _headsUpEnabled;
  final List<String> _reminderOffsets;
  int unreadInboxCount = 0;

  void updateUnreadInboxCount(int count) {
    unreadInboxCount = count;
    notifyListeners();
  }

  AppState(this._prefs)
      : _isOffline = _prefs.getBool('isOffline') ?? false,
        _themeMode = _prefs.getString('theme') == 'dark' ? ThemeMode.dark : ThemeMode.light,
        _pushEnabled = _prefs.getBool('pushEnabled') ?? false,
        _headsUpEnabled = _prefs.getBool('headsUpEnabled') ?? false,
        _reminderOffsets = _prefs.getStringList('reminderOffsets') ?? ['3d', '1d'] {
    _initNotifications();
  }

  bool get isOffline => _isOffline;
  ThemeMode get themeMode => _themeMode;
  bool get pushEnabled => _pushEnabled;
  bool get headsUpEnabled => _headsUpEnabled;
  List<String> get reminderOffsets => _reminderOffsets;
  String? get lastSyncTime => _prefs.getString('last_sync_time');

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
    
    try {
      await _notificationsPlugin.initialize(settings: initSettings);
    } catch (e) {
      // No notification support on this platform; the app works without it
      debugPrint('Notifications unavailable: $e');
    }
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

  Future<void> toggleHeadsUpNotifications() async {
    if (!_headsUpEnabled && !kIsWeb) {
      final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) await androidPlugin.requestNotificationsPermission();

      final iosPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
    }

    _headsUpEnabled = !_headsUpEnabled;
    _prefs.setBool('headsUpEnabled', _headsUpEnabled);
    
    if (!_headsUpEnabled) {
      await _notificationsPlugin.cancelAll();
    }
    
    notifyListeners();
  }

  void toggleReminderOffset(String offset) {
    if (_reminderOffsets.contains(offset)) {
      _reminderOffsets.remove(offset);
    } else {
      _reminderOffsets.add(offset);
    }
    _prefs.setStringList('reminderOffsets', _reminderOffsets);
    notifyListeners();
  }

  Future<void> scheduleDeadlines(List<Task> tasks) async {
    if (!_headsUpEnabled || kIsWeb) return;
    
    await _notificationsPlugin.cancelAll();

    for (var task in tasks) {
      if (task.isSubmitted) continue;
      if (task.dueDate.isBefore(DateTime.now())) continue;

      for (var offset in _reminderOffsets) {
        DateTime scheduleTime;
        String timeLabel;
        
        if (offset == '1w') { scheduleTime = task.dueDate.subtract(const Duration(days: 7)); timeLabel = 'in 1 week'; }
        else if (offset == '3d') { scheduleTime = task.dueDate.subtract(const Duration(days: 3)); timeLabel = 'in 3 days'; }
        else if (offset == '1d') { scheduleTime = task.dueDate.subtract(const Duration(days: 1)); timeLabel = 'tomorrow'; }
        else if (offset == '2h') { scheduleTime = task.dueDate.subtract(const Duration(hours: 2)); timeLabel = 'in 2 hours'; }
        else { continue; }

        if (scheduleTime.isAfter(DateTime.now())) {
          _notificationsPlugin.zonedSchedule(
            id: (task.id.hashCode ^ offset.hashCode).abs(),
            title: 'Heads Up: ${task.courseCode}',
            body: '${task.title} is due $timeLabel.',
            scheduledDate: tz.TZDateTime.from(scheduleTime, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'velo_reminders', 
                'Deadlines', 
                channelDescription: 'Task reminders', 
                importance: Importance.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        }
      }
    }
  }
}