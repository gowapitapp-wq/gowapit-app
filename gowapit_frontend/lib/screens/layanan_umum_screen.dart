import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class LayananUmumPage extends StatefulWidget {
  const LayananUmumPage({super.key});

  @override
  State<LayananUmumPage> createState() => _LayananUmumPageState();
}

class _LayananUmumPageState extends State<LayananUmumPage> {
  List<Map<String, dynamic>> _listLayanan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLayananData();
  }

  Future<void> _fetchLayananData() async {
    try {
      // 1. Coba ambil data dari API Backend
      final response = await http.get(ApiConfig.uri("/api/layanan-umum"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty && mounted) {
          setState(() {
            _listLayanan = (data['data'] as List).map((item) {
              return {
                'nama': item['nama_layanan'] ?? item['nama'] ?? '-',
                'nomor': item['kontak'] ?? item['nomor'] ?? '-',
                'deskripsi': item['deskripsi'] ?? '',
              };
            }).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback dari JSON lokal jika koneksi offline
    try {
      final String jsonString = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(jsonString);
      if (mounted) {
        final List<dynamic> localList = data['layanan_umum'] ?? [];
        if (localList.isNotEmpty) {
          setState(() {
            _listLayanan = localList.map((item) {
              return {
                'nama': item['nama'] ?? item['nama_layanan'] ?? '-',
                'nomor': item['nomor'] ?? item['kontak'] ?? '-',
                'deskripsi': item['deskripsi'] ?? '',
              };
            }).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 3. Fallback statis default jika semua gagal
    if (mounted) {
      setState(() {
        _listLayanan = [
          {
            'nama': 'Pemadam Kebakaran',
            'nomor': '(0293) 4901790',
            'deskripsi': 'Layanan darurat penanggulangan kebakaran dan penyelamatan (rescue) wilayah Ngadirejo. Lokasi Induk: Jl. Lingkar Utara Maron, Sidorejo, Temanggung. Jam Operasional: 24 Jam',
          },
          {
            'nama': 'Ambulance',
            'nomor': '119',
            'deskripsi': 'Layanan transportasi medis darurat untuk penanganan cepat pasien kritis dan korban kecelakaan di wilayah Ngadirejo. Lokasi: PSC 119 Dinas Kesehatan Kab. Temanggung. Jam Operasional: 24 Jam',
          },
          {
            'nama': 'Polsek Ngadirejo',
            'nomor': '(0293) 596220',
            'deskripsi': 'Unit pelaksana kepolisian di tingkat kecamatan yang menjaga keamanan, ketertiban masyarakat, dan perlindungan hukum di wilayah Kecamatan Ngadirejo. Lokasi: Jl. Raya Candiroto No.1, Dandu, Manggong, Kec. Ngadirejo, Kab. Temanggung. Jam Operasional: 24 Jam',
          },
        ];
        _isLoading = false;
      });
    }
  }

  // --- LOGIKA PANGGIL NOMOR TELEPON ---
  Future<void> _panggilNomor(String nomor) async {
    final String cleanNomor = nomor.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNomor.isEmpty) return;

    final Uri phoneUri = Uri.parse("tel:$cleanNomor");
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Membuka panggilan ke: $nomor"),
            backgroundColor: const Color(0xFF5E9190),
          ),
        );
      }
    }
  }

  // --- MODAL KONFIRMASI PANGGILAN DARURAT ---
  void _showCallConfirmationModal(Map<String, dynamic> layanan, ServiceThemeInfo themeInfo) {
    HapticFeedback.lightImpact();

    final String nama = layanan['nama'] ?? 'Layanan Darurat';
    final String nomor = layanan['nomor'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final Color sheetBg = isDark ? const Color(0xFF1C2824) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF161D1B);
        final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF5A6663);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Icon Layanan
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: themeInfo.color.withValues(alpha: isDark ? 0.25 : 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: themeInfo.color.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(themeInfo.icon, size: 36, color: themeInfo.color),
                ),
                const SizedBox(height: 16),

                // Judul Konfirmasi
                Text(
                  "Panggil $nama?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Nomor Telepon Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeInfo.color.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: themeInfo.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 18, color: themeInfo.color),
                      const SizedBox(width: 8),
                      Text(
                        nomor,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: themeInfo.color,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Penjelasan Info
                Text(
                  "Panggilan ini akan langsung membuka dialer telepon perangkat Anda untuk menghubungi petugas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Tombol Aksi
                Row(
                  children: [
                    // Tombol Batal
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          "Batal",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Tombol Panggil Sekarang
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _panggilNomor(nomor);
                        },
                        icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          "Panggil Sekarang",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161D1B);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    return Scaffold(
      backgroundColor: Colors.transparent, // Menjaga transparansi shell gradient
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Layanan & Kontak Darurat",
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF161D1B),
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _listLayanan.isEmpty
              ? Center(
                  child: Text(
                    "Data layanan darurat tidak tersedia.",
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Header Banner Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: isDarkMode ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.shield_outlined, color: primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Siaga Darurat Wilayah Wapit",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: textColor,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Hubungi nomor darurat di bawah jika membutuhkan penanganan cepat di sekitar kawasan Umbul Jumprit & Ngadirejo.",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: subTextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Daftar Kartu Layanan Umum Interaktif
                    ...List.generate(_listLayanan.length, (index) {
                      final layanan = _listLayanan[index];
                      final themeInfo = ServiceThemeInfo.fromName(layanan['nama'] ?? '');

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: HoverableLayananCard(
                          layanan: layanan,
                          themeInfo: themeInfo,
                          isDarkMode: isDarkMode,
                          onCallTap: () => _showCallConfirmationModal(layanan, themeInfo),
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}

// --- HELPER MODEL: TEMA & IKON LAYANAN ---
class ServiceThemeInfo {
  final Color color;
  final IconData icon;
  final String kategori;

  ServiceThemeInfo({
    required this.color,
    required this.icon,
    required this.kategori,
  });

  factory ServiceThemeInfo.fromName(String name) {
    final lower = name.toLowerCase();

    if (lower.contains('pemadam') || lower.contains('kebakaran') || lower.contains('fire')) {
      return ServiceThemeInfo(
        color: const Color(0xFFE53935),
        icon: Icons.local_fire_department_rounded,
        kategori: "Penanggulangan Bahaya & Penyelamatan",
      );
    } else if (lower.contains('ambulance') || lower.contains('medis') || lower.contains('kesehatan') || lower.contains('psc')) {
      return ServiceThemeInfo(
        color: const Color(0xFF0288D1),
        icon: Icons.medical_services_rounded,
        kategori: "Gawat Darurat Medis & PSC 119",
      );
    } else if (lower.contains('polsek') || lower.contains('polres') || lower.contains('polisi')) {
      return ServiceThemeInfo(
        color: const Color(0xFF1E3A8A),
        icon: Icons.local_police_rounded,
        kategori: "Keamanan & Ketertiban Masyarakat",
      );
    }

    return ServiceThemeInfo(
      color: const Color(0xFF5E9190),
      icon: Icons.phone_in_talk_rounded,
      kategori: "Layanan Umum & Informasi",
    );
  }
}

// --- KARTU INTERAKTIF LAYANAN UMUM (HOVER / PRESS EFFECT) ---
class HoverableLayananCard extends StatefulWidget {
  final Map<String, dynamic> layanan;
  final ServiceThemeInfo themeInfo;
  final bool isDarkMode;
  final VoidCallback onCallTap;

  const HoverableLayananCard({
    super.key,
    required this.layanan,
    required this.themeInfo,
    required this.isDarkMode,
    required this.onCallTap,
  });

  @override
  State<HoverableLayananCard> createState() => _HoverableLayananCardState();
}

class _HoverableLayananCardState extends State<HoverableLayananCard> {
  bool _isPressed = false;

  String? _extractLocation(String deskripsi) {
    final lower = deskripsi.toLowerCase();
    int idx = lower.indexOf('lokasi:');
    int prefixLen = 7;
    if (idx == -1) {
      idx = lower.indexOf('lokasi induk:');
      prefixLen = 13;
    }
    if (idx != -1) {
      String sub = deskripsi.substring(idx + prefixLen).trim();
      int dotIdx = sub.indexOf('. Jam Operasional');
      if (dotIdx != -1) {
        return sub.substring(0, dotIdx).trim();
      }
      int dotEnd = sub.indexOf('.');
      if (dotEnd != -1) {
        return sub.substring(0, dotEnd).trim();
      }
      return sub;
    }
    return null;
  }

  String _cleanDescriptionText(String deskripsi) {
    int idx = deskripsi.indexOf('Lokasi');
    if (idx != -1) {
      return deskripsi.substring(0, idx).trim();
    }
    return deskripsi;
  }

  @override
  Widget build(BuildContext context) {
    final String nama = widget.layanan['nama'] ?? '-';
    final String nomor = widget.layanan['nomor'] ?? '-';
    final String rawDeskripsi = widget.layanan['deskripsi'] ?? '';
    final String narasi = _cleanDescriptionText(rawDeskripsi);
    final String? lokasi = _extractLocation(rawDeskripsi);

    final Color cardBg = widget.isDarkMode
        ? (_isPressed ? const Color(0xFF283631) : const Color(0xFF1C1C1E))
        : (_isPressed ? const Color(0xFFF0F7F0) : Colors.white);

    final Color textColor = widget.isDarkMode ? Colors.white : const Color(0xFF161D1B);
    final Color subTextColor = widget.isDarkMode ? Colors.grey.shade300 : const Color(0xFF404846);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onCallTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isPressed
                ? widget.themeInfo.color.withValues(alpha: 0.8)
                : (widget.isDarkMode ? Colors.grey.shade800 : widget.themeInfo.color.withValues(alpha: 0.18)),
            width: _isPressed ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.themeInfo.color.withValues(alpha: _isPressed ? 0.22 : 0.08),
              blurRadius: _isPressed ? 18 : 10,
              offset: Offset(0, _isPressed ? 6 : 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. BARIS ATAS: IKON + NAMA + BADGE 24 JAM
            // ==========================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Ikon Layanan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.themeInfo.color.withValues(alpha: widget.isDarkMode ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.themeInfo.color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(widget.themeInfo.icon, color: widget.themeInfo.color, size: 26),
                ),
                const SizedBox(width: 14),

                // Nama Layanan & Kategori
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.themeInfo.kategori,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.themeInfo.color,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge Siaga 24 Jam
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: widget.isDarkMode ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "24 Jam",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, height: 1),
            const SizedBox(height: 14),

            // ==========================================
            // 2. DESKRIPSI LAYANAN
            // ==========================================
            if (narasi.isNotEmpty) ...[
              Text(
                narasi,
                style: TextStyle(
                  fontSize: 12.5,
                  color: subTextColor,
                  height: 1.45,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ==========================================
            // 3. LOKASI
            // ==========================================
            if (lokasi != null && lokasi.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF141F1C) : const Color(0xFFF6FAF6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: widget.themeInfo.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lokasi,
                        style: TextStyle(
                          fontSize: 11,
                          color: subTextColor,
                          height: 1.35,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ==========================================
            // 4. BARIS BAWAH: NOMOR & TOMBOL PANGGIL
            // ==========================================
            Row(
              children: [
                // Nomor Dial
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.dialer_sip_rounded, size: 18, color: widget.themeInfo.color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          nomor,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Montserrat',
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Panggil Sekarang
                ElevatedButton.icon(
                  onPressed: widget.onCallTap,
                  icon: const Icon(Icons.call_rounded, size: 15, color: Colors.white),
                  label: const Text(
                    "Panggil Sekarang",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeInfo.color,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}