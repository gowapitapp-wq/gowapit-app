import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
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
      final String response = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(response);
      if (mounted) {
        setState(() {
          _listDestinasi = data['wisata'];
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
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD); // Background Mint[cite: 4]
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287); // Primary Sage Green[cite: 4]

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text(
          "Destinasi", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 20) // Montserrat Headline[cite: 4]
        ),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _listDestinasi.isEmpty
            ? Center(child: Text("Data destinasi kosong.", style: TextStyle(color: primaryColor)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _listDestinasi.length,
                itemBuilder: (context, index) {
                  final item = _listDestinasi[index];
                  return HoverableDestinasiCard(
                    item: item,
                    allDestinasi: _listDestinasi,
                    isDarkMode: isDarkMode,
                  );
                },
              ),
    );
  }
}

// Komponen Kustom untuk Efek Hover/Press
class HoverableDestinasiCard extends StatefulWidget {
  final dynamic item;
  final List<dynamic> allDestinasi;
  final bool isDarkMode;

  const HoverableDestinasiCard({super.key, required this.item, required this.allDestinasi, required this.isDarkMode});

  @override
  State<HoverableDestinasiCard> createState() => _HoverableDestinasiCardState();
}

class _HoverableDestinasiCardState extends State<HoverableDestinasiCard> {
  bool _isPressed = false; // State untuk mendeteksi tekanan

  @override
  Widget build(BuildContext context) {
    // Definisi Warna[cite: 4]
    final Color cardColor = widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color primaryColor = widget.isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    final Color secondaryColor = const Color(0xFF88BDA4);
    
    // Warna Dinamis Berdasarkan State Tekanan
    final Color currentBgColor = _isPressed ? primaryColor : cardColor;
    final Color currentTitleColor = _isPressed ? Colors.white : (widget.isDarkMode ? Colors.white : const Color(0xFF161d1b));
    final Color currentSubColor = _isPressed ? Colors.white.withValues(alpha: 0.8) : (widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846));
    final Color currentIconColor = _isPressed ? Colors.white : secondaryColor;

    final List<BoxShadow> ambientShadow = widget.isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF659287).withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 6)) // Tinted Ambient Shadow[cite: 4]
    ];

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        // Navigasi ke Halaman Detail
        Navigator.push(context, MaterialPageRoute(builder: (context) => DetailDestinasiPage(data: widget.item, allDestinasi: widget.allDestinasi)));
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 16),
        height: 110, // Tinggi kartu agar konsisten
        decoration: BoxDecoration(
          color: currentBgColor,
          borderRadius: BorderRadius.circular(16), // rounded-lg[cite: 4]
          boxShadow: ambientShadow,
        ),
        child: Row(
          children: [
            // Gambar di sebelah kiri
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: Image.asset(
                widget.item['gambar'] ?? 'assets/images/placeholder.jpeg',
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
                    Text("Nama Wisata", style: TextStyle(fontSize: 10, color: currentSubColor, fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                    Text(
                      widget.item['nama'] ?? '-', 
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: currentTitleColor, fontFamily: 'Montserrat'), // Montserrat[cite: 4]
                      maxLines: 1, overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Deskripsi", style: TextStyle(fontSize: 10, color: currentSubColor, fontFamily: 'Inter', fontWeight: FontWeight.w600)
                    ),
                    Expanded(
                      child: Text(
                        widget.item['deskripsi_singkat'] ?? '-', 
                        style: TextStyle(fontSize: 10, color: currentSubColor, fontFamily: 'Inter', height: 1.2), // Inter[cite: 4]
                        maxLines: 2, overflow: TextOverflow.ellipsis
                      ),
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