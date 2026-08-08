import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import '../main.dart';

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

    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        // Langsung ke Home Dashboard jika sudah login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigator()),
        );
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
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        // --- GRADIENT BACKGROUND KHAS GO WAPIT ---
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
                ? [const Color(0xFF23362F), const Color(0xFF121212)] 
                : [const Color(0xFF659287), const Color(0xFF88BDA4), const Color(0xFFE6F2DD)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO TENGAH ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.park_rounded, // Ikon pohon/alam
                    color: Color(0xFF659287),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Go Wapit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}