import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ IMPORT FILE KONFIGURASI FIREBASE
import 'firebase_options.dart'; 

// ✅ IMPORT SCREEN (Sesuaikan dengan folder terbaru)
import 'screens/auth/login_screen.dart'; 
import 'screens/main_navigation_screen.dart'; 

// ✅ IMPORT THEME
import 'theme/app_theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Jalankan App dengan ProviderScope (Wajib untuk Riverpod)
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hilangkan pita Debug merah
      title: 'Go Library',
      theme: AppTheme.lightTheme, // Gunakan tema teal yang sudah dibuat
      
      // 👇 AuthWrapper: Mengecek apakah user login atau belum
      home: const AuthWrapper(),
    );
  }
}

// ==========================================
// WIDGET PENGECEK STATUS LOGIN (AuthWrapper)
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Jika sedang loading (koneksi lambat)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. Jika User Ada (Sudah Login) -> Masuk ke Menu Utama
        if (snapshot.hasData) {
          // ⚠️ PENTING: Jangan pakai 'const' di sini agar tidak error
          return const MainNavigationScreen(); 
        }

        // 3. Jika User Kosong (Belum Login) -> Masuk ke Login
        // ⚠️ PENTING: Jangan pakai 'const' di sini agar tidak error
        return const LoginScreen();
      },
    );
  }
}