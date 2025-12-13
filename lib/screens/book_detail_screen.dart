import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

// Import Provider & Model
import '../providers/book_provider.dart';
import '../providers/loan_provider.dart'; // ✅ WAJIB: Untuk logika pinjam
import '../models/book_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class BookDetailScreen extends ConsumerWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ambil data buku terbaru (Realtime update stok)
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final currentUser = ref.watch(authStateProvider).value;
    
    // Ganti email ini sesuai email admin Anda
    final isLibrarian = currentUser?.email == 'admin@library.com';

    return bookAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("Memuat...")), 
        body: const Center(child: CircularProgressIndicator())
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: const Text("Error")), 
        body: Center(child: Text("Buku tidak ditemukan atau terhapus.\nError: $e"))
      ),
      data: (book) {
        return Scaffold(
          appBar: AppBar(
            title: Text(book.title, style: GoogleFonts.poppins(fontSize: 18)),
            actions: [
               // Indikator Stok Kecil di AppBar (Opsional)
               Center(
                 child: Padding(
                   padding: const EdgeInsets.only(right: 16),
                   child: Text(
                     "Stok: ${book.stock}",
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       color: book.stock > 0 ? Colors.green : Colors.red
                     ),
                   ),
                 ),
               )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. GAMBAR SAMPUL ---
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: book.coverImageUrl, 
                        height: 300, 
                        width: 200,
                        fit: BoxFit.cover, 
                        placeholder: (_,__) => Container(color: Colors.grey[200]),
                        errorWidget: (_,__,___) => Container(
                          height: 300, width: 200, color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // --- 2. JUDUL & PENULIS ---
                Text(
                  book.title, 
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        book.author, 
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        book.category,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 24),

                // --- 3. STATUS KETERSEDIAAN (SISTEM BARU) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: book.stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: book.stock > 0 ? Colors.green : Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        book.stock > 0 ? Icons.check_circle : Icons.cancel, 
                        color: book.stock > 0 ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.stock > 0 ? "Stok Tersedia: ${book.stock}" : "Stok Habis",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: book.stock > 0 ? Colors.green[800] : Colors.red[800]
                            ),
                          ),
                          Text(
                            book.stock > 0 ? "Buku siap dipinjam sekarang." : "Tunggu hingga ada yang mengembalikan.",
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // --- 4. SINOPSIS ---
                Text("Sinopsis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  book.description, 
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.6, color: Colors.grey[800]),
                  textAlign: TextAlign.justify,
                ),

                const SizedBox(height: 40),
                
                // --- 5. TOMBOL PINJAM (SISTEM BARU) ---
                // Hanya User biasa yang butuh tombol pinjam. Admin cuma kelola.
                // Atau Admin juga boleh pinjam kalau mau.
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: book.stock > 0 ? AppTheme.primaryTeal : Colors.grey,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: book.stock > 0 
                      ? () => _showBorrowConfirmation(context, ref, book)
                      : null, // Tombol mati kalau stok 0
                    child: Text(
                      book.stock > 0 ? "PINJAM BUKU INI" : "STOK HABIS",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- 6. FITUR ADMIN (Edit & Delete) ---
                if (isLibrarian) ...[
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 10),
                  Text("Admin Zone", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  
                  // Tombol Edit
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                    title: Text("Edit Data Buku", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: const Text("Ubah judul, penulis, stok, dll"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _showEditDialog(context, ref, book),
                  ),
                  
                  // Tombol Hapus
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.delete_forever, color: Colors.red),
                    ),
                    title: Text("Hapus Buku", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.red)),
                    subtitle: const Text("Hapus permanen dari database"),
                    onTap: () => _showDeleteConfirmation(context, ref, book.id),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  //  HELPER METHODS (Dialogs & Logic)
  // =========================================================

  // 1. DIALOG KONFIRMASI PINJAM (SISTEM BARU + DENDA)
  void _showBorrowConfirmation(BuildContext context, WidgetRef ref, Book book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Konfirmasi Peminjaman"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Judul: ${book.title}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Durasi Peminjaman: 7 Hari"),
            const Divider(height: 20),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text("ATURAN DENDA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 4),
            const Text("Keterlambatan akan dikenakan denda:", style: TextStyle(fontSize: 12)),
            const Text("Rp 20.000 / Hari", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
            onPressed: () async {
              Navigator.pop(ctx);
              // Panggil Provider Loan untuk proses pinjam
              final msg = await ref.read(loanActionProvider.notifier).borrowBook(book);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(msg),
                  backgroundColor: msg.contains("Berhasil") ? Colors.green : Colors.red,
                ));
                // Jika berhasil, user bisa tetap di halaman ini (stok akan berkurang otomatis) atau keluar
              }
            },
            child: const Text("Saya Setuju & Pinjam", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 2. DIALOG KONFIRMASI HAPUS
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String bookId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah Anda yakin ingin menghapus buku ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(bookActionProvider.notifier).removeBook(bookId);
              Navigator.pop(ctx); 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Buku dihapus."), backgroundColor: Colors.red),
              );
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  // 3. DIALOG EDIT BUKU (Update Stok juga)
  void _showEditDialog(BuildContext context, WidgetRef ref, Book book) {
    final titleC = TextEditingController(text: book.title);
    final authorC = TextEditingController(text: book.author);
    final descC = TextEditingController(text: book.description);
    final imageUrlC = TextEditingController(text: book.coverImageUrl);
    final categoryC = TextEditingController(text: book.category);
    // Tambahan: Controller untuk Stok
    final stockC = TextEditingController(text: book.stock.toString());
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Edit Buku", style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCustomTextField(controller: titleC, label: 'Judul', icon: Icons.book),
                        const SizedBox(height: 10),
                        _buildCustomTextField(controller: authorC, label: 'Penulis', icon: Icons.person),
                        const SizedBox(height: 10),
                        _buildCustomTextField(controller: categoryC, label: 'Kategori', icon: Icons.category),
                        const SizedBox(height: 10),
                        // Input Stok
                        TextFormField(
                          controller: stockC,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                             labelText: 'Jumlah Stok',
                             prefixIcon: const Icon(Icons.inventory, color: Colors.grey),
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val!.isEmpty ? 'Stok wajib diisi' : null,
                        ),
                        const SizedBox(height: 10),
                        _buildCustomTextField(controller: imageUrlC, label: 'URL Gambar', icon: Icons.image),
                        const SizedBox(height: 10),
                        _buildCustomTextField(controller: descC, label: 'Sinopsis', icon: Icons.description, maxLines: 3),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final updatedBook = Book(
                        id: book.id,
                        title: titleC.text,
                        author: authorC.text,
                        description: descC.text,
                        category: categoryC.text,
                        coverImageUrl: imageUrlC.text,
                        stock: int.tryParse(stockC.text) ?? 0, // Simpan Stok Baru
                      );
                      
                      ref.read(bookActionProvider.notifier).updateBook(book.id, updatedBook);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Buku diperbarui!"), backgroundColor: AppTheme.primaryTeal),
                      );
                    }
                  },
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (val) => val!.isEmpty ? '$label tidak boleh kosong' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}