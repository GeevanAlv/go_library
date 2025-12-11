// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. MODEL PENGGUNA (AppUser) ---
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;

  AppUser({required this.uid, this.displayName, this.email});
}

// --- 2. AUTH SERVICE CLASS ---

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((User? user) {
      if (user == null) return null;
      return AppUser(
        uid: user.uid,
        displayName: user.displayName, 
        email: user.email,
      );
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login gagal. Coba lagi.';
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Pendaftaran gagal.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});