import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../widgets/onboarding_fx.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _pageOffset = 0.0;
  int _currentPage = 0;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _buttonPulseController;

  final List<Map<String, String>> _slides = [
    {
      "title": "Eksplorasi Keasrian\nHutan Pinus Wapit",
      "subtitle": "Temukan ketenangan dan pesona alam pegunungan di Umbul Jumprit, Temanggung.",
      "lottie": "assets/lottie/tent.json",
      "fallback_image": "assets/images/On Boarding 1.png",
      "fact": "🌲 Ketinggian 1.400 mdpl di lereng Sindoro",
    },
    {
      "title": "Pesan Tiket &\nPromo Wahana",
      "subtitle": "Dapatkan promo hemat untuk tiket masuk, wahana seru, dan paket wisata keluarga.",
      "lottie": "assets/lottie/Discount.json",
      "fallback_image": "assets/images/On Boarding 2.png",
      "fact": "🎟️ Promo tiket & wahana hemat mulai Rp 15.000",
    },
    {
      "title": "Pantau Cuaca &\nSuasana Pegunungan",
      "subtitle": "Rencanakan kunjungan dengan info cuaca sejuk dan suasana berkabut khas Jumprit.",
      "lottie": "assets/lottie/Foggy.json",
      "fallback_image": "assets/images/On Boarding 3.png",
      "fact": "🌫️ Suhu sejuk berkabut 18–24°C",
    },
  ];

  final List<Color> _accentColors = const [
    Color(0xFF5E9190), // Light Blue tint
    Color(0xFFB3D89C), // Celadon
    Color(0xFF88BDA4), // Soft Sage
  ];

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      if (_pageController.hasClients && _pageController.page != null) {
        setState(() {
          _pageOffset = _pageController.page!;
        });
      }
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _buttonPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _buttonPulseController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    _entranceController.reset();
    _entranceController.forward();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF4A5552);
    final Color currentAccent = _accentColors[_currentPage];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      body: Stack(
        children: [
          // 1. LAYER PARALLAX BACKGROUND
          ParallaxBackground(
            pageOffset: _pageOffset,
            isDarkMode: isDarkMode,
          ),

          // 2. LAYER AMBIENT PARTICLES
          ParticleLayer(isDarkMode: isDarkMode),

          // 3. MAIN CONTENT (PAGEVIEW)
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Logo + Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/Logo.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.park_rounded, color: currentAccent, size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Go Wapit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Montserrat',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      // Skip / Lewati Button
                      if (_currentPage < _slides.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.9),
                            backgroundColor: Colors.black.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Lewati",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),

                // Center Content: PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      final Color slideColor = _accentColors[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 1),

                            // Interactive Illustration with TapBurst
                            TapBurst(
                              factText: slide['fact']!,
                              accentColor: slideColor,
                              child: Container(
                                height: 260,
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: _buildSlideMedia(slide),
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Text Content with Staggered Entrance
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: Column(
                                  children: [
                                    Text(
                                      slide['title']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: textColor,
                                        fontFamily: 'Montserrat',
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      child: Text(
                                        slide['subtitle']!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: subTextColor,
                                          fontFamily: 'Inter',
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(flex: 2),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom Area: Indicators & Navigation Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    children: [
                      // Animated Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          final bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 7,
                            width: isActive ? 26 : 7,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? currentAccent
                                  : (isDarkMode
                                      ? Colors.grey.shade700
                                      : currentAccent.withValues(alpha: 0.25)),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: currentAccent.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 28),

                      // Action Button (Lanjut / Mulai Petualangan)
                      AnimatedBuilder(
                        animation: _buttonPulseController,
                        builder: (context, child) {
                          final isLast = _currentPage == _slides.length - 1;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode
                                  ? currentAccent
                                  : (isLast ? const Color(0xFF161d1b) : currentAccent),
                              foregroundColor: Colors.white,
                              elevation: isLast ? 4 : 0,
                              shadowColor: currentAccent.withValues(alpha: 0.5),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _nextPage,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? "Mulai Petualangan" : "Lanjut",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLast ? Icons.explore_rounded : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // Terms & Privacy Text (Only on last slide)
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage == _slides.length - 1 ? 1.0 : 0.0,
                        child: Text(
                          "Dengan melanjutkan, Anda menyetujui\nSyarat Layanan dan Kebijakan Privasi kami",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontFamily: 'Inter',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to load Lottie animation with automatic fallback to Image
  Widget _buildSlideMedia(Map<String, String> slide) {
    final String lottiePath = slide['lottie']!;
    final String fallbackImagePath = slide['fallback_image']!;

    return Lottie.asset(
      lottiePath,
      height: 250,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback 1: PNG illustration for that slide
        return Image.asset(
          fallbackImagePath,
          height: 230,
          fit: BoxFit.contain,
          errorBuilder: (context, err2, stack2) {
            // Fallback 2: 3d_onboarding.png
            return Image.asset(
              'assets/images/3d_onboarding.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, err3, stack3) {
                // Fallback 3: Icon
                return Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.park_rounded, size: 90, color: Colors.white),
                );
              },
            );
          },
        );
      },
    );
  }
}