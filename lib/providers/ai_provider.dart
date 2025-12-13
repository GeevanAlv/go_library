import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book_model.dart';
import '../services/ai_service.dart';
import 'book_provider.dart'; 

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Book> recommendedBooks; // ✅ Tambahan: Untuk menyimpan buku rekomendasi

  ChatMessage({
    required this.text, 
    required this.isUser, 
    this.recommendedBooks = const []
  });
}

class AIChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  final AIService _aiService = AIService();
  bool isLoading = false; 

  AIChatNotifier(this.ref) : super([]) {
    state = [
      ChatMessage(text: "Selamat datang. Saya Libraria. Buku genre apa yang sedang Anda cari untuk memperkaya wawasan hari ini?", isUser: false)
    ];
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // 1. Tampilkan pesan user
    state = [...state, ChatMessage(text: message, isUser: true)];
    isLoading = true;
    ref.notifyListeners(); 

    try {
      final allBooksAsync = ref.read(bookListStreamProvider);
      final allBooks = allBooksAsync.value ?? [];

      // 2. Minta jawaban AI (Formatnya: Teks ||| ID,ID)
      final rawResponse = await _aiService.chatWithLibrarian(message, allBooks);

      // 3. LOGIKA PEMISAH (Parsing)
      String cleanText = rawResponse;
      List<Book> foundBooks = [];

      if (rawResponse.contains("|||")) {
        final parts = rawResponse.split("|||");
        cleanText = parts[0].trim(); // Ambil teks obrolannya saja
        
        final idString = parts[1].trim(); // Ambil bagian ID
        final ids = idString.split(',').map((e) => e.trim()).toList();

        // Cari objek buku berdasarkan ID
        foundBooks = allBooks.where((b) => ids.contains(b.id)).toList();
      }

      // 4. Masukkan ke chat sebagai pesan AI + Bukunya
      state = [...state, ChatMessage(
        text: cleanText, 
        isUser: false, 
        recommendedBooks: foundBooks
      )];

    } catch (e) {
      state = [...state, ChatMessage(text: "Terjadi kesalahan sistem: $e", isUser: false)];
    } finally {
      isLoading = false;
    }
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  return AIChatNotifier(ref);
});