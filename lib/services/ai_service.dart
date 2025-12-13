import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/book_model.dart';

class AIService {
  // ✅ GUNAKAN API KEY YANG SUDAH VALID TADI
  static const String _apiKey = 'AIzaSyCAbn3YPqFKJ4EQJWIAqIcndU_2-ECVvvw'; 

  Future<String> chatWithLibrarian(String userQuery, List<Book> books) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-flash-latest', 
        apiKey: _apiKey,
      );

      String bookData = books.map((b) {
        return "ID:${b.id} | Judul:${b.title} | Penulis:${b.author} | Kategori:${b.category} | Sinopsis:${b.description}";
      }).join('\n');

      final prompt = '''
      Kamu adalah 'Libraria', asisten perpustakaan pribadi yang elegan, cerdas, dan hangat.
      
      Daftar Buku Tersedia:
      $bookData

      User: "$userQuery"

      INSTRUKSI KHUSUS:
      1. Jawablah dengan gaya bahasa yang berkelas, sopan, dan mengalir (seperti concierge hotel bintang 5).
      2. PENTING: JANGAN gunakan format Markdown apapun (jangan ada tanda bintang *, bold, atau bullet point). Gunakan paragraf biasa.
      3. Jika merekomendasikan buku, sebutkan alasannya dengan narasi yang menarik.
      4. Di AKHIR jawaban, WAJIB tambahkan pemisah "|||" diikuti daftar ID buku yang direkomendasikan (dipisah koma).
      
      Contoh Format Jawaban yang Benar:
      Tentu, saya memiliki koleksi yang sangat menyentuh hati. Buku ini mengisahkan perjuangan yang luar biasa dan akan sangat cocok untuk menemani sore Anda. ||| 101,102
      
      Jika tidak ada rekomendasi, cukup jawab dengan teks saja tanpa tanda pemisah.
      ''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      return response.text?.trim() ?? "Maaf, saya sedang menata ulang rak buku di pikiran saya.";
    } catch (e) {
      return "Mohon maaf, koneksi ke server perpustakaan sedang terganggu. ($e)";
    }
  }
}