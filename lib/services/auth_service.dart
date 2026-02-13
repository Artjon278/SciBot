import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _username;
  bool _isLoading = true;
  String? _error;

  User? get user => _user;
  String get username => _username ?? _user?.displayName ?? 'Përdorues';
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  /// Dëgjo ndryshimet e gjendjes së autentifikimit
  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _loadUsername();
    } else {
      _username = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Ngarko username nga Firestore
  Future<void> _loadUsername() async {
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        _username = doc.data()?['username'] ?? _user!.displayName;
      } else {
        _username = _user!.displayName;
      }
    } catch (e) {
      _username = _user!.displayName;
    }
  }

  /// Ruaj të dhënat e përdoruesit në Firestore
  Future<void> _saveUserToFirestore({required String username}) async {
    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'username': username,
        'email': _user!.email,
        'photoUrl': _user!.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _username = username;
    } catch (e) {
      debugPrint('Gabim gjatë ruajtjes në Firestore: $e');
    }
  }

  /// Përditëso timestamp-in e login-it
  Future<void> _updateLastLogin() async {
    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Gabim gjatë përditësimit: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Regjistrohu me Email & Password
  // ═══════════════════════════════════════════════════════════
  Future<bool> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Vendos display name
      await credential.user?.updateDisplayName(username);
      await credential.user?.reload();
      _user = _auth.currentUser;

      // Ruaj në Firestore
      await _saveUserToFirestore(username: username);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Ndodhi një gabim i papritur.';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Hyr me Email & Password
  // ═══════════════════════════════════════════════════════════
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _loadUsername();
      await _updateLastLogin();

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'Ndodhi një gabim i papritur.';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Vazhdo me Google
  // ═══════════════════════════════════════════════════════════
  Future<bool> signInWithGoogle() async {
    try {
      _error = null;
      _isLoading = true;
      notifyListeners();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false; // Përdoruesi anuloi
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Ruaj në Firestore nëse është përdorues i ri
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      if (isNewUser) {
        await _saveUserToFirestore(
          username: googleUser.displayName ?? 'Përdorues',
        );
      } else {
        await _loadUsername();
        await _updateLastLogin();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Gabim me Google Sign-In: $e';
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Dil nga llogaria
  // ═══════════════════════════════════════════════════════════
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _username = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Gabim gjatë daljes: $e';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Përditëso username
  // ═══════════════════════════════════════════════════════════
  Future<void> updateUsername(String newUsername) async {
    try {
      await _user?.updateDisplayName(newUsername);
      await _firestore.collection('users').doc(_user!.uid).update({
        'username': newUsername,
      });
      _username = newUsername;
      notifyListeners();
    } catch (e) {
      _error = 'Gabim gjatë përditësimit të username: $e';
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Reset password - Dërgo email
  // ═══════════════════════════════════════════════════════════
  Future<bool> resetPassword(String email) async {
    try {
      _error = null;
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Verifiko kodin e reset-it
  // ═══════════════════════════════════════════════════════════
  Future<String?> verifyResetCode(String code) async {
    try {
      _error = null;
      final email = await _auth.verifyPasswordResetCode(code);
      return email;
    } on FirebaseAuthException catch (e) {
      _error = _getVerifyCodeError(e.code);
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Kodi nuk është i vlefshëm ose ka skaduar.';
      notifyListeners();
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Konfirmo fjalëkalimin e ri me kodin
  // ═══════════════════════════════════════════════════════════
  Future<bool> confirmReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      _error = null;
      await _auth.confirmPasswordReset(code: code, newPassword: newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getVerifyCodeError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Ndodhi një gabim gjatë ndryshimit të fjalëkalimit.';
      notifyListeners();
      return false;
    }
  }

  /// Kthen mesazh gabimi për kodin e verifikimit
  String _getVerifyCodeError(String code) {
    switch (code) {
      case 'expired-action-code':
        return 'Kodi ka skaduar. Dërgo një kod të ri.';
      case 'invalid-action-code':
        return 'Kodi nuk është i vlefshëm. Kontrollo dhe provo përsëri.';
      case 'user-disabled':
        return 'Kjo llogari është çaktivizuar.';
      case 'user-not-found':
        return 'Nuk u gjet llogari me këtë email.';
      case 'weak-password':
        return 'Fjalëkalimi është shumë i dobët. Përdor të paktën 6 karaktere.';
      default:
        return 'Ndodhi një gabim: $code';
    }
  }

  /// Pastro gabimin
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Kthen mesazh gabimi në shqip
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Fjalëkalimi është shumë i dobët. Përdor të paktën 6 karaktere.';
      case 'email-already-in-use':
        return 'Ky email është i regjistruar tashmë. Provo të hysh.';
      case 'invalid-email':
        return 'Email-i nuk është i vlefshëm.';
      case 'user-not-found':
        return 'Nuk u gjet llogari me këtë email.';
      case 'wrong-password':
        return 'Fjalëkalimi është i gabuar.';
      case 'user-disabled':
        return 'Kjo llogari është çaktivizuar.';
      case 'too-many-requests':
        return 'Shumë tentativa. Provo përsëri më vonë.';
      case 'operation-not-allowed':
        return 'Ky veprim nuk lejohet.';
      case 'invalid-credential':
        return 'Email ose fjalëkalim i gabuar.';
      default:
        return 'Ndodhi një gabim: $code';
    }
  }
}
