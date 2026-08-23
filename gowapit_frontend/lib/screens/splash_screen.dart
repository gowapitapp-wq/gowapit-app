import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'login_screen.dart';
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
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

    Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        // Langsung ke Home Dashboard jika sudah login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigator()),
        );
      } else if (!onboardingDone) {
        // Ke halaman Onboarding jika belum pernah menyelesaikan onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        // Ke Login jika sudah pernah onboarding
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF141917) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF121E1C);

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- LOGO TENGAH APLIKASI ---
            Image.asset(
              'assets/images/Logo.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E524D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.park_rounded,
                  color: Color(0xFF1E524D),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Go Wapit",
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}