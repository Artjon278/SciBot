import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mastery_service.dart';
import 'quiz_stats_service.dart';
import 'streak_service.dart';
import 'gamification_service.dart';

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int quizzesCompleted;
  final int questionsAnswered;
  final int correctAnswers;
  final double averageAccuracy;
  final int homeworkSolved;
  final int chatQuestions;
  final int audioLessons;
  final int xpEarned;
  final int streakDays;
  final List<String> strongSubjects;
  final List<String> weakSubjects;
  final List<String> improvements;
  final List<String> objectives;
  final int previousQuizzes;
  final double previousAccuracy;
  final int previousXP;

  WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    this.quizzesCompleted = 0,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.averageAccuracy = 0,
    this.homeworkSolved = 0,
    this.chatQuestions = 0,
    this.audioLessons = 0,
    this.xpEarned = 0,
    this.streakDays = 0,
    this.strongSubjects = const [],
    this.weakSubjects = const [],
    this.improvements = const [],
    this.objectives = const [],
    this.previousQuizzes = 0,
    this.previousAccuracy = 0,
    this.previousXP = 0,
  });

  int get quizDelta => quizzesCompleted - previousQuizzes;
  double get accuracyDelta => averageAccuracy - previousAccuracy;
  int get xpDelta => xpEarned - previousXP;

  Map<String, dynamic> toJson() => {
    'weekStart': weekStart.toIso8601String(),
    'weekEnd': weekEnd.toIso8601String(),
    'quizzesCompleted': quizzesCompleted,
    'questionsAnswered': questionsAnswered,
    'correctAnswers': correctAnswers,
    'averageAccuracy': averageAccuracy,
    'homeworkSolved': homeworkSolved,
    'chatQuestions': chatQuestions,
    'audioLessons': audioLessons,
    'xpEarned': xpEarned,
    'streakDays': streakDays,
    'strongSubjects': strongSubjects,
    'weakSubjects': weakSubjects,
    'improvements': improvements,
    'objectives': objectives,
    'previousQuizzes': previousQuizzes,
    'previousAccuracy': previousAccuracy,
    'previousXP': previousXP,
  };

  factory WeeklyReport.fromJson(Map<String, dynamic> json) => WeeklyReport(
    weekStart: DateTime.parse(json['weekStart']),
    weekEnd: DateTime.parse(json['weekEnd']),
    quizzesCompleted: json['quizzesCompleted'] ?? 0,
    questionsAnswered: json['questionsAnswered'] ?? 0,
    correctAnswers: json['correctAnswers'] ?? 0,
    averageAccuracy: (json['averageAccuracy'] ?? 0).toDouble(),
    homeworkSolved: json['homeworkSolved'] ?? 0,
    chatQuestions: json['chatQuestions'] ?? 0,
    audioLessons: json['audioLessons'] ?? 0,
    xpEarned: json['xpEarned'] ?? 0,
    streakDays: json['streakDays'] ?? 0,
    strongSubjects: (json['strongSubjects'] as List?)?.cast<String>() ?? [],
    weakSubjects: (json['weakSubjects'] as List?)?.cast<String>() ?? [],
    improvements: (json['improvements'] as List?)?.cast<String>() ?? [],
    objectives: (json['objectives'] as List?)?.cast<String>() ?? [],
    previousQuizzes: json['previousQuizzes'] ?? 0,
    previousAccuracy: (json['previousAccuracy'] ?? 0).toDouble(),
    previousXP: json['previousXP'] ?? 0,
  );
}

class ActivityLog {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  ActivityLog({required this.type, required this.timestamp, this.data = const {}});

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    type: json['type'] ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    data: json['data'] ?? {},
  );
}

class WeeklyReportService extends ChangeNotifier {
  static const String _reportsKey = 'weekly_reports';
  static const String _activityLogKey = 'activity_log';

  List<WeeklyReport> _reports = [];
  List<ActivityLog> _activityLog = [];

  List<WeeklyReport> get reports => List.unmodifiable(_reports);
  WeeklyReport? get latestReport => _reports.isNotEmpty ? _reports.first : null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList(_reportsKey) ?? [];
    _reports = reportsJson
        .map((j) => WeeklyReport.fromJson(jsonDecode(j)))
        .toList()
      ..sort((a, b) => b.weekStart.compareTo(a.weekStart));

    final logJson = prefs.getStringList(_activityLogKey) ?? [];
    _activityLog = logJson
        .map((j) => ActivityLog.fromJson(jsonDecode(j)))
        .toList();

    _autoGenerateIfSunday(prefs);
    notifyListeners();
  }

  void _autoGenerateIfSunday(SharedPreferences prefs) {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return;
    if (_reports.isEmpty) return;
    final latest = _reports.first;
    final daysSinceLastReport = now.difference(latest.weekEnd).inDays;
    if (daysSinceLastReport > 6) {
      _pendingAutoGenerate = true;
    }
  }

  bool _pendingAutoGenerate = false;
  bool get needsAutoGenerate => _pendingAutoGenerate;

  void clearAutoGenerate() {
    _pendingAutoGenerate = false;
  }

  void logActivity(String type, {Map<String, dynamic> data = const {}}) {
    _activityLog.add(ActivityLog(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    ));
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _activityLog.removeWhere((a) => a.timestamp.isBefore(cutoff));
    _saveActivityLog();
  }

  WeeklyReport generateReport({
    required MasteryService mastery,
    required QuizStatsService quizStats,
    required StreakService streak,
    required GamificationService gamification,
  }) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday));
    final weekEnd = now;

    final weekLogs = _activityLog.where((a) =>
        a.timestamp.isAfter(weekStart) && a.timestamp.isBefore(weekEnd)).toList();

    final quizzes = weekLogs.where((a) => a.type == 'quiz').length;
    final questions = weekLogs
        .where((a) => a.type == 'quiz')
        .fold<int>(0, (sum, a) => sum + ((a.data['total'] ?? 0) as int));
    final correct = weekLogs
        .where((a) => a.type == 'quiz')
        .fold<int>(0, (sum, a) => sum + ((a.data['correct'] ?? 0) as int));
    final homework = weekLogs.where((a) => a.type == 'homework').length;
    final chats = weekLogs.where((a) => a.type == 'chat').length;
    final audio = weekLogs.where((a) => a.type == 'audio').length;
    final xp = weekLogs
        .fold<int>(0, (sum, a) => sum + ((a.data['xp'] ?? 0) as int));

    final allMasteries = mastery.getAllSubjectMasteries();
    final strong = allMasteries
        .where((m) => m.overallMastery >= 0.7)
        .map((m) => m.subject)
        .toList();
    final weak = allMasteries
        .where((m) => m.overallMastery < 0.5 && m.totalAttempts > 0)
        .map((m) => m.subject)
        .toList();

    final prevReport = _reports.isNotEmpty ? _reports.first : null;
    final prevQuizzes = prevReport?.quizzesCompleted ?? 0;
    final prevAccuracy = prevReport?.averageAccuracy ?? 0;
    final prevXP = prevReport?.xpEarned ?? 0;

    final currentAccuracy = questions > 0 ? correct / questions * 100 : 0.0;
    final improvements = <String>[];
    if (prevReport != null) {
      if (currentAccuracy > prevAccuracy) {
        improvements.add('Saktësia u rrit me ${(currentAccuracy - prevAccuracy).round()}%');
      }
      if (quizzes > prevQuizzes) {
        improvements.add('Ke bërë ${quizzes - prevQuizzes} kuize më shumë se javën e kaluar');
      }
      if (currentAccuracy < prevAccuracy && prevAccuracy > 0) {
        improvements.add('Saktësia ra me ${(prevAccuracy - currentAccuracy).round()}% - fokusohu më shumë!');
      }
      for (final s in strong) {
        if (prevReport.weakSubjects.contains(s)) {
          improvements.add('U përmirësove në $s!');
        }
      }
    }

    final weakTopics = mastery.getWeakestTopics(limit: 3);
    final objectives = <String>[];
    if (weakTopics.isNotEmpty) {
      objectives.add('Praktiko ${weakTopics.first.topic} në ${weakTopics.first.subject}');
    }
    if (quizzes < 5) {
      objectives.add('Përfundo të paktën 5 kuize këtë javë');
    }
    if (streak.currentStreak < 7) {
      objectives.add('Arrij streak 7-ditor');
    }

    final report = WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      quizzesCompleted: quizzes,
      questionsAnswered: questions,
      correctAnswers: correct,
      averageAccuracy: currentAccuracy,
      homeworkSolved: homework,
      chatQuestions: chats,
      audioLessons: audio,
      xpEarned: xp,
      streakDays: streak.currentStreak,
      strongSubjects: strong,
      weakSubjects: weak,
      improvements: improvements,
      objectives: objectives,
      previousQuizzes: prevQuizzes,
      previousAccuracy: prevAccuracy,
      previousXP: prevXP,
    );

    _reports.insert(0, report);
    if (_reports.length > 12) {
      _reports = _reports.sublist(0, 12);
    }
    _saveReports();
    notifyListeners();
    return report;
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _reportsKey,
      _reports.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> _saveActivityLog() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _activityLogKey,
      _activityLog.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }
}
