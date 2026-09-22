import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'dart:async';
import '../config/api_config.dart';
import '../config/api_cache.dart';
import '../config/map_config.dart';
import '../auth/auth_service.dart';
import '../design/tokens.dart';
import 'cuaca_screen.dart';
import 'destinasi_screen.dart';
import 'detail_destinasi_screen.dart';
import 'kuliner_screen.dart';
import 'booking_screen.dart';
import 'layanan_umum_screen.dart';
import 'search_screen.dart';
import 'galeri_screen.dart';

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
  String _email = "";
  String _fotoProfil = "";

  // Variabel Destinasi Populer
  List<dynamic> _popularDestinasi = [];
  List<dynamic> _allDestinasi = [];
  bool _isLoadingDestinasi = true;
  Position? _userPosition;

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
    _getUserLocation();

    // Setup Auto-Scroll Carousel
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < 2) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        setState(() => _userPosition = position);
      }
    } catch (_) {}
  }

  // --- API DESTINASI POPULER LOGIC WITH CLIENT CACHE ---
  Future<void> _fetchDestinasiData({bool forceRefresh = false}) async {
    try {
      final cached = ApiCache.instance.get("destinasi");
      if (cached is List && cached.isNotEmpty && !forceRefresh) {
        _applyDestinasiData(cached);
      }

      final data = await ApiCache.instance.getOrFetch(
        cacheKey: "destinasi",
        uri: ApiConfig.uri("/api/destinasi"),
        ttl: ApiCache.destinasiTTL,
        forceRefresh: forceRefresh,
      );

      if (data is List && mounted) {
        _applyDestinasiData(data);
      } else {
        if (mounted) setState(() => _isLoadingDestinasi = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDestinasi = false);
    }
  }

  void _applyDestinasiData(List<dynamic> list) {
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
  }

  // --- API USER LOGIC WITH CLIENT CACHE ---
  Future<void> _fetchUserData({bool forceRefresh = false}) async {
    final token = await AuthService.instance.getToken();

    if (token == null) {
      if (mounted) setState(() => _namaPengguna = "Petualang");
      return;
    }

    try {
      final cached = ApiCache.instance.get("user_me");
      if (cached is Map && !forceRefresh) {
        _applyUserData(cached);
      }

      final data = await ApiCache.instance.getOrFetch(
        cacheKey: "user_me",
        uri: ApiConfig.uri("/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
        ttl: ApiCache.userTTL,
        forceRefresh: forceRefresh,
      );

      if (data is Map && mounted) {
        _applyUserData(data);
      }
    } catch (e) {
      debugPrint("Gagal mengambil data user me: $e");
    }
  }

  void _applyUserData(Map data) {
    final userData = data['data'] ?? data;
    setState(() {
      _namaPengguna = userData['nama_lengkap'] ?? userData['name'] ?? "Petualang";
      _email = userData['email'] ?? "";
      _fotoProfil = userData['foto_profil'] ?? "";
    });
  }

  String _dapatkanUrlAvatarEmail(String email, String nama) {
    final namaBersih = Uri.encodeComponent(nama.isNotEmpty ? nama : "Wapit");
    return "https://ui-avatars.com/api/?name=$namaBersih&background=1E524D&color=ffffff&size=256&bold=true";
  }

  String _getInitials(String text) {
    if (text.isEmpty || text == "Petualang") return "GW";
    List<String> parts = text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    }
    String clean = text.split('@')[0];
    if (clean.length >= 2) return clean.substring(0, 2).toUpperCase();
    return clean.substring(0, 1).toUpperCase();
  }

  ImageProvider? _getAvatarImageProvider() {
    if (_fotoProfil.isNotEmpty) {
      if (_fotoProfil.startsWith("data:image")) {
        try {
          String base64Str = _fotoProfil.split(',').last;
          return MemoryImage(base64Decode(base64Str));
        } catch (_) {}
      } else if (_fotoProfil.startsWith("http")) {
        return NetworkImage(_fotoProfil);
      }
    }

    final fbPhoto = AuthService.instance.currentUser?.photoURL;
    if (fbPhoto != null && fbPhoto.isNotEmpty) {
      return NetworkImage(fbPhoto);
    }

    if (_email.isNotEmpty) {
      return NetworkImage(_dapatkanUrlAvatarEmail(_email, _namaPengguna));
    }
    return const NetworkImage("https://ui-avatars.com/api/?name=Wapit&background=1E524D&color=ffffff&size=256&bold=true");
  }

  // --- API CUACA LOGIC WITH CLIENT CACHE ---
  Future<void> _fetchWeatherData({bool forceRefresh = false}) async {
    const String apiUrl =
        "https://api.open-meteo.com/v1/forecast?latitude=-7.2558&longitude=110.0183&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,rain,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m&hourly=temperature_2m,precipitation,rain,apparent_temperature,precipitation_probability,weather_code,wind_speed_80m,wind_direction_10m,wind_gusts_10m,temperature_80m,uv_index_clear_sky,uv_index,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_clear_sky_max&timezone=auto";
    try {
      final cached = ApiCache.instance.get("weather_open_meteo");
      if (cached is Map && !forceRefresh) {
        _applyWeatherData(cached);
      }

      final data = await ApiCache.instance.getOrFetch(
        cacheKey: "weather_open_meteo",
        uri: Uri.parse(apiUrl),
        ttl: ApiCache.weatherTTL,
        forceRefresh: forceRefresh,
      );

      if (data is Map && mounted) {
        _applyWeatherData(data);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingWeather = false);
    }
  }

  void _applyWeatherData(Map data) {
    final current = data['current'];
    if (current == null) return;
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
    if (code == 0) return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
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
    final bool isDark = context.isDarkMode;
    final Color cardColor = context.surfaceCard;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;
    final Color primaryPine = context.primaryAccent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: primaryPine,
          onRefresh: () async {
            await _fetchWeatherData(forceRefresh: true);
            await _fetchUserData(forceRefresh: true);
            await _fetchDestinasiData(forceRefresh: true);
          },
          child: ListView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
            children: [
              // --- 1. HEADER USER & CUACA MINI PILL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.hairlineBorder, width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: primaryPine.withValues(alpha: 0.15),
                          backgroundImage: _getAvatarImageProvider(),
                          child: Text(
                            _getInitials(_namaPengguna),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: primaryPine,
                              fontFamily: AppTokens.fontFamily,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.sSM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Selamat Datang,",
                            style: AppTokens.finePrint.copyWith(color: subTextColor),
                          ),
                          Text(
                            _namaPengguna,
                            style: AppTokens.bodyStrong.copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Weather Mini Capsule
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CuacaScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? AppTokens.surfaceTile2 : AppTokens.canvasParchment,
                        borderRadius: AppTokens.pill,
                        border: Border.all(color: context.hairlineBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(_weatherIcon, color: primaryPine, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _isLoadingWeather ? "--" : _currentTemp,
                            style: AppTokens.captionStrong.copyWith(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: AppTokens.sLG),

              // --- 2. SEARCH INPUT PILL ---
              GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
                  _fetchDestinasiData();
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.surfaceTile1 : AppTokens.canvas,
                    borderRadius: AppTokens.pill,
                    border: Border.all(color: context.hairlineBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: primaryPine, size: 18),
                      const SizedBox(width: AppTokens.sSM),
                      Text(
                        "Cari destinasi, wahana, atau kuliner...",
                        style: AppTokens.caption.copyWith(color: subTextColor),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.sLG),

              // --- 3. CAROUSEL BERITA / PROMO HERO TILES ---
              SizedBox(
                height: 165,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildPromoCard(
                      "Promo",
                      "Diskon 30% Tiket Masuk",
                      "Berlaku untuk kunjungan akhir pekan ini di Hutan Pinus Wapit.",
                      primaryPine,
                      isDark,
                      'assets/images/BeritaDiskon.png',
                    ),
                    _buildPromoCard(
                      "Event",
                      "Festival Kopi Temanggung",
                      "Nikmati seduhan kopi Arabika gratis dari petani lokal lereng Sindoro.",
                      AppTokens.statusAmber,
                      isDark,
                      'assets/images/BeritaFestivalKopi.png',
                    ),
                    _buildPromoCard(
                      "Informasi",
                      "Wahana High Rope & Flying Fox",
                      "Uji adrenalinmu di wahana petualangan seru standar internasional.",
                      primaryPine,
                      isDark,
                      'assets/images/HighRope.jpg',
                    ),
                  ],
                ),
              ),

              // Titik Indikator Carousel
              const SizedBox(height: AppTokens.sSM),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 5,
                    width: _currentPage == index ? 18 : 5,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? primaryPine : primaryPine.withValues(alpha: 0.25),
                      borderRadius: AppTokens.pill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.sLG),

              // --- 4. MENU QUICK ACTION (HORIZONTAL PILL / SQUARES) ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildMenuIcon(Icons.landscape_outlined, "Destinasi", cardColor, primaryPine, textColor, () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const DestinasiPage()));
                      _fetchDestinasiData();
                    }),
                    const SizedBox(width: AppTokens.sSM),
                    _buildMenuIcon(Icons.restaurant_menu_outlined, "Kuliner", cardColor, primaryPine, textColor, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const KulinerPage()));
                    }),
                    const SizedBox(width: AppTokens.sSM),
                    _buildMenuIcon(Icons.confirmation_number_outlined, "Tiket", cardColor, primaryPine, textColor, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen()));
                    }),
                    const SizedBox(width: AppTokens.sSM),
                    _buildMenuIcon(Icons.support_agent_outlined, "Layanan", cardColor, primaryPine, textColor, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LayananUmumPage()));
                    }),
                    const SizedBox(width: AppTokens.sSM),
                    _buildMenuIcon(Icons.photo_library_outlined, "Galeri", cardColor, primaryPine, textColor, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const GaleriScreen()));
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.sXL),

              // --- 5. WIDGET CUACA APPLE UTILITY CARD ---
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CuacaScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(AppTokens.sMD),
                  decoration: BoxDecoration(
                    color: isDark ? AppTokens.surfaceTile1 : AppTokens.canvasParchment,
                    borderRadius: AppTokens.r18,
                    border: Border.all(color: context.hairlineBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryPine.withValues(alpha: 0.12),
                          borderRadius: AppTokens.r11,
                        ),
                        child: Lottie.asset(
                          _weatherLottie,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => Icon(_weatherIcon, size: 24, color: primaryPine),
                        ),
                      ),
                      const SizedBox(width: AppTokens.sMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Cuaca di Umbul Jumprit", style: AppTokens.bodyStrong.copyWith(color: textColor)),
                            const SizedBox(height: 2),
                            Text(_weatherDesc, style: AppTokens.caption.copyWith(color: subTextColor)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _isLoadingWeather ? "--" : _currentTemp,
                            style: AppTokens.tagline.copyWith(color: primaryPine, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "Terasa ${_isLoadingWeather ? "--" : _feelsLike}",
                            style: AppTokens.microLegal.copyWith(color: subTextColor),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.sXL),

              // --- 6. DESTINASI POPULER (PHOTOGRAPHY-FIRST UTILITY CARDS) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Destinasi Populer",
                    style: AppTokens.tagline.copyWith(color: textColor),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DestinasiPage())),
                    child: Text("Lihat Semua", style: AppTokens.caption.copyWith(color: primaryPine, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.sSM),
              if (_isLoadingDestinasi)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.sXL),
                    child: CircularProgressIndicator(color: primaryPine),
                  ),
                )
              else if (_popularDestinasi.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppTokens.sLG),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: AppTokens.r18,
                    border: Border.all(color: context.hairlineBorder),
                  ),
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

                    double? distKm;
                    if (_userPosition != null && item['latitude'] != null && item['longitude'] != null) {
                      double? lat = double.tryParse(item['latitude'].toString());
                      double? lon = double.tryParse(item['longitude'].toString());
                      if (lat != null && lon != null) {
                        distKm = MapConfig.haversineDistanceKm(_userPosition!.latitude, _userPosition!.longitude, lat, lon);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.sMD),
                      child: _buildPopularCardVertical(
                        title: title,
                        rating: ratingStr,
                        description: description,
                        imagePath: imagePath,
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        primaryColor: primaryPine,
                        distKm: distKm,
                        onTap: () async {
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

  // --- WIDGET BUILDERS ---

  Widget _buildPromoCard(
    String tag,
    String title,
    String description,
    Color color,
    bool isDark,
    String imagePath,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: AppTokens.r18,
        border: Border.all(color: context.hairlineBorder, width: 1),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.25), BlendMode.darken),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppTokens.r18,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppTokens.sMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppTokens.pill,
              ),
              child: Text(
                tag,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTokens.fontFamily,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: AppTokens.fontFamily,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontFamily: AppTokens.fontFamily,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(
    IconData icon,
    String label,
    Color cardColor,
    Color primaryColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: AppTokens.r18,
                border: Border.all(color: context.hairlineBorder, width: 1),
              ),
              child: Center(
                child: Icon(icon, color: primaryColor, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTokens.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCardVertical({
    required String title,
    required String rating,
    required String description,
    required String imagePath,
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required Color primaryColor,
    required double? distKm,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: AppTokens.r18,
          border: Border.all(color: context.hairlineBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar dengan soft product shadow
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Image.asset(
                imagePath,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 160,
                  color: context.surfaceParchment,
                  child: Icon(Icons.image_outlined, color: subTextColor),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.sMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTokens.bodyStrong.copyWith(color: textColor, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppTokens.sXS),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTokens.statusAmber.withValues(alpha: 0.15),
                          borderRadius: AppTokens.pill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppTokens.statusAmber, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTokens.statusAmber,
                                fontWeight: FontWeight.w700,
                                fontFamily: AppTokens.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTokens.caption.copyWith(color: subTextColor, height: 1.45),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (distKm != null) ...[
                    const SizedBox(height: AppTokens.sSM),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.10),
                        borderRadius: AppTokens.pill,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.near_me_rounded, size: 12, color: primaryColor),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "${MapConfig.formatDistance(distKm)} (${MapConfig.estimateDuration(distKm)})",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                fontFamily: AppTokens.fontFamily,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}