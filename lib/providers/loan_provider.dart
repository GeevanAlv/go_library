import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_model.dart';
import '../models/book_model.dart';

final firebaseFirestore = FirebaseFirestore.instance;
final firebaseAuth = FirebaseAuth.instance;

class LoanNotifier extends StateNotifier<bool> {
  LoanNotifier() : super(false); // false = idle, true = loading

  // 1. PINJAM BUKU (User)
  Future<String> borrowBook(Book book) async {
    state = true; 
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) throw "Anda harus login.";
      if (book.stock <= 0) throw "Stok buku habis!";

      // Ambil nama user
      final userDoc = await firebaseFirestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['fullName'] ?? 'User';

      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 7)); // Pinjam 7 Hari

      // Batch Write (Agar Loan tersimpan DAN Stok berkurang bersamaan)
      final batch = firebaseFirestore.batch();

      // A. Buat data peminjaman
      final loanRef = firebaseFirestore.collection('loans').doc();
      final newLoan = Loan(
        id: loanRef.id,
        bookId: book.id,
        bookTitle: book.title,
        userId: user.uid,
        userName: userName,
        borrowDate: now,
        dueDate: dueDate,
        status: 'active',
      );
      batch.set(loanRef, newLoan.toFirestore());

      // B. KURANGI STOK (-1)
      final bookRef = firebaseFirestore.collection('books').doc(book.id);
      batch.update(bookRef, {'stock': FieldValue.increment(-1)});

      await batch.commit(); 
      return "Berhasil meminjam buku!";
    } catch (e) {
      return "Gagal: $e";
    } finally {
      state = false; 
    }
  }

  // 2. KEMBALIKAN BUKU (Admin)
  Future<String> returnBook(Loan loan) async {
    state = true;
    try {
      final fine = Loan.calculateCurrentFine(loan.dueDate);
      
      final batch = firebaseFirestore.batch();

      // A. Update status jadi returned
      final loanRef = firebaseFirestore.collection('loans').doc(loan.id);
      batch.update(loanRef, {
        'status': 'returned',
        'returnDate': Timestamp.now(),
        'fineAmount': fine,
      });

      // B. TAMBAH STOK KEMBALI (+1)
      final bookRef = firebaseFirestore.collection('books').doc(loan.bookId);
      batch.update(bookRef, {'stock': FieldValue.increment(1)});

      await batch.commit();
      return "Buku diterima. Total Denda: Rp $fine";
    } catch (e) {
      return "Gagal: $e";
    } finally {
      state = false;
    }
  }
}

// Provider Logic
final loanActionProvider = StateNotifierProvider<LoanNotifier, bool>((ref) => LoanNotifier());

// Provider Data List Loan
final loanListProvider = StreamProvider.autoDispose.family<List<Loan>, bool>((ref, isAdmin) {
  Query query = firebaseFirestore.collection('loans').orderBy('borrowDate', descending: true);

  // Jika bukan admin, filter hanya punya user sendiri
  if (!isAdmin) {
    final uid = firebaseAuth.currentUser?.uid;
    if (uid != null) {
      query = query.where('userId', isEqualTo: uid);
    }
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Loan.fromFirestore(doc)).toList();
  });
});