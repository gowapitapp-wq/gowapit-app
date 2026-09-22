import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import '../design/tokens.dart';

/// Memeriksa apakah sebuah tanggal ISO telah kedaluwarsa sebelum hari ini.
/// Mendukung parameter [now] opsional untuk kemudahan pengujian unit (deterministik).
bool isExpired(String? iso, {DateTime? now}) {
  if (iso == null || iso.trim().isEmpty) return false;
  final current = now ?? DateTime.now();
  final today = DateTime(current.year, current.month, current.day);
  try {
    final expiryDate = DateTime.parse(iso.trim());
    return expiryDate.isBefore(today);
  } catch (_) {
    return false;
  }
}

/// Data dummy bawaan resmi Go Wapit (digunakan sebagai data default & fallback instan)
const List<Map<String, dynamic>> kDefaultBeritaList = [
  {
    "id": 1,
    "kategori": "Promo",
    "judul": "Diskon 30% Tiket Masuk Akhir Pekan",
    "tanggal": "2026-09-18",
    "ringkasan": "Nikmati potongan harga tiket masuk sebesar 30% untuk kunjungan akhir pekan ini bersama keluarga.",
    "isi": "Kabar gembira untuk para petualang! Dapatkan potongan harga tiket masuk sebesar 30% untuk semua kategori tiket masuk ke kawasan Hutan Pinus Wapit. Promo ini berlaku spesial untuk menyambut liburan akhir pekan bersama keluarga dan sahabat tercinta. Nikmati keasrian pohon pinus, spot foto estetik, dan udara pegunungan yang sejuk di lereng Gunung Sindoro dengan harga lebih terjangkau.",
    "gambar": "assets/images/BeritaDiskon.png",
    "berlaku_hingga": "2026-10-31",
    "todo": "KONFIRMASI KE PENGELOLA: batas berlaku Diskon 30%"
  },
  {
    "id": 2,
    "kategori": "Event",
    "judul": "Festival Kopi Temanggung 2026",
    "tanggal": "2026-09-15",
    "ringkasan": "Nikmati seduhan kopi Arabika gratis dari petani lokal Jumprit di kawasan Hutan Pinus Wapit.",
    "isi": "Saksikan dan ikuti semarak Festival Kopi Temanggung di Hutan Pinus Wapit! Pengunjung dapat mencicipi seduhan kopi Arabika khas lereng Sindoro-Sumbing secara gratis, mengikuti workshop manual brew & cupping bersama barista lokal, serta membeli biji kopi pilihan langsung dari kelompok tani Jumprit.",
    "gambar": "assets/images/BeritaFestivalKopi.png",
    "berlaku_hingga": "2026-10-15",
    "todo": "KONFIRMASI KE PENGELOLA: tanggal pelaksanaan pasti Festival Kopi"
  },
  {
    "id": 3,
    "kategori": "Informasi",
    "judul": "Wahana High Rope & Flying Fox Resmi Dibuka!",
    "tanggal": "2026-09-10",
    "ringkasan": "Uji adrenalin dan ketangkasanmu di wahana rintangan tali gantung terbaru Hutan Pinus Wapit.",
    "isi": "Wahana High Rope & Flying Fox kini telah resmi dibuka untuk umum setelah melewati uji kelayakan dan sertifikasi keselamatan standar internasional. Pengunjung dapat menikmati sensasi melintasi titian tali di antara pepohonan pinus rindang dengan didampingi instruktur profesional dan perlengkapan pengaman lengkap (harness, helm, dan carabiner ganda).",
    "gambar": "assets/images/HighRope.jpg",
    "berlaku_hingga": null,
    "todo": "KONFIRMASI KE PENGELOLA: tarif resmi wahana High Rope terpisah"
  },
  {
    "id": 4,
    "kategori": "Promo",
    "judul": "Paket Camping Hemat & BBQ Hutan Pinus",
    "tanggal": "2026-09-08",
    "ringkasan": "Nikmati pengalaman bermalam di bawah bintang dengan fasilitas tenda dome lengkap dan paket BBQ hangat.",
    "isi": "Ingin merasakan sensasi berkemah tanpa repot membawa perlengkapan? Paket Camping Hemat Hutan Pinus Wapit kini hadir dengan fasilitas lengkap: tenda dome kapasitas 4 orang, matras empuk, sleeping bag, lampu tenda, api unggun bersama, serta perlengkapan grill BBQ lengkap dengan jagung manis dan sosis panggang.",
    "gambar": "assets/images/6.png",
    "berlaku_hingga": "2026-11-30",
    "todo": "KONFIRMASI KE PENGELOLA: ketersediaan slot camping akhir pekan"
  },
  {
    "id": 5,
    "kategori": "Pengumuman",
    "judul": "Jam Operasional Kawasan Wisata 2026",
    "tanggal": "2026-09-01",
    "ringkasan": "Informasi jam buka dan tutup kawasan Hutan Pinus Wapit serta Mata Air Umbul Jumprit.",
    "isi": "Kawasan Wisata Hutan Pinus Wapit dan Umbul Jumprit beroperasi setiap hari mulai pukul 07.30 WIB hingga 17.00 WIB. Loket tiket masuk dan layanan kasir ditutup pada pukul 16.30 WIB. Bagi pengunjung yang ingin berkemah (camping) atau mengadakan acara malam hari, wajib melakukan registrasi dan konfirmasi terlebih dahulu kepada petugas pengelola.",
    "gambar": null,
    "berlaku_hingga": null,
    "todo": "KONFIRMASI KE PENGELOLA: jam operasional saat hari libur nasional"
  },
  {
    "id": 6,
    "kategori": "Pengumuman",
    "judul": "Aturan & Tata Tertib Kunjungan Wisata",
    "tanggal": "2026-08-25",
    "ringkasan": "Panduan keselamatan, kebersihan, dan etika berkunjung di kawasan konservasi Hutan Pinus Wapit.",
    "isi": "Demi menjaga kelestarian alam dan kenyamanan bersama, seluruh pengunjung diimbau untuk: (1) Membuang sampah pada tempat pemilahan yang telah disediakan, (2) Tidak menyalakan api unggun sembarangan tanpa pengawasan petugas, (3) Menjaga etika saat berinteraksi dengan satwa kera ekor panjang dan tidak memberi makanan berbahaya, serta (4) Menghormati kesucian area Mata Air Umbul Jumprit serta Makam Ki Jumprit.",
    "gambar": null,
    "berlaku_hingga": null,
    "todo": "KONFIRMASI KE PENGELOLA: sanksi pelanggaran membuang sampah sembarangan"
  },
  {
    "id": 7,
    "kategori": "Event",
    "judul": "Jadwal Pementasan Tari Wedok Tegowanuh",
    "tanggal": "2026-08-20",
    "ringkasan": "Pementasan kesenian tradisional khas Temanggung di panggung alam terbuka Hutan Pinus Wapit.",
    "isi": "Nikmati keindahan tarian tradisional Tari Wedok Tegowanuh yang dibawakan oleh sanggar seni lokal Temanggung di panggung alam terbuka Hutan Pinus Wapit. Pementasan ini merupakan wujud pelestarian kearifan lokal budaya lereng Gunung Sindoro yang diselenggarakan setiap hari Minggu pagi.",
    "gambar": null,
    "berlaku_hingga": null,
    "todo": "KONFIRMASI KE PENGELOLA: jadwal rutin pementasan bulanan"
  },
  {
    "id": 8,
    "kategori": "Informasi",
    "judul": "Fasilitas Gazebo & Spot Istirahat Baru",
    "tanggal": "2026-08-15",
    "ringkasan": "Peningkatan kenyamanan pengunjung dengan penambahan 10 unit gazebo kayu estetik di area bukit pinus.",
    "isi": "Pengelola Hutan Pinus Wapit telah menyelesaikan pembangunan 10 unit gazebo kayu baru yang tersebar di titik-titik teduh kawasan hutan pinus. Fasilitas ini dapat digunakan oleh seluruh pengunjung untuk beristirahat, bersantap santai, dan menikmati pemandangan alam secara gratis tanpa dipungut biaya tambahan.",
    "gambar": "assets/images/3.png",
    "berlaku_hingga": null,
    "todo": "KONFIRMASI KE PENGELOLA: kapasitas maksimal per gazebo"
  }
];

class BeritaKegiatanPage extends StatefulWidget {
  const BeritaKegiatanPage({super.key});

  @override
  State<BeritaKegiatanPage> createState() => _BeritaKegiatanPageState();
}

class _BeritaKegiatanPageState extends State<BeritaKegiatanPage> {
  final List<String> _kategoriList = const [
    'Semua',
    'Promo',
    'Event',
    'Informasi',
    'Pengumuman',
  ];

  String _selectedKategori = 'Semua';
  List<Map<String, dynamic>> _allBerita = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBerita();
  }

  void _processAndSetBerita(List rawList) {
    List<Map<String, dynamic>> validList = [];
    for (var item in rawList) {
      if (item is Map) {
        final mapItem = Map<String, dynamic>.from(item);
        // Lewati item yang sudah kedaluwarsa
        if (!isExpired(mapItem['berlaku_hingga']?.toString())) {
          validList.add(mapItem);
        }
      }
    }

    // Urutkan menurun berdasarkan tanggal (ISO YYYY-MM-DD leksikografis)
    validList.sort((a, b) {
      final String tglA = a['tanggal']?.toString() ?? '';
      final String tglB = b['tanggal']?.toString() ?? '';
      return tglB.compareTo(tglA);
    });

    if (mounted) {
      setState(() {
        _allBerita = validList;
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  Future<void> _loadBerita() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data_berita.json');
      final dynamic decoded = jsonDecode(jsonString);

      if (decoded is List && decoded.isNotEmpty) {
        _processAndSetBerita(decoded);
        return;
      }
    } catch (_) {
      // Fallback mulus ke data dummy bawaan jika asset bundle belum ke-reload di web dev session
    }

    // Gunakan kDefaultBeritaList sebagai data dummy bawaan yang selalu siap
    _processAndSetBerita(kDefaultBeritaList);
  }

  List<Map<String, dynamic>> get _filteredBerita {
    if (_selectedKategori == 'Semua') {
      return _allBerita;
    }
    return _allBerita.where((item) {
      final kat = (item['kategori'] ?? '').toString().toLowerCase();
      return kat == _selectedKategori.toLowerCase();
    }).toList();
  }

  Color _getKategoriColor(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'promo':
        return const Color(0xFFE65100);
      case 'event':
        return const Color(0xFF2E7D6A);
      case 'informasi':
        return const Color(0xFF1565C0);
      case 'pengumuman':
        return const Color(0xFF5E35B1);
      default:
        return const Color(0xFF1E524D);
    }
  }

  IconData _getKategoriIcon(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'promo':
        return Icons.local_offer_outlined;
      case 'event':
        return Icons.event_available_outlined;
      case 'informasi':
        return Icons.info_outline_rounded;
      case 'pengumuman':
        return Icons.campaign_outlined;
      default:
        return Icons.newspaper_outlined;
    }
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return "-";
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('d MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF121E1C);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF4A5D5A);
    final Color primaryColor = isDarkMode ? const Color(0xFF76B3AC) : const Color(0xFF1E524D);

    const List<BoxShadow> ambientShadow = AppTokens.noShadow;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          "Berita & Pengumuman",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: AppTokens.fontFamily,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _errorMessage != null
              ? _buildErrorView(primaryColor, textColor, subTextColor)
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _loadBerita,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 120, top: 4),
                    children: [
                      // --- 1. FILTER CHIPS KATEGORI ---
                      _buildKategoriFilterChips(cardColor, textColor, primaryColor, isDarkMode, ambientShadow),
                      const SizedBox(height: 16),

                      // --- 2. DAFTAR BERITA / EMPTY STATE ---
                      if (_filteredBerita.isEmpty)
                        _buildEmptyState(cardColor, textColor, subTextColor, primaryColor, ambientShadow, isDarkMode)
                      else
                        ..._filteredBerita.map((item) {
                          return _buildBeritaCard(
                            item: item,
                            cardColor: cardColor,
                            textColor: textColor,
                            subTextColor: subTextColor,
                            primaryColor: primaryColor,
                            ambientShadow: ambientShadow,
                            isDarkMode: isDarkMode,
                          );
                        }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView(Color primaryColor, Color textColor, Color subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              "Data Berita Gagal Dimuat",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamily,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? "Terjadi kesalahan saat membaca file data berita.",
              style: TextStyle(fontSize: 13, color: subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loadBerita,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Coba Lagi", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriFilterChips(
    Color cardColor,
    Color textColor,
    Color primaryColor,
    bool isDarkMode,
    List<BoxShadow> ambientShadow,
  ) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _kategoriList.length,
        itemBuilder: (context, index) {
          final kat = _kategoriList[index];
          final bool isSelected = _selectedKategori == kat;
          final Color activeColor = kat == 'Semua' ? primaryColor : _getKategoriColor(kat);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedKategori = kat;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected ? [] : ambientShadow,
                border: Border.all(
                  color: isSelected ? activeColor : (isDarkMode ? Colors.grey.shade800 : const Color(0xFFE5EBE8)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kat != 'Semua') ...[
                    Icon(
                      _getKategoriIcon(kat),
                      size: 14,
                      color: isSelected ? Colors.white : activeColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    kat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
    List<BoxShadow> ambientShadow,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ambientShadow,
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE5EBE8)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.newspaper_outlined, size: 40, color: primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada berita di kategori ini",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              fontFamily: AppTokens.fontFamily,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            "Nantikan informasi, promo, dan kegiatan menarik lainnya di Hutan Pinus Wapit.",
            style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBeritaCard({
    required Map<String, dynamic> item,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
    required List<BoxShadow> ambientShadow,
    required bool isDarkMode,
  }) {
    final String judul = item['judul'] ?? 'Berita Wapit';
    final String ringkasan = item['ringkasan'] ?? item['isi'] ?? '';
    final String? gambar = item['gambar'];
    final String kategori = item['kategori'] ?? 'Informasi';
    final String tglFormatted = _formatTanggal(item['tanggal']);
    final Color katColor = _getKategoriColor(kategori);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBeritaPage(data: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: ambientShadow,
          border: Border.all(color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE5EBE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Berita atau Placeholder Gradien
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: _buildCardImageHeader(gambar, katColor, kategori),
            ),

            // Konten Teks
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris Kategori & Tanggal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: katColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getKategoriIcon(kategori), size: 12, color: katColor),
                            const SizedBox(width: 4),
                            Text(
                              kategori,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: katColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 12, color: subTextColor),
                          const SizedBox(width: 4),
                          Text(
                            tglFormatted,
                            style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Judul Berita
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontFamily: AppTokens.fontFamily,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Ringkasan
                  Text(
                    ringkasan,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Tombol Baca Selengkapnya
                  Row(
                    children: [
                      Text(
                        "Baca Selengkapnya",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: primaryColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImageHeader(String? gambar, Color katColor, String kategori) {
    if (gambar != null && gambar.trim().isNotEmpty) {
      return Stack(
        children: [
          Image.asset(
            gambar,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(katColor, kategori),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _buildPlaceholderBanner(katColor, kategori);
  }

  Widget _buildPlaceholderBanner(Color katColor, String kategori) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            katColor.withValues(alpha: 0.85),
            katColor.withValues(alpha: 0.60),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(
              _getKategoriIcon(kategori),
              size: 110,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.newspaper_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pengumuman & Kabar Wapit",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTokens.fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Halaman Detail Berita / Pengumuman
class DetailBeritaPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailBeritaPage({super.key, required this.data});

  Color _getKategoriColor(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'promo':
        return const Color(0xFFE65100);
      case 'event':
        return const Color(0xFF2E7D6A);
      case 'informasi':
        return const Color(0xFF1565C0);
      case 'pengumuman':
        return const Color(0xFF5E35B1);
      default:
        return const Color(0xFF1E524D);
    }
  }

  IconData _getKategoriIcon(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'promo':
        return Icons.local_offer_outlined;
      case 'event':
        return Icons.event_available_outlined;
      case 'informasi':
        return Icons.info_outline_rounded;
      case 'pengumuman':
        return Icons.campaign_outlined;
      default:
        return Icons.newspaper_outlined;
    }
  }

  String _formatTanggalLengkap(String? iso) {
    if (iso == null || iso.isEmpty) return "-";
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('d MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF121E1C);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF4A5D5A);
    final Color primaryColor = isDarkMode ? const Color(0xFF76B3AC) : const Color(0xFF1E524D);

    final String judul = data['judul'] ?? 'Berita Go Wapit';
    final String isi = data['isi'] ?? data['ringkasan'] ?? 'Konten tidak tersedia.';
    final String? gambar = data['gambar'];
    final String kategori = data['kategori'] ?? 'Informasi';
    final String tglLengkap = _formatTanggalLengkap(data['tanggal']);
    final String? berlakuHingga = data['berlaku_hingga'];
    final Color katColor = _getKategoriColor(kategori);

    final bool hasImage = gambar != null && gambar.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: cardColor,
      body: CustomScrollView(
        slivers: [
          // Header Gambar / Banner
          SliverAppBar(
            expandedHeight: hasImage ? 300.0 : 180.0,
            pinned: true,
            backgroundColor: isDarkMode ? const Color(0xFF141917) : Colors.white,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: CircleAvatar(
                backgroundColor: isDarkMode ? Colors.black54 : Colors.white70,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, size: 18, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          gambar,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDetailHeaderPlaceholder(katColor, kategori),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildDetailHeaderPlaceholder(katColor, kategori),
            ),
          ),

          // Konten Detail
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Kategori & Tanggal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: katColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getKategoriIcon(kategori), size: 14, color: katColor),
                            const SizedBox(width: 6),
                            Text(
                              kategori,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: katColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.calendar_month_outlined, size: 14, color: subTextColor),
                          const SizedBox(width: 6),
                          Text(
                            tglLengkap,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subTextColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Judul Lengkap
                  Text(
                    judul,
                    style: TextStyle(
                      fontFamily: AppTokens.fontFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),

                  // Info Berlaku Hingga (Jika Ada)
                  if (berlakuHingga != null && berlakuHingga.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: Colors.amber.shade800),
                          const SizedBox(width: 8),
                          Text(
                            "Berlaku hingga: ${_formatTanggalLengkap(berlakuHingga)}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.amber.shade200 : Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      thickness: 1.5,
                    ),
                  ),

                  // Isi Berita Lengkap
                  Text(
                    isi,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.8,
                      color: textColor.withValues(alpha: 0.9),
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 36),

                  // Footer Info Pengelola
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDarkMode ? 0.12 : 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.verified_outlined, color: primaryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Informasi Resmi Go Wapit",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontFamily: AppTokens.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Pengelola Kawasan Hutan Pinus Wapit & Umbul Jumprit",
                                style: TextStyle(fontSize: 11, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeaderPlaceholder(Color katColor, String kategori) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            katColor.withValues(alpha: 0.9),
            katColor.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getKategoriIcon(kategori), size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              "Berita & Informasi Resmi",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: AppTokens.fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}