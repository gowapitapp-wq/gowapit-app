import 'dart:ui';
import 'package:flutter/material.dart';

// ============================================================================
// MODEL STORY HIGHLIGHT (INSTAGRAM STORIES STYLE)
// ============================================================================
class StorySlide {
  final String image;
  final String caption;
  final String location;
  final String time;

  const StorySlide({
    required this.image,
    required this.caption,
    required this.location,
    required this.time,
  });
}

class HighlightGroup {
  final String id;
  final String title;
  final String coverImage;
  final List<StorySlide> slides;

  const HighlightGroup({
    required this.id,
    required this.title,
    required this.coverImage,
    required this.slides,
  });
}

// ============================================================================
// HALAMAN UTAMA GALERI
// ============================================================================
class GaleriScreen extends StatefulWidget {
  const GaleriScreen({super.key});

  @override
  State<GaleriScreen> createState() => _GaleriScreenState();
}

class _GaleriScreenState extends State<GaleriScreen> {
  late PageController _pageController;
  double _currentPageValue = 0.0;
  String _selectedFeedCategory = "Semua";

  // --- DATA KONTEN UTAMA GALERI BUDAYA & EVENT TEMANGGUNG ---
  final List<Map<String, dynamic>> _galeriItems = const [
    {
      "id": 1,
      "name": "Topeng Ireng",
      "kategori": "Budaya",
      "info": "Budaya dan Pariwisata",
      "image": "assets/images/3.png",
      "deskripsi": "Topeng Ireng adalah seni tari rakyat khas Temanggung yang berakar dari akronim Toto Lempeng Irama Kenceng, menggambarkan gerakan penari yang lurus, kompak, dan berirama cepat. Dahulu, tarian ini diciptakan oleh para ulama sebagai media syiar Islam sekaligus kamuflase latihan bela diri masyarakat dari penjajah Belanda.\n\nCiri khas utama tarian ini terletak pada kostumnya yang meriah menyerupai suku Indian dengan mahkota bulu unggas di kepala. Selain itu, para penari mengenakan sepatu berpasang ratusan lonceng kecil yang menghasilkan suara gemerincing riuh setiap kali kaki dihentakkan. Dipadukan dengan musik enerjik dan lirik lagu berisi selawat, Topeng Ireng selalu menyuguhkan pertunjukan yang dinamis dan penuh semangat kebersamaan.",
      "lokasi": "Kabupaten Temanggung",
      "foto_count": 84,
    },
    {
      "id": 2,
      "name": "Jaran Kepang Simo Putih",
      "kategori": "Event",
      "info": "Kesenian Rakyat",
      "image": "assets/images/1.png",
      "deskripsi": "Jaran Kepang Simo Putih merupakan salah satu variasi atau nama kelompok kesenian Jaran Kepang Temanggungan yang mengusung karakter visual serta filosofi \"Simo Putih\" (Macan Putih).\n\nDalam tradisi pertunjukan jaran kepang di lereng Gunung Sumbing dan Sindoro, unsur simo atau harimau sering kali dihadirkan sebagai representasi kekuatan alam, kegagahan, dan aspek spiritual. Kostum dan riasan khas kelompok Simo Putih umumnya didominasi oleh warna putih bersih yang melambangkan kesucian hati serta ketulusan, dipadukan dengan gerakan-gerakan tari keprajuran berkuda yang tegas, enerjik, dan sarat akan nuansa magis. Pertunjukan ini tidak sekadar menjadi sarana hiburan rakyat, melainkan juga simbol kekuatan komunal dan pelindung spiritual bagi masyarakat agraris di Temanggung.",
      "lokasi": "Lereng Gunung Sumbing dan Sindoro",
      "foto_count": 92,
    },
    {
      "id": 3,
      "name": "Tari Bangilun",
      "kategori": "Event",
      "info": "Tari Tradisional & Dakwah",
      "image": "assets/images/2.png",
      "deskripsi": "Tari Bangilun adalah kesenian rakyat tradisional khas Kabupaten Temanggung yang menggabungkan unsur gerak tari dengan syiar agama Islam.\n\nDiciptakan oleh para ulama pada era kolonial Belanda, tarian ini awalnya berfungsi sebagai media dakwah kreatif. Ciri khas utama Tari Bangilun terletak pada kostum penarinya yang menyerupai tentara Belanda lengkap dengan kacamata hitam, topi pet, dan peluit sebagai bentuk penyamaran sekaligus sindiran satir kepada penjajah. Selama pertunjukan, para penari bergerak dinamis dengan iringan tabuhan musik terbangan dan jidur. Alunan musik tersebut dipadukan dengan lantunan selawat serta lirik lagu yang berisi pesan moral dan tuntunan hidup islami bagi masyarakat.",
      "lokasi": "Kabupaten Temanggung",
      "foto_count": 68,
    },
    {
      "id": 4,
      "name": "Nyadran",
      "kategori": "Event",
      "info": "Tradisi & Doa Leluhur",
      "image": "assets/images/4.png",
      "deskripsi": "Nyadran adalah tradisi ritual pembersihan diri dan makam leluhur yang dilakukan oleh masyarakat Jawa, termasuk di Kabupaten Temanggung, sebagai bentuk penghormatan dan rasa syukur. Tradisi yang biasanya digelar menjelang bulan suci Ramadan atau bertepatan dengan masa panen ini menjadi simbol hubungan harmonis antara manusia, leluhur, dan Sang Pencipta.\n\nProsesi Nyadran diawali dengan kerja bakti membersihkan makam keluarga secara gotong royong, dilanjutkan dengan doa dan zikir bersama. Puncak acara ditandai dengan tradisi kenduri atau makan bersama, di mana warga membawa makanan dalam wadah bambu bernama tenong untuk dinikmati bersama di area pemakaman atau pelataran desa sebagai wujud kebersamaan dan kerukunan.",
      "lokasi": "Kabupaten Temanggung",
      "foto_count": 115,
    },
    {
      "id": 5,
      "name": "Wiwit Mbako",
      "kategori": "Event",
      "info": "Ritual Sakral Panen",
      "image": "assets/images/5.png",
      "deskripsi": "Wiwit Mbako adalah ritual sakral petani Temanggung di lereng Gunung Sumbing dan Sindoro untuk menandai awal masa panen tembakau. Tradisi ini digelar di ladang sebagai ungkapan rasa syukur kepada Tuhan, sekaligus doa agar hasil panen melimpah dan mendapat harga jual yang tinggi.\n\nProsesi diawali dengan pemetikan daun tembakau pertama oleh sesepuh adat, lalu dilanjutkan dengan doa bersama. Acara diakhiri dengan kenduri atau makan bersama menggunakan tenong (wadah bambu) berisi nasi megono dan ingkung ayam, yang berfungsi mempererat silaturahmi serta semangat gotong royong antarpetani.",
      "lokasi": "Lereng Gunung Sumbing dan Sindoro",
      "foto_count": 130,
    },
    {
      "id": 6,
      "name": "Ruwat Rigen",
      "kategori": "Event",
      "info": "Tradisi Selamatan Adat",
      "image": "assets/images/6.png",
      "deskripsi": "Ruwat Rigen adalah tradisi selamatan adat tahunan yang digelar oleh masyarakat petani di wilayah lereng Gunung Sumbing dan Sindoro, khususnya di Kecamatan Kledung, Kabupaten Temanggung. Tradisi ini diadakan secara rutin menjelang musim panen raya tembakau sebagai wujud permohonan spiritual kepada Tuhan agar proses panen berjalan lancar, terhindar dari marabahaya, serta menghasilkan harga jual tembakau yang tinggi.\n\nSecara harfiah, \"rigen\" adalah alat berbentuk anyaman bambu persegi panjang yang digunakan petani untuk menjemur rajangan daun tembakau. Dalam ritual ini, rigen-rigen milik petani dikeluarkan untuk dicuci dan disucikan menggunakan air bersih yang biasanya diambil dari berbagai sumber mata air suci di lereng gunung. Prosesi Ruwat Rigen biasanya dimeriahkan dengan kirab budaya, pertunjukan seni tradisional seperti tari warok, serta doa bersama. Di akhir acara, masyarakat melakukan kenduri dengan menyantap tumpeng hasil bumi secara komunal.",
      "lokasi": "Kecamatan Kledung, Kabupaten Temanggung",
      "foto_count": 140,
    },
  ];

  // --- DATA SOROTAN (INSTAGRAM STORIES) ---
  final List<HighlightGroup> _highlightGroups = const [
    HighlightGroup(
      id: "topeng_ireng",
      title: "Topeng Ireng",
      coverImage: "assets/images/3.png",
      slides: [
        StorySlide(
          image: "assets/images/3.png",
          caption: "Seni tari rakyat Toto Lempeng Irama Kenceng khas Temanggung dengan kostum mahkota bulu unggas meriah 🦚✨",
          location: "Kabupaten Temanggung",
          time: "Baru saja",
        ),
      ],
    ),
    HighlightGroup(
      id: "simo_putih",
      title: "Simo Putih",
      coverImage: "assets/images/1.png",
      slides: [
        StorySlide(
          image: "assets/images/1.png",
          caption: "Kesenian Jaran Kepang Simo Putih (Macan Putih) lambang kesucian hati dan kekuatan spiritual prajurit 🐅🤍",
          location: "Lereng Sumbing & Sindoro",
          time: "2 jam lalu",
        ),
      ],
    ),
    HighlightGroup(
      id: "bangilun",
      title: "Tari Bangilun",
      coverImage: "assets/images/2.png",
      slides: [
        StorySlide(
          image: "assets/images/2.png",
          caption: "Tari dakwah islamiah dengan kostum satir khas tentara Belanda, kacamata hitam, dan alunan terbang jidur 💂‍♂️🎺",
          location: "Kabupaten Temanggung",
          time: "3 jam lalu",
        ),
      ],
    ),
    HighlightGroup(
      id: "nyadran",
      title: "Nyadran",
      coverImage: "assets/images/4.png",
      slides: [
        StorySlide(
          image: "assets/images/4.png",
          caption: "Tradisi pembersihan makam leluhur dan kenduri tenong bersama wujud kerukunan masyarakat Jawa 🍲🎋",
          location: "Kabupaten Temanggung",
          time: "4 jam lalu",
        ),
      ],
    ),
    HighlightGroup(
      id: "wiwit_mbako",
      title: "Wiwit Mbako",
      coverImage: "assets/images/5.png",
      slides: [
        StorySlide(
          image: "assets/images/5.png",
          caption: "Ritual sakral petik tembakau pertama di ladang lereng Sindoro-Sumbing sebagai ungkapan syukur panen 🌿🍃",
          location: "Lereng Sumbing & Sindoro",
          time: "5 jam lalu",
        ),
      ],
    ),
    HighlightGroup(
      id: "ruwat_rigen",
      title: "Ruwat Rigen",
      coverImage: "assets/images/6.png",
      slides: [
        StorySlide(
          image: "assets/images/6.png",
          caption: "Penyucian rigen anyaman bambu penjemur tembakau dengan air suci pegunungan menjelang panen raya 🌾🏞️",
          location: "Kledung, Temanggung",
          time: "6 jam lalu",
        ),
      ],
    ),
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
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredFeed() {
    if (_selectedFeedCategory == "Semua") return _galeriItems;
    return _galeriItems.where((item) {
      final String kat = (item['kategori'] ?? '').toString().toLowerCase();
      return kat.contains(_selectedFeedCategory.toLowerCase());
    }).toList();
  }

  // --- BUKA INSTAGRAM STORY VIEWER ---
  void _openStoryViewer(int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, anim, _) => StoryViewerScreen(
          highlightGroups: _highlightGroups,
          initialGroupIndex: initialIndex,
        ),
        transitionsBuilder: (context, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  // --- DETAIL POP-UP DIALOG (BLUR BACKGROUND) ---
  void _showDetailPopup(Map<String, dynamic> item) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color(0xFF5E9190);
    const Color celadonColor = Color(0xFFB3D89C);
    final Color cardBg = isDark ? const Color(0xFF1C2824) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF404846);

    final String name = item['name'] ?? 'Kesenian Temanggung';
    final String infoTag = item['info'] ?? item['kategori'] ?? 'Budaya';
    final String desc = item['deskripsi'] ?? '-';
    final String imagePath = item['image'] ?? 'assets/images/3.png';
    final String lokasi = item['lokasi'] ?? "Kabupaten Temanggung";
    final int fotoCount = item['foto_count'] ?? 100;

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
                width: MediaQuery.of(context).size.width * 0.90,
                constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
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
                        // Foto 3:4 Header
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 3.2,
                              child: Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.image, color: Colors.white54, size: 48),
                                ),
                              ),
                            ),
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
                                  item['kategori'] ?? 'Event & Budaya',
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

                        // Content Section
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
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: celadonColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      infoTag,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                        color: isDark ? celadonColor : primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "•  $fotoCount Dokumentasi Foto",
                                    style: TextStyle(fontSize: 12, color: subTextColor, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: subTextColor,
                                  height: 1.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 14),
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
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text(
                                    "Tutup",
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
    final Color primaryColor = isDark ? const Color(0xFF76B3AC) : const Color(0xFF1E524D);
    const Color emeraldColor = Color(0xFF2E7D6A);
    final Color textColor = isDark ? Colors.white : const Color(0xFF121E1C);
    final Color subTextColor = isDark ? Colors.grey.shade400 : const Color(0xFF4A5D5A);

    final filteredFeed = _getFilteredFeed();
    final List<String> categories = ["Semua", "Event", "Budaya"];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Galeri Wisata Wapit",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
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
              child: Text(
                "Pesona Unggulan",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 290,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: _galeriItems.length,
                itemBuilder: (context, index) {
                  final item = _galeriItems[index];
                  final String imagePath = item['image'];
                  final String title = item['name'];
                  final String kategori = item['kategori'];
                  final String infoTag = item['info'] ?? kategori;

                  final double diff = index - _currentPageValue;
                  final double rotateY = (-diff * 0.22).clamp(-0.4, 0.4);
                  final double scale = (1 - (diff.abs() * 0.16)).clamp(0.82, 1.0);
                  final double opacity = (1 - (diff.abs() * 0.35)).clamp(0.65, 1.0);
                  final double translationX = diff * 16.0;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
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
                                Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.image, color: Colors.white54, size: 36),
                                  ),
                                ),
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
                                Positioned(
                                  bottom: 14,
                                  left: 14,
                                  right: 14,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: celadonColor.withValues(alpha: 0.5)),
                                        ),
                                        child: Text(
                                          infoTag,
                                          style: const TextStyle(
                                            color: celadonColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
              children: List.generate(_galeriItems.length, (i) {
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
            // SECTION 2: SOROTAN (HIGHLIGHTS) - INSTAGRAM STORIES
            // =========================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Sorotan Momen",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "Ketuk untuk putar",
                    style: TextStyle(fontSize: 11, color: subTextColor, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 102,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _highlightGroups.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final h = _highlightGroups[index];
                  final String imagePath = h.coverImage;

                  return GestureDetector(
                    onTap: () => _openStoryViewer(index),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 66,
                          height: 66,
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF5E9190),
                                Color(0xFFB3D89C),
                                Color(0xFFFDBB2D),
                                Color(0xFF22C1C3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? const Color(0xFF16221D) : Colors.white,
                            ),
                            child: ClipOval(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: primaryColor.withValues(alpha: 0.2),
                                      child: const Icon(Icons.landscape, color: primaryColor, size: 24),
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 72,
                          child: Text(
                            h.title,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Inter',
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // =========================================================
            // SECTION 3: FEED GALERI UTAMA (GRID 2-KOLOM 3:4)
            // =========================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Koleksi Foto",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Kategori Pills untuk Feed Grid
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final bool isSelected = (_selectedFeedCategory == cat);

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFeedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDark ? const Color(0xFF1C2824) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : subTextColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),

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
                  final String imagePath = item['image'];
                  final String title = item['name'];
                  final String kategori = item['kategori'];

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
                            Image.asset(
                              imagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.image, color: Colors.white54),
                              ),
                            ),
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
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      kategori,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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
    );
  }
}

// ============================================================================
// FULLSCREEN INSTAGRAM STORY VIEWER WIDGET
// ============================================================================
class StoryViewerScreen extends StatefulWidget {
  final List<HighlightGroup> highlightGroups;
  final int initialGroupIndex;

  const StoryViewerScreen({
    super.key,
    required this.highlightGroups,
    required this.initialGroupIndex,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> with SingleTickerProviderStateMixin {
  late int _currentGroupIndex;
  late int _currentSlideIndex;
  late AnimationController _animController;
  bool _isPaused = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialGroupIndex;
    _currentSlideIndex = 0;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSlideTimerCompleted();
      }
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onSlideTimerCompleted() {
    final currentGroup = widget.highlightGroups[_currentGroupIndex];
    if (_currentSlideIndex < currentGroup.slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
        _isLiked = false;
      });
      _animController.reset();
      _animController.forward();
    } else {
      if (_currentGroupIndex < widget.highlightGroups.length - 1) {
        setState(() {
          _currentGroupIndex++;
          _currentSlideIndex = 0;
          _isLiked = false;
        });
        _animController.reset();
        _animController.forward();
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _previousSlide() {
    if (_currentSlideIndex > 0) {
      setState(() {
        _currentSlideIndex--;
        _isLiked = false;
      });
      _animController.reset();
      _animController.forward();
    } else if (_currentGroupIndex > 0) {
      setState(() {
        _currentGroupIndex--;
        _currentSlideIndex = widget.highlightGroups[_currentGroupIndex].slides.length - 1;
        _isLiked = false;
      });
      _animController.reset();
      _animController.forward();
    }
  }

  void _nextSlide() {
    final currentGroup = widget.highlightGroups[_currentGroupIndex];
    if (_currentSlideIndex < currentGroup.slides.length - 1) {
      setState(() {
        _currentSlideIndex++;
        _isLiked = false;
      });
      _animController.reset();
      _animController.forward();
    } else if (_currentGroupIndex < widget.highlightGroups.length - 1) {
      setState(() {
        _currentGroupIndex++;
        _currentSlideIndex = 0;
        _isLiked = false;
      });
      _animController.reset();
      _animController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  void _pauseTimer() {
    setState(() => _isPaused = true);
    _animController.stop();
  }

  void _resumeTimer() {
    setState(() => _isPaused = false);
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final currentGroup = widget.highlightGroups[_currentGroupIndex];
    final currentSlide = currentGroup.slides[_currentSlideIndex];
    final int totalSlides = currentGroup.slides.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: false,
        child: GestureDetector(
          onTapDown: (_) => _pauseTimer(),
          onTapCancel: () => _resumeTimer(),
          onTapUp: (details) {
            _resumeTimer();
            final double screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth * 0.35) {
              _previousSlide();
            } else {
              _nextSlide();
            }
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 250) {
              Navigator.pop(context);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fullscreen Image Story
              Image.asset(
                currentSlide.image,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey.shade900,
                  child: const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                  ),
                ),
              ),

              // 2. Gradient Overlays
              Positioned(
                top: 0, left: 0, right: 0,
                height: 180,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                bottom: 0, left: 0, right: 0,
                height: 240,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Top Progress Bars & Header
              AnimatedOpacity(
                opacity: _isPaused ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 12,
                    right: 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: List.generate(totalSlides, (i) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: SizedBox(
                                  height: 2.8,
                                  child: AnimatedBuilder(
                                    animation: _animController,
                                    builder: (context, _) {
                                      double val = 0.0;
                                      if (i < _currentSlideIndex) {
                                        val = 1.0;
                                      } else if (i == _currentSlideIndex) {
                                        val = _animController.value;
                                      }
                                      return LinearProgressIndicator(
                                        value: val,
                                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF5E9190), Color(0xFFB3D89C)],
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(currentGroup.coverImage, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      currentGroup.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text("•", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentSlide.time,
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${_currentSlideIndex + 1} dari $totalSlides cerita",
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Caption Bar
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _isPaused ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFB3D89C).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFB3D89C), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              currentSlide.location,
                              style: const TextStyle(
                                color: Color(0xFFB3D89C),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          currentSlide.caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            height: 1.4,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Kirim tanggapan cerita...",
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              setState(() => _isLiked = !_isLiked);
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _isLiked ? Colors.red.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isLiked ? Colors.red : Colors.white24,
                                ),
                              ),
                              child: Icon(
                                _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _isLiked ? Colors.red : Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
