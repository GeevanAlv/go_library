import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';

final firebaseFirestore = FirebaseFirestore.instance;

// 1. STREAM: Ambil Semua Data Buku (Raw Data)
final bookListStreamProvider = StreamProvider<List<Book>>((ref) {
  return firebaseFirestore.collection('books').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Book.fromFirestore(doc)).toList();
  });
});

// 2. STATE: Menyimpan Kata Kunci Pencarian User
final searchQueryProvider = StateProvider<String>((ref) => '');

// 3. LOGIC: Filter Buku Berdasarkan Pencarian (Ini yang dicari error tadi)
final filteredBookListProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final booksAsync = ref.watch(bookListStreamProvider);

  return booksAsync.whenData((books) {
    if (searchQuery.isEmpty) {
      return books;
    }
    // Filter berdasarkan Judul atau Penulis
    return books.where((book) {
      return book.title.toLowerCase().contains(searchQuery) ||
             book.author.toLowerCase().contains(searchQuery);
    }).toList();
  });
});

// 4. DETAIL: Ambil 1 Buku berdasarkan ID
final bookByIdProvider = StreamProvider.family<Book, String>((ref, id) {
  return firebaseFirestore.collection('books').doc(id).snapshots().map((doc) {
    if (!doc.exists) throw Exception("Buku tidak ditemukan");
    return Book.fromFirestore(doc);
  });
});

// 5. ACTION: Tambah/Edit/Hapus (Book Manager)
// (Sebelumnya mungkin Anda namakan firestoreBookManagerProvider, kita standarkan jadi bookActionProvider)
class BookActionNotifier extends StateNotifier<bool> {
  BookActionNotifier() : super(false); 

  Future<void> addBook(Book book) async {
    state = true;
    try {
      final docRef = firebaseFirestore.collection('books').doc();
      final newBook = Book(
        id: docRef.id,
        title: book.title,
        author: book.author,
        description: book.description,
        category: book.category,
        coverImageUrl: book.coverImageUrl,
        stock: book.stock, // Pastikan stok tersimpan
      );
      await docRef.set(newBook.toJson());
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> updateBook(String id, Book book) async {
    state = true;
    try {
      await firebaseFirestore.collection('books').doc(id).update(book.toJson());
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> removeBook(String id) async {
    state = true;
    try {
      await firebaseFirestore.collection('books').doc(id).delete();
    } catch (e) {
      rethrow;
    } finally {
      state = false;
    }
  }
}

final bookActionProvider = StateNotifierProvider<BookActionNotifier, bool>((ref) {
  return BookActionNotifier();
});