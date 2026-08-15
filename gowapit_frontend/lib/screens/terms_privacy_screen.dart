import 'package:flutter/material.dart';

class TermsPrivacyPage extends StatefulWidget {
  const TermsPrivacyPage({super.key});

  @override
  State<TermsPrivacyPage> createState() => _TermsPrivacyPageState();
}

class _TermsPrivacyPageState extends State<TermsPrivacyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F9F4);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Terms & Privacy Policy",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          tabs: const [
            Tab(text: "Syarat & Ketentuan"),
            Tab(text: "Kebijakan Privasi"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Syarat & Ketentuan Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Syarat & Ketentuan Penggunaan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                  const SizedBox(height: 8),
                  Text("Terakhir diperbarui: 8 Agustus 2026", style: TextStyle(fontSize: 12, color: subTextColor)),
                  const Divider(height: 24),
                  _buildSectionTitle("1. Ketentuan Umum", primaryColor),
                  _buildParagraph("Dengan mengunduh dan menggunakan aplikasi Go Wapit, Anda menyetujui seluruh ketentuan dan aturan penggunaan layanan di kawasan Wahana Wisata Alam Jumprit Temanggung (WAPITT).", subTextColor),
                  _buildSectionTitle("2. Pemesanan Tiket & Kuliner", primaryColor),
                  _buildParagraph("E-Tiket dan pesanan kuliner yang telah dibayar berlaku sesuai tanggal kedatangan yang dipilih. Tiket yang sudah dibeli tidak dapat diuangkan kembali (non-refundable) kecuali terjadi penutupan wahana oleh pengelola.", subTextColor),
                  _buildSectionTitle("3. Keamanan & Keselamatan", primaryColor),
                  _buildParagraph("Wisatawan wajib mematuhi panduan keselamatan di area wahana ekstrim (Flying Fox, High Rope) serta menjaga kebersihan dan kelestarian flora & satwa di kawasan hutan pinus.", subTextColor),
                ],
              ),
            ),
          ),

          // 2. Kebijakan Privasi Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kebijakan Privasi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                  const SizedBox(height: 8),
                  Text("Privasi Anda adalah prioritas kami.", style: TextStyle(fontSize: 12, color: subTextColor)),
                  const Divider(height: 24),
                  _buildSectionTitle("1. Pengumpulan Data", primaryColor),
                  _buildParagraph("Kami mengumpulkan informasi akun dasar seperti Nama Lengkap, Email, dan Foto Profil yang Anda berikan saat mendaftar untuk memfasilitasi transaksi tiket dan identifikasi profil.", subTextColor),
                  _buildSectionTitle("2. Perlindungan Data", primaryColor),
                  _buildParagraph("Seluruh kata sandi Anda disimpan menggunakan enkripsi hashing aman (Bcrypt) dan data pribadi Anda tidak akan dijual atau dibagikan ke pihak ketiga tanpa persetujuan Anda.", subTextColor),
                  _buildSectionTitle("3. Penggunaan Lokasi", primaryColor),
                  _buildParagraph("Fitur peta lokasi menggunakan GPS hanya untuk membantu Anda mendapatkan petunjuk arah menuju Wahana Wisata Alam Jumprit via Google Maps.", subTextColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'Montserrat')),
    );
  }

  Widget _buildParagraph(String content, Color color) {
    return Text(content, style: TextStyle(fontSize: 13, height: 1.5, color: color), textAlign: TextAlign.justify);
  }
}
