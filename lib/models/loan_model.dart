import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String bookId;
  final String bookTitle;
  final String userId;
  final String userName; // Nama peminjam
  final DateTime borrowDate; // Tgl Pinjam
  final DateTime dueDate; // Tgl Jatuh Tempo
  final DateTime? returnDate; // Tgl Dikembalikan
  final int fineAmount; // Besar Denda
  final String status; // 'active' atau 'returned'

  Loan({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.fineAmount = 0,
    required this.status,
  });

  // 👇 RUMUS DENDA: Rp 20.000 per hari keterlambatan
  static int calculateCurrentFine(DateTime dueDate) {
    final now = DateTime.now();
    if (now.isBefore(dueDate)) return 0; // Belum telat
    
    final difference = now.difference(dueDate).inDays;
    
    // Jika telat (walau baru lewat jam), minimal hitung 1 hari
    int daysLate = difference;
    if (daysLate <= 0) daysLate = 1; 

    return daysLate * 20000; // Kalikan Rp 20.000
  }

  // Simpan ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'userId': userId,
      'userName': userName,
      'borrowDate': Timestamp.fromDate(borrowDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'fineAmount': fineAmount,
      'status': status,
    };
  }

  // Baca dari Firestore
  factory Loan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Loan(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Tanpa Nama',
      borrowDate: (data['borrowDate'] as Timestamp).toDate(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      returnDate: data['returnDate'] != null ? (data['returnDate'] as Timestamp).toDate() : null,
      fineAmount: data['fineAmount'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }
}