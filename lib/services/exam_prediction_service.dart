import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'gemini_service.dart';
import 'curriculum_service.dart';
import 'mastery_service.dart';

class ExamTopic {
  final String subject;
  final String topic;
  final double probability;
  final String importance;
  final bool mastered;

  ExamTopic({
    required this.subject,
    required this.topic,
    required this.probability,
    required this.importance,
    this.mastered = false,
  });
}

class ExamPrediction {
  final String subject;
  final int grade;
  final List<ExamTopic> topics;
  final DateTime generatedAt;
  final String advice;

  ExamPrediction({
    required this.subject,
    required this.grade,
    required this.topics,
    required this.advice,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  double get readinessScore {
    if (topics.isEmpty) return 0;
    final mastered = topics.where((t) => t.mastered).length;
    final weighted = topics.fold<double>(
        0, (sum, t) => sum + (t.mastered ? t.probability : 0));
    return weighted.clamp(0, 100);
  }

  List<ExamTopic> get criticalGaps =>
      topics.where((t) => !t.mastered && t.probability > 60).toList();
}

class ExamPredictionService extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  bool _isGenerating = false;
  ExamPrediction? _lastPrediction;

  bool get isGenerating => _isGenerating;
  ExamPrediction? get lastPrediction => _lastPrediction;

  static const Map<String, List<Map<String, dynamic>>> _maturaPatterns = {
    'Matematikë': [
      {'topic': 'Ekuacionet dhe inekuacionet', 'weight': 90},
      {'topic': 'Funksionet', 'weight': 85},
      {'topic': 'Derivatet dhe integralet', 'weight': 85},
      {'topic': 'Gjeometria analitike', 'weight': 75},
      {'topic': 'Trigonometria', 'weight': 70},
      {'topic': 'Vargjet dhe seritë', 'weight': 65},
      {'topic': 'Probabiliteti dhe statistika', 'weight': 60},
      {'topic': 'Numrat kompleksë', 'weight': 50},
      {'topic': 'Kombinatorika', 'weight': 45},
      {'topic': 'Matricat dhe determinantat', 'weight': 35},
    ],
    'Fizikë': [
      {'topic': 'Mekanika (Kinematika + Dinamika)', 'weight': 90},
      {'topic': 'Termodinamika', 'weight': 80},
      {'topic': 'Elektriçiteti dhe magnetizmi', 'weight': 85},
      {'topic': 'Valët dhe optika', 'weight': 75},
      {'topic': 'Fizika bërthamore', 'weight': 65},
      {'topic': 'Energjia dhe puna', 'weight': 70},
      {'topic': 'Lëvizja rrethore', 'weight': 55},
      {'topic': 'Gravitacioni', 'weight': 50},
    ],
    'Kimi': [
      {'topic': 'Struktura atomike dhe lidhjet', 'weight': 85},
      {'topic': 'Steokiometria', 'weight': 85},
      {'topic': 'Ekuilibri kimik', 'weight': 80},
      {'topic': 'Acide, baza dhe kripëra', 'weight': 80},
      {'topic': 'Kimia organike', 'weight': 75},
      {'topic': 'Termodinamika kimike', 'weight': 65},
      {'topic': 'Elektrokimia', 'weight': 60},
      {'topic': 'Kinetika kimike', 'weight': 55},
    ],
    'Biologji': [
      {'topic': 'Gjenetika dhe trashëgimia', 'weight': 90},
      {'topic': 'Biologjia qelizore', 'weight': 85},
      {'topic': 'Evolucioni', 'weight': 75},
      {'topic': 'Ekologjia dhe mjedisi', 'weight': 70},
      {'topic': 'Fiziologjia e njeriut', 'weight': 80},
      {'topic': 'Biologjia molekulare (ADN/ARN)', 'weight': 85},
      {'topic': 'Fotosinteza dhe frymëmarrja', 'weight': 70},
      {'topic': 'Bioteknologjia', 'weight': 50},
    ],
  };

  Future<ExamPrediction> generatePrediction({
    required String subject,
    required int grade,
    required MasteryService mastery,
  }) async {
    _isGenerating = true;
    notifyListeners();

    try {
      final patterns = _maturaPatterns[subject] ?? [];
      final subjectMastery = mastery.getSubjectMastery(subject);

      final topics = patterns.map((p) {
        final topicName = p['topic'] as String;
        final weight = (p['weight'] as int).toDouble();

        final isMastered = subjectMastery.topics.any(
            (t) => t.topic.contains(topicName.split(' ').first) && t.mastery >= 0.7);

        return ExamTopic(
          subject: subject,
          topic: topicName,
          probability: weight,
          importance: weight >= 80 ? 'Kritike' : weight >= 60 ? 'E Rëndësishme' : 'Mundësi',
          mastered: isMastered,
        );
      }).toList();

      topics.sort((a, b) => b.probability.compareTo(a.probability));

      final gaps = topics.where((t) => !t.mastered && t.probability >= 70).toList();
      String advice;
      if (gaps.isEmpty) {
        advice = 'Je në gjendje të shkëlqyer! Vazhdo me kuize përmbysëse për çdo temë.';
      } else if (gaps.length <= 2) {
        advice = 'Pothuajse gati! Fokusohu tek: ${gaps.map((g) => g.topic).join(", ")}.';
      } else {
        advice = 'Fokusohu tek temat kritike: ${gaps.take(3).map((g) => g.topic).join(", ")}. Fillo me temën me mundësi më të lartë dalës.';
      }

      _lastPrediction = ExamPrediction(
        subject: subject,
        grade: grade,
        topics: topics,
        advice: advice,
      );

      return _lastPrediction!;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> generatePracticeExam({
    required String subject,
    required int grade,
    required List<ExamTopic> focusTopics,
  }) async {
    final topicList = focusTopics.take(5).map((t) => t.topic).join(', ');
    final prompt = '''
Krijo 10 pyetje kuizi për provimin e Maturës Shtetërore në "$subject".
Temat: $topicList
Niveli: Klasa $grade, Shqipëri.

VETËM JSON array:
[{"question":"...","options":["A","B","C","D"],"correctIndex":0,"explanation":"...","topic":"tema"}]

Rregulla:
- Stili i pyetjeve duhet të ngjajë me Maturën
- Opsione bindëse, jo qartazi të gabuara
- Shpjegim konciz (2-3 fjali)
''';

    try {
      final response = await _gemini.sendMessage(prompt, useHistory: false);
      final start = response.indexOf('[');
      final end = response.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        final jsonStr = response.substring(start, end + 1);
        final decoded = List<Map<String, dynamic>>.from(
          (jsonDecode(jsonStr) as List).map((e) => Map<String, dynamic>.from(e)),
        );
        return decoded;
      }
    } catch (e) {
      debugPrint('generatePracticeExam error: $e');
    }
    return [];
  }
}
