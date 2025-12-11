// lib/screens/book_catalog_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 

import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../services/auth_service.dart';
import 'book_detail_screen.dart'; 


// Konstanta Uuid (Perbaikan: Kita letakkan di sini karena digunakan di _showAddBookDialog)
const _uuid = Uuid(); // ✅ PERBAIKAN: Menghilangkan warning 'isn\'t referenced'

// --- 1. UBAH DARI ConsumerWidget MENJADI ConsumerStatefulWidget ---

class BookCatalogScreen extends ConsumerStatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  ConsumerState<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

// --- 2. KELAS STATE BARU UNTUK MENAMPUNG METHOD HELPER ---

class _BookCatalogScreenState extends ConsumerState<BookCatalogScreen> {
  
  // Method ini sekarang didefinisikan di sini
  // ❌ _buildSearchBar (METHOD) sekarang ada di sini
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari Judul, Penulis, atau Kategori...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        ),
        onChanged: (query) {
          ref.read(searchQueryProvider.notifier).state = query;
        },
      ),
    );
  }

  // ❌ _showAddBookDialog (METHOD) sekarang ada di sini
  void _showAddBookDialog(BuildContext context) {
    final bookNotifier = ref.read(bookListProvider.notifier);
    
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Buku Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul')),
              TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Penulis')),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategori')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && authorController.text.isNotEmpty) {
                  final newBook = Book(
                    id: _uuid.v4(), // Menggunakan _uuid dari scope global
                    title: titleController.text,
                    author: authorController.text,
                    category: categoryController.text.isNotEmpty ? categoryController.text : 'Umum',
                  );
                  bookNotifier.addBook(newBook);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Akses ref dari kelas state
    final currentUser = ref.watch(authStateProvider).value;
    final filteredBooks = ref.watch(filteredBookListProvider);
    final isLibrarian = currentUser?.email == 'admin@library.com';

    return Scaffold(
      appBar: AppBar(
        title: Text('Katalog Perpustakaan (${currentUser?.displayName ?? 'Pengguna'})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).signOut();
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildSearchBar(), // ✅ Panggil method dari State
        ),
      ),
      body: filteredBooks.isEmpty
          ? _buildEmptyState(ref.watch(searchQueryProvider)) 
          : _buildBookList(filteredBooks, ref, isLibrarian),
      
      floatingActionButton: isLibrarian 
        ? FloatingActionButton(
            onPressed: () => _showAddBookDialog(context), // ✅ Panggil method dari State
            child: const Icon(Icons.add),
          )
        : null,
    );
  }

  // --- WIDGET HELPER LAIN (Dipindahkan ke dalam State) ---

  Widget _buildBookList(List<Book> books, WidgetRef ref, bool isLibrarian) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        // Kita perlu mengubah BookListTile menjadi StatelessWidget atau ConsumerWidget
        return BookListTile(book: book, isLibrarian: isLibrarian); 
      },
    );
  }

  Widget _buildEmptyState(String currentQuery) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            currentQuery.isEmpty
                ? 'Katalog buku masih kosong.'
                : 'Tidak ada buku yang cocok dengan "$currentQuery".',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- WIDGET CUSTOM: BOOK LIST TILE (Dibuat terpisah sebagai ConsumerWidget) ---

class BookListTile extends ConsumerWidget {
  final Book book;
  final bool isLibrarian;

  // Hapus parameter WidgetRef ref dari konstruktor
  const BookListTile({super.key, required this.book, required this.isLibrarian});

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Akses ref dari sini
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final canToggle = book.isAvailable || (book.borrowerId == currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: CachedNetworkImage( 
            imageUrl: book.coverImageUrl,
            width: 50,
            height: 70,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => const Icon(Icons.book, size: 40),
          ),
        ),
        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penulis: ${book.author}', style: const TextStyle(fontSize: 13)),
            Text('Kategori: ${book.category}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(book.isAvailable ? 'Tersedia' : 'Dipinjam', style: TextStyle(fontWeight: FontWeight.bold, color: book.isAvailable ? Colors.green : Colors.red)),
          ],
        ),
        trailing: canToggle
            ? IconButton(
                icon: Icon(
                  book.isAvailable ? Icons.bookmark_add : Icons.bookmark_remove,
                  color: book.isAvailable ? Colors.blue : Colors.red,
                ),
                onPressed: () {
                  ref.read(bookListProvider.notifier).toggleAvailability(book.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(book.isAvailable ? 'Berhasil meminjam ${book.title}' : 'Berhasil mengembalikan ${book.title}'),
                    ),
                  );
                },
              )
            : null,
        
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Pastikan BookDetailScreen sudah dibuat
              builder: (context) => BookDetailScreen(bookId: book.id), 
            ),
          );
        },
      ),
    );
  }
}