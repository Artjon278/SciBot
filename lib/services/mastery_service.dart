import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TopicScore {
  final String subject;
  final String topic;
  int correct;
  int total;
  double mastery;
  DateTime lastPracticed;

  TopicScore({
    required this.subject,
    required this.topic,
    this.correct = 0,
    this.total = 0,
    this.mastery = 0,
    DateTime? lastPracticed,
  }) : lastPracticed = lastPracticed ?? DateTime.now();

  double get accuracy => total > 0 ? correct / total : 0;
  String get masteryLabel {
    if (mastery >= 0.9) return 'Mjeshtër';
    if (mastery >= 0.7) return 'I Fortë';
    if (mastery >= 0.5) return 'Mesatar';
    if (mastery >= 0.3) return 'Fillestar';
    return 'I Ri';
  }

  void recordAttempt(bool isCorrect) {
    total++;
    if (isCorrect) correct++;
    mastery = _calculateMastery();
    lastPracticed = DateTime.now();
  }

  double _calculateMastery() {
    if (total == 0) return 0;
    final recentWeight = 0.7;
    final overallWeight = 0.3;
    final recentCorrect = total > 5 ? correct / total : accuracy;
    return (recentCorrect * recentWeight + accuracy * overallWeight).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'topic': topic,
    'correct': correct,
    'total': total,
    'mastery': mastery,
    'lastPracticed': lastPracticed.toIso8601String(),
  };

  factory TopicScore.fromJson(Map<String, dynamic> json) => TopicScore(
    subject: json['subject'] ?? '',
    topic: json['topic'] ?? '',
    correct: json['correct'] ?? 0,
    total: json['total'] ?? 0,
    mastery: (json['mastery'] ?? 0).toDouble(),
    lastPracticed: json['lastPracticed'] != null
        ? DateTime.parse(json['lastPracticed'])
        : DateTime.now(),
  );
}

class SubjectMastery {
  final String subject;
  final List<TopicScore> topics;

  SubjectMastery({required this.subject, List<TopicScore>? topics})
      : topics = topics ?? [];

  double get overallMastery {
    if (topics.isEmpty) return 0;
    return topics.fold<double>(0, (sum, t) => sum + t.mastery) / topics.length;
  }

  int get totalAttempts => topics.fold<int>(0, (sum, t) => sum + t.total);
  int get totalCorrect => topics.fold<int>(0, (sum, t) => sum + t.correct);

  List<TopicScore> get weakTopics =>
      topics.where((t) => t.mastery < 0.5 && t.total > 0).toList()
        ..sort((a, b) => a.mastery.compareTo(b.mastery));

  List<TopicScore> get strongTopics =>
      topics.where((t) => t.mastery >= 0.7).toList()
        ..sort((a, b) => b.mastery.compareTo(a.mastery));
}

class MasteryService extends ChangeNotifier {
  static const String _scoresKey = 'topic_scores';

  final Map<String, Map<String, TopicScore>> _scores = {};

  Map<String, Map<String, TopicScore>> get scores => Map.unmodifiable(_scores);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_scoresKey) ?? [];
    _scores.clear();
    for (final json in jsonList) {
      final score = TopicScore.fromJson(jsonDecode(json));
      _scores.putIfAbsent(score.subject, () => {});
      _scores[score.subject]![score.topic] = score;
    }
    notifyListeners();
  }

  void recordAnswer({
    required String subject,
    required String topic,
    required bool isCorrect,
  }) {
    _scores.putIfAbsent(subject, () => {});
    _scores[subject]!.putIfAbsent(
      topic,
      () => TopicScore(subject: subject, topic: topic),
    );
    _scores[subject]![topic]!.recordAttempt(isCorrect);
    _save();
    notifyListeners();
  }

  SubjectMastery getSubjectMastery(String subject) {
    final topics = _scores[subject]?.values.toList() ?? [];
    return SubjectMastery(subject: subject, topics: topics);
  }

  List<SubjectMastery> getAllSubjectMasteries() {
    return _scores.keys.map(getSubjectMastery).toList();
  }

  List<TopicScore> getWeakestTopics({int limit = 5}) {
    final all = <TopicScore>[];
    for (final subjects in _scores.values) {
      for (final score in subjects.values) {
        if (score.total > 0) all.add(score);
      }
    }
    all.sort((a, b) => a.mastery.compareTo(b.mastery));
    return all.take(limit).toList();
  }

  List<TopicScore> getStrongestTopics({int limit = 5}) {
    final all = <TopicScore>[];
    for (final subjects in _scores.values) {
      for (final score in subjects.values) {
        if (score.total > 0) all.add(score);
      }
    }
    all.sort((a, b) => b.mastery.compareTo(a.mastery));
    return all.take(limit).toList();
  }

  String getDifficultyForTopic(String subject, String topic) {
    final score = _scores[subject]?[topic];
    if (score == null || score.total < 3) return 'mesatar';
    if (score.mastery >= 0.8) return 'i vështirë';
    if (score.mastery >= 0.5) return 'mesatar';
    return 'i lehtë';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final all = <String>[];
    for (final subjects in _scores.values) {
      for (final score in subjects.values) {
        all.add(jsonEncode(score.toJson()));
      }
    }
    await prefs.setStringList(_scoresKey, all);
    _syncToFirestore();
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final data = <String, dynamic>{};
      for (final entry in _scores.entries) {
        data[entry.key] = entry.value.map(
          (k, v) => MapEntry(k, v.toJson()),
        );
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('mastery')
          .doc('scores')
          .set(data);
    } catch (_) {}
  }
}
