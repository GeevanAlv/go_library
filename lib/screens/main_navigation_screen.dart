import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

// Import halaman-halaman yang akan ditampilkan
import 'home_screen.dart';
import 'ai_search_screen.dart'; // AI jadi menu tengah
import 'my_loans_screen.dart';   // Untuk User
import 'admin_loan_screen.dart'; // Untuk Admin

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 1. Cek Role User saat ini
    final user = ref.watch(authStateProvider).value;
    final isAdmin = user?.email == 'admin@library.com';

    // 2. Tentukan Halaman Menu ke-3 (Kanan)
    // Jika Admin -> AdminLoanScreen (Monitor)
    // Jika User  -> MyLoansScreen (Pinjaman Saya)
    final Widget rightMenuScreen = isAdmin ? const AdminLoanScreen() : const MyLoansScreen();
    
    // Teks & Icon untuk Menu ke-3
    final String rightMenuLabel = isAdmin ? "Monitor" : "Pinjaman";
    final IconData rightMenuIcon = isAdmin ? Icons.assignment_ind : Icons.history_edu;

    // 3. Daftar Halaman (Urutan: Kiri - Tengah - Kanan)
    final List<Widget> pages = [
      const HomeScreen(),     // 0: Home
      const AISearchScreen(), // 1: AI Chat
      rightMenuScreen,        // 2: Dynamic (Monitor / Pinjaman)
    ];

    return Scaffold(
      // Tampilkan halaman sesuai index yang dipilih
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryTeal,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          
          items: [
            // MENU 1: HOME
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Beranda",
            ),

            // MENU 2: AI (Tengah)
            const BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: "AI Assistant",
            ),

            // MENU 3: DINAMIS (Sesuai Role)
            BottomNavigationBarItem(
              icon: Icon(rightMenuIcon),
              label: rightMenuLabel,
            ),
          ],
        ),
      ),
    );
  }
}