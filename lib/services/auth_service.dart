// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _googleInitialized = false;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  // Web Client ID dari Firebase Console > Authentication > Sign-in method >
  // Google > Web SDK configuration. Wajib diisi di Android untuk google_sign_in.
  static const _serverClientId =
      '849959450481-oqpjj30qom1ajv4htvn6mcmacf55um44.apps.googleusercontent.com';

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _googleInitialized = true;
  }

  static Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google tidak memberikan ID token. Coba lagi.');
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Sign-out Google gagal (mis. belum pernah init) — sesi Firebase
      // sudah berakhir di atas, jadi ini tidak fatal.
    }
  }
}
