import 'package:cloud_firestore/cloud_firestore.dart';

class Book {
  final String id;
  final String title;
  final String author;
  final String description;
  final String category;
  final String coverImageUrl;
  final bool isAvailable;
  final String? borrowerId;
  // 👇 INI PERBAIKANNYA: Tambah variabel stock
  final int stock; 

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.category,
    required this.coverImageUrl,
    this.isAvailable = true,
    this.borrowerId,
    // 👇 Wajib diisi
    required this.stock, 
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'category': category,
      'coverImageUrl': coverImageUrl,
      'isAvailable': isAvailable,
      'borrowerId': borrowerId,
      'stock': stock, // Simpan ke database
    };
  }

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      coverImageUrl: data['coverImageUrl'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      borrowerId: data['borrowerId'],
      stock: data['stock'] ?? 0, // Baca dari database (default 0)
    );
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      coverImageUrl: json['coverImageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      borrowerId: json['borrowerId'],
      stock: json['stock'] ?? 0,
    );
  }
}