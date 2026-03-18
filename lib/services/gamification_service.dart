import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum XPActivity {
  quizComplete(25, 'Kuiz i përfunduar'),
  quizPerfect(50, 'Kuiz perfekt'),
  homeworkSolved(20, 'Ushtrim i zgjidhur'),
  chatQuestion(5, 'Pyetje në chat'),
  challengeComplete(30, 'Sfidë e përfunduar'),
  audioLesson(15, 'Mësim audio'),
  dailyLogin(10, 'Hyrje ditore'),
  streakBonus(15, 'Bonus streak'),
  reviewComplete(20, 'Përsëritje e përfunduar');

  final int xp;
  final String label;
  const XPActivity(this.xp, this.label);
}

class Badge {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool unlocked;
  final DateTime? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    this.unlocked = false,
    this.unlockedAt,
  });

  Badge copyWith({bool? unlocked, DateTime? unlockedAt}) => Badge(
    id: id,
    name: name,
    icon: icon,
    description: description,
    unlocked: unlocked ?? this.unlocked,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon': icon,
    'description': description,
    'unlocked': unlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    icon: json['icon'] ?? '',
    description: json['description'] ?? '',
    unlocked: json['unlocked'] ?? false,
    unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
  );
}

class GamificationService extends ChangeNotifier {
  static const String _xpKey = 'user_xp';
  static const String _levelKey = 'user_level';
  static const String _badgesKey = 'user_badges';
  static const String _xpHistoryKey = 'xp_history';

  int _totalXP = 0;
  int _level = 1;
  List<Badge> _badges = [];
  List<Map<String, dynamic>> _xpHistory = [];

  int get totalXP => _totalXP;
  int get level => _level;
  List<Badge> get badges => List.unmodifiable(_badges);
  List<Badge> get unlockedBadges => _badges.where((b) => b.unlocked).toList();
  int get xpForCurrentLevel => _xpForLevel(_level);
  int get xpForNextLevel => _xpForLevel(_level + 1);
  int get xpInCurrentLevel => _totalXP - _xpForLevel(_level);
  int get xpNeededForNext => xpForNextLevel - _xpForLevel(_level);
  double get levelProgress => xpNeededForNext > 0 ? xpInCurrentLevel / xpNeededForNext : 0;
  String get levelTitle => _getLevelTitle(_level);

  static final List<Badge> _allBadges = [
    const Badge(id: 'first_quiz', name: 'Kuiz i Parë', icon: '🎯', description: 'Përfundo kuizin e parë'),
    const Badge(id: 'quiz_master', name: 'Mjeshtër Kuizesh', icon: '🏆', description: 'Përfundo 50 kuize'),
    const Badge(id: 'perfect_score', name: 'Rezultat Perfekt', icon: '💯', description: 'Merr 100% në një kuiz'),
    const Badge(id: 'streak_7', name: '7 Ditë Rresht', icon: '🔥', description: 'Mbaj streak 7 ditë'),
    const Badge(id: 'streak_30', name: '30 Ditë Rresht', icon: '⚡', description: 'Mbaj streak 30 ditë'),
    const Badge(id: 'streak_100', name: '100 Ditë Rresht', icon: '👑', description: 'Mbaj streak 100 ditë'),
    const Badge(id: 'math_pro', name: 'Pro Matematike', icon: '📐', description: 'Arrij nivel mjeshtri në Matematikë'),
    const Badge(id: 'physics_pro', name: 'Pro Fizike', icon: '⚡', description: 'Arrij nivel mjeshtri në Fizikë'),
    const Badge(id: 'chemistry_pro', name: 'Pro Kimie', icon: '⚗️', description: 'Arrij nivel mjeshtri në Kimi'),
    const Badge(id: 'biology_pro', name: 'Pro Biologjie', icon: '🧬', description: 'Arrij nivel mjeshtri në Biologji'),
    const Badge(id: 'homework_hero', name: 'Hero Detyrave', icon: '📚', description: 'Zgjidh 25 ushtrime'),
    const Badge(id: 'level_5', name: 'Nivel 5', icon: '⭐', description: 'Arrij nivelin 5'),
    const Badge(id: 'level_10', name: 'Nivel 10', icon: '🌟', description: 'Arrij nivelin 10'),
    const Badge(id: 'level_25', name: 'Nivel 25', icon: '💫', description: 'Arrij nivelin 25'),
    const Badge(id: 'curious_mind', name: 'Mendje Kurioz', icon: '🧠', description: 'Bëj 100 pyetje në chat'),
    const Badge(id: 'scientist', name: 'Shkencëtar', icon: '🔬', description: 'Përfundo 20 sfida laboratori'),
  ];

  int _xpForLevel(int level) {
    if (level <= 1) return 0;
    return ((level - 1) * (level - 1) * 50).toInt();
  }

  int _calculateLevel(int xp) {
    int level = 1;
    while (_xpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  String _getLevelTitle(int level) {
    if (level >= 25) return 'Gjeni Shkence';
    if (level >= 20) return 'Ekspert';
    if (level >= 15) return 'Mjeshtër';
    if (level >= 10) return 'I Avancuar';
    if (level >= 5) return 'I Aftë';
    if (level >= 3) return 'Nxënës Aktiv';
    return 'Fillestar';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _totalXP = prefs.getInt(_xpKey) ?? 0;
    _level = _calculateLevel(_totalXP);

    final badgesJson = prefs.getStringList(_badgesKey) ?? [];
    final unlockedIds = <String>{};
    final unlockedMap = <String, DateTime>{};
    for (final json in badgesJson) {
      final decoded = jsonDecode(json);
      if (decoded['unlocked'] == true) {
        unlockedIds.add(decoded['id']);
        if (decoded['unlockedAt'] != null) {
          unlockedMap[decoded['id']] = DateTime.parse(decoded['unlockedAt']);
        }
      }
    }
    _badges = _allBadges.map((b) {
      if (unlockedIds.contains(b.id)) {
        return b.copyWith(unlocked: true, unlockedAt: unlockedMap[b.id]);
      }
      return b;
    }).toList();

    final historyJson = prefs.getStringList(_xpHistoryKey) ?? [];
    _xpHistory = historyJson
        .map((j) => jsonDecode(j) as Map<String, dynamic>)
        .toList();

    notifyListeners();
  }

  Future<int> awardXP(XPActivity activity, {int multiplier = 1}) async {
    final xpGained = activity.xp * multiplier;
    final oldLevel = _level;
    _totalXP += xpGained;
    _level = _calculateLevel(_totalXP);

    _xpHistory.add({
      'activity': activity.name,
      'xp': xpGained,
      'timestamp': DateTime.now().toIso8601String(),
    });
    if (_xpHistory.length > 200) {
      _xpHistory = _xpHistory.sublist(_xpHistory.length - 200);
    }

    await _save();
    await _checkLevelBadges();
    notifyListeners();

    if (_level > oldLevel) {
      return _level;
    }
    return 0;
  }

  Future<Badge?> unlockBadge(String badgeId) async {
    final index = _badges.indexWhere((b) => b.id == badgeId);
    if (index == -1 || _badges[index].unlocked) return null;

    _badges[index] = _badges[index].copyWith(
      unlocked: true,
      unlockedAt: DateTime.now(),
    );
    await _save();
    notifyListeners();
    return _badges[index];
  }

  Future<void> _checkLevelBadges() async {
    if (_level >= 5) await unlockBadge('level_5');
    if (_level >= 10) await unlockBadge('level_10');
    if (_level >= 25) await unlockBadge('level_25');
  }

  Future<void> checkStreakBadges(int streak) async {
    if (streak >= 7) await unlockBadge('streak_7');
    if (streak >= 30) await unlockBadge('streak_30');
    if (streak >= 100) await unlockBadge('streak_100');
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_xpKey, _totalXP);
    await prefs.setInt(_levelKey, _level);
    await prefs.setStringList(
      _badgesKey,
      _badges.map((b) => jsonEncode(b.toJson())).toList(),
    );
    await prefs.setStringList(
      _xpHistoryKey,
      _xpHistory.map((h) => jsonEncode(h)).toList(),
    );
    _syncToFirestore();
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'xp': _totalXP,
        'level': _level,
        'badges': _badges.where((b) => b.unlocked).map((b) => b.id).toList(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
