// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAuth(bool isLogin) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = ref.read(authServiceProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (isLogin) {
        await authService.signInWithEmailAndPassword(email, password);
      } else {
        await authService.signUpWithEmailAndPassword(email, password);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error Autentikasi: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Ornamen Latar Belakang (Variasi Elegan)
          _buildBackgroundOrnaments(primaryColor),

          // Konten Utama (Form Login)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Profesional
                          Text(
                            'Selamat Datang',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk atau Daftar untuk mengakses katalog.',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 30),

                          // Input Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty || !value.contains('@')) {
                                return 'Email harus valid.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Input Password
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(labelText: 'Kata Sandi', prefixIcon: Icon(Icons.lock_outline)),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Sandi min. 6 karakter.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),

                          // Tombol Login / Loading
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () => _submitAuth(true), // Login
                                    label: const Text('MASUK'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Tombol Daftar
                                TextButton(
                                  onPressed: () => _submitAuth(false), // Daftar
                                  child: Text('Belum punya akun? DAFTAR di sini', style: TextStyle(color: primaryColor)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET ORNAMEN LATAR BELAKANG ---
  Widget _buildBackgroundOrnaments(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.05), Colors.white, primaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -150,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 150,
            right: 50,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}