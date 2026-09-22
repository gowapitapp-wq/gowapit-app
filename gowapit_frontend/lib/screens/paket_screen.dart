import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/api_cache.dart';
import '../design/tokens.dart';
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

  Future<void> _fetchPaketData({bool forceRefresh = false}) async {
    try {
      final cached = ApiCache.instance.get("paket");
      if (cached is List && cached.isNotEmpty && !forceRefresh) {
        setState(() {
          _listPaket = cached;
          _isLoading = false;
          _error = null;
        });
      }

      final data = await ApiCache.instance.getOrFetch(
        cacheKey: "paket",
        uri: ApiConfig.uri('/api/paket'),
        ttl: ApiCache.paketTTL,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      if (data is List) {
        setState(() {
          _listPaket = data;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data paket';
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
    final bool isDark = context.isDarkMode;
    final Color primaryPine = context.primaryAccent;
    final Color textColor = context.textPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Paket Wisata",
          style: AppTokens.tagline.copyWith(color: textColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPine))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 44, color: primaryPine.withValues(alpha: 0.5)),
                      const SizedBox(height: AppTokens.sSM),
                      Text(_error!, style: AppTokens.caption.copyWith(color: context.textMuted)),
                      const SizedBox(height: AppTokens.sSM),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _fetchPaketData(forceRefresh: true);
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text("Coba Lagi"),
                        style: TextButton.styleFrom(foregroundColor: primaryPine),
                      ),
                    ],
                  ),
                )
              : _listPaket.isEmpty
                  ? Center(
                      child: Text(
                        "Data paket wisata kosong.",
                        style: AppTokens.caption.copyWith(color: context.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: AppTokens.sSM),
                      itemCount: _listPaket.length,
                      itemBuilder: (context, index) {
                        final paket = _listPaket[index];
                        return HoverablePaketCard(
                          paket: paket,
                          isDarkMode: isDark,
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
  bool _isPressed = false;

  String _formatRupiah(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}";
  }

  List<Widget> _buildFasilitasList(String fasilitas, Color textColor) {
    final lines = fasilitas.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines.map((line) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: textColor, fontFamily: AppTokens.fontFamily, fontSize: 13)),
            Expanded(
              child: Text(
                line,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: textColor,
                  fontFamily: AppTokens.fontFamily,
                ),
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

    final Color primaryPine = context.primaryAccent;
    final Color cardColor = context.surfaceCard;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
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
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTokens.sMD),
          padding: const EdgeInsets.all(AppTokens.sLG),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppTokens.r18,
            border: Border.all(color: context.hairlineBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nama,
                      style: AppTokens.bodyStrong.copyWith(color: textColor, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryPine.withValues(alpha: 0.12),
                      borderRadius: AppTokens.pill,
                    ),
                    child: Text(
                      _formatRupiah(harga),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryPine,
                        fontFamily: AppTokens.fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.sMD),
                child: Divider(color: context.hairlineBorder, thickness: 1),
              ),
              Text(
                "Fasilitas yang didapat:",
                style: AppTokens.captionStrong.copyWith(color: textColor),
              ),
              const SizedBox(height: AppTokens.sXS),
              if (fasilitas.isNotEmpty)
                ..._buildFasilitasList(fasilitas, subTextColor)
              else
                Text('-', style: TextStyle(color: subTextColor, fontFamily: AppTokens.fontFamily)),
              const SizedBox(height: AppTokens.sLG),
              if (nama.toLowerCase().contains('platinum'))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.sSM),
                  child: Row(
                    children: [
                      Icon(Icons.night_shelter_outlined, size: 14, color: subTextColor),
                      const SizedBox(width: 6),
                      Text(
                        "Termasuk camping — pilih range tanggal",
                        style: AppTokens.finePrint.copyWith(color: subTextColor),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPine,
                    foregroundColor: widget.isDarkMode ? AppTokens.surfaceBlack : AppTokens.canvas,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
                  ),
                  onPressed: () {
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pilih Paket",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTokens.fontFamily,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(width: AppTokens.sXS),
                      Icon(Icons.arrow_forward_rounded, size: 16),
                    ],
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