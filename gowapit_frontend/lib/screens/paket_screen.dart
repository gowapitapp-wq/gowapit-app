import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'booking_screen.dart';

class PaketPage extends StatefulWidget {
  const PaketPage({super.key});

  @override
  State<PaketPage> createState() => _PaketPageState();
}

class _PaketPageState extends State<PaketPage> {
  List<dynamic> _listPaket = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPaketData();
  }

  Future<void> _fetchPaketData() async {
    try {
      final response = await http.get(ApiConfig.uri('/api/paket'));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _listPaket = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data paket (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Tidak dapat terhubung ke server';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: const Text(
          "Paket Wisata",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 48, color: primaryColor.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: primaryColor, fontFamily: 'Inter')),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() { _isLoading = true; _error = null; });
                          _fetchPaketData();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Coba Lagi"),
                        style: TextButton.styleFrom(foregroundColor: primaryColor),
                      ),
                    ],
                  ),
                )
              : _listPaket.isEmpty
                  ? Center(
                      child: Text(
                        "Data paket wisata kosong.",
                        style: TextStyle(color: primaryColor, fontFamily: 'Inter'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: _listPaket.length,
                      itemBuilder: (context, index) {
                        final paket = _listPaket[index];
                        return HoverablePaketCard(
                          paket: paket,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
    );
  }
}

class HoverablePaketCard extends StatefulWidget {
  final dynamic paket;
  final bool isDarkMode;

  const HoverablePaketCard({super.key, required this.paket, required this.isDarkMode});

  @override
  State<HoverablePaketCard> createState() => _HoverablePaketCardState();
}

class _HoverablePaketCardState extends State<HoverablePaketCard> {
  bool _isHovered = false;

  Color _getPackageThemeColor(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('platinum')) return const Color(0xFF607D8B);
    if (name.contains('gold'))     return const Color(0xFFC5A059);
    if (name.contains('silver'))   return const Color(0xFF9E9E9E);
    if (name.contains('bronze'))   return const Color(0xFFCD7F32);
    return widget.isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
  }

  String _formatRupiah(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}";
  }

  /// Ubah string fasilitas (newline-separated) jadi bullet list widget
  List<Widget> _buildFasilitasList(String fasilitas, Color textColor) {
    final lines = fasilitas
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: textColor, fontFamily: 'Inter', fontSize: 13)),
            Expanded(
              child: Text(
                line,
                style: TextStyle(fontSize: 13, height: 1.5, color: textColor, fontFamily: 'Inter'),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final String nama = widget.paket['nama'] ?? '-';
    final int harga = widget.paket['harga'] ?? 0;
    final String fasilitas = widget.paket['fasilitas'] ?? '';

    final Color themeColor = _getPackageThemeColor(nama);
    final Color defaultCardColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color currentBgColor = _isHovered ? themeColor : defaultCardColor;
    final Color currentTitleColor = _isHovered ? Colors.white : themeColor;
    final Color currentTextColor = _isHovered
        ? Colors.white.withValues(alpha: 0.9)
        : (widget.isDarkMode ? Colors.grey.shade300 : const Color(0xFF404846));
    final Color currentDividerColor = _isHovered
        ? Colors.white.withValues(alpha: 0.3)
        : (widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200);
    final Color currentBtnBgColor = _isHovered ? Colors.white : themeColor;
    final Color currentBtnTextColor = _isHovered ? themeColor : Colors.white;

    final List<BoxShadow> ambientShadow = widget.isDarkMode
        ? []
        : [BoxShadow(color: themeColor.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6))];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Buka BookingScreen dengan paket ini sudah dipilih
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingScreen(paket: {
                'id': widget.paket['id'],
                'nama': nama,
                'harga': harga,
                'fasilitas': fasilitas,
              }),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: currentBgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ambientShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nama,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: currentTitleColor,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isHovered
                          ? Colors.white.withValues(alpha: 0.2)
                          : themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatRupiah(harga),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: currentTitleColor,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Divider(color: currentDividerColor, thickness: 1),
              ),
              Text(
                "Fasilitas yang didapat:",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: currentTextColor,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              if (fasilitas.isNotEmpty)
                ..._buildFasilitasList(fasilitas, currentTextColor)
              else
                Text('-', style: TextStyle(color: currentTextColor, fontFamily: 'Inter')),
              const SizedBox(height: 24),
              // Badge "Pilih Tanggal" untuk Platinum
              if (nama.toLowerCase().contains('platinum'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.night_shelter_outlined, size: 14, color: currentTextColor.withValues(alpha: 0.7)),
                      const SizedBox(width: 6),
                      Text(
                        "Termasuk camping — pilih range tanggal",
                        style: TextStyle(fontSize: 12, color: currentTextColor.withValues(alpha: 0.8), fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: currentBtnBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      "Pilih Paket →",
                      style: TextStyle(
                        color: currentBtnTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}