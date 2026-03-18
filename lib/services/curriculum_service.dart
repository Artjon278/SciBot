import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CurriculumService extends ChangeNotifier {
  static const String _gradeKey = 'student_grade';
  static const String _learningStyleKey = 'learning_style';

  int _grade = 0;
  String _learningStyle = 'balanced';
  bool _isLoaded = false;

  int get grade => _grade;
  String get gradeLabel => _grade > 0 ? 'Klasa $_grade' : 'Pa zgjedhur';
  String get learningStyle => _learningStyle;
  bool get isLoaded => _isLoaded;
  bool get hasGrade => _grade > 0;

  static const Map<int, Map<String, List<String>>> curriculum = {
    6: {
      'Matematikë': ['Numrat natyrorë', 'Thyesat', 'Gjeometria bazë', 'Matjet', 'Përqindja'],
      'Fizikë': ['Lëvizja', 'Forcat bazë', 'Energjia', 'Temperatura'],
      'Kimi': ['Lënda dhe vetitë', 'Ndryshimet fizike/kimike', 'Elementet bazë'],
      'Biologji': ['Qeliza', 'Bimët', 'Kafshët', 'Trupi i njeriut bazë'],
    },
    7: {
      'Matematikë': ['Numrat e plotë', 'Ekuacionet lineare', 'Proporcionaliteti', 'Statistikë bazë', 'Simetria'],
      'Fizikë': ['Dendësia', 'Presioni', 'Puna dhe energjia', 'Nxehtësia'],
      'Kimi': ['Atomet dhe molekulat', 'Tabela periodike bazë', 'Reaksionet kimike', 'Acide dhe baza'],
      'Biologji': ['Sistemi tretës', 'Sistemi i qarkullimit', 'Sistemi frymëmarrës', 'Ekosistemi'],
    },
    8: {
      'Matematikë': ['Shprehjet algjebrike', 'Ekuacionet', 'Funksionet lineare', 'Teorema e Pitagorës', 'Probabiliteti'],
      'Fizikë': ['Ligjet e Njutonit', 'Puna mekanike', 'Energjia kinetike/potenciale', 'Valët'],
      'Kimi': ['Struktura atomike', 'Lidhjet kimike', 'Reaksionet redoks', 'Tretësirat'],
      'Biologji': ['Sistemi nervor', 'Sistemi endokrin', 'Riprodhimi', 'Gjenetika bazë'],
    },
    9: {
      'Matematikë': ['Ekuacionet kuadratike', 'Funksionet', 'Trigonometria bazë', 'Vektorët', 'Statistika'],
      'Fizikë': ['Kinematika', 'Dinamika', 'Termodinamika', 'Elektrostatika'],
      'Kimi': ['Steokiometria', 'Termodinamika kimike', 'Kinetika', 'Ekuilibri kimik'],
      'Biologji': ['ADN dhe ARN', 'Mitoza/Mejoza', 'Evolucioni', 'Bioteknologjia'],
    },
    10: {
      'Matematikë': ['Logaritmet', 'Vargjet', 'Limitet', 'Derivatet bazë', 'Kombinatorika'],
      'Fizikë': ['Lëvizja rrethore', 'Gravitacioni', 'Rryma elektrike', 'Magnetizmi'],
      'Kimi': ['Kimia organike bazë', 'Hidrokarburet', 'Alkoolet', 'Polimerizimi'],
      'Biologji': ['Fotosinteza detajuar', 'Frymëmarrja qelizore', 'Ekologjia', 'Biodiversiteti'],
    },
    11: {
      'Matematikë': ['Derivatet', 'Integralet bazë', 'Funksionet trigonometrike', 'Numrat kompleksë', 'Matricat'],
      'Fizikë': ['Fizika bërthamore', 'Radioaktiviteti', 'Optika', 'Fizika moderne'],
      'Kimi': ['Acide/baza avancuar', 'Elektrokimia', 'Kimia e mjedisit', 'Biokimia bazë'],
      'Biologji': ['Gjenetika avancuar', 'Inxhinieria gjenetike', 'Imunologjia', 'Neuroshkenca'],
    },
    12: {
      'Matematikë': ['Integralet', 'Ekuacionet diferenciale', 'Gjeometria analitike', 'Statistika avancuar', 'Përgatitje Mature'],
      'Fizikë': ['Mekanika kuantike bazë', 'Relativiteti', 'Fizika e grimcave', 'Përgatitje Mature'],
      'Kimi': ['Kimia industriale', 'Biokimia avancuar', 'Nanokimia', 'Përgatitje Mature'],
      'Biologji': ['Biologjia molekulare', 'Bioteknologjia avancuar', 'Evolucioni modern', 'Përgatitje Mature'],
    },
  };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _grade = prefs.getInt(_gradeKey) ?? 0;
    _learningStyle = prefs.getString(_learningStyleKey) ?? 'balanced';
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setGrade(int grade) async {
    _grade = grade;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gradeKey, grade);
    _syncToFirestore();
    notifyListeners();
  }

  Future<void> setLearningStyle(String style) async {
    _learningStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_learningStyleKey, style);
    _syncToFirestore();
    notifyListeners();
  }

  List<String> getTopicsForSubject(String subject) {
    if (_grade == 0) return [];
    return curriculum[_grade]?[subject] ?? [];
  }

  Map<String, List<String>> getAllTopicsForGrade() {
    if (_grade == 0) return {};
    return curriculum[_grade] ?? {};
  }

  String getContextForAI() {
    if (_grade == 0) return '';
    return 'Nxënësi është në Klasën $_grade të shkollës së mesme në Shqipëri.';
  }

  Future<void> _syncToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'grade': _grade,
        'learningStyle': _learningStyle,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
