import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';
import 'dart:async'; // Diperlukan untuk Timer Carousel
import '../config/api_config.dart';
import 'cuaca_screen.dart';
import 'destinasi_screen.dart';
import 'detail_destinasi_screen.dart';
import 'kuliner_screen.dart';
import 'booking_screen.dart';
import 'layanan_umum_screen.dart';
import 'search_screen.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Variabel Cuaca
  String _currentTemp = "--";
  String _feelsLike = "--";
  String _weatherDesc = "Memuat...";
  IconData _weatherIcon = Icons.cloud_outlined;
  String _weatherLottie = 'assets/lottie/cloudy.json';
  bool _isLoadingWeather = true;

  // Variabel User
  String _namaPengguna = "Petualang";
  
  // Variabel Destinasi Populer
  List<dynamic> _popularDestinasi = [];
  List<dynamic> _allDestinasi = [];
  bool _isLoadingDestinasi = true;

  // Variabel Carousel Berita
  final PageController _pageController = PageController();
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _fetchUserData();
    _fetchDestinasiData();
    
    // Setup Auto-Scroll Carousel
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 600), curve: Curves.easeInOut);
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- API DESTINASI POPULER LOGIC ---
  Future<void> _fetchDestinasiData() async {
    try {
      final response = await http.get(ApiConfig.uri("/api/destinasi"));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        _allDestinasi = list;
        List<dynamic> sorted = List.from(list);
        sorted.sort((a, b) {
          num ratingA = (a['rating'] is num) ? a['rating'] : 0;
          num ratingB = (b['rating'] is num) ? b['rating'] : 0;
          return ratingB.compareTo(ratingA);
        });
        setState(() {
          _popularDestinasi = sorted.take(4).toList();
          _isLoadingDestinasi = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingDestinasi = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDestinasi = false);
    }
  }

  // --- API USER LOGIC ---
  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() => _namaPengguna = "Petualang");
      return;
    }

    try {
      final response = await http.get(
        ApiConfig.uri("/api/users/me"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          String namaLengkap = data['nama_lengkap'] ?? 'Petualang';
          _namaPengguna = namaLengkap.split(' ')[0];
        });
      } else {
        setState(() => _namaPengguna = "Petualang");
      }
    } catch (e) {
      setState(() => _namaPengguna = "Petualang");
    }
  }

  // --- API CUACA LOGIC ---
  Future<void> _fetchWeatherData() async {
    const String apiUrl = "https://api.open-meteo.com/v1/forecast?latitude=-7.2558&longitude=110.0183&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,rain,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m&hourly=temperature_2m,precipitation,rain,apparent_temperature,precipitation_probability,weather_code,wind_speed_80m,wind_direction_10m,wind_gusts_10m,temperature_80m,uv_index_clear_sky,uv_index,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_clear_sky_max&timezone=auto";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        int code = (current['weather_code'] as num).toInt();
        int isDay = (current['is_day'] as num).toInt();
        setState(() {
          _currentTemp = "${(current['temperature_2m'] as num).round()}°C";
          _feelsLike = "${(current['apparent_temperature'] as num).round()}°C";
          _weatherDesc = _getWeatherDescription(code);
          _weatherIcon = _getWeatherIcon(code, isDay == 1);
          _weatherLottie = _getWeatherLottie(code);
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return "Cerah";
    if (code >= 1 && code <= 3) return "Cerah Berawan";
    if (code == 45 || code == 48) return "Berkabut";
    if (code >= 51 && code <= 55) return "Gerimis";
    if (code >= 61 && code <= 82) return "Hujan";
    if (code >= 95) return "Badai Petir";
    return "Berawan";
  }

  IconData _getWeatherIcon(int code, bool isDay) {
    if (code == 0) return isDay ? Icons.wb_sunny : Icons.nightlight_round;
    if (code >= 51 && code <= 67) return Icons.water_drop_outlined;
    return Icons.cloud_outlined;
  }

  String _getWeatherLottie(int code) {
    if (code == 0) return 'assets/lottie/detail cuaca/sun.json';
    if (code >= 1 && code <= 3) return 'assets/lottie/cloudy.json';
    if (code == 45 || code == 48) return 'assets/lottie/detail cuaca/Fog.json';
    if (code >= 51 && code <= 55) return 'assets/lottie/detail cuaca/drizzle.json';
    if (code >= 61 && code <= 82) return 'assets/lottie/detail cuaca/rain.json';
    if (code >= 95) return 'assets/lottie/thunderstorm.json';
    return 'assets/lottie/cloudy.json';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    const Color secondaryColor = Color(0xFFB3D89C);
    
    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.16), blurRadius: 15, offset: const Offset(0, 6))
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await _fetchWeatherData();
            await _fetchUserData();
            await _fetchDestinasiData();
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 120),
            children: [
              // --- 1. HEADER (TERINTEGRASI API USER) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 20, backgroundImage: AssetImage('assets/images/default_avatar.png')),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome Back,", style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w500)),
                          Text(_namaPengguna, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Montserrat')),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Icon(_weatherIcon, color: isDarkMode ? const Color(0xFF121212) : Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(_isLoadingWeather ? "--" : _currentTemp, style: TextStyle(color: isDarkMode ? const Color(0xFF121212) : Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // --- 2. SEARCH BAR ---
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
                  _fetchDestinasiData();
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDarkMode ? Colors.grey.shade800 : secondaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: secondaryColor, size: 20),
                      const SizedBox(width: 12),
                      Text("Cari destinasi, tiket, atau kuliner...", style: TextStyle(color: subTextColor, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- 3. CAROUSEL BERITA / PROMO ---
              SizedBox(
                height: 170, // Tinggi area carousel
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() { _currentPage = page; });
                  },
                  children: [
                    _buildPromoCard(
                      "Promo", 
                      "Diskon 30% Tiket Masuk", 
                      "Berlaku untuk kunjungan akhir pekan ini. Jangan sampai kehabisan!", 
                      primaryColor, 
                      isDarkMode, 
                      ambientShadow,
                      'assets/images/BeritaDiskon.png'
                    ),
                    _buildPromoCard(
                      "Event", 
                      "Festival Kopi Temanggung", 
                      "Nikmati seduhan kopi Arabika gratis dari petani lokal Jumprit.", 
                      const Color(0xFF44634e), 
                      isDarkMode, 
                      ambientShadow,
                      'assets/images/BeritaFestivalKopi.png'
                    ),
                    _buildPromoCard(
                      "Info", 
                      "Wahana High Rope Dibuka!", 
                      "Uji adrenalinmu di wahana terbaru Hutan Pinus Wapit.", 
                      const Color(0xFFD32F2F), 
                      isDarkMode, 
                      ambientShadow,
                      'assets/images/HighRope.jpg'
                    ),
                  ],
                ),
              ),
              
              // Titik Indikator Carousel
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == index ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? primaryColor : primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                )),
              ),
              const SizedBox(height: 32),

              // --- 4. GRID MENU IKON ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMenuIcon(Icons.landscape, "Destinasi", cardColor, primaryColor, textColor, ambientShadow, () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const DestinasiPage()));
                    _fetchDestinasiData();
                  }),
                  _buildMenuIcon(Icons.restaurant, "Kuliner", cardColor, primaryColor, textColor, ambientShadow, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KulinerPage()))),
                  _buildMenuIcon(Icons.confirmation_number_outlined, "Tiket", cardColor, primaryColor, textColor, ambientShadow, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen()))),
                  _buildMenuIcon(Icons.support_agent, "Layanan", cardColor, primaryColor, textColor, ambientShadow, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LayananUmumPage()))),
                ],
              ),
              const SizedBox(height: 32),

            // --- 5. WIDGET CUACA KACA ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CuacaScreen()),
                );
              },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: const Color(0xFFE6F2DD), borderRadius: BorderRadius.circular(12)),
                    child: Lottie.asset(
                      _weatherLottie,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(_weatherIcon, size: 28, color: primaryColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Cuaca di Jumprit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                        const SizedBox(height: 4),
                        Text(_weatherDesc, style: TextStyle(fontSize: 13, color: subTextColor)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_isLoadingWeather ? "--" : _currentTemp, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Montserrat')),
                      Text("Terasa ${_isLoadingWeather ? "--" : _feelsLike}", style: TextStyle(fontSize: 11, color: subTextColor)),
                    ],
                  )
                ],
              ),
            ),
            ),
            const SizedBox(height: 32),

            // --- 6. DESTINASI POPULER (VERTIKAL) ---
            Text("Destinasi Populer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor, fontFamily: 'Montserrat')),
            const SizedBox(height: 16),
            if (_isLoadingDestinasi)
              Center(child: Padding(padding: const EdgeInsets.all(24.0), child: CircularProgressIndicator(color: primaryColor)))
            else if (_popularDestinasi.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                child: Center(child: Text("Belum ada destinasi.", style: TextStyle(color: subTextColor))),
              )
            else
              Column(
                children: _popularDestinasi.map((item) {
                  final String title = item['name'] ?? item['nama'] ?? 'Destinasi Wapit';
                  final num ratingNum = (item['rating'] is num) ? item['rating'] : 0.0;
                  final String ratingStr = ratingNum > 0 ? ratingNum.toStringAsFixed(1) : "Baru";
                  final String description = item['deskripsi_pendek'] ?? item['deskripsi_panjang'] ?? item['deskripsi_singkat'] ?? '-';
                  String rawGambar = item['image'] ?? item['gambar'] ?? 'assets/images/placeholder.jpeg';
                  final String imagePath = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildPopularCardVertical(
                      title,
                      ratingStr,
                      description,
                      imagePath,
                      cardColor,
                      textColor,
                      subTextColor,
                      primaryColor,
                      secondaryColor,
                      ambientShadow,
                      () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailDestinasiPage(
                              data: item,
                              allDestinasi: _allDestinasi,
                            ),
                          ),
                        );
                        _fetchDestinasiData();
                      },
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDER ---

Widget _buildPromoCard(String tag, String title, String description, Color color, bool isDarkMode, List<BoxShadow> ambientShadow, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: ambientShadow,
        // --- MEMASANG GAMBAR SEBAGAI BACKGROUND ---
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          // Fallback warna jika gambar gagal dimuat sementara
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
        ),
      ),
      child: Container(
        // --- GRADIENT OVERLAY AGAR TEKS TETAP TERBACA JELAS ---
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8), // Gelap di bagian bawah (tempat teks)
              Colors.transparent, // Transparan di bagian atas
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end, // Mendorong teks ke bawah
          children: [
            // Tag (Label Promo/Event)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
            ),
            const SizedBox(height: 8),
            // Judul Promo
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Deskripsi Promo
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Inter'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color cardColor, Color primaryColor, Color textColor, List<BoxShadow> shadow, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
            child: Icon(icon, color: primaryColor, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)),
        ],
      ),
    );
  }

  // Desain Kartu Populer Diubah Menjadi Vertikal Penuh
  Widget _buildPopularCardVertical(
    String title,
    String rating,
    String description,
    String imagePath,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color primaryColor,
    Color secondaryColor,
    List<BoxShadow> shadow,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 160,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: textColor, fontFamily: 'Montserrat'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(rating, style: TextStyle(fontSize: 14, color: subTextColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description, 
                    style: TextStyle(fontSize: 13, height: 1.5, color: subTextColor), 
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}