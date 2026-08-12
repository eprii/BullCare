import 'package:firebase_auth/firebase_auth.dart';

import 'user_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, UserService? userService})
      : _auth = auth ?? FirebaseAuth.instance,
        _userService = userService ?? UserService();

  final FirebaseAuth _auth;
  final UserService _userService;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = credential.user;
    if (user != null) {
      await _userService.ensureUserProfile(user);
    }
  }

  Future<void> register({
    required String nama,
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final User? user = credential.user;
    if (user == null) throw StateError('Akun tidak berhasil dibuat.');
    await user.updateDisplayName(nama.trim());
    await _userService.createPetugasProfile(user: user, nama: nama.trim());
  }

  Future<void> signOut() => _auth.signOut();
}
