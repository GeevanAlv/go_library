// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import layar Login Anda
import 'package:go_library/screens/auth/login_screen.dart'; 

void main() {
  testWidgets('Smoke test: Halaman Login muncul dengan benar', (WidgetTester tester) async {
    // 1. Build Halaman Login dalam lingkungan test.
    // Kita HARUS membungkusnya dengan ProviderScope karena aplikasi menggunakan Riverpod.
    // Kita juga butuh MaterialApp agar widget Scaffold bisa bekerja.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // 2. Verifikasi bahwa elemen-elemen Login muncul di layar.
    
    // Cek apakah teks tombol "MASUK" ada
    expect(find.text('MASUK'), findsOneWidget);
    
    // Cek apakah teks tombol "DAFTAR" TIDAK ada (karena defaultnya mode login)
    expect(find.text('DAFTAR'), findsNothing);

    // Cek apakah ada 2 kotak input (Email dan Password)
    expect(find.byType(TextField), findsNWidgets(2));

    // Cek apakah Ikon Buku muncul
    expect(find.byIcon(Icons.library_books), findsOneWidget);
  });
}