import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'detail_destinasi_screen.dart'; 

class DestinasiPage extends StatefulWidget {
  const DestinasiPage({super.key});

  @override
  State<DestinasiPage> createState() => _DestinasiPageState();
}

class _DestinasiPageState extends State<DestinasiPage> {
  List<dynamic> _listDestinasi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDestinasiData();
  }

  Future<void> _fetchDestinasiData() async {
    try {
      final response = await http.get(ApiConfig.uri("/api/destinasi"));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _listDestinasi = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
          "Destinasi", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 20)
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _listDestinasi.isEmpty
            ? Center(child: Text("Data destinasi kosong.", style: TextStyle(color: primaryColor)))
            : RefreshIndicator(
                color: primaryColor,
                onRefresh: _fetchDestinasiData,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _listDestinasi.length,
                  itemBuilder: (context, index) {
                    final item = _listDestinasi[index];
                    return HoverableDestinasiCard(
                      item: item,
                      allDestinasi: _listDestinasi,
                      isDarkMode: isDarkMode,
                      onRefresh: _fetchDestinasiData,
                    );
                  },
                ),
              ),
    );
  }
}

// Komponen Kustom untuk Efek Hover/Press
class HoverableDestinasiCard extends StatefulWidget {
  final dynamic item;
  final List<dynamic> allDestinasi;
  final bool isDarkMode;
  final VoidCallback onRefresh;

  const HoverableDestinasiCard({
    super.key,
    required this.item,
    required this.allDestinasi,
    required this.isDarkMode,
    required this.onRefresh,
  });

  @override
  State<HoverableDestinasiCard> createState() => _HoverableDestinasiCardState();
}

class _HoverableDestinasiCardState extends State<HoverableDestinasiCard> {
  bool _isPressed = false; // State untuk mendeteksi tekanan

  @override
  Widget build(BuildContext context) {
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color primaryColor = widget.isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    final Color secondaryColor = const Color(0xFF9DC3C2);
    
    final Color currentBgColor = _isPressed ? primaryColor : cardColor;
    final Color currentTitleColor = _isPressed ? Colors.white : (widget.isDarkMode ? Colors.white : const Color(0xFF161d1b));
    final Color currentSubColor = _isPressed ? Colors.white.withValues(alpha: 0.8) : (widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846));
    final Color currentIconColor = _isPressed ? Colors.white : secondaryColor;

    final List<BoxShadow> ambientShadow = widget.isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF5E9190).withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 6))
    ];

    final String nama = widget.item['name'] ?? widget.item['nama'] ?? '-';
    final String deskripsi = widget.item['deskripsi_pendek'] ?? widget.item['deskripsi_singkat'] ?? widget.item['deskripsi_panjang'] ?? '-';
    String rawGambar = widget.item['image'] ?? widget.item['gambar'] ?? 'assets/images/placeholder.jpeg';
    final String gambarPath = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';
    final num ratingNum = (widget.item['rating'] is num) ? widget.item['rating'] : 0.0;
    final int jmlUlasan = (widget.item['jumlah_ulasan'] is num) ? (widget.item['jumlah_ulasan'] as num).toInt() : 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        // Navigasi ke Halaman Detail
        await Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => DetailDestinasiPage(
              data: widget.item, 
              allDestinasi: widget.allDestinasi,
            )
          )
        );
        widget.onRefresh();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 16),
        height: 110,
        decoration: BoxDecoration(
          color: currentBgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ambientShadow,
        ),
        child: Row(
          children: [
            // Gambar di sebelah kiri
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.asset(
                gambarPath,
                width: 100,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 100, color: Colors.grey.shade300, child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            
            // Konten Teks di Tengah
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            nama, 
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: currentTitleColor, fontFamily: 'Montserrat'),
                            maxLines: 1, overflow: TextOverflow.ellipsis
                          ),
                        ),
                        if (ratingNum > 0)
                          Row(
                            children: [
                              Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                ratingNum.toStringAsFixed(1),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentSubColor),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        deskripsi, 
                        style: TextStyle(fontSize: 11, color: currentSubColor, fontFamily: 'Inter', height: 1.2),
                        maxLines: 2, overflow: TextOverflow.ellipsis
                      ),
                    ),
                    if (jmlUlasan > 0)
                      Text(
                        "$jmlUlasan ulasan",
                        style: TextStyle(fontSize: 9, color: currentSubColor.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),
            
            // Ikon Panah/Play di Kanan
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.play_circle_fill, color: currentIconColor, size: 28),
            )
          ],
        ),
      ),
    );
  }
}