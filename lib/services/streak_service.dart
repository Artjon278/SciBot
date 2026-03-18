import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubjectStreak {
  final String subject;
  int current;
  int longest;
  String? lastActiveDate;

  SubjectStreak({
    required this.subject,
    this.current = 0,
    this.longest = 0,
    this.lastActiveDate,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'current': current,
    'longest': longest,
    'lastActiveDate': lastActiveDate,
  };

  factory SubjectStreak.fromJson(Map<String, dynamic> json) => SubjectStreak(
    subject: json['subject'] ?? '',
    current: json['current'] ?? 0,
    longest: json['longest'] ?? 0,
    lastActiveDate: json['lastActiveDate'],
  );
}

class StreakService extends ChangeNotifier {
  static const String _keyCurrentStreak = 'streak_current';
  static const String _keyLongestStreak = 'streak_longest';
  static const String _keyLastActiveDate = 'streak_last_active';
  static const String _keyTotalActiveDays = 'streak_total_days';
  static const String _keySubjectStreaks = 'streak_subjects';
  static const String _keyFreezeUsedDate = 'streak_freeze_used';
  static const String _keyWeeklyGoalMinutes = 'streak_weekly_goal';
  static const String _keyDailyMinutes = 'streak_daily_minutes';
  static const String _keyActivityCalendar = 'streak_activity_calendar';

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalActiveDays = 0;
  String? _lastActiveDate;
  bool _todayRecorded = false;

  Map<String, SubjectStreak> _subjectStreaks = {};
  String? _freezeUsedDate;
  int _weeklyGoalMinutes = 30;
  Map<String, int> _dailyMinutes = {};
  Map<String, Set<String>> _activityCalendar = {};

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalActiveDays => _totalActiveDays;
  bool get todayRecorded => _todayRecorded;
  Map<String, SubjectStreak> get subjectStreaks => Map.unmodifiable(_subjectStreaks);
  int get weeklyGoalMinutes => _weeklyGoalMinutes;
  Map<String, Set<String>> get activityCalendar => Map.unmodifiable(_activityCalendar);

  bool get canFreezeToday {
    if (_freezeUsedDate == null) return true;
    final freezeDate = DateTime.tryParse(_freezeUsedDate!);
    if (freezeDate == null) return true;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return freezeDate.isBefore(DateTime(weekStart.year, weekStart.month, weekStart.day));
  }

  bool get todayGoalMet {
    final today = _todayString();
    final minutes = _dailyMinutes[today] ?? 0;
    return minutes >= _weeklyGoalMinutes;
  }

  int getSubjectStreak(String subject) => _subjectStreaks[subject]?.current ?? 0;

  Set<String> getActivitiesForDate(String date) => _activityCalendar[date] ?? {};

  Map<String, int> getLast30DaysActivity() {
    final result = <String, int>{};
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = _dateString(now.subtract(Duration(days: i)));
      result[date] = _activityCalendar[date]?.length ?? 0;
    }
    return result;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    _longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
    _totalActiveDays = prefs.getInt(_keyTotalActiveDays) ?? 0;
    _lastActiveDate = prefs.getString(_keyLastActiveDate);
    _freezeUsedDate = prefs.getString(_keyFreezeUsedDate);
    _weeklyGoalMinutes = prefs.getInt(_keyWeeklyGoalMinutes) ?? 30;

    final subjectJson = prefs.getStringList(_keySubjectStreaks) ?? [];
    _subjectStreaks = {};
    for (final j in subjectJson) {
      final s = SubjectStreak.fromJson(jsonDecode(j));
      _subjectStreaks[s.subject] = s;
    }

    final minutesJson = prefs.getString(_keyDailyMinutes);
    if (minutesJson != null) {
      final decoded = jsonDecode(minutesJson) as Map<String, dynamic>;
      _dailyMinutes = decoded.map((k, v) => MapEntry(k, v as int));
    }

    final calJson = prefs.getString(_keyActivityCalendar);
    if (calJson != null) {
      final decoded = jsonDecode(calJson) as Map<String, dynamic>;
      _activityCalendar = decoded.map(
        (k, v) => MapEntry(k, (v as List).cast<String>().toSet()),
      );
    }

    _cleanOldData();
    _checkAndUpdateStreak();
    notifyListeners();
  }

  Future<void> recordActivity({String? subject, String activityType = 'general'}) async {
    final today = _todayString();

    _activityCalendar.putIfAbsent(today, () => {});
    _activityCalendar[today]!.add(activityType);

    if (subject != null) {
      _updateSubjectStreak(subject, today);
    }

    if (_todayRecorded || _lastActiveDate == today) {
      _todayRecorded = true;
      await _save();
      notifyListeners();
      return;
    }

    final validActivity = activityType != 'general';
    if (!validActivity) {
      await _save();
      notifyListeners();
      return;
    }

    _todayRecorded = true;
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (_lastActiveDate == yesterday) {
      _currentStreak++;
    } else if (_lastActiveDate != yesterday && _lastActiveDate != today) {
      _currentStreak = 1;
    }

    _lastActiveDate = today;
    _totalActiveDays++;

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    await _save();
    notifyListeners();
  }

  Future<void> addStudyMinutes(int minutes) async {
    final today = _todayString();
    _dailyMinutes[today] = (_dailyMinutes[today] ?? 0) + minutes;
    await _save();
    notifyListeners();
  }

  Future<void> setWeeklyGoal(int minutes) async {
    _weeklyGoalMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWeeklyGoalMinutes, minutes);
    notifyListeners();
  }

  Future<bool> useFreeze() async {
    if (!canFreezeToday) return false;
    final today = _todayString();
    _freezeUsedDate = today;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFreezeUsedDate, today);
    notifyListeners();
    return true;
  }

  void _updateSubjectStreak(String subject, String today) {
    _subjectStreaks.putIfAbsent(subject, () => SubjectStreak(subject: subject));
    final ss = _subjectStreaks[subject]!;
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (ss.lastActiveDate == today) return;

    if (ss.lastActiveDate == yesterday) {
      ss.current++;
    } else {
      ss.current = 1;
    }
    ss.lastActiveDate = today;
    if (ss.current > ss.longest) ss.longest = ss.current;
  }

  void _checkAndUpdateStreak() {
    final today = _todayString();
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (_lastActiveDate == today) {
      _todayRecorded = true;
    } else if (_lastActiveDate == yesterday) {
      _todayRecorded = false;
    } else if (_lastActiveDate != null) {
      if (canFreezeToday && _currentStreak > 0) {
        _todayRecorded = false;
      } else {
        _currentStreak = 0;
        _todayRecorded = false;
      }
    }

    for (final ss in _subjectStreaks.values) {
      if (ss.lastActiveDate != today && ss.lastActiveDate != yesterday) {
        ss.current = 0;
      }
    }
  }

  void _cleanOldData() {
    final cutoff = _dateString(DateTime.now().subtract(const Duration(days: 90)));
    _activityCalendar.removeWhere((date, _) => date.compareTo(cutoff) < 0);
    _dailyMinutes.removeWhere((date, _) => date.compareTo(cutoff) < 0);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentStreak, _currentStreak);
    await prefs.setInt(_keyLongestStreak, _longestStreak);
    await prefs.setInt(_keyTotalActiveDays, _totalActiveDays);
    if (_lastActiveDate != null) {
      await prefs.setString(_keyLastActiveDate, _lastActiveDate!);
    }
    await prefs.setStringList(
      _keySubjectStreaks,
      _subjectStreaks.values.map((s) => jsonEncode(s.toJson())).toList(),
    );
    await prefs.setString(_keyDailyMinutes, jsonEncode(_dailyMinutes));

    final calForJson = _activityCalendar.map(
      (k, v) => MapEntry(k, v.toList()),
    );
    await prefs.setString(_keyActivityCalendar, jsonEncode(calForJson));
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
