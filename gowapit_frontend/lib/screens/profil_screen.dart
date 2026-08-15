import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'faq_screen.dart';
import 'terms_privacy_screen.dart';
import 'login_screen.dart';
import '../theme_notifier.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  String _namaLengkap = "Memuat...";
  String _email = "Memuat data...";
  String _fotoProfil = "";
  String _referralCode = "WAPIT-0000";
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final response = await http.get(
        ApiConfig.uri("/api/users/me"),
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _namaLengkap = data['nama_lengkap'] ?? 'Petualang Wapit';
          _email = data['email'] ?? 'email@tidak.ditemukan';
          _fotoProfil = data['foto_profil'] ?? '';

          String namaDepan = _namaLengkap.split(' ')[0].toUpperCase();
          namaDepan = namaDepan.replaceAll(RegExp(r'[^A-Z]'), '');
          if (namaDepan.isEmpty) namaDepan = "WAPIT";
          String angkaAcak = (1000 + Random().nextInt(9000)).toString();
          _referralCode = "$namaDepan-$angkaAcak";

          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile(String newName, String newPhotoBase64) async {
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');
      if (token == null) return;

      final response = await http.put(
        ApiConfig.uri("/api/users/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "nama_lengkap": newName,
          "foto_profil": newPhotoBase64,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _namaLengkap = data['user']['nama_lengkap'] ?? newName;
          _fotoProfil = data['user']['foto_profil'] ?? newPhotoBase64;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil berhasil diperbarui!")),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal memperbarui profil di server.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source, TextEditingController nameController, StateSetter setModalState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
        setModalState(() {
          _fotoProfil = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil foto dari galeri.")),
        );
      }
    }
  }

  void _showEditProfileModal() {
    final TextEditingController nameController = TextEditingController(text: _namaLengkap);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
        final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
        final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text("Edit Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                  const SizedBox(height: 20),

                  // Avatar Picker Preview
                  GestureDetector(
                    onTap: () => _showImageSourcePicker(nameController, setModalState),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          backgroundImage: _getAvatarImageProvider(),
                          child: _fotoProfil.isEmpty ? Icon(Icons.person, size: 45, color: primaryColor) : null,
                        ),
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: primaryColor,
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Ketuk untuk mengubah foto", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 20),

                  // Edit Nama Field
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Nama Lengkap",
                      labelStyle: TextStyle(color: primaryColor),
                      prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              String newName = nameController.text.trim();
                              if (newName.isEmpty) return;
                              Navigator.pop(context);
                              await _updateProfile(newName, _fotoProfil);
                            },
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showImageSourcePicker(TextEditingController nameController, StateSetter setModalState) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pilih dari Galeri"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, nameController, setModalState);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Ambil Foto dari Kamera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, nameController, setModalState);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getAvatarImageProvider() {
    if (_fotoProfil.isNotEmpty) {
      if (_fotoProfil.startsWith("data:image")) {
        try {
          String base64Str = _fotoProfil.split(',').last;
          return MemoryImage(base64Decode(base64Str));
        } catch (_) {}
      } else if (_fotoProfil.startsWith("http")) {
        return NetworkImage(_fotoProfil);
      }
    }
    return NetworkImage(_dapatkanUrlGravatar(_email));
  }

  String _dapatkanUrlGravatar(String email) {
    String cleanEmail = email.trim().toLowerCase();
    String md5Hash = md5.convert(utf8.encode(cleanEmail)).toString();
    return "https://www.gravatar.com/avatar/$md5Hash?d=identicon&s=200";
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    final Color dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color iconBgColor = isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFF9DC3C2).withValues(alpha: 0.16);

    final List<BoxShadow> ambientShadow = isDarkMode
        ? []
        : [
            BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.16), blurRadius: 15, offset: const Offset(0, 6))
          ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
          child: CircleAvatar(
            backgroundColor: primaryColor.withValues(alpha: 0.2),
            backgroundImage: _getAvatarImageProvider(),
          ),
        ),
        title: const Text("Go Wapit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22, fontFamily: 'Montserrat')),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -- 1. KARTU PROFIL UTAMA --
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showEditProfileModal,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 3)),
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _getAvatarImageProvider(),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: cardColor, width: 2)),
                                child: const Icon(Icons.edit, color: Colors.white, size: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_namaLengkap, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Montserrat')),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, size: 18, color: primaryColor),
                              onPressed: _showEditProfileModal,
                            )
                          ],
                        ),
                        Text(_email, style: TextStyle(fontSize: 13, color: subTextColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- 2. KARTU KODE REFERRAL --
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("KODE REFERRAL ANDA", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 1.1, fontFamily: 'Montserrat')),
                            const SizedBox(height: 4),
                            Text(_referralCode, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 1.5, fontFamily: 'Montserrat')),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.copy, color: primaryColor),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Kode Referral $_referralCode berhasil disalin!")),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- 3. PENGATURAN TEMA & BAHASA --
                  _buildSectionHeader("PENGATURAN", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(Icons.palette_outlined, "Theme", textColor, iconBgColor, primaryColor, trailing: ValueListenableBuilder<bool>(
                      valueListenable: isDarkModeGlobal,
                      builder: (context, isDark, child) {
                        return Switch(
                          value: isDark,
                          activeTrackColor: primaryColor,
                          onChanged: (val) => isDarkModeGlobal.value = val,
                        );
                      },
                    )),
                  ]),
                  const SizedBox(height: 24),

                  // -- 4. PUSAT BANTUAN & LEGAL --
                  _buildSectionHeader("INFORMASI & SYARAT", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(
                      Icons.help_outline, "FAQ", textColor, iconBgColor, primaryColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqPage())),
                    ),
                    _buildDivider(dividerColor),
                    _buildListItem(
                      Icons.security, "Terms & Privacy Policy", textColor, iconBgColor, primaryColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsPrivacyPage())),
                    ),
                  ]),
                  const SizedBox(height: 32),

                  // -- 5. TOMBOL KELUAR --
                  GestureDetector(
                    onTap: () => _showLogoutDialog(context, isDarkMode),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                      child: const Center(
                        child: Text("Keluar Akun", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Montserrat')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2, fontFamily: 'Montserrat')),
    );
  }

  Widget _buildMenuContainer(Color bgColor, List<BoxShadow> shadow, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
      child: Column(children: children),
    );
  }

  Widget _buildListItem(IconData icon, String title, Color textColor, Color iconBgColor, Color primaryColor, {Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color, indent: 16, endIndent: 16);
  }

  void _showLogoutDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Konfirmasi Keluar", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi Go Wapit?"),
          actions: [
            TextButton(child: const Text("Batal", style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.of(context).pop()),
            TextButton(child: const Text("Keluar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onPressed: () { Navigator.of(context).pop(); _logout(); }),
          ],
        );
      },
    );
  }
}