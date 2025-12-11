// lib/screens/book_catalog_screen.dart (FINAL Fungsional)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:google_fonts/google_fonts.dart';

// ✅ Import yang diperlukan
import '../theme/app_theme.dart'; 
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import '../services/auth_service.dart';
import 'book_detail_screen.dart'; 

// --- BOOK CATALOG SCREEN ---

class BookCatalogScreen extends ConsumerStatefulWidget {
  const BookCatalogScreen({super.key});

  @override
  ConsumerState<BookCatalogScreen> createState() => _BookCatalogScreenState();
}

class _BookCatalogScreenState extends ConsumerState<BookCatalogScreen> {
  // Input Controllers untuk Dialog Tambah Buku
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final _addFormKey = GlobalKey<FormState>(); 

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // --- WIDGET HELPER: DIALOG TAMBAH BUKU (CRUD ADMIN) ---
  
  Future<void> _showAddBookDialog(BuildContext context) async {
    _titleController.clear();
    _authorController.clear();
    _categoryController.clear();
    _imageUrlController.clear();
    _descriptionController.clear();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Tambah Buku Baru", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _addFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Judul'),
                    validator: (v) => v!.isEmpty ? 'Judul wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Penulis'),
                    validator: (v) => v!.isEmpty ? 'Penulis wajib diisi' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'URL Sampul (Opsional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Sinopsis'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () {
                if (_addFormKey.currentState!.validate()) {
                  final newBook = Book(
                    id: '', // ID akan di-generate oleh Firestore
                    title: _titleController.text,
                    author: _authorController.text,
                    category: _categoryController.text.isEmpty ? 'Umum' : _categoryController.text,
                    description: _descriptionController.text,
                    coverImageUrl: _imageUrlController.text.isEmpty ? 'https://picsum.photos/200/300' : _imageUrlController.text,
                  );
                  // Panggil manager untuk menambahkan buku ke Firestore
                  ref.read(firestoreBookManagerProvider).addBook(newBook);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
  
  // --- WIDGET HELPER: EMPTY STATE ---
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: AppTheme.primaryTeal.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: BOOK LIST VIEW ---
  
  Widget _buildBookList(List<Book> books, WidgetRef ref, bool isLibrarian) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 80.0), // Padding untuk FAB
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return BookListTile(book: book, isLibrarian: isLibrarian);
      },
    );
  }
  
  // --- WIDGET HELPER: SEARCH BAR ---

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari Judul, Penulis, atau Kategori...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryTeal),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
        ),
        onChanged: (query) {
          ref.read(searchQueryProvider.notifier).state = query;
        },
      ),
    );
  }

  // --- LOGIKA UTAMA BUILD ---
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final filteredBooksAsync = ref.watch(filteredBookListProvider); 
    final isLibrarian = currentUser?.email == 'admin@library.com';
    
    // Dapatkan nilai String query secara langsung
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Katalog Buku', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: _buildSearchBar(),
        ),
      ),
      
      // Menggunakan .when() untuk menangani status data Firestore (Loading, Data, Error)
      body: filteredBooksAsync.when(
        data: (books) {
          // Logika penghitungan statistik real-time
          final totalAvailable = books.where((b) => b.isAvailable).length;
          final totalBorrowed = books.length - totalAvailable;

          // Cek hasil pencarian atau katalog kosong
          if (books.isEmpty && currentQuery.isNotEmpty) {
            return _buildEmptyState("Tidak ada buku yang cocok dengan kueri: '$currentQuery'.");
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tampilan Statistik Profesional
              _buildStatsCard(context, totalAvailable, totalBorrowed),

              Expanded(
                child: books.isEmpty 
                    ? _buildEmptyState("Katalog buku kosong.")
                    : _buildBookList(books, ref, isLibrarian),
              ),
            ],
          );
        },
        
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
        error: (e, s) => Center(child: Text('Gagal memuat katalog: ${e.toString()}', style: GoogleFonts.poppins(color: Colors.red))),
      ),
      
      floatingActionButton: isLibrarian 
        ? FloatingActionButton.extended(
            onPressed: () => _showAddBookDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Tambah Buku'),
            backgroundColor: AppTheme.primaryTeal,
          )
        : null,
    );
  }

  // --- WIDGET STATISTIK BARU ---
  Widget _buildStatsCard(BuildContext context, int available, int borrowed) {
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Card(
        elevation: 0,
        color: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.check_circle_outline,
                label: 'Tersedia',
                count: available,
                color: Colors.green.shade700,
              ),
              _StatItem(
                icon: Icons.book_outlined,
                label: 'Total',
                count: available + borrowed,
                color: primaryColor,
              ),
              _StatItem(
                icon: Icons.schedule_outlined,
                label: 'Dipinjam',
                count: borrowed,
                color: Colors.red.shade700,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET STATISTIK ITEM (Helper) ---
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatItem({required this.icon, required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text('$count', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }
}

// --- WIDGET BOOK LIST TILE ---
class BookListTile extends ConsumerWidget {
  final Book book;
  final bool isLibrarian;

  const BookListTile({super.key, required this.book, required this.isLibrarian});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authStateProvider).value?.uid;
    final canToggle = book.isAvailable || (book.borrowerId == currentUserId) || isLibrarian;
    final isCurrentlyBorrowed = book.borrowerId != null;
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage( 
            imageUrl: book.coverImageUrl,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            errorWidget: (context, url, error) => Icon(Icons.book, size: 50, color: primaryColor),
          ),
        ),
        title: Text(book.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.author, style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 6),
            Text(
              book.isAvailable ? 'Tersedia' : 'Dipinjam',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, 
                color: book.isAvailable ? Colors.green.shade700 : Colors.red.shade700
              ),
            ),
          ],
        ),
        trailing: canToggle
            ? IconButton(
                icon: Icon(
                  book.isAvailable ? Icons.bookmark_add : Icons.bookmark_remove,
                  color: book.isAvailable ? primaryColor : Colors.red.shade700,
                  size: 28,
                ),
                onPressed: () {
                  ref.read(bookActionProvider.notifier).toggleAvailability(book.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        book.isAvailable ? 'Meminjam ${book.title}' : 'Mengembalikan ${book.title}',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: book.isAvailable ? primaryColor : Colors.redAccent,
                    ),
                  );
                },
              )
            : isCurrentlyBorrowed
              ? const Icon(Icons.lock_outline, color: Colors.grey)
              : null,
        
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(bookId: book.id),
            ),
          );
        },
      ),
    );
  }
}