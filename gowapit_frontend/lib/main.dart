import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/auth_service.dart';

import 'screens/onboarding_screen.dart';
import 'screens/profil_screen.dart'; // Sesuaikan nama file jika berbeda
import 'theme_notifier.dart';
import 'screens/peta_screen.dart';
import 'screens/home_screen.dart';
import 'screens/tiket_screen.dart';
import 'screens/berita_screen.dart';
import 'screens/scanner_screen.dart';
import 'widgets/floating_dock.dart';
import 'config/api_cache.dart';
import 'config/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init: $e");
  }
  await ApiCache.instance.init();
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
              color: isDark ? const Color(0xFF141917) : Colors.white,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Bayangan Logo Emboss di Background
                  Center(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: isDark ? 0.05 : 0.065,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Lapisan Shadow (Bawah-Kanan) untuk efek kedalaman emboss
                            Transform.translate(
                              offset: const Offset(3.5, 3.5),
                              child: Image.asset(
                                'assets/images/Logo.png',
                                width: 320,
                                fit: BoxFit.contain,
                                color: isDark ? Colors.black : const Color(0xFF2C534F),
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            // Lapisan Highlight (Atas-Kiri) untuk efek timbul emboss
                            Transform.translate(
                              offset: const Offset(-2.5, -2.5),
                              child: Image.asset(
                                'assets/images/Logo.png',
                                width: 320,
                                fit: BoxFit.contain,
                                color: isDark ? const Color(0xFF4A6B65) : Colors.white,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),
                            // Lapisan Siluet Logo Utama
                            Image.asset(
                              'assets/images/Logo.png',
                              width: 320,
                              fit: BoxFit.contain,
                              color: isDark ? const Color(0xFF1E2F2B) : const Color(0xFF5E9190),
                              colorBlendMode: BlendMode.srcIn,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Konten Layar Aplikasi
                  if (child != null) child,
                ],
              ),
            );
          },

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
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
    final user = AuthService.instance.currentUser;
    String? role;
    if (user != null) {
      final syncRes = await AuthService.instance.ensureBackendSynced();
      role = syncRes.role;
    }
    final prefs = await SharedPreferences.getInstance();
    role = role ?? prefs.getString('user_role');

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (AuthService.instance.currentUser != null) {
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
    const BeritaKegiatanPage(),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

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
                icon: Icons.newspaper_outlined,
                activeIcon: Icons.newspaper_rounded,
                label: 'Berita',
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