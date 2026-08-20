import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'detail_destinasi_screen.dart';

class GaleriScreen extends StatefulWidget {
  const GaleriScreen({super.key});

  @override
  State<GaleriScreen> createState() => _GaleriScreenState();
}

class _GaleriScreenState extends State<GaleriScreen> {
  List<dynamic> _listDestinasi = [];
  bool _isLoading = true;

  late PageController _pageController;
  double _currentPageValue = 0.0;
  String _selectedCategory = "Semua";

  // Data Fallback jika koneksi offline / lambat
  final List<Map<String, dynamic>> _fallbackDestinasi = [
    {
      "id": 1,
      "name": "Hutan Pinus Wapit",
      "kategori": "Alam",
      "rating": 4.8,
      "image": "assets/images/HutanPinus.jpeg",
      "deskripsi_pendek": "Hutan pinus asri berhawa sejuk dengan spot foto estetik di Umbul Jumprit.",
      "deskripsi_panjang": "Objek wisata Hutan Pinus Wapit menawarkan keasrian alam pegunungan di lereng Gunung Sindoro dengan deretan pohon pinus menjulang tinggi, udara segar nan sejuk, dan suasana menenangkan.",
      "lokasi": "Umbul Jumprit, Ngadirejo, Temanggung",
      "foto_count": 142
    },
    {
      "id": 2,
      "name": "Mata Air Suci Umbul Jumprit",
      "kategori": "Budaya",
      "rating": 4.9,
      "image": "assets/images/MataAirSuci.jpeg",
      "deskripsi_pendek": "Mata air sakral penyuplai air berkah perayaan Waisak di Candi Borobudur.",
      "deskripsi_panjang": "Sumber air suci yang tak pernah kering sepanjang tahun, dikelilingi hutan pinus yang rindang dan udara sejuk pegunungan.",
      "lokasi": "Jumprit, Pringapus, Ngadirejo",
      "foto_count": 98
    },
    {
      "id": 3,
      "name": "Wahana High Rope",
      "kategori": "Wahana",
      "rating": 4.7,
      "image": "assets/images/HighRope.jpg",
      "deskripsi_pendek": "Tantangan petualangan di atas ketinggian pepohonan pinus.",
      "deskripsi_panjang": "Jalur outbound melintasi jembatan tali dan rintangan di antara kanopi pohon pinus dengan standar keselamatan lengkap.",
      "lokasi": "Area Outbound Hutan Pinus Wapit",
      "foto_count": 76
    },
    {
      "id": 4,
      "name": "Flying Fox Dewasa",
      "kategori": "Wahana",
      "rating": 4.7,
      "image": "assets/images/FlyingFox.jpeg",
      "deskripsi_pendek": "Meluncur bebas melintasi lembah hijau pohon pinus.",
      "deskripsi_panjang": "Sensasi meluncur di udara sepanjang lebih dari 100 meter dengan panorama hutan pinus yang memukau.",
      "lokasi": "Zona Petualangan Wapit",
      "foto_count": 88
    },
    {
      "id": 5,
      "name": "Makam Ki Jumprit",
      "kategori": "Budaya",
      "rating": 4.8,
      "image": "assets/images/MakamKiJumprit.jpeg",
      "deskripsi_pendek": "Situs religi bersejarah peninggalan era Kerajaan Majapahit.",
      "deskripsi_panjang": "Makam tokoh legendaris Ki Jumprit yang dihormati sebagai cikal bakal wilayah Jumprit Temanggung.",
      "lokasi": "Kompleks Wisata Religi Jumprit",
      "foto_count": 54
    },
    {
      "id": 6,
      "name": "Tari Wedok Tegowanuh",
      "kategori": "Budaya",
      "rating": 4.6,
      "image": "assets/images/Tari.jpeg",
      "deskripsi_pendek": "Kesenian tari tradisional khas lereng Gunung Sindoro.",
      "deskripsi_panjang": "Tarian sakral yang dibawakan dalam upacara adat dan festival kebudayaan di kawasan lereng Temanggung.",
      "lokasi": "Panggung Seni Budaya Wapit",
      "foto_count": 65
    },
    {
      "id": 7,
      "name": "Interaksi Monyet Ekor Panjang",
      "kategori": "Fauna",
      "rating": 4.6,
      "image": "assets/images/InteraksiDenganMonyet.jpg",
      "deskripsi_pendek": "Kawanan primata ramah penjaga kawasan hutan Jumprit.",
      "deskripsi_panjang": "Pengunjung dapat memberi makan kacang dan pisang serta berfoto bersama kawanan monyet ekor panjang yang jinak.",
      "lokasi": "Taman Satwa Hutan Jumprit",
      "foto_count": 110
    },
    {
      "id": 8,
      "name": "Festival Kopi Temanggung",
      "kategori": "Event",
      "rating": 4.9,
      "image": "assets/images/BeritaFestivalKopi.png",
      "deskripsi_pendek": "Semarak seduh kopi Arabika langsung bersama petani lokal.",
      "deskripsi_panjang": "Perayaan panen kopi tahunan dengan pesta seduh gratis, live music akustik, dan workshop barista di bawah pepohonan pinus.",
      "lokasi": "Amfiteater Hutan Pinus Wapit",
      "foto_count": 125
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.65, initialPage: 0);
    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        setState(() {
          _currentPageValue = _pageController.page!;
        });
      }
    });
    _fetchDestinasiData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDestinasiData() async {
    try {
      final response = await http.get(ApiConfig.uri("/api/destinasi")).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final List<dynamic> fetched = data['data'] ?? [];
        if (fetched.isNotEmpty) {
          setState(() {
            _listDestinasi = fetched;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Gunakan fallback data jika backend offline / tidak merespons
    if (mounted) {
      setState(() {
        _listDestinasi = _fallbackDestinasi;
        _isLoading = false;
      });
    }
  }

  // Ambil item untuk Coverflow (Top 4 rated atau destinasi utama)
  List<dynamic> _getFeaturedItems() {
    if (_listDestinasi.isEmpty) return _fallbackDestinasi.take(4).toList();
    final items = List<dynamic>.from(_listDestinasi);
    items.sort((a, b) {
      final num rA = (a['rating'] is num) ? a['rating'] : 4.5;
      final num rB = (b['rating'] is num) ? b['rating'] : 4.5;
      return rB.compareTo(rA);
    });
    return items.take(5).toList();
  }

  // Ambil daftar kategori unik untuk Sorotan (Highlights)
  List<Map<String, dynamic>> _getHighlights() {
    return [
      {"label": "Semua", "kategori": "Semua", "image": "assets/images/HutanPinus.jpeg"},
      {"label": "Alam", "kategori": "Alam", "image": "assets/images/HutanPinus.jpeg"},
      {"label": "Budaya", "kategori": "Budaya", "image": "assets/images/MataAirSuci.jpeg"},
      {"label": "Wahana", "kategori": "Wahana", "image": "assets/images/HighRope.jpg"},
      {"label": "Fauna", "kategori": "Fauna", "image": "assets/images/InteraksiDenganMonyet.jpg"},
      {"label": "Event", "kategori": "Event", "image": "assets/images/BeritaFestivalKopi.png"},
    ];
  }

  // Filter destinasi untuk Feed Grid
  List<dynamic> _getFilteredFeed() {
    if (_listDestinasi.isEmpty) return _fallbackDestinasi;
    if (_selectedCategory == "Semua") return _listDestinasi;
    return _listDestinasi.where((item) {
      final String kat = (item['kategori'] ?? '').toString().toLowerCase();
      return kat.contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  String _cleanImagePath(dynamic raw) {
    if (raw == null) return 'assets/images/HutanPinus.jpeg';
    String str = raw.toString();
    if (!str.startsWith('assets/')) {
      str = 'assets/$str';
    }
    return str;
  }

  // --- DETAIL POP-UP DIALOG (BLUR BACKGROUND) ---
  void _showDetailPopup(dynamic item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF5E9190);
    const Color celadonColor = Color(0xFFB3D89C);
    final Color cardBg = isDark ? const Color(0xFF1C2824) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF404846);

    final String name = item['name'] ?? item['nama'] ?? 'Destinasi Wapit';
    final num ratingNum = (item['rating'] is num) ? item['rating'] : 4.8;
    final String ratingStr = ratingNum > 0 ? ratingNum.toStringAsFixed(1) : "4.8";
    final String desc = item['deskripsi_panjang'] ?? item['deskripsi_pendek'] ?? item['deskripsi'] ?? 'Pesona keindahan alam lereng Gunung Sindoro di kawasan Hutan Pinus Wapit.';
    final String imagePath = _cleanImagePath(item['image'] ?? item['gambar']);
    final String lokasi = item['lokasi'] ?? "Kawasan Hutan Pinus Wapit, Ngadirejo";
    final int fotoCount = item['foto_count'] ?? (80 + (item['id'] is int ? item['id'] * 15 : 45));

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Tutup Galeri",
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                constraints: const BoxConstraints(maxWidth: 360, maxHeight: 600),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- FOTO 3:4 HEADER WITH CLOSE BUTTON ---
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 3.4,
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.image, color: Colors.white54, size: 48),
                                ),
                              ),
                            ),
                            // Gradient shadow top
                            Positioned(
                              top: 0, left: 0, right: 0,
                              height: 60,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Close Button [X]
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(ctx),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.55),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 1),
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                            // Category Tag on image
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6),
                                  ],
                                ),
                                child: Text(
                                  item['kategori'] ?? 'Wisata Wapit',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // --- CONTENT SECTION ---
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Rating and Photo Count
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          ratingStr,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "•  $fotoCount Koleksi Foto",
                                    style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Description
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subTextColor,
                                  height: 1.45,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Location Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 16, color: celadonColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lokasi,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: subTextColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Action Button: Lihat Detail Destinasi
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailDestinasiPage(
                                          data: Map<String, dynamic>.from(item),
                                          allDestinasi: _listDestinasi,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.explore_rounded, size: 16),
                                  label: const Text(
                                    "Lihat Detail Destinasi",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: anim,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF5E9190);
    const Color celadonColor = Color(0xFFB3D89C);
    final Color textColor = isDark ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF404846);

    final featuredItems = _getFeaturedItems();
    final highlights = _getHighlights();
    final filteredFeed = _getFilteredFeed();

    return Scaffold(
      backgroundColor: Colors.transparent, // Tetap transparan agar gradient shell global tampil
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Galeri Wisata Wapit",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _fetchDestinasiData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // =========================================================
                    // SECTION 1: 3D COVERFLOW CAROUSEL (3:4 ASPECT RATIO)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Pesona Unggulan",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Featured 3:4",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3D Coverflow PageView
                    SizedBox(
                      height: 290,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        itemCount: featuredItems.length,
                        itemBuilder: (context, index) {
                          final item = featuredItems[index];
                          final String imagePath = _cleanImagePath(item['image'] ?? item['gambar']);
                          final String title = item['name'] ?? item['nama'] ?? 'Hutan Pinus Wapit';
                          final num ratingNum = (item['rating'] is num) ? item['rating'] : 4.8;
                          final String ratingStr = ratingNum > 0 ? ratingNum.toStringAsFixed(1) : "4.8";

                          // Hitung transformasi 3D
                          final double diff = index - _currentPageValue;
                          final double rotateY = (-diff * 0.22).clamp(-0.4, 0.4);
                          final double scale = (1 - (diff.abs() * 0.16)).clamp(0.82, 1.0);
                          final double opacity = (1 - (diff.abs() * 0.35)).clamp(0.65, 1.0);
                          final double translationX = diff * 16.0;

                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0018) // Efek perspektif 3D
                              ..translate(translationX)
                              ..scale(scale)
                              ..rotateY(rotateY),
                            child: Opacity(
                              opacity: opacity,
                              child: GestureDetector(
                                onTap: () => _showDetailPopup(item),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(alpha: (1 - diff.abs()).clamp(0.1, 0.3)),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // Foto 3:4
                                        Image.asset(
                                          imagePath,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            color: Colors.grey.shade800,
                                            child: const Icon(Icons.image, color: Colors.white54, size: 36),
                                          ),
                                        ),
                                        // Gradient Overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.transparent,
                                                Colors.black.withValues(alpha: 0.2),
                                                Colors.black.withValues(alpha: 0.85),
                                              ],
                                              stops: const [0.4, 0.65, 1.0],
                                            ),
                                          ),
                                        ),
                                        // Caption / Label
                                        Positioned(
                                          bottom: 14,
                                          left: 14,
                                          right: 14,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.5),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: celadonColor.withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text(
                                                      item['kategori'] ?? 'Wisata',
                                                      style: const TextStyle(
                                                        color: celadonColor,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber.withValues(alpha: 0.25),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                                        const SizedBox(width: 3),
                                                        Text(
                                                          ratingStr,
                                                          style: const TextStyle(
                                                            color: Colors.amber,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Dot Indicators Carousel
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(featuredItems.length, (i) {
                        final bool isCurrent = (_currentPageValue.round() == i);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 5,
                          width: isCurrent ? 18 : 6,
                          decoration: BoxDecoration(
                            color: isCurrent ? primaryColor : (isDark ? Colors.white24 : Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // SECTION 2: SOROTAN (HIGHLIGHTS) - INSTAGRAM STORY STYLE
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Sorotan Kategori",
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 98,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: highlights.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final h = highlights[index];
                          final bool isSelected = (_selectedCategory == h['kategori']);
                          final String imagePath = _cleanImagePath(h['image']);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = h['kategori'];
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.all(2.5),
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [primaryColor, celadonColor],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark ? const Color(0xFF16221D) : Colors.white,
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          color: primaryColor.withValues(alpha: 0.2),
                                          child: const Icon(Icons.landscape, color: primaryColor, size: 24),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  h['label'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? primaryColor : subTextColor,
                                    fontFamily: 'Inter',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================================================
                    // SECTION 3: FEED GALERI UTAMA (GRID 2-KOLOM 3:4)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Koleksi Momen",
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${filteredFeed.length} Foto",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCategory != "Semua")
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = "Semua"),
                              child: Text(
                                "Reset Filter",
                                style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (filteredFeed.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2824) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 48, color: subTextColor.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              "Tidak ada foto pada kategori '$_selectedCategory'",
                              style: TextStyle(fontSize: 13, color: subTextColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredFeed.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3 / 4,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemBuilder: (context, index) {
                            final item = filteredFeed[index];
                            final String imagePath = _cleanImagePath(item['image'] ?? item['gambar']);
                            final String title = item['name'] ?? item['nama'] ?? 'Hutan Pinus';
                            final num ratingNum = (item['rating'] is num) ? item['rating'] : 4.8;
                            final String ratingStr = ratingNum > 0 ? ratingNum.toStringAsFixed(1) : "4.8";

                            return GestureDetector(
                              onTap: () => _showDetailPopup(item),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      // Image 3:4
                                      Image.asset(
                                        imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          color: Colors.grey.shade800,
                                          child: const Icon(Icons.image, color: Colors.white54),
                                        ),
                                      ),

                                      // Gradient Bottom
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withValues(alpha: 0.1),
                                              Colors.black.withValues(alpha: 0.8),
                                            ],
                                            stops: const [0.5, 0.7, 1.0],
                                          ),
                                        ),
                                      ),

                                      // Top Right Pin Icon
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.45),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                        ),
                                      ),

                                      // Bottom Caption
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        right: 10,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                                const SizedBox(width: 3),
                                                Text(
                                                  ratingStr,
                                                  style: const TextStyle(
                                                    color: Colors.amber,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
