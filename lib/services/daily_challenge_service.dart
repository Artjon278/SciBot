import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyChallenge {
  final String id;
  final String date;
  final String subject;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String difficulty;

  DailyChallenge({
    required this.id,
    required this.date,
    required this.subject,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.difficulty = 'mesatar',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'subject': subject,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
    'difficulty': difficulty,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
    id: json['id'] ?? '',
    date: json['date'] ?? '',
    subject: json['subject'] ?? '',
    question: json['question'] ?? '',
    options: (json['options'] as List?)?.cast<String>() ?? [],
    correctIndex: json['correctIndex'] ?? 0,
    explanation: json['explanation'] ?? '',
    difficulty: json['difficulty'] ?? 'mesatar',
  );
}

class ChallengeResult {
  final String date;
  final bool completed;
  final bool correct;
  final int score;

  ChallengeResult({
    required this.date,
    this.completed = false,
    this.correct = false,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'completed': completed,
    'correct': correct,
    'score': score,
  };

  factory ChallengeResult.fromJson(Map<String, dynamic> json) => ChallengeResult(
    date: json['date'] ?? '',
    completed: json['completed'] ?? false,
    correct: json['correct'] ?? false,
    score: json['score'] ?? 0,
  );
}

class DailyChallengeService extends ChangeNotifier {
  static const String _challengeKey = 'daily_challenge';
  static const String _resultsKey = 'daily_challenge_results';
  static const String _streakKey = 'daily_challenge_streak';

  DailyChallenge? _todayChallenge;
  Map<String, ChallengeResult> _results = {};
  int _challengeStreak = 0;

  DailyChallenge? get todayChallenge => _todayChallenge;
  int get challengeStreak => _challengeStreak;
  Map<String, ChallengeResult> get results => Map.unmodifiable(_results);

  bool get todayCompleted {
    final today = _todayString();
    return _results[today]?.completed ?? false;
  }

  ChallengeResult? get todayResult => _results[_todayString()];
  ChallengeResult? get yesterdayResult {
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));
    return _results[yesterday];
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _challengeStreak = prefs.getInt(_streakKey) ?? 0;

    final challengeJson = prefs.getString(_challengeKey);
    if (challengeJson != null) {
      _todayChallenge = DailyChallenge.fromJson(jsonDecode(challengeJson));
      if (_todayChallenge!.date != _todayString()) {
        _todayChallenge = null;
      }
    }

    final resultsJson = prefs.getStringList(_resultsKey) ?? [];
    _results = {};
    for (final j in resultsJson) {
      final r = ChallengeResult.fromJson(jsonDecode(j));
      _results[r.date] = r;
    }

    _updateStreak();

    if (_todayChallenge == null) {
      _todayChallenge = _generateDeterministicChallenge();
      await _saveChallenge();
    }

    notifyListeners();
  }

  DailyChallenge _generateDeterministicChallenge() {
    final today = _todayString();
    final seed = today.hashCode;
    final rng = Random(seed);

    final subjects = ['Matematikë', 'Fizikë', 'Kimi', 'Biologji'];
    final subject = subjects[rng.nextInt(subjects.length)];

    final challenges = _getChallengePool(subject);
    final challenge = challenges[rng.nextInt(challenges.length)];

    return DailyChallenge(
      id: 'dc_$today',
      date: today,
      subject: challenge['subject'] as String,
      question: challenge['question'] as String,
      options: (challenge['options'] as List).cast<String>(),
      correctIndex: challenge['correctIndex'] as int,
      explanation: challenge['explanation'] as String,
    );
  }

  List<Map<String, dynamic>> _getChallengePool(String subject) {
    final pools = <String, List<Map<String, dynamic>>>{
      'Matematikë': [
        {'subject': 'Matematikë', 'question': 'Sa eshte vlera e x ne ekuacionin 3x + 7 = 22?', 'options': ['3', '5', '7', '15'], 'correctIndex': 1, 'explanation': '3x + 7 = 22 → 3x = 15 → x = 5'},
        {'subject': 'Matematikë', 'question': 'Cili eshte derivati i f(x) = x³ + 2x?', 'options': ['3x² + 2', 'x² + 2', '3x + 2', '3x²'], 'correctIndex': 0, 'explanation': 'f\'(x) = 3x² + 2 sipas rregulles se fuqise'},
        {'subject': 'Matematikë', 'question': 'Sa eshte log₂(32)?', 'options': ['4', '5', '6', '8'], 'correctIndex': 1, 'explanation': '2⁵ = 32, pra log₂(32) = 5'},
        {'subject': 'Matematikë', 'question': 'Siperfaqja e rrethit me rreze 7 cm eshte:', 'options': ['154 cm²', '44 cm²', '49 cm²', '22 cm²'], 'correctIndex': 0, 'explanation': 'S = πr² = π × 49 ≈ 154 cm²'},
        {'subject': 'Matematikë', 'question': 'Sa eshte shuma e kendeve te brendshme te nje pentagoni?', 'options': ['360°', '540°', '720°', '180°'], 'correctIndex': 1, 'explanation': '(5-2) × 180° = 540°'},
        {'subject': 'Matematikë', 'question': 'Nese f(x) = 2x - 3, sa eshte f(f(4))?', 'options': ['7', '5', '11', '3'], 'correctIndex': 0, 'explanation': 'f(4) = 5, f(5) = 7'},
      ],
      'Fizikë': [
        {'subject': 'Fizikë', 'question': 'Cila eshte njesia matese e forces?', 'options': ['Joule', 'Newton', 'Watt', 'Pascal'], 'correctIndex': 1, 'explanation': 'Forca matet ne Newton (N) = kg·m/s²'},
        {'subject': 'Fizikë', 'question': 'Nje trup me mase 5 kg nxitim 3 m/s². Sa eshte forca?', 'options': ['15 N', '8 N', '1.67 N', '2 N'], 'correctIndex': 0, 'explanation': 'F = m × a = 5 × 3 = 15 N'},
        {'subject': 'Fizikë', 'question': 'Shpejtesia e drites ne vakum eshte perafersisht:', 'options': ['3×10⁶ m/s', '3×10⁸ m/s', '3×10¹⁰ m/s', '3×10⁴ m/s'], 'correctIndex': 1, 'explanation': 'c ≈ 3 × 10⁸ m/s ose 300,000 km/s'},
        {'subject': 'Fizikë', 'question': 'Energjia kinetike varet nga:', 'options': ['Masa dhe lartesia', 'Masa dhe shpejtesia', 'Forca dhe koha', 'Forca dhe largesia'], 'correctIndex': 1, 'explanation': 'Ek = ½mv², varet nga masa dhe shpejtesia'},
        {'subject': 'Fizikë', 'question': 'Ligji i trete i Njutonit thote:', 'options': ['F = ma', 'Per cdo veprim ka nje kunderpergjigje te barabarte', 'Objektet ne levizje mbeten ne levizje', 'Energjia ruhet'], 'correctIndex': 1, 'explanation': 'Ligji III: Per cdo force veprimi ka nje force kundervepruese te barabarte ne madhesi'},
      ],
      'Kimi': [
        {'subject': 'Kimi', 'question': 'Cili element ka simbolin Fe?', 'options': ['Fluori', 'Hekuri', 'Fosfori', 'Fermiumi'], 'correctIndex': 1, 'explanation': 'Fe vjen nga latinishtja "Ferrum" = Hekur'},
        {'subject': 'Kimi', 'question': 'Sa elektrone ka atomi i karbonit?', 'options': ['4', '6', '8', '12'], 'correctIndex': 1, 'explanation': 'Karboni ka numrin atomik 6, pra 6 elektrone'},
        {'subject': 'Kimi', 'question': 'pH e nje solucioni neutral eshte:', 'options': ['0', '7', '14', '1'], 'correctIndex': 1, 'explanation': 'pH = 7 eshte neutral, < 7 eshte acid, > 7 eshte bazik'},
        {'subject': 'Kimi', 'question': 'Cili gaz prodhohet gjate fotosinteses?', 'options': ['CO₂', 'N₂', 'O₂', 'H₂'], 'correctIndex': 2, 'explanation': '6CO₂ + 6H₂O → C₆H₁₂O₆ + 6O₂'},
        {'subject': 'Kimi', 'question': 'Lidhja kovalente formohet nga:', 'options': ['Transferimi i elektroneve', 'Ndarja e elektroneve', 'Forca elektrostatike', 'Forca berthamore'], 'correctIndex': 1, 'explanation': 'Lidhja kovalente krijohet kur dy atome ndajne cifteza elektronike'},
      ],
      'Biologji': [
        {'subject': 'Biologji', 'question': 'Cila organele eshte "qendra energjitike" e qelizes?', 'options': ['Ribozomi', 'Mitokondria', 'Kloroplasti', 'Berthama'], 'correctIndex': 1, 'explanation': 'Mitokondria prodhon ATP permes frymemarrjes qelizore'},
        {'subject': 'Biologji', 'question': 'ADN-ja perbehet nga sa zinxhire?', 'options': ['1', '2', '3', '4'], 'correctIndex': 1, 'explanation': 'ADN ka strukture te dyfishtë spirale (double helix)'},
        {'subject': 'Biologji', 'question': 'Cila eshte njesia baze e trashegimise?', 'options': ['Kromozomi', 'Gjeni', 'ADN', 'ARN'], 'correctIndex': 1, 'explanation': 'Gjeni eshte njesia baze qe mbart informacionin trashegimor'},
        {'subject': 'Biologji', 'question': 'Mitoza prodhon:', 'options': ['2 qeliza identike', '4 qeliza identike', '2 qeliza te ndryshme', '4 qeliza te ndryshme'], 'correctIndex': 0, 'explanation': 'Mitoza prodhon 2 qeliza bija identike me qelizen nene'},
        {'subject': 'Biologji', 'question': 'Cili sistem transporton gjakun ne trup?', 'options': ['Nervor', 'Tretës', 'Qarkullimit', 'Frymëmarrjes'], 'correctIndex': 2, 'explanation': 'Sistemi i qarkullimit (kardiovaskular) transporton gjakun'},
      ],
    };
    return pools[subject] ?? pools['Matematikë']!;
  }

  Future<void> submitAnswer(int selectedIndex) async {
    if (_todayChallenge == null || todayCompleted) return;

    final today = _todayString();
    final isCorrect = selectedIndex == _todayChallenge!.correctIndex;
    final score = isCorrect ? 100 : 0;

    _results[today] = ChallengeResult(
      date: today,
      completed: true,
      correct: isCorrect,
      score: score,
    );

    _updateStreak();
    await _saveResults();
    notifyListeners();
  }

  void _updateStreak() {
    final today = _todayString();
    final yesterday = _dateString(DateTime.now().subtract(const Duration(days: 1)));

    if (_results[today]?.completed == true) {
      if (_results[yesterday]?.completed == true) {
        // Consecutive days — compute full streak
        _challengeStreak = _calculateStreak();
      } else {
        // Today done but yesterday wasn't — start fresh at 1
        _challengeStreak = 1;
      }
    } else if (_results[yesterday]?.completed != true) {
      // Neither today nor yesterday completed — streak broken
      _challengeStreak = 0;
    }
    // If today not done but yesterday was: keep current streak (still time today)
  }

  int _calculateStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final date = _dateString(now.subtract(Duration(days: i)));
      if (_results[date]?.completed == true) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<void> _saveChallenge() async {
    if (_todayChallenge == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_challengeKey, jsonEncode(_todayChallenge!.toJson()));
  }

  Future<void> _saveResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _resultsKey,
      _results.values.map((r) => jsonEncode(r.toJson())).toList(),
    );
    await prefs.setInt(_streakKey, _challengeStreak);
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
