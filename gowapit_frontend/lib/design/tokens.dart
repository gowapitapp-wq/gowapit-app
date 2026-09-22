import 'package:flutter/material.dart';

/// Design Tokens untuk Go Wapit App
/// Sumber kebenaran tunggal (Single Source of Truth) berbasis DESIGN.md (Apple Photography-First)
/// dengan adaptasi Aksen Pine (#1E524D) dan Emboss Go Wapit.
abstract class AppTokens {
  AppTokens._();

  // ==================== 1. COLORS ====================
  // Brand & Interactive Accent (Single Accent)
  static const Color actionPine = Color(0xFF1E524D);       // Deep Forest Pine (Light Mode Action)
  static const Color actionPineDark = Color(0xFF76B3AC);   // Mint Pine Accent (Dark Mode Action)
  static const Color actionPineFocus = Color(0xFF286A63);  // Focus state
  static const Color actionPineOnDark = Color(0xFF8FD4C1); // Sky Link on dark tiles

  // Text & Inks
  static const Color ink = Color(0xFF121E1C);              // Primary text on light canvas (#121E1C / #1D1D1F)
  static const Color inkOnDark = Color(0xFFFFFFFF);        // Text on dark tiles
  static const Color inkMuted80 = Color(0xFF333333);       // Slightly softer body
  static const Color inkMuted48 = Color(0xFF7A7A7A);       // Secondary captions & fine print
  static const Color bodyMutedOnDark = Color(0xFFCCCCCC);  // Secondary copy on dark tiles

  // Canvases & Surfaces
  static const Color canvas = Color(0xFFFFFFFF);           // Dominant white canvas
  static const Color canvasParchment = Color(0xFFF5F5F7);  // Apple Parchment (alternating light tile)
  static const Color surfacePearl = Color(0xFFFAFAFC);     // Near-white for ghost capsules
  static const Color surfaceTile1 = Color(0xFF272729);     // Primary dark tile surface
  static const Color surfaceTile2 = Color(0xFF2A2A2C);     // Micro-step lighter dark tile
  static const Color surfaceTile3 = Color(0xFF252527);     // Micro-step darker dark tile
  static const Color surfaceBlack = Color(0xFF000000);     // Void & Nav bar
  static const Color surfaceChipTranslucent = Color(0xA3D2D2D7); // rgba(210, 210, 215, 0.64)

  // Hairlines & Borders (No heavy shadows)
  static const Color hairlineLight = Color(0x14000000);    // 1px ~8% black hairline
  static const Color hairlineDark = Color(0x1FFFFFFF);     // 1px ~12% white hairline
  static const Color dividerSoft = Color(0xFFF0F0F0);      // Soft divider

  // Semantic aliases for tiles & labels
  static const Color tileLight = canvas;
  static const Color tileDark = surfaceTile1;
  static const Color labelPrimaryLight = ink;
  static const Color labelPrimaryDark = inkOnDark;
  static const Color labelSecondaryLight = inkMuted48;
  static const Color labelSecondaryDark = bodyMutedOnDark;
  static const Color actionPineLight = actionPine;

  // Status & Badges (Passive status only, non-interactive accent)
  static const Color statusAmber = Color(0xFFE59819);      // Golden Amber rating / status
  static const Color statusRed = Color(0xFFD32F2F);        // Error / expired
  static const Color statusGreen = Color(0xFF2E7D32);      // Success / open
  static const Color statusBlue = Color(0xFF1565C0);       // Info

  // ==================== 2. RADIUS ====================
  static const double r5Val = 5.0;
  static const double r8Val = 8.0;
  static const double r11Val = 11.0;
  static const double r18Val = 18.0;
  static const double pillVal = 9999.0;

  // Semantic radius aliases
  static const double rSm = r5Val;
  static const double rMd = r8Val;
  static const double rLg = r18Val;
  static const double rPill = pillVal;

  static final BorderRadius r5 = BorderRadius.circular(r5Val);
  static final BorderRadius r8 = BorderRadius.circular(r8Val);
  static final BorderRadius r11 = BorderRadius.circular(r11Val);
  static final BorderRadius r18 = BorderRadius.circular(r18Val);
  static final BorderRadius pill = BorderRadius.circular(pillVal);

  // ==================== 3. SPACING ====================
  static const double sXXS = 4.0;
  static const double sXS = 8.0;
  static const double sSM = 12.0;

  // ==================== FONT WEIGHTS & SIZES ====================
  static const FontWeight wLight = FontWeight.w300;
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wSemiBold = FontWeight.w600;
  static const FontWeight wBold = FontWeight.w700;

  static const double fsTitleLg = 20.0;
  static const double fsTitleMd = 18.0;
  static const double fsBody = 15.0;
  static const double fsCaption = 12.0;
  static const double sMD = 17.0;
  static const double sLG = 24.0;
  static const double sXL = 32.0;
  static const double sXXL = 48.0;
  static const double sSection = 80.0;

  // ==================== 4. ELEVATION & SHADOW ====================
  /// Satu-satunya drop shadow resmi DESIGN.md — KHUSUS imajeri/foto produk/destinasi yang bersandar di kanvas
  static const List<BoxShadow> productShadow = [
    BoxShadow(
      color: Color(0x38000000), // rgba(0,0,0, 0.22)
      offset: Offset(0, 5),
      blurRadius: 30,
    ),
  ];

  /// Seluruh kromo & kartu tidak memiliki drop-shadow (flat + hairline border)
  static const List<BoxShadow> noShadow = <BoxShadow>[];

  // ==================== 5. TYPOGRAPHY SCALE (Inter) ====================
  // Ladder bobot ketat DESIGN.md: 300 / 400 / 600 / 700 (tanpa bobot 500)
  static const String fontFamily = 'Inter';

  static const TextStyle heroDisplay = TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    height: 1.07,
    letterSpacing: -0.28,
  );

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    height: 1.10,
    letterSpacing: 0,
  );

  static const TextStyle displayMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    height: 1.47,
    letterSpacing: -0.374,
  );

  static const TextStyle lead = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.14,
    letterSpacing: 0.196,
  );

  static const TextStyle leadAiry = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w300,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle tagline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 21,
    fontWeight: FontWeight.w600,
    height: 1.19,
    letterSpacing: 0.231,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.24,
    letterSpacing: -0.374,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.47,
    letterSpacing: -0.374,
  );

  static const TextStyle denseLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 2.41,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: -0.224,
  );

  static const TextStyle captionStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.29,
    letterSpacing: -0.224,
  );

  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w300,
    height: 1.0,
    letterSpacing: 0,
  );

  static const TextStyle buttonUtility = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.29,
    letterSpacing: -0.224,
  );

  static const TextStyle finePrint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: -0.12,
  );

  static const TextStyle microLegal = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.08,
  );
}

/// Helper extension untuk kemudahan akses context warna & tema
extension AppContextTheme on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get primaryAccent => isDarkMode ? AppTokens.actionPineDark : AppTokens.actionPine;
  Color get textPrimary => isDarkMode ? AppTokens.inkOnDark : AppTokens.ink;
  Color get textMuted => isDarkMode ? AppTokens.bodyMutedOnDark : AppTokens.inkMuted48;
  Color get surfaceCard => isDarkMode ? AppTokens.surfaceTile1 : AppTokens.canvas;
  Color get surfaceParchment => isDarkMode ? AppTokens.surfaceTile2 : AppTokens.canvasParchment;
  Color get hairlineBorder => isDarkMode ? AppTokens.hairlineDark : AppTokens.hairlineLight;
  Border get cardBorder => Border.all(color: hairlineBorder, width: 1);
}
