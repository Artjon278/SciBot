import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StudentPersonality {
  fast('I Shpejtë', 'Përgjigje direkte, pa hyrje, më shumë sfida'),
  unsure('I Pasigurt', 'Inkurajim, celebrim suksesesh, hapa të vegjël'),
  curious('Kurioz', 'Fun facts, lidhje me jetën reale, thellësi'),
  rushed('I Ngutur', 'Përmbledhje të shkurtra, bullet points, direkt'),
  balanced('I Balancuar', 'Stil standard, i përshtatur');

  final String label;
  final String description;
  const StudentPersonality(this.label, this.description);
}

class AdaptiveAIService extends ChangeNotifier {
  static const String _personalityKey = 'ai_personality';
  static const String _manualOverrideKey = 'ai_manual_override';
  static const String _interactionStatsKey = 'ai_interaction_stats';
  static const String _toneKey = 'ai_tone';

  StudentPersonality _personality = StudentPersonality.balanced;
  bool _manualOverride = false;
  String _tone = 'miqësor';
  Map<String, int> _interactionStats = {};
  bool _isLoaded = false;

  StudentPersonality get personality => _personality;
  bool get manualOverride => _manualOverride;
  String get tone => _tone;
  bool get isLoaded => _isLoaded;

  static const List<String> toneOptions = [
    'miqësor',
    'strikt',
    'humoristik',
    'motivues',
    'akademik',
  ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final pIndex = prefs.getInt(_personalityKey) ?? StudentPersonality.balanced.index;
    _personality = StudentPersonality.values[pIndex.clamp(0, StudentPersonality.values.length - 1)];
    _manualOverride = prefs.getBool(_manualOverrideKey) ?? false;
    _tone = prefs.getString(_toneKey) ?? 'miqësor';

    final statsJson = prefs.getString(_interactionStatsKey);
    if (statsJson != null) {
      _interactionStats = Map<String, int>.from(jsonDecode(statsJson));
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setPersonality(StudentPersonality personality) async {
    _personality = personality;
    _manualOverride = true;
    await _save();
    notifyListeners();
  }

  Future<void> setTone(String tone) async {
    _tone = tone;
    await _save();
    notifyListeners();
  }

  Future<void> disableManualOverride() async {
    _manualOverride = false;
    await _save();
    notifyListeners();
  }

  void recordInteraction({
    required String type,
    int responseTime = 0,
    bool askedFollowUp = false,
    bool usedHint = false,
  }) {
    _interactionStats['total'] = (_interactionStats['total'] ?? 0) + 1;
    _interactionStats['$type'] = (_interactionStats['$type'] ?? 0) + 1;

    if (askedFollowUp) {
      _interactionStats['followUps'] = (_interactionStats['followUps'] ?? 0) + 1;
    }
    if (usedHint) {
      _interactionStats['hints'] = (_interactionStats['hints'] ?? 0) + 1;
    }
    if (responseTime < 5) {
      _interactionStats['fastResponses'] = (_interactionStats['fastResponses'] ?? 0) + 1;
    }

    if (!_manualOverride) {
      _autoDetectPersonality();
    }
    _save();
  }

  void _autoDetectPersonality() {
    final total = _interactionStats['total'] ?? 0;
    if (total < 10) return;

    final followUps = _interactionStats['followUps'] ?? 0;
    final hints = _interactionStats['hints'] ?? 0;
    final fastResponses = _interactionStats['fastResponses'] ?? 0;

    final followUpRatio = followUps / total;
    final hintRatio = hints / total;
    final fastRatio = fastResponses / total;

    if (fastRatio > 0.6) {
      _personality = StudentPersonality.fast;
    } else if (hintRatio > 0.4) {
      _personality = StudentPersonality.unsure;
    } else if (followUpRatio > 0.5) {
      _personality = StudentPersonality.curious;
    } else {
      _personality = StudentPersonality.balanced;
    }
    notifyListeners();
  }

  String buildSystemPrompt({String? gradeContext, String? subject}) {
    final buffer = StringBuffer();

    buffer.writeln('Ti je SciBot, asistent AI i shkencës për nxënësit e shkollave të mesme në Shqipëri.');
    buffer.writeln('Ekspertizë: Matematikë, Fizikë, Kimi, Biologji.');
    if (gradeContext != null && gradeContext.isNotEmpty) {
      buffer.writeln(gradeContext);
    }

    buffer.writeln('\nRregulla:');
    buffer.writeln('- Përgjigju VETËM në shqip');
    buffer.writeln('- Përdor emoji për ta bërë më tërheqës');
    buffer.writeln('- Për probleme matematikore: trego çdo hap me formulë');
    buffer.writeln('- Për koncepte shkencore: analogji e thjeshtë + shembull real');
    buffer.writeln('- Përdor markdown (bold, lista, headers) për strukturë');
    buffer.writeln('- Nëse nxënësi gabon, korrigjo me mirësjellje dhe shpjego PSE');

    buffer.writeln('\nToni yt: $_tone');

    switch (_personality) {
      case StudentPersonality.fast:
        buffer.writeln('\nKy nxënës mëson shpejt:');
        buffer.writeln('- Përgjigje direkte, pa hyrje të gjata');
        buffer.writeln('- Shkurto shpjegimet, jep vetëm thelbin');
        buffer.writeln('- Propozo sfida më të vështira');
        buffer.writeln('- Max 150 fjalë përveç zgjidhje detajuar');
      case StudentPersonality.unsure:
        buffer.writeln('\nKy nxënës ka nevojë për inkurajim:');
        buffer.writeln('- Celebro çdo sukses, edhe të voglin');
        buffer.writeln('- Thuaj "Shumë mirë!" dhe "Po e kupton!"');
        buffer.writeln('- Ndaj problemin në hapa të vegjël');
        buffer.writeln('- Jep shembuj para konceptit');
        buffer.writeln('- Max 250 fjalë');
      case StudentPersonality.curious:
        buffer.writeln('\nKy nxënës është kurioz:');
        buffer.writeln('- Shto "Fun fact" dhe lidhje me jetën reale');
        buffer.writeln('- Shpjego edhe "pse" jo vetëm "si"');
        buffer.writeln('- Propozo tema të ngjashme për eksplorim');
        buffer.writeln('- Max 300 fjalë');
      case StudentPersonality.rushed:
        buffer.writeln('\nKy nxënës nuk ka kohë:');
        buffer.writeln('- Vetëm bullet points');
        buffer.writeln('- Zero hyrje apo mbyllje');
        buffer.writeln('- Përgjigje minimale por të sakta');
        buffer.writeln('- Max 100 fjalë');
      case StudentPersonality.balanced:
        buffer.writeln('- Përgjigje koncize (max 200 fjalë) përveç kur kërkohet detajuar');
        buffer.writeln('- Ji inkurajues por i drejtpërdrejtë');
    }

    if (subject != null) {
      switch (subject) {
        case 'Matematikë':
          buffer.writeln('\nPër matematikë: ji preciz me formulat, trego hapat numerikë.');
        case 'Fizikë':
          buffer.writeln('\nPër fizikë: lidh me fenomene reale, vizualizo forcën/lëvizjen.');
        case 'Kimi':
          buffer.writeln('\nPër kimi: përdor analogji për reaksione, shpjego si recetar.');
        case 'Biologji':
          buffer.writeln('\nPër biologji: përdor krahasime me gjëra të njohura, analogji trupi.');
      }
    }

    return buffer.toString();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_personalityKey, _personality.index);
    await prefs.setBool(_manualOverrideKey, _manualOverride);
    await prefs.setString(_toneKey, _tone);
    await prefs.setString(_interactionStatsKey, jsonEncode(_interactionStats));
  }
}
