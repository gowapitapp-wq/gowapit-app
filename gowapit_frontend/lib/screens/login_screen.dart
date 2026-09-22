import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../auth/auth_service.dart';
import '../main.dart';
import 'terms_privacy_screen.dart';
import 'scanner_screen.dart';
import '../design/tokens.dart';

class LoginScreen extends StatefulWidget {
  final bool initialRegisterMode;
  const LoginScreen({super.key, this.initialRegisterMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late bool isLoginMode;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    isLoginMode = !widget.initialRegisterMode;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  // --- LOGIKA AUTENTIKASI VIA AUTH SERVICE (EMAIL & PASSWORD) ---
  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthResult res = isLoginMode
          ? await AuthService.instance.signInWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            )
          : await AuthService.instance.signUpWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
              _nameController.text.trim(),
              referralCode: _referralCodeController.text.trim(),
            );

      if (!mounted) return;

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLoginMode ? "Login Berhasil!" : "Pendaftaran Berhasil! Selamat datang di Go Wapit."),
            backgroundColor: AppTokens.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
          ),
        );

        final String role = res.role ?? 'user';
        if (role == 'petugas' || role == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen(isStaffPortal: true)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigator()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppTokens.statusRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan autentikasi: ${e.toString()}"),
          backgroundColor: AppTokens.statusRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA GOOGLE SIGN IN VIA AUTH SERVICE ---
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final AuthResult res = await AuthService.instance.signInWithGoogle();

      if (!mounted) return;

      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message.isEmpty ? "Login Google Berhasil!" : res.message),
            backgroundColor: AppTokens.statusGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
          ),
        );

        final String role = res.role ?? 'user';
        if (role == 'petugas' || role == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ScannerScreen(isStaffPortal: true)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigator()),
          );
        }
      } else {
        if (!res.message.contains("dibatalkan")) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.message),
              backgroundColor: AppTokens.statusRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan Google Sign-In: $error"),
          backgroundColor: AppTokens.statusRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.r18,
          side: BorderSide(color: context.hairlineBorder),
        ),
        title: Row(
          children: [
            Icon(Icons.lock_reset, color: context.primaryAccent),
            const SizedBox(width: AppTokens.sXS),
            Text("Lupa Password?", style: AppTokens.tagline.copyWith(color: context.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.",
              style: AppTokens.caption.copyWith(color: context.textMuted),
            ),
            const SizedBox(height: AppTokens.sMD),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontFamily: AppTokens.fontFamily, color: context.textPrimary),
              decoration: InputDecoration(
                hintText: "nama@email.com",
                prefixIcon: const Icon(Icons.email_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: AppTokens.pill),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: TextStyle(color: context.textMuted, fontFamily: AppTokens.fontFamily)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryAccent,
              foregroundColor: context.isDarkMode ? AppTokens.surfaceBlack : AppTokens.canvas,
              shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
            ),
            onPressed: () async {
              final String emailTarget = resetEmailController.text.trim();
              Navigator.pop(ctx);
              if (emailTarget.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Silakan masukkan alamat email yang valid."),
                    backgroundColor: AppTokens.statusRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
                  ),
                );
                return;
              }

              final res = await AuthService.instance.sendPasswordResetEmail(emailTarget);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.message),
                    backgroundColor: res.isSuccess ? AppTokens.statusGreen : AppTokens.statusRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
                  ),
                );
              }
            },
            child: const Text("Kirim Tautan"),
          ),
        ],
      ),
    );
  }

  // --- LOGO EMBOSS TRANSPARAN DI BELAKANG ELEMEN KARTU ---
  Widget _buildEmbossedWatermark(bool isDark) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(3.0, 3.0),
                  child: Opacity(
                    opacity: isDark ? 0.08 : 0.05,
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                      color: isDark ? Colors.black : AppTokens.actionPine,
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-2.5, -2.5),
                  child: Opacity(
                    opacity: isDark ? 0.05 : 0.60,
                    child: Image.asset(
                      'assets/images/Logo.png',
                      fit: BoxFit.contain,
                      color: isDark ? AppTokens.actionPineDark : Colors.white,
                    ),
                  ),
                ),
                Opacity(
                  opacity: isDark ? 0.04 : 0.03,
                  child: Image.asset(
                    'assets/images/Logo.png',
                    fit: BoxFit.contain,
                    color: isDark ? Colors.white : AppTokens.actionPine,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color primaryPine = context.primaryAccent;
    final Color cardBg = context.surfaceCard;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;

    return Scaffold(
      backgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: AppTokens.sLG),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: AppTokens.r18,
                    border: Border.all(color: context.hairlineBorder, width: 1.0),
                  ),
                  child: ClipRRect(
                    borderRadius: AppTokens.r18,
                    child: Stack(
                      children: [
                        _buildEmbossedWatermark(isDark),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // --- ANIMATED LOTTIE LOGO ---
                                Center(
                                  child: SizedBox(
                                    height: 84,
                                    width: 84,
                                    child: Lottie.asset(
                                      'assets/lottie/login.json',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: AppTokens.canvas,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: context.hairlineBorder),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Image.asset('assets/images/Logo.png', fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTokens.sXS),

                                // --- TITLE & SUBTITLE ---
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Column(
                                    key: ValueKey<bool>(isLoginMode),
                                    children: [
                                      Text(
                                        isLoginMode ? "Selamat Datang" : "Buat Akun",
                                        textAlign: TextAlign.center,
                                        style: AppTokens.lead.copyWith(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppTokens.sXXS),
                                      Text(
                                        isLoginMode
                                            ? "Masuk untuk menjelajahi Hutan Pinus Wapit"
                                            : "Daftar untuk reservasi & kemudahan wisata",
                                        textAlign: TextAlign.center,
                                        style: AppTokens.caption.copyWith(
                                          color: subTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTokens.sLG),

                                // --- SOCIAL AUTH BUTTON (GOOGLE GHOST PILL) ---
                                _buildSocialButton(
                                  onPressed: _isLoading ? null : _loginWithGoogle,
                                  isDark: isDark,
                                  icon: const GoogleLogoWidget(size: 18),
                                  label: "Lanjutkan dengan Google",
                                  textColor: textColor,
                                  borderColor: context.hairlineBorder,
                                ),
                                const SizedBox(height: AppTokens.sMD),

                                // --- OR DIVIDER ---
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: context.hairlineBorder)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        isLoginMode ? "atau email" : "atau email",
                                        style: AppTokens.finePrint.copyWith(color: subTextColor),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: context.hairlineBorder)),
                                  ],
                                ),
                                const SizedBox(height: AppTokens.sMD),

                                // --- INPUT FIELDS ---
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Column(
                                    children: [
                                      if (!isLoginMode) ...[
                                        _buildModernField(
                                          controller: _nameController,
                                          hint: "Nama Lengkap",
                                          icon: Icons.person_outline_rounded,
                                          isDark: isDark,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) {
                                              return "Nama lengkap tidak boleh kosong";
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: AppTokens.sSM),
                                      ],
                                      _buildModernField(
                                        controller: _emailController,
                                        hint: "Alamat Email",
                                        icon: Icons.alternate_email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        isDark: isDark,
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return "Email tidak boleh kosong";
                                          }
                                          if (!v.contains('@') || !v.contains('.')) {
                                            return "Format email tidak valid";
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTokens.sSM),
                                      _buildModernField(
                                        controller: _passwordController,
                                        hint: "Kata Sandi",
                                        icon: Icons.lock_outline_rounded,
                                        isPassword: true,
                                        obscureText: _obscurePassword,
                                        isDark: isDark,
                                        onTogglePassword: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return "Kata sandi tidak boleh kosong";
                                          }
                                          if (v.length < 6) {
                                            return "Kata sandi minimal 6 karakter";
                                          }
                                          return null;
                                        },
                                      ),
                                      if (!isLoginMode) ...[
                                        const SizedBox(height: AppTokens.sSM),
                                        _buildModernField(
                                          controller: _referralCodeController,
                                          hint: "Kode Referral (opsional)",
                                          icon: Icons.card_giftcard_rounded,
                                          isDark: isDark,
                                          validator: (v) => null,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // --- FORGOT PASSWORD ---
                                if (isLoginMode) ...[
                                  const SizedBox(height: AppTokens.sXS),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: _showForgotPasswordDialog,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: Text(
                                          "Lupa password?",
                                          style: AppTokens.caption.copyWith(
                                            color: primaryPine,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppTokens.sLG),

                                // --- PRIMARY SUBMIT PILL BUTTON ---
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submitAuth,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPine,
                                      foregroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
                                              strokeWidth: 2.0,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isLoginMode ? "Masuk" : "Daftar",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: AppTokens.fontFamily,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              const SizedBox(width: AppTokens.sXS),
                                              const Icon(Icons.arrow_forward_rounded, size: 16),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: AppTokens.sMD),

                                // --- TOGGLE LOGIN / REGISTER MODE ---
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isLoginMode = !isLoginMode;
                                        _formKey.currentState?.reset();
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: AppTokens.caption.copyWith(
                                            color: subTextColor,
                                            fontFamily: AppTokens.fontFamily,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: isLoginMode
                                                  ? "Belum memiliki akun? "
                                                  : "Sudah memiliki akun? ",
                                            ),
                                            TextSpan(
                                              text: isLoginMode ? "Daftar" : "Masuk",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: primaryPine,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTokens.sSM),

                                // --- TERMS & PRIVACY FOOTER LINK ---
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const TermsPrivacyPage(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Syarat & Kebijakan Privasi",
                                      style: AppTokens.finePrint.copyWith(
                                        color: subTextColor,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildModernField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    final Color fieldBg = isDark ? AppTokens.surfaceTile2 : AppTokens.canvasParchment;
    final Color borderColor = context.hairlineBorder;
    final Color activeColor = context.primaryAccent;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: context.textPrimary,
        fontFamily: AppTokens.fontFamily,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13.5,
          color: context.textMuted,
          fontFamily: AppTokens.fontFamily,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: context.textMuted,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 18,
                  color: context.textMuted,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: BorderSide(color: activeColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required bool isDark,
    required Widget icon,
    required String label,
    required Color textColor,
    required Color borderColor,
  }) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? AppTokens.surfaceTile2 : AppTokens.canvas,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: AppTokens.sXS),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFamily: AppTokens.fontFamily,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- PIXEL-PERFECT LOGO WIDGETS ---

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius * 0.78);

    // Blue arc (Right top)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.785, 1.57, false, paint);

    // Green arc (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.785, 1.57, false, paint);

    // Yellow arc (Left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.355, 1.57, false, paint);

    // Red arc (Top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.925, 1.57, false, paint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      w * 0.46,
      h * 0.40,
      w * 0.50,
      h * 0.20,
    );
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, Radius.circular(w * 0.04)), barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}