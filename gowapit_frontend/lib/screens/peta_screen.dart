import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PetaScreen extends StatelessWidget {
  const PetaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFD0EFB1);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.20), blurRadius: 20, offset: const Offset(0, 8))
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, 
        title: Text("Peta Lokasi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Ruang untuk nav bar tembus pandang
        child: Column(
          children: [
            // KARTU GAMBAR PETA
            Container(
              height: 250,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: ambientShadow,
                image: const DecorationImage(image: AssetImage('assets/images/peta_wapit.png'), fit: BoxFit.cover),
              ),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withValues(alpha: 0.3)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 50, color: Colors.white.withValues(alpha: 0.9)),
                      const SizedBox(height: 8),
                      const Text("Wisata Alam Jumprit", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Montserrat')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KARTU INFO
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(Icons.location_on, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Wisata Alam Jumprit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                            const SizedBox(height: 4),
                            Text("Ketinggian 1280 mdpl", style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
                  Text("Alamat Lengkap", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text("Jl. Ngadirejo, Jumprit, Tegalrejo, Temanggung, Jawa Tengah 56255.", style: TextStyle(fontSize: 13, height: 1.5, color: subTextColor), textAlign: TextAlign.justify),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // TOMBOL GOOGLE MAPS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final Uri mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=Wahana+Wisata+Alam+Jumprit+Temanggung+(WAPITT)');
                    try {
                      bool launched = await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
                      if (!launched) {
                        await launchUrl(mapsUrl, mode: LaunchMode.platformDefault);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Membuka Google Maps: $mapsUrl")),
                        );
                      }
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Buka di Google Maps", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}