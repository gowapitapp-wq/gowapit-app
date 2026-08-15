import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/onboarding_screen.dart';
import 'screens/profil_screen.dart'; // Sesuaikan nama file jika berbeda
import 'theme_notifier.dart';
import 'screens/peta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tiket_screen.dart';
import 'screens/scanner_screen.dart';
import 'widgets/floating_dock.dart';

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

          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFF162524), // Light Blue Dark tint
                          Color(0xFF17241C), // Celadon Dark tint
                          Color(0xFF101614), // Base Dark
                        ]
                      : const [
                          Color(0xFF9DC3C2), // Light Blue
                          Color(0xFFB3D89C), // Celadon
                          Color(0xFFD0EFB1), // Tea Green
                        ],
                  stops: const [0.0, 0.55, 1.0],
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
              primary: Color(0xFF5E9190), // Contras Light Blue for text/action
              secondary: Color(0xFFB3D89C), // Celadon
              tertiary: Color(0xFFD0EFB1), // Tea Green
              surface: Color(0xFFFFFFFF),
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
              primary: Color(0xFF9DC3C2), // Light Blue
              secondary: Color(0xFFB3D89C), // Celadon
              tertiary: Color(0xFFD0EFB1), // Tea Green
              surface: Color(0xFF1A2420),
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
    _checkLoginSession();
  }

  Future<void> _checkLoginSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');
    final String? role = prefs.getString('user_role');

    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        // Jika akun ber-role Petugas, langsung ke halaman Scanner Petugas (tanpa dock)
        if (role == 'petugas' || role == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen(isStaffPortal: true)),
          );
        } else {
          // Pengunjung biasa ke Home Dashboard (dengan dock navigasi)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigator()),
          );
        }
      } else {
        // Ke halaman Onboarding jika belum login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
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
    return Scaffold(
      backgroundColor: Colors.transparent, // Biarkan gradien belakang menembus
      extendBody: true,
      body: _pages[_selectedIndex],

      // Floating Animated Dock Navigation
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
          child: FloatingDock(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemTapped,
            items: const [
              DockItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),
              DockItem(
                icon: Icons.confirmation_number_outlined,
                activeIcon: Icons.confirmation_number_rounded,
                label: 'Tiket',
              ),
              DockItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Peta',
              ),
              DockItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}