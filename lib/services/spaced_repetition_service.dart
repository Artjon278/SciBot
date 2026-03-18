import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReviewItem {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;
  final String subject;
  final String topic;
  double easeFactor;
  int interval;
  int repetitions;
  DateTime nextReview;
  DateTime lastReview;

  ReviewItem({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
    required this.subject,
    required this.topic,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.repetitions = 0,
    DateTime? nextReview,
    DateTime? lastReview,
  })  : nextReview = nextReview ?? DateTime.now(),
        lastReview = lastReview ?? DateTime.now();

  bool get isDue => DateTime.now().isAfter(nextReview) || DateTime.now().isAtSameMomentAs(nextReview);

  void review(int quality) {
    // SM-2 algorithm: quality 0-5 (0=total fail, 5=perfect)
    if (quality >= 3) {
      if (repetitions == 0) {
        interval = 1;
      } else if (repetitions == 1) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
      repetitions++;
    } else {
      repetitions = 0;
      interval = 1;
    }

    easeFactor = (easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        .clamp(1.3, 2.5);
    lastReview = DateTime.now();
    nextReview = DateTime.now().add(Duration(days: interval));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'question': question,
    'options': options,
    'correctIndex': correctIndex,
    'explanation': explanation,
    'subject': subject,
    'topic': topic,
    'easeFactor': easeFactor,
    'interval': interval,
    'repetitions': repetitions,
    'nextReview': nextReview.toIso8601String(),
    'lastReview': lastReview.toIso8601String(),
  };

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
    id: json['id'] ?? '',
    question: json['question'] ?? '',
    options: (json['options'] as List?)?.cast<String>() ?? [],
    correctIndex: json['correctIndex'] ?? 0,
    explanation: json['explanation'],
    subject: json['subject'] ?? '',
    topic: json['topic'] ?? '',
    easeFactor: (json['easeFactor'] ?? 2.5).toDouble(),
    interval: json['interval'] ?? 1,
    repetitions: json['repetitions'] ?? 0,
    nextReview: json['nextReview'] != null ? DateTime.parse(json['nextReview']) : null,
    lastReview: json['lastReview'] != null ? DateTime.parse(json['lastReview']) : null,
  );
}

class SpacedRepetitionService extends ChangeNotifier {
  static const String _itemsKey = 'sr_items';
  static const int _maxItems = 500;

  List<ReviewItem> _items = [];

  List<ReviewItem> get allItems => List.unmodifiable(_items);
  List<ReviewItem> get dueItems => _items.where((i) => i.isDue).toList();
  int get dueCount => dueItems.length;
  int get totalItems => _items.length;

  List<ReviewItem> getDueBySubject(String subject) =>
      dueItems.where((i) => i.subject == subject).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_itemsKey) ?? [];
    _items = jsonList
        .map((j) => ReviewItem.fromJson(jsonDecode(j)))
        .toList();
    notifyListeners();
  }

  void addFromQuiz({
    required String question,
    required List<String> options,
    required int correctIndex,
    String? explanation,
    required String subject,
    required String topic,
    required bool wasCorrect,
  }) {
    final existing = _items.indexWhere((i) => i.question == question);
    if (existing != -1) {
      // Item already tracked — review with quality based on correctness
      _items[existing].review(wasCorrect ? 4 : 1);
    } else {
      // New item: always add to the deck so it's reviewed later.
      // Wrong answers get interval=1 (review tomorrow).
      // Correct answers start with interval=3 (less urgent).
      final item = ReviewItem(
        id: 'sr_${DateTime.now().millisecondsSinceEpoch}',
        question: question,
        options: options,
        correctIndex: correctIndex,
        explanation: explanation,
        subject: subject,
        topic: topic,
      );
      if (wasCorrect) {
        item.review(4); // Sets interval to 1 then 6 days via SM-2
      }
      _items.add(item);
    }

    if (_items.length > _maxItems) {
      _items.sort((a, b) => b.nextReview.compareTo(a.nextReview));
      _items = _items.sublist(0, _maxItems);
    }

    _save();
    notifyListeners();
  }

  void reviewItem(String itemId, int quality) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    _items[index].review(quality);
    _save();
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    _save();
    notifyListeners();
  }

  Map<String, int> getDueCountBySubject() {
    final counts = <String, int>{};
    for (final item in dueItems) {
      counts[item.subject] = (counts[item.subject] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _itemsKey,
      _items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }
}
