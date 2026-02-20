import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/audio_lesson.dart';
import 'auth_service.dart';
import 'gemini_service.dart';

enum TtsState { stopped, playing, paused }

class AudiobookService extends ChangeNotifier {
  AuthService _auth;
  final FlutterTts _tts = FlutterTts();
  final GeminiService _gemini = GeminiService();

  List<AudioLesson> _lessons = [];
  List<AudioLesson> get lessons => _lessons;

  TtsState _ttsState = TtsState.stopped;
  TtsState get ttsState => _ttsState;

  double _speechRate = 1.0;
  double get speechRate => _speechRate;

  String? _currentLessonId;
  String? get currentLessonId => _currentLessonId;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  AudiobookService(this._auth) {
    _initTts();
    if (_auth.isLoggedIn) loadLessons();
  }

  void updateAuth(AuthService auth) {
    final changed = _auth.user?.uid != auth.user?.uid;
    _auth = auth;
    if (changed && auth.isLoggedIn) loadLessons();
  }

  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('audio_lessons');

  void _initTts() {
    _tts.setLanguage('sq-AL');
    _tts.setSpeechRate(_speechRate);

    _tts.setCompletionHandler(() {
      _ttsState = TtsState.stopped;
      _currentLessonId = null;
      notifyListeners();
    });

    _tts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      _currentLessonId = null;
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      _ttsState = TtsState.paused;
      notifyListeners();
    });

    _tts.setContinueHandler(() {
      _ttsState = TtsState.playing;
      notifyListeners();
    });
  }

  Future<void> loadLessons() async {
    final user = _auth.user;
    if (user == null) return;
    try {
      final snap = await _col
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();
      _lessons = snap.docs.map((d) => AudioLesson.fromDoc(d)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('loadLessons error: $e');
    }
  }

  Future<AudioLesson?> generateLesson({
    required String subject,
    required String topic,
  }) async {
    final user = _auth.user;
    if (user == null) return null;
    _isGenerating = true;
    notifyListeners();

    try {
      final result = await _gemini.generateAudioLessonScript(
        subject: subject,
        topic: topic,
      );
      if (result == null) {
        _isGenerating = false;
        notifyListeners();
        return null;
      }

      final script = result['script']!;
      // Estimate ~2.5 words/sec for Albanian TTS
      final wordCount = script.split(RegExp(r'\s+')).length;
      final duration = (wordCount / 2.5).round();

      final lesson = AudioLesson(
        id: '',
        userId: user.uid,
        subject: subject,
        topic: topic,
        title: result['title']!,
        script: script,
        durationSeconds: duration,
        createdAt: DateTime.now(),
      );

      final docRef = await _col.add(lesson.toMap());
      final saved = AudioLesson(
        id: docRef.id,
        userId: lesson.userId,
        subject: lesson.subject,
        topic: lesson.topic,
        title: lesson.title,
        script: lesson.script,
        durationSeconds: lesson.durationSeconds,
        createdAt: lesson.createdAt,
      );

      _lessons.insert(0, saved);
      _isGenerating = false;
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('generateLesson error: $e');
      _isGenerating = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleFavorite(AudioLesson lesson) async {
    lesson.isFavorite = !lesson.isFavorite;
    notifyListeners();
    try {
      await _col.doc(lesson.id).update({'isFavorite': lesson.isFavorite});
    } catch (e) {
      lesson.isFavorite = !lesson.isFavorite;
      notifyListeners();
    }
  }

  Future<void> deleteLesson(AudioLesson lesson) async {
    _lessons.remove(lesson);
    notifyListeners();
    try {
      await _col.doc(lesson.id).delete();
    } catch (e) {
      debugPrint('deleteLesson error: $e');
    }
  }

  // --- Playback ---

  Future<void> playLesson(AudioLesson lesson) async {
    if (_ttsState == TtsState.playing) {
      await _tts.stop();
    }
    _currentLessonId = lesson.id;
    _ttsState = TtsState.playing;
    notifyListeners();
    await _tts.speak(lesson.script);
  }

  Future<void> pausePlayback() async {
    if (_ttsState == TtsState.playing) {
      await _tts.pause();
      _ttsState = TtsState.paused;
      notifyListeners();
    }
  }

  Future<void> resumePlayback() async {
    // FlutterTts doesn't support resume on all platforms; treat as continue
    // On Android it may work via pause/continue handlers
    _ttsState = TtsState.playing;
    notifyListeners();
  }

  Future<void> stopPlayback() async {
    await _tts.stop();
    _ttsState = TtsState.stopped;
    _currentLessonId = null;
    notifyListeners();
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.5, 2.0);
    await _tts.setSpeechRate(_speechRate);
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
