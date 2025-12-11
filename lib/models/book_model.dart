// lib/models/book_model.dart

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverImageUrl; // URL gambar sampul
  final String category; // Misal: Fiksi, Sains, Sejarah
  final bool isAvailable; // Status ketersediaan (Tersedia/Dipinjam)
  final String? borrowerId; // UID pengguna yang meminjam buku (null jika tersedia)

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description = 'Deskripsi belum tersedia.',
    this.coverImageUrl = 'https://picsum.photos/200/300', 
    required this.category,
    this.isAvailable = true,
    this.borrowerId,
  });

  // Method untuk membuat salinan (copy) objek dengan perubahan properti tertentu.
  // Ini penting untuk Riverpod (immutable state).
  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverImageUrl,
    String? category,
    bool? isAvailable,
    String? borrowerId,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      category: category ?? this.category,
      // Jika isAvailable diubah, borrowerId harus disesuaikan
      isAvailable: isAvailable ?? this.isAvailable,
      borrowerId: (isAvailable == true) ? null : borrowerId ?? this.borrowerId,
    );
  }
}