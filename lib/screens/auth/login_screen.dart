// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart'; // Import AuthService

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil instansi AuthService untuk memanggil signInWithGoogle
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Judul Aplikasi
              Text(
                'Katalog Perpustakaan',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Masuk untuk mengakses katalog buku.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 50),
              
              // Tombol Login Google
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Masuk dengan Google'),
                onPressed: () async {
                  try {
                    await authService.signInWithGoogle();
                    // Jika berhasil, MainRouter di main.dart akan otomatis navigasi ke CatalogScreen
                  } catch (e) {
                    // Tampilkan pesan error jika login gagal (misalnya, koneksi terputus)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Login Gagal. Pastikan Anda memiliki koneksi internet.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(250, 50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}