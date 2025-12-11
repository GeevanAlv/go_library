// lib/screens/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/book_provider.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';

// ====================================================================
// KELAS UTAMA
// ====================================================================

class BookDetailScreen extends ConsumerWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data buku. Karena ini Provider.family, data buku pasti ada.
    final book = ref.watch(bookByIdProvider(bookId)); 
    
    // Ambil data pengguna
    final currentUser = ref.watch(authStateProvider).value;
    final currentUserId = currentUser?.uid;
    final isLibrarian = currentUser?.email == 'admin@library.com';

    final isCurrentBorrower = book.borrowerId == currentUserId;
    final canToggle = book.isAvailable || isCurrentBorrower || isLibrarian;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: COVER & INFO RINGKAS (Panggilan function) ---
            _BuildHeaderSection(book: book),
            const Divider(height: 30),

            // --- DESKRIPSI & SINOPSIS ---
            Text('Sinopsis', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(book.description, style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 30),

            // --- INFORMASI PINJAMAN (Panggilan function) ---
            _BuildAvailabilityInfo(book: book, isCurrentBorrower: isCurrentBorrower),
            const Divider(height: 30),

            // --- TOMBOL AKSI (Panggilan function ConsumerWidget) ---
            if (canToggle)
              _BuildActionButton(book: book, isCurrentBorrower: isCurrentBorrower),
              
            const SizedBox(height: 20),

            // Opsi Tambahan (Admin)
            if (isLibrarian)
              _BuildAdminActions(book: book),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// WIDGET HELPER BARU (Dibuat sebagai StatelessWidget/ConsumerWidget)
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
            errorWidget: (context, url, error) => const Icon(Icons.book, size: 100),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(book.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('Oleh: ${book.author}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Chip(label: Text(book.category), backgroundColor: Colors.blue.shade100),
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
        Text('Status Ketersediaan', style: Theme.of(context).textTheme.titleLarge),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: book.isAvailable ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!book.isAvailable && isCurrentBorrower)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            // ✅ PERBAIKAN ERROR 5: Menggunakan .primaryColor
            child: Text('Anda adalah peminjam buku ini.', style: TextStyle(color: Theme.of(context).primaryColor)), 
          ),
      ],
    );
  }
}

// --- TOMBOL AKSI (Membutuhkan ref, jadi ConsumerWidget) ---
class _BuildActionButton extends ConsumerWidget {
  final Book book;
  final bool isCurrentBorrower;
  const _BuildActionButton({required this.book, required this.isCurrentBorrower});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: book.isAvailable || isCurrentBorrower 
        ? () {
            ref.read(bookListProvider.notifier).toggleAvailability(book.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  book.isAvailable ? 'Berhasil meminjam ${book.title}' : 'Berhasil mengembalikan ${book.title}',
                ),
              ),
            );
          }
        : null, 
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        backgroundColor: book.isAvailable ? Theme.of(context).primaryColor : Colors.red,
        foregroundColor: Colors.white,
      ),
      child: Text(
        book.isAvailable ? 'Pinjam Sekarang' : 'Kembalikan Buku',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

// --- ADMIN ACTIONS ---
class _BuildAdminActions extends ConsumerWidget {
  final Book book;
  const _BuildAdminActions({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      icon: const Icon(Icons.delete_forever, color: Colors.red),
      label: const Text('Hapus Buku dari Katalog', style: TextStyle(color: Colors.red)),
      onPressed: () {
        ref.read(bookListProvider.notifier).removeBook(book.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${book.title} telah dihapus.')),
        );
        Navigator.of(context).pop(); 
      },
    );
  }
}