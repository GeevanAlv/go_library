import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; 
import '../providers/loan_provider.dart';
import '../models/loan_model.dart';
import '../theme/app_theme.dart';

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parameter 'false' artinya mode User (hanya ambil data saya)
    final loanAsync = ref.watch(loanListProvider(false));

    return Scaffold(
      appBar: AppBar(title: const Text("Pinjaman Saya")),
      body: loanAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return const Center(child: Text("Anda belum meminjam buku apapun."));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final isLate = DateTime.now().isAfter(loan.dueDate) && loan.status == 'active';
              final currentFine = Loan.calculateCurrentFine(loan.dueDate);

              return Card(
                elevation: 2,
                color: loan.status == 'returned' ? Colors.grey[200] : Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Judul Buku & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(loan.bookTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: loan.status == 'active' 
                                  ? (isLate ? Colors.red : AppTheme.primaryTeal) 
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(8)
                            ),
                            child: Text(
                              loan.status == 'active' 
                                  ? (isLate ? "TELAT" : "DIPINJAM") 
                                  : "DIKEMBALIKAN",
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      
                      // Tanggal
                      Text("Tgl Pinjam: ${DateFormat('dd MMM yyyy').format(loan.borrowDate)}"),
                      Text(
                        "Batas Kembali: ${DateFormat('dd MMM yyyy').format(loan.dueDate)}",
                        style: TextStyle(
                          color: isLate ? Colors.red : Colors.black,
                          fontWeight: isLate ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                      
                      const SizedBox(height: 8),

                      // Info Denda
                      if (loan.status == 'active' && isLate)
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          color: Colors.red[50],
                          child: Text("DENDA BERJALAN: Rp $currentFine", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                        
                      if (loan.status == 'returned')
                        Text("Denda Akhir: Rp ${loan.fineAmount}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }
}