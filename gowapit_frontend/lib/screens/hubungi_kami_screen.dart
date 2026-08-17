import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';

class HubungiKamiScreen extends StatefulWidget {
  const HubungiKamiScreen({super.key});

  @override
  State<HubungiKamiScreen> createState() => _HubungiKamiScreenState();
}

class _HubungiKamiScreenState extends State<HubungiKamiScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserPrefill();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  // Prefill otomatis nama & email pengguna jika sudah login
  Future<void> _loadUserPrefill() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token != null) {
        final response = await http.get(
          ApiConfig.uri("/api/users/me"),
          headers: {"Authorization": "Bearer $token"},
        );
        if (response.statusCode == 200 && mounted) {
          final data = jsonDecode(response.body);
          setState(() {
            if (_namaController.text.isEmpty && data['nama_lengkap'] != null) {
              _namaController.text = data['nama_lengkap'];
            }
            if (_emailController.text.isEmpty && data['email'] != null) {
              _emailController.text = data['email'];
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _bukaUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal membuka tautan: $url")),
        );
      }
    }
  }

  Future<void> _kirimPesan() async {
    final String nama = _namaController.text.trim();
    final String email = _emailController.text.trim();
    final String isiPesan = _pesanController.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama wajib diisi."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alamat email tidak valid."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (isiPesan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi pesan atau saran wajib diisi."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final response = await http.post(
        ApiConfig.uri("/api/pesan"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "nama": nama,
          "email": email,
          "isi_pesan": isiPesan,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pesan berhasil dikirim! Terima kasih atas masukan Anda."),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _pesanController.clear();
      } else {
        if (mounted) {
          final resData = jsonDecode(response.body);
          String err = resData['detail'] ?? "Gagal mengirim pesan. Silakan coba lagi.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161D1B);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF5A6663);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    final List<BoxShadow> ambientShadow = isDarkMode
        ? []
        : [
            BoxShadow(
              color: const Color(0xFF9DC3C2).withValues(alpha: 0.16),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Menjaga transparansi shell gradient
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Hubungi Kami",
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF161D1B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // BAGIAN A — HEADER DESKRIPSI
            // ==========================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ambientShadow,
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade800 : primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDarkMode ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.support_agent_rounded, size: 32, color: primaryColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pusat Bantuan & Saran",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Hubungi kami untuk informasi, bantuan, atau saran mengenai layanan wisata Go Wapit.",
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==========================================
            // BAGIAN B — CARD WHATSAPP & INSTAGRAM
            // ==========================================
            Text(
              "Kontak Langsung",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Card WhatsApp
                Expanded(
                  child: _ContactActionCard(
                    isDarkMode: isDarkMode,
                    icon: Icons.chat_rounded,
                    iconColor: const Color(0xFF25D366),
                    iconBgColor: const Color(0xFF25D366).withValues(alpha: isDarkMode ? 0.2 : 0.12),
                    title: "WhatsApp Admin",
                    subtitle: "0813-9306-5625",
                    onTap: () => _bukaUrl("https://wa.me/6281393065625"),
                  ),
                ),
                const SizedBox(width: 14),

                // Card Instagram
                Expanded(
                  child: _ContactActionCard(
                    isDarkMode: isDarkMode,
                    icon: Icons.camera_alt_rounded,
                    iconColor: const Color(0xFFE1306C),
                    iconBgColor: const Color(0xFFE1306C).withValues(alpha: isDarkMode ? 0.2 : 0.12),
                    title: "Instagram Go Wapit",
                    subtitle: "@smadatara",
                    onTap: () => _bukaUrl("https://instagram.com/smadatara"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==========================================
            // BAGIAN C — CARD KRITIK & SARAN
            // ==========================================
            Text(
              "Kirim Kritik & Saran",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: ambientShadow,
                border: Border.all(
                  color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field Nama
                    Text(
                      "Nama Lengkap",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _namaController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Masukkan nama Anda",
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.person_outline, color: primaryColor, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF141F1C) : const Color(0xFFF9FBFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Field Email
                    Text(
                      "Alamat Email",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "contoh@email.com",
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.email_outlined, color: primaryColor, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF141F1C) : const Color(0xFFF9FBFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Field Pesan / Kritik / Saran
                    Text(
                      "Pesan / Kritik / Saran",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _pesanController,
                      maxLines: 5,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Tuliskan pesan, kritik membangun, atau saran untuk pengelola wisata...",
                        hintStyle: TextStyle(color: subTextColor.withValues(alpha: 0.6), fontSize: 13),
                        contentPadding: const EdgeInsets.all(16),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF141F1C) : const Color(0xFFF9FBFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Tombol Kirim Pesan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _kirimPesan,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        label: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                              )
                            : const Text(
                                "Kirim Pesan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          disabledBackgroundColor: primaryColor.withValues(alpha: 0.6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET HELPER: CARD AKSI KONTAK CEPAT (WHATSAPP & INSTAGRAM) ---
class _ContactActionCard extends StatefulWidget {
  final bool isDarkMode;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactActionCard({
    required this.isDarkMode,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_ContactActionCard> createState() => _ContactActionCardState();
}

class _ContactActionCardState extends State<_ContactActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color cardBg = widget.isDarkMode
        ? (_isPressed ? const Color(0xFF242C28) : const Color(0xFF1C1C1E))
        : (_isPressed ? const Color(0xFFF0F7F0) : Colors.white);

    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF161D1B);
    final Color subTextColor = widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF5A6663);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isPressed
                ? widget.iconColor.withValues(alpha: 0.8)
                : (widget.isDarkMode ? Colors.grey.shade800 : widget.iconColor.withValues(alpha: 0.2)),
            width: _isPressed ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.iconColor.withValues(alpha: _isPressed ? 0.2 : 0.06),
              blurRadius: _isPressed ? 14 : 8,
              offset: Offset(0, _isPressed ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
