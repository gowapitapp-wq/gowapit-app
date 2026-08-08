import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; 
import 'package:crypto/crypto.dart'; // --- TAMBAHAN UNTUK GRAVATAR ---
import '../config/api_config.dart';
import 'faq_screen.dart'; 
import '../theme_notifier.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _namaLengkap = "Memuat...";
  String _email = "Memuat data...";
  String _referralCode = "WAPIT-0000"; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return;
      final response = await http.get(
        ApiConfig.uri("/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _namaLengkap = data['nama_lengkap'] ?? 'Petualang Wapit';
          _email = data['email'] ?? 'email@tidak.ditemukan';

          String namaDepan = _namaLengkap.split(' ')[0].toUpperCase();
          namaDepan = namaDepan.replaceAll(RegExp(r'[^A-Z]'), ''); 
          if (namaDepan.isEmpty) namaDepan = "WAPIT";
          String angkaAcak = (1000 + Random().nextInt(9000)).toString(); 
          _referralCode = "$namaDepan-$angkaAcak";

          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Placeholder()),
          (route) => false);
    }
  }

  // --- FUNGSI MENGUBAH EMAIL MENJADI FOTO GRAVATAR ---
  String _dapatkanUrlGravatar(String email) {
    if (email == "Memuat data..." || email.isEmpty || email == 'email@tidak.ditemukan') {
      // Tampilkan siluet default jika email belum selesai dimuat
      return "https://www.gravatar.com/avatar/00000000000000000000000000000000?s=200&d=mp";
    }
    final cleanEmail = email.toLowerCase().trim();
    final emailHash = md5.convert(utf8.encode(cleanEmail)).toString();
    return "https://www.gravatar.com/avatar/$emailHash?s=200&d=mp";
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor =
        isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor =
        isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    final Color iconBgColor =
        isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFeef5f2);
    final Color dividerColor =
        isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade100;

    final List<BoxShadow> ambientShadow = isDarkMode
        ? []
        : [
            BoxShadow(
                color: const Color(0xFF659287).withValues(alpha: 0.12),
                blurRadius: 15,
                offset: const Offset(0, 6))
          ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
          child: CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            // --- FOTO KECIL DI APPBAR ---
            backgroundImage: NetworkImage(_dapatkanUrlGravatar(_email)),
            onBackgroundImageError: (e, s) {}, // Abaikan jika error jaringan
            child: const Icon(Icons.person, color: Colors.transparent),
          ),
        ),
        title: const Text("Go Wapit",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
                fontFamily: 'Montserrat')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: CircleAvatar(
                backgroundColor: cardColor,
                radius: 20,
                child: Icon(Icons.notifications_none, color: primaryColor)),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 20, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- 1. KARTU PROFIL UTAMA --
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: ambientShadow),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: bgColor, width: 4)),
                              child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.grey.shade200,
                                  // --- FOTO BESAR DI TENGAH ---
                                  backgroundImage: NetworkImage(_dapatkanUrlGravatar(_email)),
                                  onBackgroundImageError: (e, s) {}, // Abaikan jika error jaringan
                                  child: const Icon(Icons.person,
                                      size: 40, color: Colors.transparent)),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: cardColor, width: 2)),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_namaLengkap,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontFamily: 'Montserrat')),
                        const SizedBox(height: 4),
                        Text(_email,
                            style:
                                TextStyle(fontSize: 13, color: subTextColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // -- 2. MENU AKTIVITAS --
                  _buildSectionTitle("AKTIVITAS", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(Icons.confirmation_number_outlined,
                        "Daftar Tiket", textColor, iconBgColor, primaryColor),
                    _buildDivider(dividerColor),
                    _buildListItem(Icons.history, "Riwayat Transaksi",
                        textColor, iconBgColor, primaryColor),
                  ]),
                  const SizedBox(height: 24),

                  // -- 3. MENU PENGATURAN --
                  _buildSectionTitle("REWARD & PENGATURAN", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(
                      Icons.card_giftcard,
                      "Poin & Referal",
                      textColor,
                      iconBgColor,
                      primaryColor,
                      trailingText: "150 Pts",
                      onTap: () => _showReferralDialog(context, isDarkMode, primaryColor),
                    ),
                    _buildDivider(dividerColor),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: iconBgColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.palette_outlined,
                            color: primaryColor, size: 20),
                      ),
                      title: Text("Tema",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(isDarkMode ? "Gelap" : "Terang",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 12),
                          CustomThemeToggle(
                            isDarkMode: isDarkMode,
                            onChanged: (val) {
                              isDarkModeGlobal.value = val;
                            },
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // -- 4. MENU DUKUNGAN --
                  _buildSectionTitle("DUKUNGAN", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(Icons.help_outline, "FAQ", textColor,
                        iconBgColor, primaryColor,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const FaqPage()))),
                    _buildDivider(dividerColor),
                    _buildListItem(Icons.security, "Terms & Privacy Policy",
                        textColor, iconBgColor, primaryColor),
                  ]),
                  const SizedBox(height: 32),

                  // -- 5. TOMBOL KELUAR --
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, isDarkMode),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: ambientShadow),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout,
                              color: Color(0xFFD32F2F), size: 20),
                          SizedBox(width: 10),
                          Text("Logout",
                              style: TextStyle(
                                  color: Color(0xFFD32F2F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              letterSpacing: 1.0)),
    );
  }

  Widget _buildMenuContainer(
      Color cardColor, List<BoxShadow> shadow, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: shadow),
      child: Column(children: children),
    );
  }

  Widget _buildListItem(IconData icon, String title, Color textColor,
      Color iconBgColor, Color iconColor,
      {String? trailingText, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: iconBgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (trailingText != null) const SizedBox(width: 8),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(
        height: 1, thickness: 1, color: color, indent: 65, endIndent: 16);
  }

  void _showReferralDialog(BuildContext context, bool isDarkMode, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.stars, size: 50, color: Colors.orange.shade400),
            const SizedBox(height: 12),
            Text(
              "Ajak Teman, Dapatkan Poin!", 
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87, fontFamily: 'Montserrat')
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Bagikan kode referal ini ke temanmu. Dapatkan 50 poin setiap kali mereka mendaftar dan memesan tiket!", 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5)
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kode berhasil disalin!"), backgroundColor: Color(0xFF4CAF50)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_referralCode, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: 2.0)),
                    Icon(Icons.copy, color: primaryColor, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Tutup", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Konfirmasi Logout",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
                fontFamily: 'Montserrat')),
        content: const Text("Apakah Anda yakin ingin keluar dari akun ini?",
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal",
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Keluar",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class CustomThemeToggle extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const CustomThemeToggle(
      {super.key, required this.isDarkMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDarkMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 26,
        decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF88BDA4) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(30)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment:
                  isDarkMode ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: Center(
                    child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        size: 12,
                        color: isDarkMode
                            ? const Color(0xFF88BDA4)
                            : Colors.orange),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}