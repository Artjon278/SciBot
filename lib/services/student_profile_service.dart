import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/student_profile.dart';
import 'auth_service.dart';

class StudentProfileService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthService _authService;

  StudentProfile? _profile;
  bool _isLoading = false;
  bool _isLoaded = false;

  StudentProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  bool get hasProfile => _profile != null;

  StudentProfileService(this._authService) {
    _loadProfile();
  }

  void updateAuth(AuthService auth) {
    _authService = auth;
    if (auth.isLoggedIn) {
      _loadProfile();
    } else {
      _profile = null;
      _isLoaded = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    final uid = _authService.user?.uid;
    if (uid == null) {
      _isLoaded = true;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists && doc.data()?['studentProfile'] != null) {
        _profile = StudentProfile.fromMap(
          Map<String, dynamic>.from(doc.data()!['studentProfile']),
        );
      } else {
        _profile = null;
      }
    } catch (e) {
      debugPrint('Gabim gjatë ngarkimit të profilit: $e');
      _profile = null;
    } finally {
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Ruaj profilin e studentit në Firestore
  Future<String?> saveProfile({
    required String learningStyle,
    required List<String> preferredSubjects,
    required String currentLevel,
    required String goal,
    required int dailyStudyMinutes,
  }) async {
    final uid = _authService.user?.uid;
    if (uid == null) return 'Përdoruesi nuk është i loguar.';

    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final profile = StudentProfile(
        uid: uid,
        learningStyle: learningStyle,
        preferredSubjects: preferredSubjects,
        currentLevel: currentLevel,
        goal: goal,
        dailyStudyMinutes: dailyStudyMinutes,
        createdAt: _profile?.createdAt ?? now,
        updatedAt: now,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set({'studentProfile': profile.toMap()}, SetOptions(merge: true));

      _profile = profile;
      _isLoading = false;
      notifyListeners();
      return null; // null = sukses
    } catch (e) {
      debugPrint('Gabim gjatë ruajtjes së profilit: $e');
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  /// Fshi profilin (për ri-bërje të quiz-it)
  Future<void> deleteProfile() async {
    final uid = _authService.user?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'studentProfile': FieldValue.delete()});

      _profile = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Gabim gjatë fshirjes së profilit: $e');
    }
  }

  /// Ri-ngarko profilin
  Future<void> reload() async {
    await _loadProfile();
  }
}
