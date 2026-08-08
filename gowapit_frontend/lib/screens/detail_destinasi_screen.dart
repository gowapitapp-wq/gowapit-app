import 'package:flutter/material.dart';
import 'dart:ui';

class DetailDestinasiPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final List<dynamic> allDestinasi;

  const DetailDestinasiPage({super.key, required this.data, required this.allDestinasi});

  @override
  State<DetailDestinasiPage> createState() => _DetailDestinasiPageState();
}

class _DetailDestinasiPageState extends State<DetailDestinasiPage> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Palet Warna
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD); 
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white; 
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);

    final String nama = widget.data['nama'] ?? 'Destinasi Wapit';
    final String deskripsi = widget.data['deskripsi_panjang'] ?? widget.data['deskripsi_singkat'] ?? 'Deskripsi tidak tersedia.';
    String rawGambar = widget.data['gambar'] ?? 'assets/images/placeholder.jpeg';
    final String gambar = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';

    // Menyaring destinasi lain
    final List<dynamic> wisataLain = widget.allDestinasi.where((item) => item['nama'] != nama).toList();

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
            // Ikon bendera di sudut kanan atas telah dihilangkan
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

                    const SizedBox(height: 36),

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
                          return GestureDetector(
                            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DetailDestinasiPage(data: itemLain, allDestinasi: widget.allDestinasi))),
                            child: Container(
                              width: 150,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isDarkMode ? [] : [BoxShadow(color: const Color(0xFF659287).withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 6))],
                                image: DecorationImage(
                                  image: AssetImage(
                                    (itemLain['gambar'] ?? 'assets/images/placeholder.jpeg').toString().startsWith('assets/')
                                      ? itemLain['gambar']
                                      : 'assets/${itemLain['gambar']}'
                                  ),
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
                                child: Text(itemLain['nama'] ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Montserrat')),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40), // Jarak disesuaikan setelah bar bawah dihapus
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // Bottom navigation bar pemesanan telah dihapus
    );
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