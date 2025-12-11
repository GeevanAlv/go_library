// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palet Warna Kunci
  static const Color primaryTeal = Color(0xFF00796B); // Teal Primer (Profesional)
  static const Color backgroundWhite = Color(0xFFFAFAFA); // Putih Hangat/Pudar

  static ThemeData get lightTheme {
    // Definisi TextTheme menggunakan GoogleFonts (Poppins)
    final baseTextTheme = GoogleFonts.poppinsTextTheme(); 

    return ThemeData(
      // --- DASAR & WARNA ---
      primaryColor: primaryTeal,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ).copyWith(
        background: backgroundWhite,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundWhite,
      
      // --- TYPOGRAPHY ---
      textTheme: baseTextTheme,
      
      // --- WIDGET STYLING ---

      // AppBar (Kontras Tinggi)
      appBarTheme: AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0, 
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      
      // Tombol (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Sudut yang halus
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      
      // Kartu/Card (Estetik, Shadow Minimalis)
      cardTheme: CardThemeData( 
        elevation: 6, 
        shadowColor: primaryTeal.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), 
          side: BorderSide(color: Colors.grey.shade200, width: 0.5)
        ),
      ),
      
      // Input Form (Field Teks)
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10), 
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        filled: true,
        fillColor: Colors.white, 
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      )
    );
  }
  
  // ✅ PERBAIKAN: Getter darkTheme yang wajib ada untuk MaterialApp.
  // Kita mengembalikannya sebagai tema Dark default dengan warna primary yang sama.
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryTeal,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryTeal,
        secondary: primaryTeal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      // Jika Anda tidak ingin menyesuaikan widget lain di dark mode, ini sudah cukup.
    ); 
  }
}