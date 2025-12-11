// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // Wajib
import 'package:go_library/firebase_options.dart'; // <--- PERBAIKAN: Import file yang dibuat FlutterFire CLI
// import 'services/firebase_service_config.dart'; // <-- DIHAPUS (File dummy)

import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/book_catalog_screen.dart'; 
import 'theme/app_theme.dart'; // Asumsi: path ini benar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // PERBAIKAN KRUSIAL: Memanggil inisialisasi dengan opsi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); 
  
  runApp(const ProviderScope(child: BookCatalogApp()));
}

class BookCatalogApp extends StatelessWidget {
  const BookCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katalog Perpustakaan',
      // Pastikan AppTheme ada di path lib/theme/app_theme.dart
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainRouter(),
    );
  }
}

// Router utama yang menangani status login
class MainRouter extends ConsumerWidget {
  const MainRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // StreamProvider.when() adalah cara yang tepat untuk menangani state async
    return authState.when(
      data: (user) {
        if (user != null) {
          // Jika sudah login, tampilkan katalog
          return const BookCatalogScreen(); 
        }
        // Jika belum login, tampilkan layar login
        return const LoginScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: ${err.toString()}'))),
    );
  }
}