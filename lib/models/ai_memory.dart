import 'package:cloud_firestore/cloud_firestore.dart';

/// Kujtesa e AI-it për çdo student
class AIMemory {
  final String uid;

  /// Temat e diskutuara sipas lëndës: {"Matematikë": ["ekuacione", "gjeometri"]}
  final Map<String, List<String>> discussedTopics;

  /// Gabimet e shpeshta: {"Matematikë": ["ngatërron shenjat +/-", ...]}
  final Map<String, List<String>> commonMistakes;

  /// Konceptet e zotëruara: {"Matematikë": ["ekuacione lineare"]}
  final Map<String, List<String>> masteredConcepts;

  /// Konceptet që nuk janë zotëruar akoma: {"Fizikë": ["termodinamikë"]}
  final Map<String, List<String>> weakConcepts;

  /// Stili i shpjegimit që funksionon më mirë: vizual, hap-pas-hapi, analogji, shembuj
  final String preferredExplanationStyle;

  /// Rezymeja e fundit e bisedave (kontekst i përgjithshëm)
  final String lastSummary;

  /// Statistika të kuizeve sipas lëndës: {"Matematikë": {"correct": 15, "total": 20}}
  final Map<String, Map<String, int>> quizStats;

  final DateTime updatedAt;

  AIMemory({
    required this.uid,
    this.discussedTopics = const {},
    this.commonMistakes = const {},
    this.masteredConcepts = const {},
    this.weakConcepts = const {},
    this.preferredExplanationStyle = '',
    this.lastSummary = '',
    this.quizStats = const {},
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'discussedTopics': discussedTopics.map((k, v) => MapEntry(k, v)),
      'commonMistakes': commonMistakes.map((k, v) => MapEntry(k, v)),
      'masteredConcepts': masteredConcepts.map((k, v) => MapEntry(k, v)),
      'weakConcepts': weakConcepts.map((k, v) => MapEntry(k, v)),
      'preferredExplanationStyle': preferredExplanationStyle,
      'lastSummary': lastSummary,
      'quizStats': quizStats.map((k, v) => MapEntry(k, v)),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory AIMemory.fromMap(Map<String, dynamic> map) {
    return AIMemory(
      uid: map['uid'] ?? '',
      discussedTopics: _parseMapOfLists(map['discussedTopics']),
      commonMistakes: _parseMapOfLists(map['commonMistakes']),
      masteredConcepts: _parseMapOfLists(map['masteredConcepts']),
      weakConcepts: _parseMapOfLists(map['weakConcepts']),
      preferredExplanationStyle: map['preferredExplanationStyle'] ?? '',
      lastSummary: map['lastSummary'] ?? '',
      quizStats: _parseMapOfMaps(map['quizStats']),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, List<String>> _parseMapOfLists(dynamic data) {
    if (data == null || data is! Map) return {};
    return data.map<String, List<String>>(
      (key, value) => MapEntry(
        key.toString(),
        value is List ? value.map((e) => e.toString()).toList() : [],
      ),
    );
  }

  static Map<String, Map<String, int>> _parseMapOfMaps(dynamic data) {
    if (data == null || data is! Map) return {};
    return data.map<String, Map<String, int>>(
      (key, value) => MapEntry(
        key.toString(),
        value is Map
            ? value.map<String, int>(
                (k, v) => MapEntry(k.toString(), v is int ? v : 0))
            : {},
      ),
    );
  }

  AIMemory copyWith({
    Map<String, List<String>>? discussedTopics,
    Map<String, List<String>>? commonMistakes,
    Map<String, List<String>>? masteredConcepts,
    Map<String, List<String>>? weakConcepts,
    String? preferredExplanationStyle,
    String? lastSummary,
    Map<String, Map<String, int>>? quizStats,
  }) {
    return AIMemory(
      uid: uid,
      discussedTopics: discussedTopics ?? this.discussedTopics,
      commonMistakes: commonMistakes ?? this.commonMistakes,
      masteredConcepts: masteredConcepts ?? this.masteredConcepts,
      weakConcepts: weakConcepts ?? this.weakConcepts,
      preferredExplanationStyle:
          preferredExplanationStyle ?? this.preferredExplanationStyle,
      lastSummary: lastSummary ?? this.lastSummary,
      quizStats: quizStats ?? this.quizStats,
      updatedAt: DateTime.now(),
    );
  }
}
