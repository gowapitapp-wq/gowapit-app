import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme_notifier.dart';
import 'login_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool isStaffPortal;

  const ScannerScreen({super.key, this.isStaffPortal = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();
  late MobileScannerController _cameraController;

  bool _isLoading = false;
  bool _isProcessingScan = false;
  bool _isTorchOn = false;
  bool _isCameraRestarting = false;
  Map<String, dynamic>? _scanResult;
  String? _errorMessage;

  String _staffName = "Petugas Loket Wapit";
  String _staffEmail = "petugas@gowapit.com";
  int _sessionScanCount = 0;
  final List<Map<String, dynamic>> _sessionScanHistory = [];

  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScannerController();
    _loadStaffProfile();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void _initScannerController() {
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController.stop().catchError((_) {});
    } else if (state == AppLifecycleState.resumed) {
      _cameraController.start().catchError((_) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    _cameraController.stop().catchError((_) {});
    _cameraController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _restartCamera() async {
    setState(() => _isCameraRestarting = true);
    try {
      await _cameraController.stop().catchError((_) {});
      await Future.delayed(const Duration(milliseconds: 300));
      await _cameraController.start().catchError((e) {
        debugPrint("Gagal start camera: $e");
      });
    } catch (e) {
      debugPrint("Gagal me-restart kamera: $e");
    } finally {
      if (mounted) {
        setState(() => _isCameraRestarting = false);
      }
    }
  }

  Future<void> _loadStaffProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        ApiConfig.uri('/api/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _staffName = data['nama_lengkap'] ?? _staffName;
          _staffEmail = data['email'] ?? _staffEmail;
        });
      }
    } catch (_) {}
  }

  // --- API: VALIDASI KODE TIKET ---
  Future<void> _validateTicketCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan masukkan atau scan kode tiket!"), backgroundColor: Colors.orange),
      );
      _isProcessingScan = false;
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scanResult = null;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/tickets/validate');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ticket_code': cleanCode}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _scanResult = body['data'];
          _isLoading = false;
        });
        _showResultDialog(isRedeemed: body['is_redeemed'] ?? false);
      } else {
        setState(() {
          _errorMessage = ApiConfig.extractErrorMessage(body['detail'], fallback: 'Kode tiket tidak valid atau tidak terdaftar');
          _isLoading = false;
        });
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal terhubung ke server backend: ${ApiConfig.extractErrorMessage(e)}';
        _isLoading = false;
      });
      _showErrorDialog("Koneksi gagal. Pastikan server backend aktif.");
    }
  }

  // --- API: REDEEM / TUKAR TIKET (KONFIRMASI MASUK) ---
  Future<void> _redeemTicket(String code) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/api/tickets/redeem');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'ticket_code': code}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog sebelumnya
        }
        
        final ticketData = body['data'] ?? {};
        setState(() {
          _scanResult = ticketData;
          _isLoading = false;
          _sessionScanCount++;
          _sessionScanHistory.insert(0, {
            'ticket_code': ticketData['ticket_code'] ?? code,
            'nama_pemesan': ticketData['nama_pemesan'] ?? '-',
            'nama_paket': ticketData['nama_paket'] ?? '-',
            'jumlah_orang': ticketData['jumlah_orang'] ?? 1,
            'time': TimeOfDay.now().format(context),
            'status': 'Valid',
          });
        });
        _showSuccessRedeemDialog(body['message'] ?? 'Tiket berhasil diverifikasi!');
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        final errText = ApiConfig.extractErrorMessage(body['detail'], fallback: 'Gagal menukarkan tiket');
        _showErrorDialog(errText);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Koneksi gagal saat menukarkan tiket: ${ApiConfig.extractErrorMessage(e)}');
    }
  }

  // --- DIALOG HASIL SCAN ---
  void _showResultDialog({required bool isRedeemed}) {
    if (_scanResult == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1C2824) : Colors.white;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              isRedeemed ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isRedeemed ? Colors.redAccent : const Color(0xFF4CAF50),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isRedeemed ? "Tiket Sudah Terpakai" : "Tiket Valid & Aktif",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isRedeemed ? Colors.redAccent : const Color(0xFF4CAF50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow("Nama Pemesan", _scanResult!['nama_pemesan'] ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow("Paket Wisata", _scanResult!['nama_paket'] ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow("Jumlah Orang", "${_scanResult!['jumlah_orang']} Orang"),
            const SizedBox(height: 8),
            _buildInfoRow("Tanggal Kunjungan", _scanResult!['tanggal_pakai'] ?? '-'),
            const SizedBox(height: 8),
            _buildInfoRow("Kode Tiket", _scanResult!['ticket_code'] ?? '-'),
            if (isRedeemed && _scanResult!['redeemed_at'] != null) ...[
              const Divider(height: 24),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "⚠️ Tiket ini sudah digunakan pada ${_scanResult!['redeemed_at']} oleh ${_scanResult!['redeemed_by'] ?? 'Petugas'}.",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _codeController.clear();
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) setState(() => _isProcessingScan = false);
              });
            },
            child: const Text("Tutup"),
          ),
          if (!isRedeemed)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _redeemTicket(_scanResult!['ticket_code']),
              icon: const Icon(Icons.verified, size: 18),
              label: const Text("Konfirmasi Masuk (Tukar)"),
            ),
        ],
      ),
    );
  }

  void _showSuccessRedeemDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 10),
            Text("Berhasil Divalidasi!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "$msg\n\nPengunjung: ${_scanResult?['nama_pemesan'] ?? '-'}\nJumlah: ${_scanResult?['jumlah_orang'] ?? '-'} Orang",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E9190),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _codeController.clear();
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) setState(() => _isProcessingScan = false);
              });
            },
            child: const Text("Selesai"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Verifikasi Gagal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(msg, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (mounted) setState(() => _isProcessingScan = false);
              });
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT PETUGAS ---
  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Keluar Akun Petugas", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Apakah Anda yakin ingin mengakhiri sesi scanner dan keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('jwt_token');
              await prefs.remove('user_role');
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text("Ya, Keluar"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF5E9190);
    const celadonColor = Color(0xFFB3D89C);
    final cardBg = isDark ? const Color(0xFF1B2824) : Colors.white;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: !widget.isStaffPortal,
        automaticallyImplyLeading: !widget.isStaffPortal,
        title: Text(
          widget.isStaffPortal ? "Portal Petugas Loket" : "Scanner Tiket Petugas",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Montserrat'),
        ),
        actions: [
          // Theme Toggle Switcher
          ValueListenableBuilder<bool>(
            valueListenable: isDarkModeGlobal,
            builder: (context, isDarkMode, child) {
              return IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 20),
                tooltip: "Ganti Tema",
                onPressed: () => isDarkModeGlobal.value = !isDarkMode,
              );
            },
          ),
          // Logout button if in dedicated Staff Portal
          if (widget.isStaffPortal)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
              tooltip: "Keluar Akun Petugas",
              onPressed: _confirmLogout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // --- KARTU PROFIL & STATUS OPERASIONAL PETUGAS ---
            if (widget.isStaffPortal) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
                      child: const Icon(Icons.badge_rounded, color: primaryColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _staffName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Montserrat'),
                          ),
                          const SizedBox(height: 2),
                          Text(_staffEmail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: Color(0xFF4CAF50)),
                          SizedBox(width: 6),
                          Text("ONLINE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // --- STATS RINGKASAN SESI ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withValues(alpha: 0.85), celadonColor.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Tiket Diverifikasi", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      SizedBox(height: 2),
                      Text("Shift Hari Ini", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$_sessionScanCount Tiket",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- LIVE CAMERA SCANNER FRAME WITH MOBILE SCANNER ---
            Container(
              width: double.infinity,
              height: 290,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141F1C) : const Color(0xFF1A2A26),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: celadonColor.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // LIVE CAMERA PREVIEW
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: (BarcodeCapture capture) {
                        if (_isProcessingScan || _isLoading) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final String? code = barcode.rawValue;
                          if (code != null && code.isNotEmpty) {
                            setState(() => _isProcessingScan = true);
                            _codeController.text = code;
                            _validateTicketCode(code);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error, child) {
                        final String errCode = error.errorCode.name;
                        final String errMsg = error.errorDetails?.message ?? "Inisialisasi kamera gagal";

                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.videocam_off_outlined, color: Colors.orangeAccent, size: 42),
                                const SizedBox(height: 10),
                                Text(
                                  errCode == "permissionDenied"
                                      ? "Izin kamera belum aktif di aplikasi"
                                      : "Kamera perlu diinisialisasi ulang ($errCode)",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  errMsg,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                                ),
                                const SizedBox(height: 14),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  onPressed: _isCameraRestarting ? null : _restartCamera,
                                  icon: _isCameraRestarting
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.refresh_rounded, size: 16),
                                  label: Text(_isCameraRestarting ? "Menghubungkan..." : "Aktifkan / Coba Lagi"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Viewfinder Corners Overlays
                    Positioned(top: 20, left: 20, child: Container(width: 28, height: 28, decoration: const BoxDecoration(border: Border(top: BorderSide(color: celadonColor, width: 4), left: BorderSide(color: celadonColor, width: 4))))),
                    Positioned(top: 20, right: 20, child: Container(width: 28, height: 28, decoration: const BoxDecoration(border: Border(top: BorderSide(color: celadonColor, width: 4), right: BorderSide(color: celadonColor, width: 4))))),
                    Positioned(bottom: 20, left: 20, child: Container(width: 28, height: 28, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: celadonColor, width: 4), left: BorderSide(color: celadonColor, width: 4))))),
                    Positioned(bottom: 20, right: 20, child: Container(width: 28, height: 28, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: celadonColor, width: 4), right: BorderSide(color: celadonColor, width: 4))))),

                    // Animated Scanning Laser Line
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: 290 * _scanLineAnimation.value,
                          left: 36,
                          right: 36,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.transparent, Color(0xFFD0EFB1), Color(0xFF9DC3C2), Colors.transparent],
                              ),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFD0EFB1).withValues(alpha: 0.9), blurRadius: 12, spreadRadius: 3),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Quick Camera Controls (Restart, Torch & Flip)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                          tooltip: "Muat Ulang Kamera",
                          onPressed: _restartCamera,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Row(
                        children: [
                          // Torch Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                color: _isTorchOn ? Colors.amber : Colors.white70,
                                size: 20,
                              ),
                              tooltip: "Senter Kamera",
                              onPressed: () async {
                                await _cameraController.toggleTorch();
                                setState(() => _isTorchOn = !_isTorchOn);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Camera Flip Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70, size: 20),
                              tooltip: "Ganti Kamera Depan/Belakang",
                              onPressed: () => _cameraController.switchCamera(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Helper Bottom Text
                    Positioned(
                      bottom: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isProcessingScan) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              const Text("Memvalidasi kode...", style: TextStyle(color: Colors.white, fontSize: 11)),
                            ] else ...[
                              const Icon(Icons.qr_code_scanner_rounded, size: 14, color: Colors.white70),
                              const SizedBox(width: 6),
                              const Text(
                                "Arahkan kamera ke QR Code Tiket",
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- MANUAL CODE INPUT / TEST SECTION ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Input Manual Kode Tiket",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Gunakan jika QR Code kotor, basah, atau tidak terbaca.",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: "Contoh: WPT-20260815-XXXXX",
                      prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _codeController.clear(),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF14201C) : const Color(0xFFF7FAF8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _validateTicketCode(_codeController.text),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: Text(_isLoading ? "Memeriksa..." : "Periksa & Validasi Tiket"),
                    ),
                  ),
                ],
              ),
            ),

            // --- RIWAYAT SCAN SESI INI ---
            if (_sessionScanHistory.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Riwayat Scan Sesi Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Icon(Icons.history_rounded, size: 18, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sessionScanHistory.length,
                      separatorBuilder: (c, i) => const Divider(height: 16),
                      itemBuilder: (c, i) {
                        final item = _sessionScanHistory[i];
                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_pemesan'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "${item['ticket_code']} • ${item['nama_paket']} (${item['jumlah_orang']} Org)",
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              item['time'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
