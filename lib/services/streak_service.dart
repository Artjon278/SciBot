import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menaxhon streak-un ditor të përdoruesit.
/// Çdo ditë që përdoruesi ndërvepron me app-in, streak vazhdon.
/// Nëse humbet një ditë, streak ristarton në 1.
class StreakService extends ChangeNotifier {
  static const String _keyCurrentStreak = 'streak_current';
  static const String _keyLongestStreak = 'streak_longest';
  static const String _keyLastActiveDate = 'streak_last_active';
  static const String _keyTotalActiveDays = 'streak_total_days';

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalActiveDays = 0;
  String? _lastActiveDate; // format: 'yyyy-MM-dd'
  bool _todayRecorded = false;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalActiveDays => _totalActiveDays;
  bool get todayRecorded => _todayRecorded;

  /// Ngarko streak nga SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt(_keyCurrentStreak) ?? 0;
    _longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
    _totalActiveDays = prefs.getInt(_keyTotalActiveDays) ?? 0;
    _lastActiveDate = prefs.getString(_keyLastActiveDate);

    _checkAndUpdateStreak();
    notifyListeners();
  }

  /// Regjistro aktivitetin e sotëm
  Future<void> recordActivity() async {
    if (_todayRecorded) return;

    final today = _todayString();
    if (_lastActiveDate == today) {
      _todayRecorded = true;
      return;
    }

    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (_lastActiveDate == yesterday) {
      // Vazhdon streak
      _currentStreak++;
    } else if (_lastActiveDate == null || _lastActiveDate != today) {
      // Streak i ri (humbi një ose më shumë ditë)
      _currentStreak = 1;
    }

    _lastActiveDate = today;
    _todayRecorded = true;
    _totalActiveDays++;

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    await _save();
    notifyListeners();
  }

  /// Kontrollo streak-un kur hapet app-i
  void _checkAndUpdateStreak() {
    final today = _todayString();
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (_lastActiveDate == today) {
      _todayRecorded = true;
    } else if (_lastActiveDate == yesterday) {
      // Streak është akoma aktiv, por sot nuk është regjistruar
      _todayRecorded = false;
    } else if (_lastActiveDate != null) {
      // Streak u ndërpre
      _currentStreak = 0;
      _todayRecorded = false;
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCurrentStreak, _currentStreak);
    await prefs.setInt(_keyLongestStreak, _longestStreak);
    await prefs.setInt(_keyTotalActiveDays, _totalActiveDays);
    if (_lastActiveDate != null) {
      await prefs.setString(_keyLastActiveDate, _lastActiveDate!);
    }
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
