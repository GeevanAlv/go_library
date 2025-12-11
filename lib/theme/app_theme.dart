// lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Tema Terang
  static ThemeData get lightTheme {
    const primaryColor = Color(0xFF00796B); // Teal 700

    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ).copyWith(
        secondary: const Color(0xFF4DB6AC),
        background: const Color(0xFFF7F7F7),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F7),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      
      // ✅ PERBAIKAN: Menggunakan CardThemeData()
      cardTheme: CardThemeData( 
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        // Anda juga bisa menentukan color di sini jika CardThemeData membutuhkan properti color
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade100,
      )
    );
  }

  // Tema Gelap
  static ThemeData get darkTheme {
    const primaryColor = Color(0xFF4DB6AC); // Teal 300

    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ).copyWith(
        secondary: const Color(0xFF26A69A),
        background: const Color(0xFF121212),
        surface: const Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF004D40), // Teal 900
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        ),
      ),
      
      // ✅ PERBAIKAN: Menggunakan CardThemeData()
      cardTheme: CardThemeData( 
        elevation: 2,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade800,
        hintStyle: const TextStyle(color: Colors.white54),
        labelStyle: const TextStyle(color: Colors.white70),
      )
    );
  }
}