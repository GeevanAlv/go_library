// lib/screens/book_detail_screen.dart (FINAL CODE DENGAN ASYNCVALUE)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/book_provider.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart'; // Import AppTheme

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Ambil data buku berdasarkan ID (menggunakan provider family)
    // ✅ Sekarang mengamati AsyncValue<Book>
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    
    // 2. Ambil data pengguna saat ini
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.uid;
    final isLibrarian = currentUser?.email == 'admin@library.com';

    // 3. Tangani Status Data (Loading, Error, atau Data Tersedia)
    return bookAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Memuat...', style: GoogleFonts.poppins())),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: Text('Error', style: GoogleFonts.poppins())),
        body: Center(child: Text('Gagal memuat detail buku: $e', style: GoogleFonts.poppins(color: Colors.red))),
      ),
      data: (book) {
        // Data buku telah tersedia, sekarang kita bisa melanjutkan logika UI

        // Cek apakah pengguna saat ini adalah peminjam buku ini
        final isCurrentBorrower = book.borrowerId == currentUserId;
        // Cek apakah pengguna dapat mengubah status (Meminjam/Mengembalikan)
        final canToggle = book.isAvailable || isCurrentBorrower || isLibrarian;

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: COVER & INFO RINGKAS ---
                _BuildHeaderSection(book: book),
                const Divider(height: 30),

                // --- DESKRIPSI & SINOPSIS ---
                Text('Sinopsis', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(book.description, style: GoogleFonts.poppins(fontSize: 14)),
                const Divider(height: 30),

                // --- INFORMASI PINJAMAN ---
                _BuildAvailabilityInfo(book: book, isCurrentBorrower: isCurrentBorrower),
                const Divider(height: 30),

                // --- TOMBOL AKSI ---
                if (canToggle)
                  _BuildActionButton(
                    book: book, 
                    isCurrentBorrower: isCurrentBorrower,
                  ),
                  
                const SizedBox(height: 20),

                // Opsi Tambahan (misalnya, Hapus Buku untuk Admin)
                if (isLibrarian)
                  _BuildAdminActions(book: book),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ====================================================================
// WIDGET HELPER BARU (Diambil dari kode sebelumnya)
// ====================================================================

// --- HEADER SECTION ---
class _BuildHeaderSection extends StatelessWidget {
  final Book book;
  const _BuildHeaderSection({required this.book});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: book.coverImageUrl,
            width: 120,
            height: 180,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => Icon(Icons.book, size: 100, color: Theme.of(context).primaryColor),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Oleh: ${book.author}', style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Chip(
                label: Text(book.category, style: GoogleFonts.poppins()),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- STATUS KETERSEDIAAN ---
class _BuildAvailabilityInfo extends StatelessWidget {
  final Book book;
  final bool isCurrentBorrower;
  const _BuildAvailabilityInfo({required this.book, required this.isCurrentBorrower});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Ketersediaan', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              book.isAvailable ? Icons.check_circle : Icons.schedule_outlined,
              color: book.isAvailable ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              book.isAvailable ? 'Tersedia untuk dipinjam' : 'Sedang Dipinjam',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: book.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!book.isAvailable && isCurrentBorrower)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Anda adalah peminjam buku ini.', style: GoogleFonts.poppins(color: Theme.of(context).primaryColor)),
          ),
      ],
    );
  }
}

// --- TOMBOL AKSI (Pinjam/Kembalikan) ---
class _BuildActionButton extends ConsumerWidget {
  final Book book;
  final bool isCurrentBorrower;
  const _BuildActionButton({required this.book, required this.isCurrentBorrower});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).primaryColor;

    return ElevatedButton.icon(
      icon: Icon(book.isAvailable ? Icons.bookmark_add : Icons.bookmark_remove),
      onPressed: () {
        // Menggunakan bookActionProvider untuk memanggil update Firestore
        ref.read(bookActionProvider.notifier).toggleAvailability(book.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              book.isAvailable ? 'Berhasil meminjam ${book.title}' : 'Berhasil mengembalikan ${book.title}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: book.isAvailable ? primaryColor : Colors.redAccent,
          ),
        );
        // Kembali ke katalog setelah aksi berhasil
        Navigator.of(context).pop(); 
      },
      label: Text(
        book.isAvailable ? 'PINJAM SEKARANG' : 'KEMBALIKAN BUKU',
        style: GoogleFonts.poppins(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: book.isAvailable ? primaryColor : Colors.red,
      ),
    );
  }
}

// --- AKSI ADMIN (Hapus Buku) ---
class _BuildAdminActions extends ConsumerWidget {
  final Book book;
  const _BuildAdminActions({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: TextButton.icon(
        icon: const Icon(Icons.delete_forever, color: Colors.red),
        label: Text('Hapus Buku dari Katalog', style: GoogleFonts.poppins(color: Colors.red)),
        onPressed: () {
          // Panggil fungsi removeBook di provider
          ref.read(bookActionProvider.notifier).removeBook(book.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${book.title} telah dihapus.', style: GoogleFonts.poppins())),
          );
          Navigator.of(context).pop(); 
        },
      ),
    );
  }
}