// lib/providers/book_provider.dart (INTEGRASI FIRESTORE & LOGIKA PINJAM)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';

// --- 1. FIRESTORE MANAGER CLASS ---

class FirestoreBookManager {
  final _firestore = FirebaseFirestore.instance;

  Stream<List<Book>> getBooksStream() {
    // Mengambil data dari koleksi 'books' secara real-time
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Book(
          id: doc.id, 
          title: doc['title'] ?? 'N/A',
          author: doc['author'] ?? 'N/A',
          description: doc['description'] ?? 'Deskripsi kosong',
          category: doc['category'] ?? 'Umum',
          coverImageUrl: doc['coverImageUrl'] ?? 'https://picsum.photos/200/300',
          isAvailable: doc['isAvailable'] ?? true,
          borrowerId: doc['borrowerId'], 
        );
      }).toList();
    });
  }

  // Menambah Buku Baru (Admin)
  Future<void> addBook(Book book) async {
    await _firestore.collection('books').add({
      'title': book.title,
      'author': book.author,
      'category': book.category,
      'description': book.description,
      'coverImageUrl': book.coverImageUrl,
      'isAvailable': true,
      'borrowerId': null,
    });
  }

  // Mengubah Status Ketersediaan (Peminjaman/Pengembalian)
  Future<void> updateAvailability(String bookId, bool isAvailable, String? borrowerId) async {
    await _firestore.collection('books').doc(bookId).update({
      'isAvailable': isAvailable,
      'borrowerId': borrowerId,
    });
  }

  // Mengupdate data buku (Edit Buku)
  Future<void> updateBook(String bookId, Book book) async {
    await _firestore.collection('books').doc(bookId).update({
      'title': book.title,
      'author': book.author,
      'category': book.category,
      'description': book.description,
      'coverImageUrl': book.coverImageUrl,
    });
  }
}

// --- 2. LOGIKA PINJAM/KEMBALI (Menggunakan Manager) ---

class BookNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final Ref ref;
  BookNotifier(this.ref) : super(const AsyncValue.loading());

  void toggleAvailability(String bookId) async {
    final bookManager = ref.read(firestoreBookManagerProvider);
    final currentUser = ref.read(authStateProvider).value; 
    final currentUserId = currentUser?.uid;

    if (state.value == null) return;

    final books = state.value!;
    final book = books.firstWhere((b) => b.id == bookId);

    if (book.isAvailable) {
        // PINJAM - hanya admin
        if (currentUser?.email != 'admin@library.com') return;
        await bookManager.updateAvailability(bookId, false, currentUserId);
    } else if (currentUser?.email == 'admin@library.com') {
        // KEMBALIKAN - hanya admin
        await bookManager.updateAvailability(bookId, true, null);
    }
  }

  void removeBook(String bookId) async {
    await ref.read(firestoreBookManagerProvider)._firestore.collection('books').doc(bookId).delete();
  }

  void updateBook(String bookId, Book book) async {
    await ref.read(firestoreBookManagerProvider).updateBook(bookId, book);
  }
}

// --- 3. PROVIDER RIVERPOD ---

final firestoreBookManagerProvider = Provider((ref) => FirestoreBookManager());

// Stream data dari Firestore (AsyncValue<List<Book>>)
final bookListStreamProvider = StreamProvider<List<Book>>((ref) {
  return ref.watch(firestoreBookManagerProvider).getBooksStream();
});

// State untuk menampung input pencarian
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered List Provider
final filteredBookListProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final bookListAsync = ref.watch(bookListStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return bookListAsync.when(
    data: (books) {
      if (query.isEmpty) {
        return AsyncValue.data(books);
      }
      final filteredList = books.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query);
      }).toList();
      return AsyncValue.data(filteredList);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Provider untuk mendapatkan satu buku berdasarkan ID
final bookByIdProvider = Provider.family<AsyncValue<Book>, String>((ref, id) {
  final bookListAsync = ref.watch(bookListStreamProvider);
  
  return bookListAsync.when(
    data: (books) {
      try {
        final book = books.firstWhere((book) => book.id == id);
        return AsyncValue.data(book);
      } catch (e) {
        return AsyncValue.error('Buku tidak ditemukan', StackTrace.current);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Provider untuk Aksi Pinjam/Kembali
final bookActionProvider = StateNotifierProvider<BookNotifier, AsyncValue<List<Book>>>(
  (ref) {
    final notifier = BookNotifier(ref);
    // Langganan stream untuk memastikan notifier memiliki state terbaru
    ref.listen(bookListStreamProvider, (_, next) {
      notifier.state = next;
    });
    return notifier;
  },
);