import 'package:flutter/material.dart';
import 'dart:ui'; // Wajib untuk efek BackdropFilter (Glassmorphism)
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';

import 'screens/onboarding_screen.dart';
import 'screens/profil_screen.dart'; // Sesuaikan nama file jika berbeda
import 'theme_notifier.dart';
import 'screens/peta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tiket_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('id', 'ID'),
      child: const GoWapitApp(),
    ),
  );
}

class GoWapitApp extends StatelessWidget {
  const GoWapitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkModeGlobal,
      builder: (context, isDark, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Go Wapit',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

// =========================================================
          // TRIK GLOBAL GRADIENT
          // =========================================================
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF23362F), // Gelap Atas
                          const Color(0xFF1B2824), // Gelap Tengah (Warna transisi baru)
                          const Color(0xFF121212), // Gelap Bawah
                        ] // <--- Sekarang jumlahnya 3 warna!
                      : [
                          const Color(0xFF7FA89B), // Hijau Sage
                          const Color(0xFFE2EFE1), // Transisi Lembut
                          Colors.white,            // Putih Bersih
                        ], // <--- Ini juga 3 warna!
                  stops: const [0.0, 0.5, 1.0], // 3 titik (Sempurna)
                ),
              ),
              child: child,
            );
          },

          // --- TEMA TERANG ---
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Inter',
            // PENTING: Scaffold diatur transparan agar gradien dari builder di atas bisa terlihat
            scaffoldBackgroundColor: Colors.transparent, 
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF659287), 
              secondary: Color(0xFF88BDA4), 
              surface: Color(0xFFffffff),
              onSurface: Color(0xFF161d1b),
            ),
            useMaterial3: true,
          ),

          // --- TEMA GELAP ---
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Inter',
            // PENTING: Scaffold diatur transparan
            scaffoldBackgroundColor: Colors.transparent,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF88BDA4),
              secondary: Color(0xFF659287),
              surface: Color(0xFF1C1C1E),
            ),
            useMaterial3: true,
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}

// ==================== 1. SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Berpindah ke Onboarding setelah 2.5 detik
    Timer(const Duration(milliseconds: 2500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold transparan, gradien otomatis diambil dari builder aplikasi utama
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Image.asset(
          'assets/images/Logo.png', // Pastikan jalur menggunakan 'assets/...'
          width: 200, // Diperkecil sedikit agar presisi di tengah
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            color: Colors.white,
            size: 100,
          ),
        ),
      ),
    );
  }
}

// ==================== 2. NAVIGASI GLASSMORPHISM ====================
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const TiketPage(),
    const PetaScreen(),
    const ProfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryGreen = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);

    return Scaffold(
      backgroundColor: Colors.transparent, // Biarkan gradien belakang menembus
      extendBody: true, 
      body: _pages[_selectedIndex],

      // Bottom Navigation dengan gaya Floating & Glassmorphism
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), 
            boxShadow: isDarkMode
                ? []
                : [
                    BoxShadow(
                        color: const Color(0xFF659287).withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), 
              child: BottomNavigationBar(
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: isDarkMode
                    ? const Color(0xFF1C1C1E).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.7), 
                selectedItemColor: primaryGreen,
                unselectedItemColor: isDarkMode ? Colors.grey.shade600 : const Color(0xFF717976),
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                items: const [
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_filled)),
                      label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long)),
                      label: 'Tiket'),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.map_outlined)),
                      label: 'Peta'),
                  BottomNavigationBarItem(
                      icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_outline)),
                      label: 'Profil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}