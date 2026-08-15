import 'package:flutter/material.dart';

class AppColors {
  // 3 Warna Utama Palette Baru
  static const Color teaGreen = Color(0xFFD0EFB1);
  static const Color celadon = Color(0xFFB3D89C);
  static const Color lightBlue = Color(0xFF9DC3C2);

  // Primary & Secondary Brand Tokens
  static const Color primary = Color(0xFF9DC3C2);
  static const Color secondary = Color(0xFFB3D89C);
  static const Color accent = Color(0xFFD0EFB1);

  // Gradient Global (Light Mode)
  static const List<Color> lightGradient = [
    Color(0xFF9DC3C2), // Light Blue
    Color(0xFFB3D89C), // Celadon
    Color(0xFFD0EFB1), // Tea Green
  ];

  // Gradient Global (Dark Mode)
  static const List<Color> darkGradient = [
    Color(0xFF1A2B2A), // Deep Light Blue hue
    Color(0xFF1B2A20), // Deep Celadon hue
    Color(0xFF121815), // Deep Dark
  ];
}
