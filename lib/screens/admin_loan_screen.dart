import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/loan_provider.dart';
import '../models/loan_model.dart';
import '../theme/app_theme.dart';

class AdminLoanScreen extends ConsumerWidget {
  const AdminLoanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Parameter 'true' artinya mode Admin (ambil data SEMUA orang)
    final loanAsync = ref.watch(loanListProvider(true));

    return Scaffold(
      appBar: AppBar(title: const Text("Admin: Kelola Sirkulasi")),
      body: loanAsync.when(
        data: (loans) {
          if (loans.isEmpty) return const Center(child: Text("Belum ada data peminjaman."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            itemBuilder: (context, index) {
              final loan = loans[index];
              final isLate = DateTime.now().isAfter(loan.dueDate) && loan.status == 'active';
              final estimatedFine = Loan.calculateCurrentFine(loan.dueDate);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Peminjam
                      Text(loan.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTeal)),
                      Text("Meminjam: ${loan.bookTitle}", style: const TextStyle(fontSize: 14)),
                      const Divider(),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Tenggat: ${DateFormat('dd/MM/yyyy').format(loan.dueDate)}"),
                              if (loan.status == 'active')
                                Text(
                                  isLate ? "TELAT (Denda: Rp $estimatedFine)" : "Status: Aman",
                                  style: TextStyle(
                                    color: isLate ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              if (loan.status == 'returned')
                                const Text("Sudah Kembali", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                          
                          // Tombol Aksi (Hanya muncul jika status masih active)
                          if (loan.status == 'active')
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                              onPressed: () => _confirmReturn(context, ref, loan, estimatedFine),
                              child: const Text("Terima Kembali", style: TextStyle(color: Colors.white)),
                            )
                        ],
                      ),
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

  void _confirmReturn(BuildContext context, WidgetRef ref, Loan loan, int fine) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Proses Pengembalian"),
        content: Text("User: ${loan.userName}\nBuku: ${loan.bookTitle}\n\nTotal Denda: Rp $fine\n\nPastikan buku sudah diterima fisik dan denda dibayar."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final msg = await ref.read(loanActionProvider.notifier).returnBook(loan);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            child: const Text("Proses Selesai"),
          )
        ],
      ),
    );
  }
}