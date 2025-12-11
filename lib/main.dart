// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

// WAJIB: File ini harus ada setelah menjalankan 'flutterfire configure'
import 'package:go_library/firebase_options.dart'; 

import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/book_catalog_screen.dart'; 
import 'theme/app_theme.dart'; 

void main() async {
  // Pastikan binding Flutter diinisialisasi sebelum memanggil native code
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inisialisasi Firebase Core (Penting untuk semua layanan Firebase)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ); 
  } catch (e) {
    // Ini penting jika terjadi error inisialisasi pada platform tertentu (misalnya Web)
    print("Error initializing Firebase: $e");
  }
  
  // 2. Memulai Aplikasi dengan ProviderScope (Wajib untuk Riverpod)
  runApp(const ProviderScope(child: BookCatalogApp()));
}

class BookCatalogApp extends StatelessWidget {
  const BookCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katalog Perpustakaan',
      
      // Menggunakan tema estetik yang baru kita buat
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      // ✅ Penting: Memaksa aplikasi untuk selalu menggunakan Light Theme (Tema Terang)
      themeMode: ThemeMode.light, 
      
      home: const MainRouter(),
    );
  }
}

// Router utama yang menangani status login/logout secara reaktif
class MainRouter extends ConsumerWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Amati status autentikasi dari StreamProvider
    final authState = ref.watch(authStateProvider);
    // 

    return authState.when(
      // Data telah tersedia (user terdeteksi atau tidak)
      data: (user) {
        if (user != null) {
          // Jika sudah login, tampilkan katalog
          return const BookCatalogScreen(); 
        }
        // Jika belum login, tampilkan layar login
        return const LoginScreen();
      },
      
      // Menunggu respons pertama dari Firebase Auth
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryTeal),
        ),
      ),
      
      // Jika terjadi kesalahan fatal pada stream auth
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text(
            'Error Autentikasi Fatal: ${err.toString()}', 
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}