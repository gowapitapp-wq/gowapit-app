import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import 'login_screen.dart';

class DetailDestinasiPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> allDestinasi;

  const DetailDestinasiPage({super.key, required this.data, required this.allDestinasi});

  @override
  State<DetailDestinasiPage> createState() => _DetailDestinasiPageState();
}

class _DetailDestinasiPageState extends State<DetailDestinasiPage> {
  List<dynamic> _ulasanList = [];
  bool _isLoadingUlasan = true;
  num _avgRating = 0.0;
  int _totalUlasan = 0;
  String? _jwtToken;
  bool _isLoggedIn = false;
  String _userRole = "user";
  Map<String, dynamic>? _myReview;

  // Form state
  int _selectedRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  String? _reviewFotoBase64;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _checkLoginStatus();
    await _fetchUlasan();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (mounted) {
      setState(() {
        _jwtToken = token;
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }

    if (token != null && token.isNotEmpty) {
      try {
        final res = await http.get(
          ApiConfig.uri("/api/users/me"),
          headers: {"Authorization": "Bearer $token"},
        );
        if (res.statusCode == 200 && mounted) {
          final data = jsonDecode(res.body);
          setState(() {
            _userRole = data['role'] ?? 'user';
          });
        }
      } catch (_) {}
    }
  }

  int? get _destinasiId {
    final rawId = widget.data['id'];
    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);
    return null;
  }

  Future<void> _fetchUlasan() async {
    final destId = _destinasiId;
    if (destId == null) {
      if (mounted) setState(() => _isLoadingUlasan = false);
      return;
    }

    try {
      final Map<String, String> headers = {};
      if (_jwtToken != null && _jwtToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_jwtToken';
      }

      final response = await http.get(
        ApiConfig.uri("/api/destinasi/$destId/ulasan"),
        headers: headers,
      );

      if (response.statusCode == 200 && mounted) {
        final resData = jsonDecode(response.body);
        final List<dynamic> list = resData['data'] ?? [];

        Map<String, dynamic>? userReview;
        num sumRating = 0;
        for (var u in list) {
          sumRating += (u['rating'] is num) ? u['rating'] : 0;
          if (u['milik_saya'] == true) {
            userReview = u;
          }
        }

        num avg = list.isNotEmpty ? (sumRating / list.length) : 0.0;

        setState(() {
          _ulasanList = list;
          _myReview = userReview;
          _totalUlasan = list.length;
          _avgRating = avg;
          _isLoadingUlasan = false;

          if (userReview != null) {
            _selectedRating = (userReview['rating'] is num) ? (userReview['rating'] as num).toInt() : 5;
            _reviewController.text = userReview['ulasan'] ?? '';
            _reviewFotoBase64 = userReview['foto'];
          } else {
            _reviewFotoBase64 = null;
          }
        });
      } else {
        if (mounted) setState(() => _isLoadingUlasan = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUlasan = false);
    }
  }

  Future<void> _pickReviewImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _reviewFotoBase64 = "data:image/jpeg;base64,${base64Encode(bytes)}";
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengambil foto: $e")),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2824) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Tambah Foto Ulasan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Montserrat'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E9190).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF5E9190)),
                  ),
                  title: const Text("Ambil Foto dari Kamera", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Potret langsung lokasi atau momen kunjungan Anda", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickReviewImage(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3D89C).withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF5E9190)),
                  ),
                  title: const Text("Pilih dari Galeri", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Pilih foto yang sudah tersimpan di HP Anda", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickReviewImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewImage(String fotoData, {double? height, double? width, BoxFit fit = BoxFit.cover}) {
    if (fotoData.startsWith('data:image')) {
      try {
        final commaIdx = fotoData.indexOf(',');
        final base64Str = commaIdx != -1 ? fotoData.substring(commaIdx + 1) : fotoData;
        return Image.memory(
          base64Decode(base64Str),
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        );
      } catch (_) {
        return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
      }
    } else if (fotoData.startsWith('http://') || fotoData.startsWith('https://')) {
      return Image.network(
        fotoData,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    } else {
      return Image.asset(
        fotoData,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }
  }

  void _showFullscreenImage(String fotoData) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildReviewImage(fotoData, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 18,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masuk terlebih dahulu untuk memberikan ulasan.")),
      );
      return;
    }

    final destId = _destinasiId;
    if (destId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        ApiConfig.uri("/api/destinasi/$destId/ulasan"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_jwtToken",
        },
        body: jsonEncode({
          "rating": _selectedRating,
          "ulasan": _reviewController.text.trim(),
          "foto": _reviewFotoBase64,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          final res = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? "Ulasan berhasil disimpan!")),
          );
          await _fetchUlasan();
        } else {
          final res = jsonDecode(response.body);
          final msg = ApiConfig.extractErrorMessage(res['detail'], fallback: "Gagal menyimpan ulasan");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: ${ApiConfig.extractErrorMessage(e)}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteReview() async {
    final destId = _destinasiId;
    if (destId == null || !_isLoggedIn) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Ulasan", style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin menghapus ulasan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.delete(
        ApiConfig.uri("/api/destinasi/$destId/ulasan"),
        headers: {
          "Authorization": "Bearer $_jwtToken",
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ulasan berhasil dihapus.")),
          );
          _reviewController.clear();
          _reviewFotoBase64 = null;
          _selectedRating = 5;
          _myReview = null;
          await _fetchUlasan();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal menghapus ulasan."), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan jaringan."), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Palet Warna
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFD0EFB1); 
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white; 
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    final String nama = widget.data['name'] ?? widget.data['nama'] ?? 'Destinasi Wapit';
    final String deskripsi = widget.data['deskripsi_panjang'] ?? widget.data['deskripsi_pendek'] ?? widget.data['deskripsi_singkat'] ?? 'Deskripsi tidak tersedia.';
    String rawGambar = widget.data['image'] ?? widget.data['gambar'] ?? 'assets/images/placeholder.jpeg';
    final String gambar = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';

    // Menyaring destinasi lain
    final List<dynamic> wisataLain = widget.allDestinasi.where((item) {
      final itemName = item['name'] ?? item['nama'];
      return itemName != nama;
    }).toList();

    return Scaffold(
      backgroundColor: cardColor, 
      body: CustomScrollView(
        slivers: [
          // --- HEADER GAMBAR ---
          SliverAppBar(
            expandedHeight: 420.0, 
            pinned: true,
            stretch: true,
            backgroundColor: isDarkMode ? bgColor : Colors.white,
            elevation: 0,
            leadingWidth: 66,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8, bottom: 8),
              child: _buildGlassButton(
                icon: Icons.arrow_back_ios_new, 
                size: 18, 
                onTap: () => Navigator.pop(context)
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    gambar, 
                    fit: BoxFit.cover, 
                    errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 50, color: Colors.grey))
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, 
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4), 
                          Colors.transparent, 
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6) 
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- KONTEN DETAIL ---
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)), 
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -10))
                ]
              ),
              transform: Matrix4.translationValues(0.0, -40.0, 0.0), 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Geser
                    Center(
                      child: Container(
                        width: 48, height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),

                    // --- Sapaan & Judul ---
                    Text("Halo Petualang!", style: TextStyle(fontFamily: 'Montserrat', fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text("Jelajahi $nama", style: TextStyle(fontFamily: 'Inter', fontSize: 16, color: subTextColor, fontWeight: FontWeight.w500)),
                    
                    const SizedBox(height: 32),

                    // --- 3 Ikon Indikator ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPremiumIconInfo(Icons.location_on, primaryColor, nama.length > 12 ? "${nama.substring(0, 10)}..." : nama, textColor, subTextColor),
                        _buildPremiumIconInfo(Icons.explore, primaryColor, "1,5 KM", textColor, subTextColor),
                        _buildPremiumIconInfo(Icons.park, primaryColor, "Akses Mudah", textColor, subTextColor),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1.5),
                    ),

                    // --- Deskripsi ---
                    Text("Deskripsi", style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 16),
                    Text(
                      deskripsi, 
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.7, color: subTextColor, letterSpacing: 0.2), 
                      textAlign: TextAlign.justify
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1.5),
                    ),

                    // ==========================================
                    // --- FITUR ULASAN & RATING ---
                    // ==========================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Ulasan & Rating", style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                        if (_totalUlasan > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$_totalUlasan Ulasan",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1. Ringkasan Rating
                    _buildRatingSummaryCard(cardColor, textColor, subTextColor, primaryColor, isDarkMode),
                    const SizedBox(height: 24),

                    // 2. Form Tulis / Edit Ulasan
                    _buildReviewForm(cardColor, textColor, subTextColor, primaryColor, isDarkMode),
                    const SizedBox(height: 24),

                    // 3. Daftar Ulasan Wisatawan
                    Text("Ulasan Wisatawan", style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 12),
                    _buildReviewList(cardColor, textColor, subTextColor, primaryColor, isDarkMode),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1.5),
                    ),

                    // --- Wisata Lain ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Wisata Lain", style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                        Icon(Icons.arrow_forward, color: primaryColor, size: 20)
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140, 
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none, 
                        itemCount: wisataLain.length,
                        itemBuilder: (context, index) {
                          final itemLain = wisataLain[index];
                          final itemLainName = itemLain['name'] ?? itemLain['nama'] ?? '-';
                          String rawLainImg = itemLain['image'] ?? itemLain['gambar'] ?? 'assets/images/placeholder.jpeg';
                          final lainImg = rawLainImg.startsWith('assets/') ? rawLainImg : 'assets/$rawLainImg';

                          return GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => DetailDestinasiPage(
                                  data: itemLain, 
                                  allDestinasi: widget.allDestinasi,
                                )
                              )
                            ),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isDarkMode ? [] : [BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.20), blurRadius: 12, offset: const Offset(0, 6))],
                                image: DecorationImage(
                                  image: AssetImage(lainImg),
                                  fit: BoxFit.cover,
                                )
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)])
                                ),
                                alignment: Alignment.bottomLeft,
                                padding: const EdgeInsets.all(12),
                                child: Text(itemLainName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Montserrat')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET RATING SUMMARY ---
  Widget _buildRatingSummaryCard(Color cardColor, Color textColor, Color subTextColor, Color primaryColor, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF4F9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _avgRating > 0 ? _avgRating.toStringAsFixed(1) : "0.0",
                style: TextStyle(fontFamily: 'Montserrat', fontSize: 36, fontWeight: FontWeight.w900, color: textColor),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < _avgRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                _totalUlasan > 0 ? "Berdasarkan $_totalUlasan ulasan" : "Belum ada ulasan",
                style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter'),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, color: primaryColor, size: 28),
                const SizedBox(height: 4),
                Text(
                  "Puas & Nyaman",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET REVIEW FORM ---
  Widget _buildReviewForm(Color cardColor, Color textColor, Color subTextColor, Color primaryColor, bool isDarkMode) {
    if (!_isLoggedIn) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF242426) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Ingin memberikan ulasan?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  Text("Masuk ke akun Anda untuk menilai.", style: TextStyle(fontSize: 11, color: subTextColor)),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                await _checkLoginStatus();
                await _fetchUlasan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text("Masuk", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final bool isEditing = _myReview != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF242426) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEditing ? "Ulasan Anda (Edit)" : "Tulis Ulasan Anda",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor, fontFamily: 'Montserrat'),
              ),
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: "Hapus Ulasan",
                  onPressed: _isSubmitting ? null : _deleteReview,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Star Picker
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = starValue;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    starValue <= _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Review Text Field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: textColor),
            decoration: InputDecoration(
              hintText: "Tulis pengalaman atau saran Anda tentang tempat ini (opsional)...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF9FBF9),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Photo Attachment Section
          if (_reviewFotoBase64 != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
              ),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildReviewImage(
                      _reviewFotoBase64!,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                            tooltip: "Ganti Foto",
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: _showImagePickerOptions,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
                            tooltip: "Hapus Foto",
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _reviewFotoBase64 = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _showImagePickerOptions,
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: const Text("Tambah Foto dari Kamera / Galeri", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReview,
              icon: _isSubmitting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(isEditing ? Icons.check : Icons.send, size: 16),
              label: Text(isEditing ? "Simpan Perubahan" : "Kirim Ulasan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET REVIEW LIST ---
  Widget _buildReviewList(Color cardColor, Color textColor, Color subTextColor, Color primaryColor, bool isDarkMode) {
    if (_isLoadingUlasan) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: CircularProgressIndicator(color: primaryColor)));
    }

    if (_ulasanList.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF242426) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            "Belum ada ulasan untuk destinasi ini.\nJadilah yang pertama memberikan ulasan!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
          ),
        ),
      );
    }

    return Column(
      children: _ulasanList.map((u) {
        final String namaUser = u['nama_user'] ?? 'Wisatawan';
        final int rating = (u['rating'] is num) ? (u['rating'] as num).toInt() : 5;
        final String ulasanText = u['ulasan'] ?? '';
        final String? fotoUlasan = u['foto'];
        final bool isMine = u['milik_saya'] == true;
        final String? dateStr = u['created_at'];
        final int ulasanId = u['id'];
        final String? balasanText = u['balasan'];
        final String? balasanBy = u['balasan_by'];
        final String? balasanAt = u['balasan_at'];

        String formattedDate = "";
        if (dateStr != null && dateStr.length >= 10) {
          formattedDate = dateStr.substring(0, 10);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF242426) : const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isMine ? primaryColor.withValues(alpha: 0.5) : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    child: Text(
                      namaUser.isNotEmpty ? namaUser[0].toUpperCase() : 'U',
                      style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(namaUser, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                            if (isMine) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text("Anda", style: TextStyle(color: primaryColor, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        if (formattedDate.isNotEmpty)
                          Text(formattedDate, style: TextStyle(fontSize: 10, color: subTextColor)),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        starIdx < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
              if (ulasanText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  ulasanText,
                  style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.9), height: 1.4, fontFamily: 'Inter'),
                ),
              ],
              if (fotoUlasan != null && fotoUlasan.isNotEmpty) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showFullscreenImage(fotoUlasan),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildReviewImage(
                          fotoUlasan,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("Lihat", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // --- KOTAK BALASAN PENGELOLA ---
              if (balasanText != null && balasanText.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(color: primaryColor, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(
                            balasanBy ?? "Pengelola Go Wapit",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryColor),
                          ),
                          if (balasanAt != null && balasanAt.length >= 10) ...[
                            const Spacer(),
                            Text(
                              balasanAt.substring(0, 10),
                              style: TextStyle(fontSize: 10, color: subTextColor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        balasanText,
                        style: TextStyle(fontSize: 12, color: textColor, height: 1.4, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ],

              // --- TOMBOL AKSI ADMIN ---
              if (_userRole == 'admin') ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _showReplyModal(ulasanId, currentBalasan: balasanText),
                      icon: Icon(Icons.reply_rounded, size: 14, color: primaryColor),
                      label: Text(
                        balasanText != null && balasanText.isNotEmpty ? "Edit Balasan" : "Balas Ulasan",
                        style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (balasanText != null && balasanText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _deleteReply(ulasanId),
                        icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                        label: const Text(
                          "Hapus Balasan",
                          style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showReplyModal(int ulasanId, {String? currentBalasan}) {
    final destId = _destinasiId;
    if (destId == null) return;

    final balasanCtrl = TextEditingController(text: currentBalasan ?? "");
    bool isSavingReply = false;

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
                    currentBalasan != null ? "Edit Balasan Pengelola" : "Tulis Balasan Pengelola",
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: balasanCtrl,
                    maxLines: 4,
                    style: TextStyle(color: textColor, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Tulis tanggapan atau ucapan terima kasih untuk wisatawan...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: isSavingReply
                          ? null
                          : () async {
                              final text = balasanCtrl.text.trim();
                              if (text.isEmpty) return;

                              setModalState(() => isSavingReply = true);
                              try {
                                final res = await http.post(
                                  ApiConfig.uri("/api/destinasi/$destId/ulasan/$ulasanId/balasan"),
                                  headers: {
                                    "Authorization": "Bearer $_jwtToken",
                                    "Content-Type": "application/json",
                                  },
                                  body: jsonEncode({"balasan": text}),
                                );

                                if (res.statusCode == 200) {
                                  Navigator.pop(modalCtx);
                                  _fetchUlasan();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Balasan pengelola berhasil dikirim!")),
                                  );
                                } else {
                                  final errData = jsonDecode(res.body);
                                  final msg = ApiConfig.extractErrorMessage(errData['detail'], fallback: "Gagal mengirim balasan");
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(content: Text(msg)),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(modalCtx).showSnackBar(
                                  SnackBar(content: Text("Error: ${ApiConfig.extractErrorMessage(e)}")),
                                );
                              } finally {
                                setModalState(() => isSavingReply = false);
                              }
                            },
                      child: isSavingReply
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Kirim Balasan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _deleteReply(int ulasanId) async {
    final destId = _destinasiId;
    if (destId == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Balasan"),
        content: const Text("Apakah Anda yakin ingin menghapus balasan pengelola untuk ulasan ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(
        ApiConfig.uri("/api/destinasi/$destId/ulasan/$ulasanId/balasan"),
        headers: {"Authorization": "Bearer $_jwtToken"},
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Balasan pengelola berhasil dihapus!")),
        );
        _fetchUlasan();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus balasan: $e")),
        );
      }
    }
  }

  // --- WIDGET KUSTOM ---

  Widget _buildGlassButton({required IconData icon, Color iconColor = Colors.white, double size = 20, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumIconInfo(IconData icon, Color primaryColor, String label, Color textColor, Color subTextColor) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08), 
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withValues(alpha: 0.2), width: 1)
            ),
            child: Icon(icon, color: primaryColor, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor, fontFamily: 'Inter'),
            maxLines: 2, overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }
}