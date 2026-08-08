import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'tiket_screen.dart'; // MENGHUBUNGKAN KE STATE KERANJANG GLOBAL

class PaketPage extends StatefulWidget {
  const PaketPage({super.key});

  @override
  State<PaketPage> createState() => _PaketPageState();
}

class _PaketPageState extends State<PaketPage> {
  List<dynamic> _listPaket = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPaketData();
  }

  Future<void> _fetchPaketData() async {
    try {
      final String response = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(response);
      if (mounted) {
        setState(() {
          _listPaket = data['paket_wisata'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text("Paket Wisata", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _listPaket.isEmpty
            ? Center(child: Text("Data paket wisata kosong.", style: TextStyle(color: primaryColor)))
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
  bool _isPressed = false;
  bool _isHovered = false; 

  Color _getPackageThemeColor(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('platinum')) {
      return const Color(0xFF607D8B); 
    } else if (name.contains('gold')) {
      return const Color(0xFFC5A059); 
    } else if (name.contains('silver')) {
      return const Color(0xFF9E9E9E); 
    } else if (name.contains('bronze')) {
      return const Color(0xFFCD7F32); 
    }
    return widget.isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287); 
  }

  // Fungsi tambahan untuk memformat tampilan harga di UI
  String _formatRupiahCard(String rawPrice) {
    String cleanNumber = rawPrice.replaceAll(RegExp(r'[^0-9]'), '');
    int? amount = int.tryParse(cleanNumber);
    if (amount == null) return rawPrice;
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    String daftarFasilitas = "";
    if (widget.paket['wisata'] != null && widget.paket['wisata'].isNotEmpty) daftarFasilitas += "• Wisata: ${(widget.paket['wisata'] as List).join(', ')}\n";
    if (widget.paket['included'] != null && widget.paket['included'].isNotEmpty) daftarFasilitas += "• Include: ${(widget.paket['included'] as List).join(', ')}\n";
    if (widget.paket['Wahana'] != null && widget.paket['Wahana'].isNotEmpty) daftarFasilitas += "• Wahana: ${(widget.paket['Wahana'] as List).join(', ')}";
    daftarFasilitas = daftarFasilitas.trim();

    final Color themeColor = _getPackageThemeColor(widget.paket['nama'] ?? '');
    final Color defaultCardColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final bool isActive = _isPressed || _isHovered; 
    
    final Color currentBgColor = isActive ? themeColor : defaultCardColor;
    final Color currentTitleColor = isActive ? Colors.white : themeColor;
    final Color currentTextColor = isActive ? Colors.white.withValues(alpha: 0.9) : (widget.isDarkMode ? Colors.grey.shade300 : const Color(0xFF404846));
    final Color currentDividerColor = isActive ? Colors.white.withValues(alpha: 0.3) : (widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200);
    final Color currentBtnBgColor = isActive ? Colors.white : themeColor;
    final Color currentBtnTextColor = isActive ? themeColor : Colors.white;

    final List<BoxShadow> ambientShadow = widget.isDarkMode ? [] : [
      BoxShadow(color: themeColor.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 6))
    ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click, 
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          
          final currentList = List<Map<String, dynamic>>.from(globalCart.value);
          bool exists = false;
          
          for (var c in currentList) {
            if (c['nama'] == widget.paket['nama']) {
              c['qty']++; 
              exists = true;
              break;
            }
          }

          if (!exists) {
            // --- PERBAIKAN BUG HARGA ADA DI SINI ---
            // Bersihkan segala titik, koma, spasi, atau huruf 'Rp' sebelum diubah ke Integer
            String rawPrice = widget.paket['harga'].toString();
            String cleanPrice = rawPrice.replaceAll(RegExp(r'[^0-9]'), '');
            int parsedPrice = int.tryParse(cleanPrice) ?? 0;

            currentList.add({
              'kategori': 'PAKET',
              'nama': widget.paket['nama'],
              'subtitle': 'Paket Wisata',
              'harga': parsedPrice, // Sekarang murni angka utuh
              'qty': 1,
              'gambar': 'assets/images/placeholder.jpeg',
            });
          }

          globalCart.value = currentList;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Paket ${widget.paket['nama']} ditambahkan ke keranjang!"), 
              backgroundColor: themeColor,
              duration: const Duration(seconds: 1),
            )
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: currentBgColor, borderRadius: BorderRadius.circular(20), boxShadow: ambientShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.paket['nama'] ?? '-', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: currentTitleColor, fontFamily: 'Montserrat')),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.2) : themeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    // UI Harga juga diformat otomatis
                    child: Text(_formatRupiahCard(widget.paket['harga'].toString()), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: currentTitleColor, fontFamily: 'Inter')),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Divider(color: currentDividerColor, thickness: 1),
              ),
              Text("Fasilitas yang didapat:", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: currentTextColor, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              Text(daftarFasilitas.isNotEmpty ? daftarFasilitas : "-", style: TextStyle(fontSize: 13, height: 1.6, color: currentTextColor, fontFamily: 'Inter')),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(color: currentBtnBgColor, borderRadius: BorderRadius.circular(14)),
                  child: Center(
                    child: Text("Pilih Paket", style: TextStyle(color: currentBtnTextColor, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}