import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

enum NotificationType {
  streakWarning('Paralajmërim Streak'),
  spacedRepDue('Përsëritje e planifikuar'),
  weeklyReportReady('Raporti javor gati'),
  dailyChallenge('Sfida e ditës'),
  studyReminder('Kujtesë studimi');

  final String label;
  const NotificationType(this.label);
}

class NotificationService extends ChangeNotifier {
  static const String _prefsKey = 'notification_prefs';
  static const String _historyKey = 'notification_history';
  static const String _studyTimesKey = 'notification_study_times';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Map<NotificationType, bool> _preferences = {};
  List<Map<String, dynamic>> _interactionHistory = [];
  List<int> _studyHours = [];
  int _ignoredCount = 0;

  bool get isInitialized => _initialized;
  Map<NotificationType, bool> get preferences => Map.unmodifiable(_preferences);
  int get preferredStudyHour => _studyHours.isNotEmpty
      ? (_studyHours.reduce((a, b) => a + b) / _studyHours.length).round()
      : 17;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _loadPreferences();
    _initialized = true;
    notifyListeners();
  }

  void _onNotificationTapped(NotificationResponse response) {
    _interactionHistory.add({
      'action': 'tapped',
      'payload': response.payload,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _saveHistory();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final prefsJson = prefs.getString(_prefsKey);
    if (prefsJson != null) {
      final decoded = jsonDecode(prefsJson) as Map<String, dynamic>;
      _preferences = {};
      for (final type in NotificationType.values) {
        _preferences[type] = decoded[type.name] ?? true;
      }
    } else {
      _preferences = {for (final t in NotificationType.values) t: true};
    }

    final historyJson = prefs.getStringList(_historyKey) ?? [];
    _interactionHistory = historyJson
        .map((j) => jsonDecode(j) as Map<String, dynamic>)
        .toList();

    final studyTimesJson = prefs.getStringList(_studyTimesKey) ?? [];
    _studyHours = studyTimesJson.map(int.parse).toList();

    _ignoredCount = _interactionHistory
        .where((h) => h['action'] == 'ignored')
        .length;
  }

  Future<void> setPreference(NotificationType type, bool enabled) async {
    _preferences[type] = enabled;
    final prefs = await SharedPreferences.getInstance();
    final data = {for (final e in _preferences.entries) e.key.name: e.value};
    await prefs.setString(_prefsKey, jsonEncode(data));
    notifyListeners();
  }

  void recordStudyTime() {
    final hour = DateTime.now().hour;
    _studyHours.add(hour);
    if (_studyHours.length > 30) {
      _studyHours = _studyHours.sublist(_studyHours.length - 30);
    }
    _saveStudyTimes();
  }

  int get _adaptiveInterval {
    if (_ignoredCount > 10) return 3;
    if (_ignoredCount > 5) return 2;
    return 1;
  }

  Future<void> scheduleStreakReminder({required int currentStreak}) async {
    if (_preferences[NotificationType.streakWarning] != true) return;

    await _plugin.zonedSchedule(
      0,
      'Mos e humb streak-un! 🔥',
      'Ke $currentStreak ditë rresht. Hap SciBot për të vazhduar!',
      _nextStudyTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_channel',
          'Streak Reminders',
          channelDescription: 'Paralajmërime për streak',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'streak',
    );
  }

  Future<void> scheduleSpacedRepReminder({required int dueCount}) async {
    if (_preferences[NotificationType.spacedRepDue] != true) return;
    if (dueCount == 0) return;

    await _plugin.zonedSchedule(
      1,
      'Ke $dueCount pyetje për përsëritje 📚',
      'Koha për të përsëritur temat e mësuara!',
      _nextStudyTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'review_channel',
          'Review Reminders',
          channelDescription: 'Kujtesa për përsëritje',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'review',
    );
  }

  Future<void> scheduleDailyChallengeReminder() async {
    if (_preferences[NotificationType.dailyChallenge] != true) return;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: _adaptiveInterval));
    }

    await _plugin.zonedSchedule(
      2,
      'Sfida e ditës është gati! 🎯',
      'Testo njohuritë e tua me sfidën e re!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'challenge_channel',
          'Daily Challenge',
          channelDescription: 'Sfida ditore',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'challenge',
    );
  }

  Future<void> scheduleWeeklyReportReminder() async {
    if (_preferences[NotificationType.weeklyReportReady] != true) return;

    final now = tz.TZDateTime.now(tz.local);
    var sunday = now.add(Duration(days: DateTime.sunday - now.weekday));
    var scheduled = tz.TZDateTime(tz.local, sunday.year, sunday.month, sunday.day, 18, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await _plugin.zonedSchedule(
      3,
      'Raporti javor është gati! 📊',
      'Shiko si je përmirësuar këtë javë!',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'report_channel',
          'Weekly Report',
          channelDescription: 'Raporti javor',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'report',
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextStudyTime() {
    final hour = preferredStudyHour;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: _adaptiveInterval));
    }
    return scheduled;
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _interactionHistory.removeWhere((h) {
      final ts = DateTime.tryParse(h['timestamp'] ?? '');
      return ts != null && ts.isBefore(cutoff);
    });
    await prefs.setStringList(
      _historyKey,
      _interactionHistory.map((h) => jsonEncode(h)).toList(),
    );
  }

  Future<void> _saveStudyTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _studyTimesKey,
      _studyHours.map((h) => h.toString()).toList(),
    );
  }
}
