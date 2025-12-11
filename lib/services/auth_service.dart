// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- 1. MODEL PENGGUNA (AppUser) ---
// Kita tidak bergantung pada model Firebase User, tapi model kita sendiri yang bersih
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;

  AppUser({required this.uid, this.displayName, this.email});
}


// --- 2. AUTH SERVICE CLASS ---

class AuthService {
  // Instansi Firebase dan Google Sign-In
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream status login (AppUser atau null)
  // Ini adalah sumber kebenaran untuk mengetahui apakah pengguna sudah login
  Stream<AppUser?> get authStateChanges {
    // Memetakan objek Firebase User menjadi objek AppUser kita sendiri
    return _auth.authStateChanges().map((User? user) {
      if (user == null) {
        return null; // Pengguna belum login
      }
      return AppUser(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
      );
    });
  }

  // --- LOGIKA UTAMA: LOGIN DENGAN GOOGLE ---
  Future<void> signInWithGoogle() async {
    try {
      // 1. Meminta pengguna memilih akun Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Login dibatalkan oleh pengguna
        return; 
      }

      // 2. Mendapatkan kredensial otentikasi dari Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 3. Masuk ke Firebase menggunakan kredensial Google
      await _auth.signInWithCredential(credential);
      
      // Jika berhasil, authStateChanges akan otomatis mengalirkan data AppUser
    } catch (e) {
      // Tampilkan error ke konsol
      print("Google Sign-In Failed: $e");
      // Meneruskan error agar dapat ditangkap dan ditampilkan di UI
      rethrow; 
    }
  }

  // --- LOGIKA: LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut(); // Penting untuk sign-out dari Google juga
  }
}


// --- 3. PROVIDER RIVERPOD ---

// Provider untuk mengakses AuthService (agar bisa memanggil signInWithGoogle/signOut)
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// StreamProvider untuk memantau status autentikasi
final authStateProvider = StreamProvider<AppUser?>((ref) {
  // Ketika AuthService berubah, provider ini akan memperbarui statusnya
  return ref.watch(authServiceProvider).authStateChanges;
});// TODO Implement this library.