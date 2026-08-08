import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Palet Warna
    final Color primaryColor = const Color(0xFF659287);
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color bottomBgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;

    return Scaffold(
      backgroundColor: bottomBgColor,
      body: Stack(
        children: [
          // --- 1. BACKGROUND GRADIENT (Memudar ke bawah) ---
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.65,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDarkMode
                      ? [const Color(0xFF23362F), bottomBgColor]
                      : [primaryColor, bottomBgColor],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // --- 2. LOGO DI ATAS ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.park_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Go Wapit",
                      style: TextStyle(
                        color: Colors.white, // Tetap putih karena di atas gradien gelap
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),

                // --- 3. GAMBAR 3D DI TENGAH ---
                Image.asset(
                  'assets/images/3d_onboarding.png', 
                  height: 280,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.travel_explore, size: 120, color: Colors.white),
                  ),
                ),

                const Spacer(flex: 2),

                // --- 4. TEKS & TOMBOL DI BAWAH ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Text(
                        "Eksplorasi Alam.\nKapanpun, Di manapun",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26, 
                          fontWeight: FontWeight.w900, 
                          color: textColor, 
                          fontFamily: 'Montserrat',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // --- TOMBOL 1: MULAI PETUALANGAN ---
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkMode ? primaryColor : const Color(0xFF161d1b),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          // Mengarah ke MainNavigator agar menu bawah muncul
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: const Text("Mulai Petualangan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        "Dengan melanjutkan, Anda menyetujui\nSyarat Layanan dan Kebijakan Privasi kami",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontFamily: 'Inter',
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
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
}