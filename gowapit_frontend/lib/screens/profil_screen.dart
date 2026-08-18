import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'faq_screen.dart';
import 'terms_privacy_screen.dart';
import 'hubungi_kami_screen.dart';
import 'voucher_saya_screen.dart';
import 'admin_panel_screen.dart';
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
  String _role = "user";
  int? _referredBy;
  int _voucherCount = 0;
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
          _referralCode = data['referral_code'] ?? 'WAPIT-0000';
          _role = data['role'] ?? 'user';
          _referredBy = data['referred_by'];
          _isLoading = false;
        });

        // Fetch voucher count
        try {
          final vRes = await http.get(
            ApiConfig.uri("/api/user/vouchers"),
            headers: {"Authorization": "Bearer $token"},
          );
          if (vRes.statusCode == 200 && mounted) {
            final vData = jsonDecode(vRes.body)['data'] as List?;
            final available = (vData ?? []).where((v) => v['status'] == 'tersedia').length;
            setState(() => _voucherCount = available);
          }
        } catch (_) {}
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                Clipboard.setData(ClipboardData(text: _referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Kode Referral $_referralCode berhasil disalin!")),
                                );
                              },
                            )
                          ],
                        ),
                        if (_role != 'admin' && _referredBy == null) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _showClaimReferralModal,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.card_giftcard_rounded, color: primaryColor, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Punya Kode Teman? Klaim Voucher",
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- 3. VOUCHER & REWARD --
                  _buildSectionHeader("VOUCHER & REWARD", primaryColor),
                  _buildMenuContainer(cardColor, ambientShadow, [
                    _buildListItem(
                      Icons.confirmation_num_outlined,
                      "Voucher Saya",
                      textColor,
                      iconBgColor,
                      primaryColor,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_voucherCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "$_voucherCount Tersedia",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VoucherSayaScreen())).then((_) => _fetchUserData()),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // -- 4. ADMINISTRATOR (Jika Role Admin) --
                  if (_role == 'admin') ...[
                    _buildSectionHeader("ADMINISTRATOR", Colors.amber.shade800),
                    _buildMenuContainer(cardColor, ambientShadow, [
                      _buildListItem(
                        Icons.admin_panel_settings_outlined,
                        "Panel Admin (Voucher & Referral)",
                        textColor,
                        iconBgColor,
                        Colors.amber.shade800,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminPanelScreen())).then((_) => _fetchUserData()),
                      ),
                    ]),
                    const SizedBox(height: 24),
                  ],

                  // -- 5. PENGATURAN TEMA & BAHASA --
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

                  // -- 6. PUSAT BANTUAN & LEGAL --
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
                    _buildDivider(dividerColor),
                    _buildListItem(
                      Icons.contact_mail_outlined, "Hubungi Kami", textColor, iconBgColor, primaryColor,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HubungiKamiScreen())),
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

  void _showClaimReferralModal() {
    final codeCtrl = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
        final Color cardBg = isDark ? const Color(0xFF1E2623) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final Color primaryColor = const Color(0xFF5E9190);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Klaim Kode Referral Teman",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Masukkan kode referral teman Anda untuk mendapatkan voucher diskon tiket wisata Go Wapit!",
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    decoration: InputDecoration(
                      hintText: "Contoh: BUDI-1234",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.card_giftcard_rounded, color: primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final kode = codeCtrl.text.trim().toUpperCase();
                              if (kode.isEmpty) return;

                              setModalState(() => isSubmitting = true);
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('jwt_token');

                                final res = await http.post(
                                  ApiConfig.uri("/api/referral/use"),
                                  headers: {
                                    "Authorization": "Bearer $token",
                                    "Content-Type": "application/json",
                                  },
                                  body: jsonEncode({"kode_referral": kode}),
                                );

                                final resData = jsonDecode(res.body);
                                if (res.statusCode == 200) {
                                  Navigator.pop(modalCtx);
                                  _fetchUserData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Selamat! Kode referral berhasil diklaim & voucher telah ditambahkan ke akun Anda.")),
                                  );
                                } else {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(content: Text(resData['detail'] ?? "Gagal mengklaim kode referral")),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  SnackBar(content: Text("Terjadi kesalahan: $e")),
                                );
                              } finally {
                                setModalState(() => isSubmitting = false);
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Klaim Reward Voucher", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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