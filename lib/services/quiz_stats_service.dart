import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizResult {
  final String title;
  final String? subject;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime timestamp;

  QuizResult({
    required this.title,
    this.subject,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timestamp,
  });

  double get accuracy => totalQuestions > 0 ? correctAnswers / totalQuestions * 100 : 0;

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    title: json['title'] ?? '',
    subject: json['subject'],
    totalQuestions: json['totalQuestions'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}

class QuizStatsService extends ChangeNotifier {
  static const String _resultsKey = 'quiz_results';
  static const String _streakKey = 'quiz_streak';
  static const String _lastQuizDateKey = 'last_quiz_date';
  static const int _maxResults = 100;

  List<QuizResult> _results = [];
  int _streak = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<QuizResult> get results => List.unmodifiable(_results);
  int get totalQuizzes => _results.length;
  int get streak => _streak;

  double get averageAccuracy {
    if (_results.isEmpty) return 0;
    final total = _results.fold<double>(0, (sum, r) => sum + r.accuracy);
    return total / _results.length;
  }

  int get totalCorrect => _results.fold<int>(0, (sum, r) => sum + r.correctAnswers);
  int get totalQuestions => _results.fold<int>(0, (sum, r) => sum + r.totalQuestions);

  QuizStatsService() {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load results
      final resultsJson = prefs.getStringList(_resultsKey) ?? [];
      _results = resultsJson
          .map((json) => QuizResult.fromJson(jsonDecode(json)))
          .toList();
      
      // Load streak
      _streak = prefs.getInt(_streakKey) ?? 0;
      
      // Check if streak should reset (no quiz yesterday)
      final lastDateStr = prefs.getString(_lastQuizDateKey);
      if (lastDateStr != null) {
        final lastDate = DateTime.parse(lastDateStr);
        final now = DateTime.now();
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diff > 1) {
          _streak = 0;
          await prefs.setInt(_streakKey, 0);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Gabim gjatë ngarkimit të stats: $e');
    }
  }

  Future<void> addResult({
    required String title,
    String? subject,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    final result = QuizResult(
      title: title,
      subject: subject,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      timestamp: DateTime.now(),
    );

    _results.insert(0, result);
    
    // Keep only latest results
    if (_results.length > _maxResults) {
      _results = _results.sublist(0, _maxResults);
    }

    // Update streak
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastQuizDateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final diff = today.difference(lastDay).inDays;
      
      if (diff == 1) {
        // Consecutive day - increase streak
        _streak++;
      } else if (diff > 1) {
        // Streak broken
        _streak = 1;
      }
      // diff == 0: same day, streak stays the same
    } else {
      _streak = 1;
    }

    // Save
    await prefs.setInt(_streakKey, _streak);
    await prefs.setString(_lastQuizDateKey, today.toIso8601String());
    
    final resultsJson = _results.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_resultsKey, resultsJson);

    // Ruaj gjithashtu në Firebase
    await _saveResultToFirestore(result);

    notifyListeners();
  }

  Future<void> _saveResultToFirestore(QuizResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db
        .collection('users')
        .doc(user.uid)
        .collection('quiz_results')
        .add({
      ...result.toJson(),
      'userId': user.uid,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearStats() async {
    _results.clear();
    _streak = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_resultsKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_lastQuizDateKey);
    
    notifyListeners();
  }
}
