import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../widgets/onboarding_fx.dart';
import '../design/tokens.dart';

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
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
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
        transitionDuration: const Duration(milliseconds: 400),
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
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color primaryPine = context.primaryAccent;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
      body: Stack(
        children: [
          // 1. LAYER PARALLAX BACKGROUND
          ParallaxBackground(
            pageOffset: _pageOffset,
            isDarkMode: isDark,
          ),

          // 2. LAYER AMBIENT PARTICLES
          ParticleLayer(isDarkMode: isDark),

          // 3. MAIN CONTENT (PAGEVIEW)
          SafeArea(
            child: Column(
              children: [
                // Top Bar: Logo + Skip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: AppTokens.sSM),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTokens.canvas,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.hairlineBorder),
                            ),
                            child: Image.asset(
                              'assets/images/Logo.png',
                              width: 22,
                              height: 22,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.park_rounded, color: primaryPine, size: 20),
                            ),
                          ),
                          const SizedBox(width: AppTokens.sXS),
                          const Text(
                            "Go Wapit",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppTokens.fontFamily,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),

                      // Skip / Lewati Button
                      if (_currentPage < _slides.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.95),
                            backgroundColor: Colors.black.withValues(alpha: 0.25),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
                          ),
                          child: const Text(
                            "Lewati",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppTokens.fontFamily,
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

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(flex: 1),

                            // Interactive Illustration with TapBurst
                            TapBurst(
                              factText: slide['fact']!,
                              accentColor: primaryPine,
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
                                      style: AppTokens.displayMd.copyWith(
                                        color: textColor,
                                      ),
                                    ),
                                    const SizedBox(height: AppTokens.sSM),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sMD),
                                      child: Text(
                                        slide['subtitle']!,
                                        textAlign: TextAlign.center,
                                        style: AppTokens.body.copyWith(
                                          color: subTextColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: AppTokens.sLG),
                  child: Column(
                    children: [
                      // Dots Indicator Pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_slides.length, (index) {
                          final bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            height: 6,
                            width: isActive ? 24 : 6,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? primaryPine
                                  : (isDark
                                      ? Colors.grey.shade800
                                      : AppTokens.hairlineLight),
                              borderRadius: AppTokens.pill,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: AppTokens.sXL),

                      // Action Button (Lanjut / Mulai Petualangan) — Signature Pill Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPine,
                            foregroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
                          ),
                          onPressed: _nextPage,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _slides.length - 1 ? "Mulai Petualangan" : "Lanjut",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: AppTokens.fontFamily,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: AppTokens.sXS),
                              Icon(
                                _currentPage == _slides.length - 1
                                    ? Icons.explore_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTokens.sMD),

                      // Terms & Privacy Text
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage == _slides.length - 1 ? 1.0 : 0.0,
                        child: Text(
                          "Dengan melanjutkan, Anda menyetujui Syarat Layanan & Kebijakan Privasi Go Wapit",
                          textAlign: TextAlign.center,
                          style: AppTokens.microLegal.copyWith(
                            color: subTextColor,
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
        return Image.asset(
          fallbackImagePath,
          height: 230,
          fit: BoxFit.contain,
          errorBuilder: (context, err2, stack2) {
            return Image.asset(
              'assets/images/3d_onboarding.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, err3, stack3) {
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