import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/ai_memory.dart';
import '../models/student_profile.dart';
import 'auth_service.dart';

/// Shërbimi i kujtesës së AI-it - mban mend gjithçka rreth studentit
class AIMemoryService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService _authService;

  AIMemory? _memory;
  bool _isLoaded = false;

  AIMemory? get memory => _memory;
  bool get isLoaded => _isLoaded;

  AIMemoryService(this._authService) {
    _loadMemory();
  }

  void updateAuth(AuthService auth) {
    _authService = auth;
    if (auth.isLoggedIn) {
      _loadMemory();
    } else {
      _memory = null;
      _isLoaded = false;
      notifyListeners();
    }
  }

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _model = 'gemini-2.5-flash';

  // ═══════════════════════════════════════════════════════════
  // Firestore CRUD
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadMemory() async {
    final uid = _authService.user?.uid;
    if (uid == null) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data()?['aiMemory'] != null) {
        _memory = AIMemory.fromMap(
          Map<String, dynamic>.from(doc.data()!['aiMemory']),
        );
      } else {
        // Krijo kujtesë bosh
        _memory = AIMemory(uid: uid, updatedAt: DateTime.now());
      }
    } catch (e) {
      debugPrint('Gabim gjatë ngarkimit të AI memory: $e');
      _memory = AIMemory(uid: uid, updatedAt: DateTime.now());
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _saveMemory() async {
    final uid = _authService.user?.uid;
    if (uid == null || _memory == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set({'aiMemory': _memory!.toMap()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Gabim gjatë ruajtjes së AI memory: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Ndërto System Prompt dinamikisht
  // ═══════════════════════════════════════════════════════════

  /// Ndërton system prompt-in e personalizuar bazuar në profilin dhe kujtesën
  String buildSystemPrompt({StudentProfile? profile}) {
    final buffer = StringBuffer();

    // Baza fikse
    buffer.writeln(
        'Ti je SciBot, asistent AI i shkencës për nxënësit e shkollave të mesme në Shqipëri.');
    buffer.writeln('Ekspertizë: Matematikë, Fizikë, Kimi, Biologji.\n');

    buffer.writeln('Rregulla bazë:');
    buffer.writeln('- Përgjigju VETËM në shqip');
    buffer.writeln(
        '- Përgjigje koncize (max 200 fjalë) përveç kur kërkohet zgjidhje e detajuar');
    buffer.writeln(
        '- Përdor emoji për ta bërë më tërheqës (p.sh. 📐 për matematikë, ⚗️ për kimi)');
    buffer.writeln(
        '- Për probleme matematikore: trego ÇDODNJË hap me formulë');
    buffer.writeln(
        '- Për koncepte shkencore: analogji e thjeshtë + shembull real');
    buffer.writeln('- Ji inkurajues por i drejtpërdrejtë');
    buffer.writeln(
        '- Përdor markdown (bold, lista, headers) për strukturë');
    buffer.writeln('- Referoju bisedave të mëparshme kur lidhet');
    buffer.writeln(
        '- Nëse nxënësi gabon, korrigjo me mirësjellje dhe shpjego PSE\n');

    // Profili i studentit
    if (profile != null) {
      buffer.writeln('═══ PROFILI I STUDENTIT ═══');
      buffer.writeln('Stili i të mësuarit: ${profile.learningStyle}');
      buffer.writeln(
          'Lëndët e preferuara: ${profile.preferredSubjects.join(", ")}');
      buffer.writeln('Niveli: ${profile.currentLevel}');
      buffer.writeln('Qëllimi: ${_goalDescription(profile.goal)}');
      buffer.writeln(
          'Koha e disponueshme: ${profile.dailyStudyMinutes} min/ditë\n');

      // Udhëzime specifike për stilin e të mësuarit
      buffer.writeln(_learningStyleInstructions(profile.learningStyle));
    }

    // Kujtesa e AI-it
    if (_memory != null) {
      final m = _memory!;

      if (m.discussedTopics.isNotEmpty) {
        buffer.writeln('═══ TEMAT E DISKUTUARA ═══');
        m.discussedTopics.forEach((subject, topics) {
          if (topics.isNotEmpty) {
            buffer.writeln(
                '$subject: ${topics.take(8).join(", ")}');
          }
        });
        buffer.writeln();
      }

      if (m.commonMistakes.isNotEmpty) {
        buffer.writeln('═══ GABIMET E SHPESHTA (kujdes me këto!) ═══');
        m.commonMistakes.forEach((subject, mistakes) {
          if (mistakes.isNotEmpty) {
            buffer.writeln(
                '$subject: ${mistakes.take(5).join("; ")}');
          }
        });
        buffer.writeln(
            'KUJDES: Kur studenti punon me këto tema, kujtoji gabimet e mëparshme.\n');
      }

      if (m.masteredConcepts.isNotEmpty) {
        buffer.writeln('═══ KONCEPTET E ZOTËRUARA ═══');
        m.masteredConcepts.forEach((subject, concepts) {
          if (concepts.isNotEmpty) {
            buffer.writeln(
                '$subject: ${concepts.take(8).join(", ")}');
          }
        });
        buffer.writeln(
            'Mund t\'i referohesh këtyre si bazë për koncepte të reja.\n');
      }

      if (m.weakConcepts.isNotEmpty) {
        buffer.writeln('═══ KONCEPTET QË DUAN PUNË ═══');
        m.weakConcepts.forEach((subject, concepts) {
          if (concepts.isNotEmpty) {
            buffer.writeln(
                '$subject: ${concepts.take(5).join(", ")}');
          }
        });
        buffer.writeln(
            'Shpjego këto me kujdes ekstra, me hapa më të thjeshtë.\n');
      }

      if (m.preferredExplanationStyle.isNotEmpty) {
        buffer.writeln(
            '═══ STILI I SHPJEGIMIT QË FUNKSIONON ═══');
        buffer.writeln('${m.preferredExplanationStyle}\n');
      }

      if (m.lastSummary.isNotEmpty) {
        buffer.writeln('═══ KONTEKSTI I FUNDIT ═══');
        buffer.writeln('${m.lastSummary}\n');
      }

      if (m.quizStats.isNotEmpty) {
        buffer.writeln('═══ PERFORMANCA NË KUIZE ═══');
        m.quizStats.forEach((subject, stats) {
          final correct = stats['correct'] ?? 0;
          final total = stats['total'] ?? 0;
          if (total > 0) {
            final pct = (correct / total * 100).round();
            buffer.writeln('$subject: $correct/$total ($pct%)');
          }
        });
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _goalDescription(String goal) {
    switch (goal) {
      case 'provim':
        return 'Përgatitje për provim - fokusohu tek tema të rëndësishme dhe ushtrime';
      case 'nota':
        return 'Nota më të mira - ndihmoje me detyra dhe koncepte bazë';
      case 'kuriozitet':
        return 'Kurioz - eksploro tema interesante dhe thelloje njohuritë';
      default:
        return goal;
    }
  }

  String _learningStyleInstructions(String style) {
    switch (style) {
      case 'vizual':
        return '''UDHËZIME PËR STIL VIZUAL:
- Përdor diagrama ASCII, tabela, dhe përshkrime vizuale sa më shumë
- Përshkruaj konceptet si "imagjino që..." ose "sikur..."
- Përdor emoji dhe strukturë vizuale me lista\n''';
      case 'logjik':
        return '''UDHËZIME PËR STIL LOGJIK:
- Fokusohu tek "pse?" dhe arsyetimi logjik prapa çdo hapi
- Trego lidhjet shkak-pasojë midis koncepteve
- Jep prova dhe derivime kur mundësohet\n''';
      case 'praktik':
        return '''UDHËZIME PËR STIL PRAKTIK:
- Jep shembuj praktikë dhe ushtrime për të provuar
- Sugjeroj eksperimente ose aktivitete hands-on
- Lidh konceptet me jetën reale\n''';
      case 'lexues':
        return '''UDHËZIME PËR STIL LEXUES:
- Shpjegime të detajuara me tekst të organizuar
- Përdor paragrafë të strukturuara me nën-tituj
- Jep referenca dhe materiale shtesë për lexim\n''';
      default:
        return '';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Përditëso kujtesën pas bisedës
  // ═══════════════════════════════════════════════════════════

  /// Analizon bisedën me Gemini dhe përditëson kujtesën
  Future<void> updateAfterChat(List<Map<String, String>> recentMessages) async {
    if (recentMessages.isEmpty || _memory == null) return;

    // Ndërto kontekstin e bisedës
    final chatText = recentMessages
        .map((m) => '${m['role']}: ${m['text']}')
        .join('\n');

    final prompt = '''
Analizo këtë bisedë midis studentit dhe SciBot-it. Nxirr informacion për ta ruajtur në kujtesën e AI-it.

BISEDA:
$chatText

KUJTESA AKTUALE:
Tema të diskutuara: ${_memory!.discussedTopics}
Gabime të shpeshta: ${_memory!.commonMistakes}
Koncepte të zotëruara: ${_memory!.masteredConcepts}
Koncepte të dobëta: ${_memory!.weakConcepts}

VETËM JSON:
{
  "newTopics": {"lënda": ["tema1", "tema2"]},
  "newMistakes": {"lënda": ["gabimi"]},
  "newMastered": {"lënda": ["koncepti"]},
  "newWeak": {"lënda": ["koncepti"]},
  "explanationStyle": "çfarë stili funksionoi (bosh nëse nuk ka indikacion)",
  "summary": "1-2 fjali rezyme e bisedës"
}

Rregulla:
- Mos përsërit tema/koncepte që janë tashmë në kujtesë
- Nëse studenti tregoi që e kupton, shto te mastered
- Nëse gaboi ose nuk kuptoi, shto te weak
- Lënda duhet të jetë: Matematikë, Fizikë, Kimi, ose Biologji
- Nëse nuk ka ndryshime për një fushë, lëre bosh {}
- VETËM JSON, asgjë tjetër
''';

    try {
      final response = await _callGemini(prompt);
      final jsonStr = _extractJson(response);
      if (jsonStr == null) return;

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      _applyMemoryUpdate(data);
      await _saveMemory();
      notifyListeners();
    } catch (e) {
      debugPrint('AIMemory update pas chat gabim: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Përditëso kujtesën pas kuizit
  // ═══════════════════════════════════════════════════════════

  /// Përditëson kujtesën me rezultatet e kuizit
  Future<void> updateAfterQuiz({
    required String subject,
    required int correctAnswers,
    required int totalQuestions,
    List<String>? wrongTopics,
    List<String>? correctTopics,
  }) async {
    if (_memory == null) return;

    // Përditëso statistikat e kuizit
    final stats = Map<String, Map<String, int>>.from(_memory!.quizStats);
    final subjectStats = Map<String, int>.from(stats[subject] ?? {});
    subjectStats['correct'] =
        (subjectStats['correct'] ?? 0) + correctAnswers;
    subjectStats['total'] =
        (subjectStats['total'] ?? 0) + totalQuestions;
    stats[subject] = subjectStats;

    // Përditëso konceptet
    final mastered =
        Map<String, List<String>>.from(_memory!.masteredConcepts);
    final weak = Map<String, List<String>>.from(_memory!.weakConcepts);

    if (correctTopics != null) {
      final list = List<String>.from(mastered[subject] ?? []);
      for (final t in correctTopics) {
        if (!list.contains(t)) list.add(t);
      }
      // Mbaj max 20 koncepte
      if (list.length > 20) list.removeRange(0, list.length - 20);
      mastered[subject] = list;
    }

    if (wrongTopics != null) {
      final list = List<String>.from(weak[subject] ?? []);
      for (final t in wrongTopics) {
        if (!list.contains(t)) list.add(t);
      }
      if (list.length > 15) list.removeRange(0, list.length - 15);
      weak[subject] = list;

      // Shto edhe tek gabimet
      final mistakes =
          Map<String, List<String>>.from(_memory!.commonMistakes);
      final mList = List<String>.from(mistakes[subject] ?? []);
      for (final t in wrongTopics) {
        if (!mList.contains(t)) mList.add(t);
      }
      if (mList.length > 10) mList.removeRange(0, mList.length - 10);
      mistakes[subject] = mList;

      _memory = _memory!.copyWith(
        quizStats: stats,
        masteredConcepts: mastered,
        weakConcepts: weak,
        commonMistakes: mistakes,
      );
    } else {
      _memory = _memory!.copyWith(
        quizStats: stats,
        masteredConcepts: mastered,
        weakConcepts: weak,
      );
    }

    await _saveMemory();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // Përditëso kujtesën pas detyrave
  // ═══════════════════════════════════════════════════════════

  /// Përditëson kujtesën kur studenti mëson nga detyrat
  Future<void> updateAfterHomework({
    required String subject,
    required String topic,
    required bool solvedCorrectly,
  }) async {
    if (_memory == null) return;

    // Shto temën tek diskutimet
    final topics =
        Map<String, List<String>>.from(_memory!.discussedTopics);
    final list = List<String>.from(topics[subject] ?? []);
    if (!list.contains(topic)) {
      list.add(topic);
      if (list.length > 20) list.removeAt(0);
    }
    topics[subject] = list;

    if (solvedCorrectly) {
      final mastered =
          Map<String, List<String>>.from(_memory!.masteredConcepts);
      final mList = List<String>.from(mastered[subject] ?? []);
      if (!mList.contains(topic)) mList.add(topic);
      if (mList.length > 20) mList.removeRange(0, mList.length - 20);
      mastered[subject] = mList;

      _memory = _memory!.copyWith(
        discussedTopics: topics,
        masteredConcepts: mastered,
      );
    } else {
      final weak =
          Map<String, List<String>>.from(_memory!.weakConcepts);
      final wList = List<String>.from(weak[subject] ?? []);
      if (!wList.contains(topic)) wList.add(topic);
      if (wList.length > 15) wList.removeRange(0, wList.length - 15);
      weak[subject] = wList;

      _memory = _memory!.copyWith(
        discussedTopics: topics,
        weakConcepts: weak,
      );
    }

    await _saveMemory();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  void _applyMemoryUpdate(Map<String, dynamic> data) {
    final topics =
        Map<String, List<String>>.from(_memory!.discussedTopics);
    final mistakes =
        Map<String, List<String>>.from(_memory!.commonMistakes);
    final mastered =
        Map<String, List<String>>.from(_memory!.masteredConcepts);
    final weak =
        Map<String, List<String>>.from(_memory!.weakConcepts);

    // Merge new topics
    _mergeMapOfLists(topics, data['newTopics'], maxPerKey: 20);
    _mergeMapOfLists(mistakes, data['newMistakes'], maxPerKey: 10);
    _mergeMapOfLists(mastered, data['newMastered'], maxPerKey: 20);
    _mergeMapOfLists(weak, data['newWeak'], maxPerKey: 15);

    _memory = _memory!.copyWith(
      discussedTopics: topics,
      commonMistakes: mistakes,
      masteredConcepts: mastered,
      weakConcepts: weak,
      preferredExplanationStyle:
          (data['explanationStyle'] as String?)?.isNotEmpty == true
              ? data['explanationStyle']
              : _memory!.preferredExplanationStyle,
      lastSummary: data['summary'] as String? ?? _memory!.lastSummary,
    );
  }

  void _mergeMapOfLists(
    Map<String, List<String>> target,
    dynamic source, {
    int maxPerKey = 20,
  }) {
    if (source == null || source is! Map) return;
    source.forEach((key, value) {
      if (value is! List) return;
      final k = key.toString();
      final list = List<String>.from(target[k] ?? []);
      for (final item in value) {
        final s = item.toString();
        if (s.isNotEmpty && !list.contains(s)) {
          list.add(s);
        }
      }
      if (list.length > maxPerKey) {
        list.removeRange(0, list.length - maxPerKey);
      }
      target[k] = list;
    });
  }

  /// Thirr Gemini API direkt (pa histori)
  Future<String> _callGemini(String prompt) async {
    final url =
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ],
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        return candidates[0]['content']['parts'][0]['text'] ?? '';
      }
    }
    return '';
  }

  String? _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }
}
