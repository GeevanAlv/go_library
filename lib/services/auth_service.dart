import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. PROVIDER UTAMA (PENTING)
// Ini yang didengarkan oleh Home Screen & Detail Screen
// Mengembalikan objek 'User?' dari Firebase langsung.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 2. SERVICE CLASS
// Berisi fungsi-fungsi bantuan seperti SignOut
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fungsi Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Fungsi Login (Opsional, karena di LoginScreen kita panggil FirebaseAuth langsung)
  // Tapi kita simpan di sini jika nanti butuh dipanggil dari logic lain
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login gagal.';
    }
  }

  // Fungsi Register (Opsional)
  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Pendaftaran gagal.';
    }
  }
}

// Provider untuk memanggil fungsi-fungsi di atas (misal: ref.read(authServiceProvider).signOut())
final authServiceProvider = Provider<AuthService>((ref) => AuthService());