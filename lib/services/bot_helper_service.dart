import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menaxhon gjendjen e botit ndihmës dhe preferencat e përdoruesit
class BotHelperService extends ChangeNotifier {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyBotVisible = 'bot_visible';
  static const String _keyCurrentTipIndex = 'current_tip_index';
  static const String _keySeenTips = 'seen_tips';

  bool _onboardingCompleted = false;
  bool _botVisible = true;
  bool _isLoaded = false;
  int _currentTipIndex = 0;
  Set<String> _seenTips = {};
  String? _activeTip;
  bool _isTipExpanded = false;

  bool get onboardingCompleted => _onboardingCompleted;
  bool get botVisible => _botVisible;
  bool get isLoaded => _isLoaded;
  int get currentTipIndex => _currentTipIndex;
  String? get activeTip => _activeTip;
  bool get isTipExpanded => _isTipExpanded;

  /// Këshilla kontekstuale sipas ekranit
  static const Map<String, List<String>> contextualTips = {
    'home': [
      'Përshëndetje! 👋 Unë jam SciBot, asistenti yt i shkencës! Prek mbi mua për ndihmë.',
      'Mund të më pyesësh çdo gjë rreth Matematikës, Fizikës, Kimisë ose Biologjisë!',
      'Provoje të shkruash një pyetje si "Çfarë është graviteti?" për të filluar!',
      'Dërgoj një foto të detyrës dhe unë do ta zgjidh hap pas hapi! 📸',
    ],
    'chat': [
      'Shkruaj pyetjen tënde dhe unë do të përgjigjem sa më qartë!',
      'Mund të pyesësh pyetje vijuese - unë mbaj mend bisedën!',
      'Provo: "Shpjegom si funksionon fotosinteza" 🌱',
    ],
    'lab': [
      'Mirë se erdhe në Laborator! 🧪 Këtu mund të bësh eksperimente virtuale.',
      'Zgjidh një lëndë dhe fillo eksperimentin tënd!',
      'Mos ki frikë të provosh - eksperimentet virtuale janë të sigurta! 😄',
    ],
    'quiz': [
      'Koha për kuiz! 🎯 Testo njohuritë e tua.',
      'Zgjidh një lëndë dhe vështirësinë për të filluar.',
      'Pas çdo pyetjeje do shohësh shpjegimin e saktë!',
    ],
  };

  /// Ngarko preferencat nga SharedPreferences
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
    _botVisible = prefs.getBool(_keyBotVisible) ?? true;
    _currentTipIndex = prefs.getInt(_keyCurrentTipIndex) ?? 0;
    final seenTipsList = prefs.getStringList(_keySeenTips) ?? [];
    _seenTips = seenTipsList.toSet();
    _isLoaded = true;
    notifyListeners();
  }

  /// Shëno onboarding si të përfunduar
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
    notifyListeners();
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    _onboardingCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, false);
    await prefs.setStringList(_keySeenTips, []);
    _seenTips.clear();
    _currentTipIndex = 0;
    notifyListeners();
  }

  /// Ndrysho dukshmërinë e botit
  Future<void> toggleBotVisibility() async {
    _botVisible = !_botVisible;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBotVisible, _botVisible);
    notifyListeners();
  }

  /// Vendos botin si të dukshëm
  Future<void> showBot() async {
    if (!_botVisible) {
      _botVisible = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBotVisible, true);
      notifyListeners();
    }
  }

  /// Fshih botin
  Future<void> hideBot() async {
    if (_botVisible) {
      _botVisible = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBotVisible, false);
      notifyListeners();
    }
  }

  /// Trego këshillë kontekstuale për ekranin aktual
  void showTipForScreen(String screen) {
    final tips = contextualTips[screen];
    if (tips == null || tips.isEmpty) return;

    // Gjej këshillën e parë që nuk është parë
    for (int i = 0; i < tips.length; i++) {
      final tipKey = '${screen}_$i';
      if (!_seenTips.contains(tipKey)) {
        _activeTip = tips[i];
        _isTipExpanded = true;
        notifyListeners();
        return;
      }
    }

    // Nëse janë parë të gjitha, trego random
    _activeTip = null;
    _isTipExpanded = false;
    notifyListeners();
  }

  /// Shëno këshillën aktuale si të parë
  Future<void> dismissCurrentTip(String screen) async {
    final tips = contextualTips[screen];
    if (tips == null) return;

    for (int i = 0; i < tips.length; i++) {
      if (tips[i] == _activeTip) {
        _seenTips.add('${screen}_$i');
        break;
      }
    }

    _activeTip = null;
    _isTipExpanded = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySeenTips, _seenTips.toList());
    notifyListeners();
  }

  /// Zgjero/mbyll ballonat e këshillave
  void toggleTipExpanded() {
    _isTipExpanded = !_isTipExpanded;
    notifyListeners();
  }

  /// Vendos aktivizimin manual të këshillës
  void setActiveTip(String tip) {
    _activeTip = tip;
    _isTipExpanded = true;
    notifyListeners();
  }

  /// Pastro tip-in aktiv
  void clearTip() {
    _activeTip = null;
    _isTipExpanded = false;
    notifyListeners();
  }
}
