// lib/providers/book_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart'; // Untuk mendapatkan UID pengguna yang sedang login

const _uuid = Uuid();

// State: Daftar semua buku
typedef BookList = List<Book>;

// --- 1. NOTIFIER: LOGIKA KATALOG BUKU ---

class BookNotifier extends StateNotifier<BookList> {
  final Ref ref;

  BookNotifier(this.ref) : super(_initialBooks);

  // Data Awal (Dummy Data untuk Simulasi Perpustakaan)
  static final List<Book> _initialBooks = [
    Book(
      id: _uuid.v4(),
      title: 'Dunia Sophie',
      author: 'Jostein Gaarder',
      category: 'Filsafat',
      coverImageUrl: 'https://picsum.photos/id/100/200/300',
      description: 'Sebuah novel tentang sejarah filsafat Barat.',
    ),
    Book(
      id: _uuid.v4(),
      title: 'Sapiens: Sejarah Singkat Umat Manusia',
      author: 'Yuval Noah Harari',
      category: 'Sejarah',
      coverImageUrl: 'https://picsum.photos/id/200/200/300',
      isAvailable: false, // Contoh buku sedang dipinjam
      borrowerId: 'dummy_borrower_1',
      description: 'Sebuah sejarah yang merangkum evolusi manusia.',
    ),
    Book(
      id: _uuid.v4(),
      title: 'Atomic Habits',
      author: 'James Clear',
      category: 'Pengembangan Diri',
      coverImageUrl: 'https://picsum.photos/id/300/200/300',
      description: 'Panduan praktis untuk membangun kebiasaan baik.',
    ),
    Book(
      id: _uuid.v4(),
      title: 'The Great Gatsby',
      author: 'F. Scott Fitzgerald',
      category: 'Fiksi',
      coverImageUrl: 'https://picsum.photos/id/400/200/300',
      description: 'Novel klasik Amerika tentang kemakmuran dan obsesi.',
    ),
  ];

  // --- MUTASI (CRUD Sederhana) ---
  
  void addBook(Book newBook) {
    state = [...state, newBook];
  }

  void removeBook(String bookId) {
    state = state.where((book) => book.id != bookId).toList();
  }

  // --- LOGIKA PEMINJAMAN/PENGEMBALIAN (DIPERBAIKI) ---

  void toggleAvailability(String bookId) {
    // Dapatkan UID pengguna yang sedang login
    final currentUser = ref.read(authStateProvider).value; 
    final currentUserId = currentUser?.uid;

    // Menggunakan .map().toList() untuk memastikan state selalu menghasilkan List<Book>
    state = state.map((book) {
      if (book.id == bookId) {
        // --- 1. Jika Buku Tersedia (Action: Pinjam) ---
        if (book.isAvailable) {
          // Hanya izinkan meminjam jika pengguna terautentikasi
          if (currentUserId == null) return book; 
          
          return book.copyWith(
            isAvailable: false,
            borrowerId: currentUserId,
          );
        } 
        
        // --- 2. Jika Buku Dipinjam (Action: Kembalikan) ---
        else if (book.borrowerId == currentUserId || (currentUser?.email == 'admin@library.com')) {
          // Boleh dikembalikan jika: (a) Pengguna adalah peminjam ATAU (b) Pengguna adalah admin (override)
          return book.copyWith(
            isAvailable: true,
            borrowerId: null,
          );
        } 
        
        // --- 3. Jika Buku Dipinjam Orang Lain dan Bukan Admin ---
        else {
          return book; // Kembalikan objek asli, tidak ada mutasi state
        }
      }
      return book; // Kembalikan buku yang tidak cocok ID-nya
    }).toList(); // Wajib diubah menjadi List
  }
}

// --- 2. PROVIDER RIVERPOD ---

// Provider utama untuk state buku (list penuh)
final bookListProvider = StateNotifierProvider<BookNotifier, BookList>(
  (ref) => BookNotifier(ref), // Meneruskan ref ke Notifier
);

// State untuk menampung input pencarian
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered List Provider (untuk menampilkan hasil pencarian di UI)
final filteredBookListProvider = Provider<BookList>((ref) {
  final books = ref.watch(bookListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return books;
  }

  return books.where((book) {
    // Cari berdasarkan judul, penulis, atau kategori
    return book.title.toLowerCase().contains(query) ||
           book.author.toLowerCase().contains(query) ||
           book.category.toLowerCase().contains(query);
  }).toList();
});

// Provider untuk mendapatkan satu buku berdasarkan ID (digunakan di Detail Screen)
final bookByIdProvider = Provider.family<Book, String>((ref, id) {
  // Menggunakan firstWhere (atau firstWhereOrNull jika Anda menggunakan versi Dart yang lebih baru)
  return ref.watch(bookListProvider).firstWhere((book) => book.id == id);
});