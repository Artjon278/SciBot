import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'gemini_service.dart';

/// Një ushtrim brenda një detyre
class Exercise {
  final String id;
  final String number;
  final String title;
  final String text;
  final String subject;
  String? solution;
  bool isSolved;

  Exercise({
    required this.id,
    required this.number,
    required this.title,
    required this.text,
    required this.subject,
    this.solution,
    this.isSolved = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'number': number,
        'title': title,
        'text': text,
        'subject': subject,
        'solution': solution,
        'isSolved': isSolved,
      };

  factory Exercise.fromMap(Map<String, dynamic> m) => Exercise(
        id: m['id'] ?? '',
        number: m['number'] ?? '',
        title: m['title'] ?? '',
        text: m['text'] ?? '',
        subject: m['subject'] ?? 'Tjetër',
        solution: m['solution'],
        isSolved: m['isSolved'] ?? false,
      );
}

/// Një detyrë (homework) me listë ushtrimesh
class HomeworkItem {
  final String id;
  final String title;
  final String subject;
  final DateTime createdAt;
  final List<Exercise> exercises;

  HomeworkItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.createdAt,
    List<Exercise>? exercises,
  }) : exercises = exercises ?? [];

  int get solvedCount => exercises.where((e) => e.isSolved).length;
  int get totalCount => exercises.length;
  bool get isFullySolved => exercises.every((e) => e.isSolved);
  double get progress => totalCount > 0 ? solvedCount / totalCount : 0;

  Map<String, dynamic> toMap(String userId) => {
        'userId': userId,
        'title': title,
        'subject': subject,
        'createdAt': createdAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  factory HomeworkItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawExercises = data['exercises'];
    final List<Exercise> exerciseList = [];
    if (rawExercises is List) {
      for (final e in rawExercises) {
        if (e is Map<String, dynamic>) {
          exerciseList.add(Exercise.fromMap(e));
        } else if (e is Map) {
          exerciseList.add(Exercise.fromMap(Map<String, dynamic>.from(e)));
        }
      }
    }
    return HomeworkItem(
      id: doc.id,
      title: data['title'] ?? '',
      subject: data['subject'] ?? 'Tjetër',
      createdAt: DateTime.parse(
          data['createdAt'] ?? DateTime.now().toIso8601String()),
      exercises: exerciseList,
    );
  }
}

class HomeworkService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GeminiService _gemini = GeminiService();
  AuthService _auth;
  List<HomeworkItem> _items = [];
  bool _isLoading = false;
  bool _isExtracting = false;
  String? _extractError;

  List<HomeworkItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isExtracting => _isExtracting;
  String? get extractError => _extractError;

  int get totalHomework => _items.length;
  int get fullyDoneCount => _items.where((h) => h.isFullySolved).length;
  int get inProgressCount =>
      _items.where((h) => h.solvedCount > 0 && !h.isFullySolved).length;
  int get newCount => _items.where((h) => h.solvedCount == 0).length;

  HomeworkService(this._auth);

  void updateAuth(AuthService auth) {
    _auth = auth;
  }

  /// Ngarko detyrat nga Firestore
  Future<void> loadHomework() async {
    final user = _auth.user;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('homework')
          .where('userId', isEqualTo: user.uid)
          .get();

      _items = snapshot.docs.map(HomeworkItem.fromDoc).toList();
      _items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Gabim gjatë ngarkimit të detyrave: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nxjerr ushtrimet nga foto dhe krijon detyrë të re
  Future<HomeworkItem?> createFromPhoto(File imageFile) async {
    final user = _auth.user;
    if (user == null) return null;

    _isExtracting = true;
    _extractError = null;
    notifyListeners();

    try {
      final List<Map<String, String>> extracted =
          await _gemini.extractExercisesFromImage(imageFile);

      if (extracted.isEmpty) {
        _extractError =
            'Nuk u gjetën ushtrime në foto. Provo me foto më të qartë.';
        _isExtracting = false;
        notifyListeners();
        return null;
      }

      // Krijo ushtrimet
      final exercises = extracted.asMap().entries.map((entry) {
        final e = entry.value;
        return Exercise(
          id: 'ex_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          number: e['number'] ?? '${entry.key + 1}',
          title: e['title'] ?? 'Ushtrim ${entry.key + 1}',
          text: e['text'] ?? '',
          subject: e['subject'] ?? 'Tjetër',
        );
      }).toList();

      // Gjej lëndën dominuese
      final subjectCounts = <String, int>{};
      for (final ex in exercises) {
        subjectCounts[ex.subject] = (subjectCounts[ex.subject] ?? 0) + 1;
      }
      final mainSubject = subjectCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      final hw = HomeworkItem(
        id: '',
        title: '${exercises.length} Ushtrime - $mainSubject',
        subject: mainSubject,
        createdAt: DateTime.now(),
        exercises: exercises,
      );

      // Ruaj në Firestore
      final docRef =
          await _db.collection('homework').add(hw.toMap(user.uid));

      final saved = HomeworkItem(
        id: docRef.id,
        title: hw.title,
        subject: hw.subject,
        createdAt: hw.createdAt,
        exercises: hw.exercises,
      );

      _items.insert(0, saved);
      _isExtracting = false;
      notifyListeners();
      return saved;
    } catch (e) {
      _extractError = 'Gabim: $e';
      _isExtracting = false;
      notifyListeners();
      return null;
    }
  }

  /// Nxjerr ushtrimet nga dokument PDF/tekst dhe krijon detyrë të re
  Future<HomeworkItem?> createFromDocument(File docFile) async {
    final user = _auth.user;
    if (user == null) return null;

    _isExtracting = true;
    _extractError = null;
    notifyListeners();

    try {
      final List<Map<String, String>> extracted =
          await _gemini.extractExercisesFromDocument(docFile);

      if (extracted.isEmpty) {
        _extractError =
            'Nuk u gjetën ushtrime në dokument. Provo me dokument tjetër.';
        _isExtracting = false;
        notifyListeners();
        return null;
      }

      final exercises = extracted.asMap().entries.map((entry) {
        final e = entry.value;
        return Exercise(
          id: 'ex_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
          number: e['number'] ?? '${entry.key + 1}',
          title: e['title'] ?? 'Ushtrim ${entry.key + 1}',
          text: e['text'] ?? '',
          subject: e['subject'] ?? 'Tjetër',
        );
      }).toList();

      final subjectCounts = <String, int>{};
      for (final ex in exercises) {
        subjectCounts[ex.subject] = (subjectCounts[ex.subject] ?? 0) + 1;
      }
      final mainSubject = subjectCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      // Merr emrin e skedarit si titull
      final fileName = docFile.path.split(RegExp(r'[\\/]')).last;
      final cleanName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');

      final hw = HomeworkItem(
        id: '',
        title: cleanName.isNotEmpty
            ? '$cleanName (${exercises.length} ushtrime)'
            : '${exercises.length} Ushtrime - $mainSubject',
        subject: mainSubject,
        createdAt: DateTime.now(),
        exercises: exercises,
      );

      final docRef =
          await _db.collection('homework').add(hw.toMap(user.uid));

      final saved = HomeworkItem(
        id: docRef.id,
        title: hw.title,
        subject: hw.subject,
        createdAt: hw.createdAt,
        exercises: hw.exercises,
      );

      _items.insert(0, saved);
      _isExtracting = false;
      notifyListeners();
      return saved;
    } catch (e) {
      _extractError = 'Gabim: $e';
      _isExtracting = false;
      notifyListeners();
      return null;
    }
  }

  /// Zgjidh një ushtrim me AI
  Future<String?> solveExercise(String homeworkId, String exerciseId) async {
    final hwIndex = _items.indexWhere((h) => h.id == homeworkId);
    if (hwIndex == -1) return null;

    final hw = _items[hwIndex];
    final exIndex = hw.exercises.indexWhere((e) => e.id == exerciseId);
    if (exIndex == -1) return null;

    final exercise = hw.exercises[exIndex];

    try {
      final solution = await _gemini.solveExercise(
        exerciseText: exercise.text,
        subject: exercise.subject,
      );

      exercise.solution = solution;
      exercise.isSolved = true;

      // Përditëso Firestore
      await _db.collection('homework').doc(homeworkId).update({
        'exercises': hw.exercises.map((e) => e.toMap()).toList(),
      });

      notifyListeners();
      return solution;
    } catch (e) {
      debugPrint('Gabim gjatë zgjidhjes: $e');
      return null;
    }
  }

  /// Fshi detyrën
  Future<void> deleteHomework(String homeworkId) async {
    await _db.collection('homework').doc(homeworkId).delete();
    _items.removeWhere((h) => h.id == homeworkId);
    notifyListeners();
  }
}
