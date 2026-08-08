import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoginMode = true; // Mengontrol switch antar Login dan Daftar
  final _formKey = GlobalKey<FormState>(); 
  bool _isLoading = false; 
  bool _obscurePassword = true; // Untuk kontrol icon mata (hide/show password)
  
  final TextEditingController _nameController = TextEditingController(); 
  final TextEditingController _emailController = TextEditingController(); 
  final TextEditingController _passwordController = TextEditingController(); 

  // --- LOGIKA AUTENTIKASI API ---
  Future<void> _submitAuth() async {
    if (!_formKey.currentState!.validate()) return; 

    setState(() { _isLoading = true; }); 

    final Uri authUri = ApiConfig.uri(isLoginMode ? "/api/login" : "/api/register");
    
    final Map<String, String> bodyData = isLoginMode 
      ? {"email": _emailController.text.trim(), "password": _passwordController.text} 
      : {"nama_lengkap": _nameController.text.trim(), "email": _emailController.text.trim(), "password": _passwordController.text}; 

    try {
      final response = await http.post(
        authUri, 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(bodyData), 
      );

      final responseData = jsonDecode(response.body); //[cite: 5]
      if (!mounted) return; //[cite: 5]

      if (response.statusCode == 200) { //[cite: 5]
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["message"] ?? "Berhasil!"))); //[cite: 5]
        
        if (isLoginMode) {
          final String token = responseData['access_token'] ?? '';  //[cite: 5]
          final prefs = await SharedPreferences.getInstance(); //[cite: 5]
          await prefs.setString('jwt_token', token); //[cite: 5]

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigator()), //[cite: 5]
            );
          }
        } else {
          setState(() => isLoginMode = true); //[cite: 5]
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(responseData["detail"] ?? "Terjadi kesalahan"))); //[cite: 5]
      }
    } catch (e) {
      if (!mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal terhubung ke server backend (${ApiConfig.baseUrl}). Pastikan server FastAPI berjalan."),
          duration: const Duration(seconds: 4),
        ),
      ); 
    } finally {
      if (mounted) setState(() { _isLoading = false; }); //[cite: 5]
    }
  }

  // --- LOGIKA GOOGLE SIGN IN ---
  Future<void> _loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(); //[cite: 5]
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn(); //[cite: 5]
      if (googleUser != null && mounted) { //[cite: 5]
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Google Berhasil: ${googleUser.email}"))); //[cite: 5]
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Sign-In dibatalkan atau error."))); //[cite: 5]
    }
  }

  // --- LOGIKA APPLE SIGN IN ---
  Future<void> _loginWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential( //[cite: 5]
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], //[cite: 5]
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Apple Berhasil: ${credential.email}"))); //[cite: 5]
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Apple Sign-In dibatalkan atau error."))); //[cite: 5]
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Palet Warna Adaptif
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F9F4); // Sedikit kebiruan/hijau pucat khas referensi
    final Color primaryColor = isDark ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    final Color fieldColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF161d1b);
    final Color shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF659287).withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ==========================================
          // 1. DEKORASI BACKGROUND (GAYA REFERENSI)
          // ==========================================
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withValues(alpha: 0.1)),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withValues(alpha: 0.15)),
            ),
          ),

          // ==========================================
          // 2. KONTEN UTAMA
          // ==========================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
                child: Form(
                  key: _formKey, //[cite: 5]
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- IKON 3D & TITIK DEKORATIF ---
                      SizedBox(
                        height: 140,
                        width: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ikon 3D Utama
                            Image.asset(
                              'images/3d_login.png', // <-- Masukkan gambar 3D Anda di sini
                              height: 100, width: 100, fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.hub_rounded, size: 80, color: primaryColor),
                            ),
                            // Hiasan Titik (Seperti di referensi)
                            Positioned(top: 10, left: 10, child: _buildDot(6, primaryColor)),
                            Positioned(bottom: 20, right: 10, child: _buildDot(8, primaryColor.withValues(alpha: 0.5))),
                            Positioned(top: 40, right: 0, child: _buildDot(5, primaryColor)),
                            Positioned(bottom: 30, left: 0, child: _buildDot(10, primaryColor.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- TAB MENU (SIGN IN / SIGN UP) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTabItem("MASUK", isLoginMode, primaryColor, () => setState(() => isLoginMode = true)),
                          _buildTabItem("DAFTAR", !isLoginMode, primaryColor, () => setState(() => isLoginMode = false)),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // --- FORM INPUT ---
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          key: ValueKey<bool>(isLoginMode),
                          children: [
                            // Field Nama (Hanya muncul jika Daftar)
                            if (!isLoginMode) ...[ //[cite: 5]
                              _buildTextField(
                                controller: _nameController, //[cite: 5]
                                hint: "Nama Lengkap",
                                icon: Icons.person_outline,
                                fieldColor: fieldColor,
                                shadowColor: shadowColor,
                                validator: (v) => v!.isEmpty ? "Nama tidak boleh kosong" : null, //[cite: 5]
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            // Field Email
                            _buildTextField(
                              controller: _emailController, //[cite: 5]
                              hint: "Email",
                              icon: Icons.email_outlined,
                              fieldColor: fieldColor,
                              shadowColor: shadowColor,
                              validator: (v) => v!.isEmpty ? "Email tidak boleh kosong" : null, //[cite: 5]
                            ),
                            const SizedBox(height: 20),
                            
                            // Field Password
                            _buildTextField(
                              controller: _passwordController, //[cite: 5]
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              fieldColor: fieldColor,
                              shadowColor: shadowColor,
                              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                              validator: (v) => v!.length < 6 ? "Password minimal 6 karakter" : null, //[cite: 5]
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // --- TOMBOL SUBMIT UTAMA (GAYA REFERENSI) ---
                      GestureDetector(
                        onTap: _isLoading ? null : _submitAuth, //[cite: 5]
                        child: Column(
                          children: [
                            _isLoading //[cite: 5]
                              ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3)) //[cite: 5]
                              : Text(
                                  isLoginMode ? "MASUK" : "DAFTAR",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Montserrat', letterSpacing: 1.2),
                                ),
                            const SizedBox(height: 6),
                            if (!_isLoading) //[cite: 5]
                              Container(height: 3, width: 40, decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(10))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- FORGOT PASSWORD ---
                      if (isLoginMode)
                        Text("Lupa password Anda?", style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
                      
                      const SizedBox(height: 40),

                      // --- SOSIAL LOGIN ---
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Divider(thickness: 1),
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(Icons.g_mobiledata, Colors.red, fieldColor, shadowColor, _loginWithGoogle), //[cite: 5]
                          const SizedBox(width: 20),
                          _buildSocialButton(Icons.apple, textColor, fieldColor, shadowColor, _loginWithApple), //[cite: 5]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS (Custom Components)
  // ==========================================

  // Widget Titik Dekoratif 3D
  Widget _buildDot(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)]),
    );
  }

  // Widget Menu Tab "SIGN IN / SIGN UP"
  Widget _buildTabItem(String title, bool isActive, Color primaryColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? primaryColor : Colors.grey.shade400,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 70, // Lebar garis bawah
            color: isActive ? primaryColor : Colors.grey.shade300,
          )
        ],
      ),
    );
  }

  // Widget Text Field bergaya Neumorphic (Kapsul)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required Color fieldColor,
    required Color shadowColor,
    required String? Function(String?) validator,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(30), // Bentuk kapsul
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400, size: 20),
                  onPressed: onTogglePassword,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // Widget Tombol Sosial (Lingkaran)
  Widget _buildSocialButton(IconData icon, Color iconColor, Color bgColor, Color shadowColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, size: 30, color: iconColor),
      ),
    );
  }
}