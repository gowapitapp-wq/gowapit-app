import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Cek status tema global saat ini
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 2. Tentukan palet warna adaptif
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F7F5);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.black54;
    final Color primaryGreen = isDarkMode ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
    final Color backIconColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: backIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("FAQ Wappit", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFaqItem(
            "Apa itu Wappit yang dikenal dengan wisata menarik di daerah Temanggung itu? dan dimana lokasi yang tersedia bagi wisata tersebut?",
            "Wappit (Wisata Alam Jumprit) merupakan tempat wisata indah yang sangat mempesona tepatnya terletak di lereng bawah kaki Gunung Sindoro dengan ketinggian 1280 mdpl. Berlokasikan di Jl. Ngadirejo, Jumprit, Tegalrejo, Temanggung, Kabupaten Temanggung, Jawa Tengah 56255.",
            isDarkMode, cardColor, textColor, subTextColor, primaryGreen
          ),
          const SizedBox(height: 15),
          _buildFaqItem(
            "Terdapat apa saja dari keunggulan yang dihasilkan dari tempat wisata Wappit tersebut?",
            "Wisata ini diunggulkan dengan tema \"Family Traveling and Adventure\", tempat wisata ini sangat cocok apabila dilakukan oleh keluarga untuk bersantai dan menikmati keindahan dari Hutan Pinus sembari menikmati secangkir kopi hangat. Selain itu destinasi wisata lain juga dapat dikunjungi seperti Makam KI Jumprit, Mata Air Suci, Interaksi dengan Monyet, Spot Foto, Camping Ground, dll.",
            isDarkMode, cardColor, textColor, subTextColor, primaryGreen
          ),
          const SizedBox(height: 15),
          _buildFaqItem(
            "Bagaimana ketika ingin menikmati hidangan yang ada dan dengan biaya yang terjangkau?",
            "Kedai Hutan menyediakan beberapa kuliner yang menggugah selera untuk disantap bersama dengan keluarga, sahabat, ataupun teman mulai dari makanan berat, makanan ringan sampai dengan minuman yang dapat menambah semangat untuk melakukan kegiatan di Wappit.",
            isDarkMode, cardColor, textColor, subTextColor, primaryGreen
          ),
        ],
      ),
    );
  }

  // Desain Kartu Lipat untuk FAQ dengan parameter warna dinamis
  Widget _buildFaqItem(String question, String answer, bool isDarkMode, Color cardColor, Color textColor, Color subTextColor, Color primaryGreen) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        // Hilangkan bayangan di mode gelap agar terlihat datar dan elegan
        boxShadow: isDarkMode ? [] : const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ExpansionTile(
        iconColor: primaryGreen,
        collapsedIconColor: Colors.grey,
        shape: const Border(), // Menghilangkan garis tepi saat dibuka
        title: Text(
          question, 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
            child: Text(
              answer, 
              style: TextStyle(color: subTextColor, height: 1.5, fontSize: 13),
              textAlign: TextAlign.justify,
            ),
          )
        ],
      ),
    );
  }
}