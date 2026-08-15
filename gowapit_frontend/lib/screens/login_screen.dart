import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../config/api_config.dart';
import '../main.dart';
import 'terms_privacy_screen.dart';
import 'scanner_screen.dart';

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

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    isLoginMode = !widget.initialRegisterMode;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
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
    super.dispose();
  }

  // --- LOGIKA AUTENTIKASI API (EMAIL & PASSWORD) ---
  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final Uri authUri = ApiConfig.uri(isLoginMode ? "/api/login" : "/api/register");

    final Map<String, String> bodyData = isLoginMode
        ? {
            "email": _emailController.text.trim(),
            "password": _passwordController.text,
          }
        : {
            "nama_lengkap": _nameController.text.trim(),
            "email": _emailController.text.trim(),
            "password": _passwordController.text,
          };

    try {
      final response = await http.post(
        authUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      Map<String, dynamic> responseData = {};
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData["message"] ?? (isLoginMode ? "Login Berhasil!" : "Pendaftaran Berhasil! Silakan Masuk.")),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        if (isLoginMode) {
          final String token = responseData['access_token'] ?? '';
          final String role = (responseData['user'] != null && responseData['user']['role'] != null)
              ? responseData['user']['role']
              : 'user';

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          await prefs.setString('user_role', role);

          if (mounted) {
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
          }
        } else {
          setState(() {
            isLoginMode = true;
            _passwordController.clear();
          });
        }
      } else {
        String detailMessage = responseData["detail"] ?? responseData["message"] ?? "Gagal memproses (Kode: ${response.statusCode})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(detailMessage),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Terjadi gangguan koneksi internet. Silakan coba beberapa saat lagi."),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIKA GOOGLE SIGN IN ---
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: ApiConfig.googleWebClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal mendapatkan ID Token dari Google."),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final Uri authUri = ApiConfig.uri("/api/auth/google");
      final response = await http.post(
        authUri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"id_token": idToken}),
      );

      Map<String, dynamic> responseData = {};
      try {
        responseData = jsonDecode(response.body);
      } catch (_) {}

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData["message"] ?? "Login Google Berhasil!"),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        final String token = responseData['access_token'] ?? '';
        final String role = (responseData['user'] != null && responseData['user']['role'] != null)
            ? responseData['user']['role']
            : 'user';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_role', role);

        if (mounted) {
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
        }
      } else {
        String detailMessage = responseData["detail"] ?? responseData["message"] ?? "Gagal login Google (Kode: ${response.statusCode})";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(detailMessage),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan saat Google Sign-In: $error"),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFF5E9190)),
            SizedBox(width: 10),
            Text("Lupa Password?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Masukkan email akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "nama@email.com",
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E9190),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Tautan pemulihan dikirim ke ${resetEmailController.text.trim().isEmpty ? 'email Anda' : resetEmailController.text.trim()}"),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            child: const Text("Kirim Tautan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDark ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    final Color cardBg = isDark ? const Color(0xFF1B2623) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF162421);
    final Color subTextColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF162524),
                    const Color(0xFF17241C),
                    const Color(0xFF101614),
                  ]
                : [
                    const Color(0xFF9DC3C2),
                    const Color(0xFFB3D89C),
                    const Color(0xFFD0EFB1),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background glowing circles
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9DC3C2).withValues(alpha: isDark ? 0.15 : 0.35),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB3D89C).withValues(alpha: isDark ? 0.12 : 0.30),
                ),
              ),
            ),

            // Main Centered Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 440),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.4)
                                  : const Color(0xFF2A4D41).withValues(alpha: 0.12),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- ANIMATED LOTTIE LOGO ---
                              Center(
                                child: SizedBox(
                                  height: 110,
                                  width: 110,
                                  child: Lottie.asset(
                                    'assets/lottie/login.json',
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.25),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Image.asset(
                                        'assets/images/Logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // --- TITLE & SUBTITLE ---
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: Column(
                                  key: ValueKey<bool>(isLoginMode),
                                  children: [
                                    Text(
                                      isLoginMode ? "Selamat Datang!" : "Buat Akun Baru!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isLoginMode
                                          ? "Masuk untuk menjelajahi keindahan Hutan Pinus Wapit"
                                          : "Daftar untuk menikmati berbagai fasilitas dan kemudahan",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: subTextColor,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // --- SOCIAL AUTH BUTTON (GOOGLE) ---
                              _buildSocialButton(
                                onPressed: _isLoading ? null : _loginWithGoogle,
                                isDark: isDark,
                                icon: const GoogleLogoWidget(size: 20),
                                label: "Lanjutkan dengan Google",
                                backgroundColor: isDark ? const Color(0xFF283830) : Colors.white,
                                textColor: isDark ? Colors.white : const Color(0xFF374151),
                                borderColor: isDark
                                    ? Colors.white.withValues(alpha: 0.15)
                                    : const Color(0xFFE5E7EB),
                              ),
                              const SizedBox(height: 22),

                              // --- OR DIVIDER ---
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      isLoginMode ? "atau masuk dengan email" : "atau daftar dengan email",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // --- INPUT FIELDS ---
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Column(
                                  children: [
                                    // Full Name Field (Register Mode Only)
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
                                      const SizedBox(height: 14),
                                    ],

                                    // Email Field
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
                                    const SizedBox(height: 14),

                                    // Password Field
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
                                  ],
                                ),
                              ),

                              // --- FORGOT PASSWORD (LOGIN MODE) ---
                              if (isLoginMode) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        "Lupa password?",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),

                              // --- PRIMARY SUBMIT BUTTON ---
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shadowColor: primaryColor.withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              isLoginMode ? "Masuk ke Akun" : "Daftar Sekarang",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward_rounded, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),

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
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: subTextColor,
                                          fontFamily: 'Montserrat',
                                        ),
                                        children: [
                                          TextSpan(
                                            text: isLoginMode
                                                ? "Belum memiliki akun? "
                                                : "Sudah memiliki akun? ",
                                          ),
                                          TextSpan(
                                            text: isLoginMode ? "Daftar Sekarang" : "Masuk di Sini",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

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
                                    "Syarat & Ketentuan Privasi",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subTextColor.withValues(alpha: 0.8),
                                      decoration: TextDecoration.underline,
                                      decorationColor: subTextColor.withValues(alpha: 0.5),
                                    ),
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
          ],
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
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    final Color fieldBg = isDark ? const Color(0xFF16221D) : const Color(0xFFF7FAF8);
    final Color borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    const Color activeColor = Color(0xFF5E9190);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13.5,
          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
        ),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: activeColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback? onPressed,
    required bool isDark,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          elevation: backgroundColor == Colors.white ? 0 : 1,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: textColor,
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