import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/book_provider.dart';
import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'book_detail_screen.dart';
import 'ai_search_screen.dart'; // Tetap perlu import untuk tombol AI

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(filteredBookListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    
    // Cek status admin untuk FAB (Tombol Tambah Buku di bawah kanan)
    final currentUser = ref.watch(authStateProvider).value;
    final isAdmin = currentUser?.email == 'admin@library.com';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Katalog Buku"),
        actions: [
          // 1. Tombol AI (Tetap ada biar mudah akses)
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.yellowAccent),
            tooltip: "AI Assistant",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AISearchScreen()));
            },
          ),

          // --- BAGIAN INI SUDAH DIHAPUS (Monitor & Pinjaman) ---
          // Karena sudah ada di menu bawah (Bottom Navigation)

          // 2. Tombol Refresh
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Data",
            onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
          ),
          
          // 3. Tombol Logout
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Keluar Akun",
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryTeal,
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: "Cari judul atau penulis...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),

          // --- LIST BUKU ---
          Expanded(
            child: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isEmpty 
                              ? "Belum ada buku." 
                              : "Buku tidak ditemukan.",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _buildBookCard(context, book);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
      
      // --- FAB TAMBAH BUKU (Hanya Admin) ---
      floatingActionButton: isAdmin ? FloatingActionButton(
        backgroundColor: AppTheme.primaryTeal,
        onPressed: () => _showAddBookDialog(context, ref),
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  // --- WIDGET CARD BUKU ---
  Widget _buildBookCard(BuildContext context, Book book) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: book.coverImageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: book.stock > 0 ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          book.stock > 0 ? "Stok: ${book.stock}" : "Habis",
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: book.stock > 0 ? Colors.green : Colors.red
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authServiceProvider).signOut();
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, WidgetRef ref) {
    final titleC = TextEditingController();
    final authorC = TextEditingController();
    final descC = TextEditingController();
    final imageC = TextEditingController();
    final categoryC = TextEditingController();
    final stockC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Buku Baru"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleC, decoration: const InputDecoration(labelText: "Judul")),
              TextField(controller: authorC, decoration: const InputDecoration(labelText: "Penulis")),
              TextField(controller: categoryC, decoration: const InputDecoration(labelText: "Kategori")),
              TextField(controller: stockC, decoration: const InputDecoration(labelText: "Stok Awal"), keyboardType: TextInputType.number),
              TextField(controller: imageC, decoration: const InputDecoration(labelText: "URL Cover Gambar")),
              TextField(controller: descC, decoration: const InputDecoration(labelText: "Sinopsis"), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              if (titleC.text.isEmpty || stockC.text.isEmpty) return;

              final newBook = Book(
                id: '', 
                title: titleC.text,
                author: authorC.text,
                description: descC.text,
                category: categoryC.text,
                coverImageUrl: imageC.text,
                stock: int.tryParse(stockC.text) ?? 0, 
              );

              ref.read(bookActionProvider.notifier).addBook(newBook);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Buku berhasil ditambahkan")));
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }
}