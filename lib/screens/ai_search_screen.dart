import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math'; 

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../models/book_model.dart';
import '../providers/book_provider.dart';
import 'book_detail_screen.dart';

// Provider Chat Stream
final chatStreamProvider = StreamProvider.autoDispose<List<DocumentSnapshot>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('chats')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

class AISearchScreen extends ConsumerStatefulWidget {
  const AISearchScreen({super.key});

  @override
  ConsumerState<AISearchScreen> createState() => _AISearchScreenState();
}

class _AISearchScreenState extends ConsumerState<AISearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Fungsi Pembantu: Memilih 1 kalimat acak dari banyak pilihan
  String _pick(List<String> options) {
    return options[Random().nextInt(options.length)];
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    _controller.clear();

    // 1. Simpan Pesan User
    await FirebaseFirestore.instance.collection('chats').add({
      'userId': user.uid,
      'text': text,
      'sender': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. AI BERPIKIR (Simulasi)
    Future.delayed(const Duration(milliseconds: 1200), () async {
      String reply = "";
      String? recommendedBookId;
      
      // Ambil data buku dan ACAR (Shuffle) agar tidak monoton
      final booksState = ref.read(filteredBookListProvider);
      final List<Book> allBooks = List.from(booksState.value ?? [])..shuffle();
      
      final String input = text.toLowerCase();
      bool has(String w) => input.contains(w);
      bool hasAny(List<String> ws) => ws.any((w) => input.contains(w));

      // ==========================================================
      // ENGINE BERPIKIR BEBAS (DYNAMIC PHRASING)
      // ==========================================================

      // 1. KONTEKS: EMOSI & PERASAAN (Chatbot Mode)
      if (hasAny(['sedih', 'galau', 'nangis', 'kecewa', 'patah hati'])) {
        reply = _pick([
          "Terkadang, kata-kata dalam buku adalah pelukan terbaik saat dunia terasa dingin. Izinkan saya menyarankan kisah ini untuk menemani perasaan Anda.",
          "Kesedihan itu valid. Namun, jangan biarkan ia menetap terlalu lama. Mungkin cerita dalam buku ini bisa sedikit meringankan beban pikiran Anda?",
          "Saya mendengar kesedihan dalam kata-kata Anda. Buku ini memiliki kekuatan penyembuh yang mungkin Anda butuhkan saat ini.",
        ]);
        if (allBooks.isNotEmpty) recommendedBookId = allBooks.first.id;
      }
      
      else if (hasAny(['senang', 'bahagia', 'semangat', 'happy'])) {
        reply = _pick([
          "Energi positif Anda menular! Mari kita rayakan semangat itu dengan petualangan literasi yang tak kalah seru.",
          "Senang mendengarnya! Saat hati gembira, wawasan lebih mudah terbuka. Buku ini akan menyempurnakan hari Anda.",
          "Luar biasa. Pertahankan aura itu. Saya punya rekomendasi yang sefrekuensi dengan kebahagiaan Anda."
        ]);
        if (allBooks.isNotEmpty) recommendedBookId = allBooks.first.id;
      }

      // 2. KONTEKS: CINTA & ROMANSA (Request Spesifik Anda)
      else if (hasAny(['cinta', 'sayang', 'romance', 'romantis', 'baper', 'pasangan', 'pacar'])) {
        // Filter buku romance
        var romanceBooks = allBooks.where((b) {
          final info = "${b.title} ${b.category} ${b.description}".toLowerCase();
          return info.contains('cinta') || info.contains('romance') || info.contains('love') || info.contains('novel');
        }).toList();

        if (romanceBooks.isNotEmpty) {
          final book = romanceBooks.first; // Sudah dishuffle di atas
          recommendedBookId = book.id;
          reply = _pick([
            "Ah, cinta... topik yang tak pernah usang. \"${book.title}\" menyajikan dinamika perasaan yang begitu dalam. Sangat saya rekomendasikan.",
            "Jika Anda mencari debaran hati dan emosi yang tulus, narasi dalam buku ini tidak akan mengecewakan.",
            "Sebuah kisah tentang hati. Saya rasa \"${book.title}\" akan beresonansi kuat dengan apa yang Anda cari.",
            "Romantisme dalam buku ini dikemas dengan sangat elegan. Silakan nikmati perjalanannya."
          ]);
        } else {
          // Jika stok romance kosong, alihkan pembicaraan dengan elegan
          reply = _pick([
            "Stok kisah romansa kami sedang dipinjam oleh para pujangga lain. Namun, buku ini memiliki sentuhan emosi yang mungkin Anda sukai.",
            "Saya tidak menemukan genre romantis spesifik saat ini, tapi biarkan intuisi saya memilihkan sesuatu yang menyentuh hati Anda."
          ]);
          if (allBooks.isNotEmpty) recommendedBookId = allBooks.first.id;
        }
      }

      // 3. KONTEKS: BASA-BASI & IDENTITAS
      else if (hasAny(['halo', 'hai', 'pagi', 'siang', 'malam'])) {
        reply = _pick([
          "Selamat datang di ruang literasi. Pikiran apa yang ingin Anda jelajahi hari ini?",
          "Halo. Saya siap menjadi kompas Anda dalam menelusuri lautan buku di sini.",
          "Salam hangat. Rak-rak digital kami penuh dengan keajaiban hari ini. Ada yang menarik perhatian Anda?"
        ]);
      }
      else if (hasAny(['siapa kamu', 'robot', 'ai'])) {
        reply = _pick([
          "Saya adalah penjaga perpustakaan digital ini. Tidak berwujud fisik, namun penuh dengan informasi.",
          "Anggap saja saya teman diskusi Anda yang paling tahu letak setiap buku di sini.",
          "Saya hanyalah sekumpulan kode yang diprogram untuk mencintai literasi, sama seperti Anda."
        ]);
      }

      // 4. KONTEKS: OPERASIONAL (Variasi Kalimat)
      else if (hasAny(['jam', 'buka', 'tutup'])) {
        reply = _pick([
          "Pintu pengetahuan kami terbuka dari pukul 08.00 pagi hingga 21.00 malam, setiap hari.",
          "Kami melayani dahaga ilmu Anda mulai jam 8 pagi sampai jam 9 malam. Senin hingga Minggu.",
          "Anda bisa berkunjung kapan saja antara pukul 08.00 - 21.00 WIB."
        ]);
      }

      // 5. KONTEKS: PENCARIAN BUKU SPESIFIK (JUDUL/PENULIS)
      else {
        // Cari buku yang cocok
        var matches = allBooks.where((b) => 
          input.contains(b.title.toLowerCase()) || 
          input.contains(b.author.toLowerCase()) || 
          input.contains(b.category.toLowerCase())
        ).toList();

        if (matches.isNotEmpty) {
          final book = matches.first;
          recommendedBookId = book.id;
          reply = _pick([
            "Mata Anda jeli sekali. \"${book.title}\" memang salah satu koleksi terbaik kami.",
            "Tentu saja, karya ${book.author} selalu memiliki tempat spesial di rak kami. Ini dia.",
            "Pencarian Anda berakhir di sini. Buku ini tersedia dan siap untuk dipinjam.",
            "Topik yang menarik! Buku ini mengupas hal tersebut dengan sangat baik."
          ]);
        } 
        
        // 6. KONTEKS: JAWABAN BEBAS (Fallback)
        // Jika tidak ada keyword yang cocok, AI akan "berfilosofi" dan memberi buku acak
        else {
          if (allBooks.isNotEmpty) {
            recommendedBookId = allBooks.first.id; // Karena sudah di shuffle, ini pasti acak
            reply = _pick([
              "Pertanyaan yang unik. Meski saya tidak memiliki jawaban pasti, intuisi pustakawan saya mengatakan Anda harus membaca ini.",
              "Saya mungkin belum memahami konteks sepenuhnya, tapi biarkan saya menawarkan sebuah kejutan literasi untuk Anda.",
              "Terkadang, buku yang tidak kita cari justru adalah buku yang paling kita butuhkan. Cobalah lihat ini.",
              "Hmm, menarik. Bagaimana kalau kita alihkan perhatian sejenak ke mahakarya yang satu ini?"
            ]);
          } else {
            reply = "Perpustakaan sedang sunyi, belum ada buku yang bisa saya tawarkan saat ini.";
          }
        }
      }

      // Kirim ke Firebase
      if (mounted) {
        await FirebaseFirestore.instance.collection('chats').add({
          'userId': user.uid,
          'text': reply,
          'sender': 'ai',
          'bookId': recommendedBookId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _confirmDeleteChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Chat?"),
        content: const Text("Riwayat akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final user = ref.read(authStateProvider).value;
              if (user == null) return;
              final snapshots = await FirebaseFirestore.instance
                  .collection('chats')
                  .where('userId', isEqualTo: user.uid)
                  .get();
              for (var doc in snapshots.docs) {
                await doc.reference.delete();
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 20, color: Colors.yellowAccent),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Concierge", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Online", style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDeleteChat(context))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatAsync.when(
              data: (docs) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (docs.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildChatBubble(data, context);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Ruang Diskusi",
            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Ceritakan apa yang Anda rasakan, atau buku apa yang Anda butuhkan.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> data, BuildContext context) {
    final isUser = data['sender'] == 'user';
    final text = data['text'] ?? '';
    final bookId = data['bookId']; 

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryTeal : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14.5,
                  height: 1.6,
                ),
              ),
            ),
            if (!isUser && bookId != null) 
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _BookRecommendationCard(bookId: bookId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Ketik pesan Anda...",
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryTeal.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookRecommendationCard extends ConsumerWidget {
  final String bookId;
  const _BookRecommendationCard({required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    return bookAsync.when(
      data: (book) {
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.blueGrey.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: book.coverImageUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_,__) => Container(color: Colors.grey[50]),
                        errorWidget: (_,__,___) => Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(20)),
                        child: Row(children: [const Icon(Icons.verified, color: Colors.yellowAccent, size: 12), const SizedBox(width: 4), Text("Pilihan AI", style: GoogleFonts.poppins(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))]),
                      ),
                    )
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18, height: 1.2)),
                      const SizedBox(height: 6),
                      Text("Karya ${book.author}", maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF0FDFC), borderRadius: BorderRadius.circular(8)), child: Text(book.category, style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600))),
                          Row(children: [Text("Lihat Detail", style: TextStyle(fontSize: 12, color: Colors.grey[800], fontWeight: FontWeight.w600)), const SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey[800])])
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(),
      error: (_,__) => const SizedBox(), 
    );
  }
}