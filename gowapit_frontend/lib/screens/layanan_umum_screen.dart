import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class LayananUmumPage extends StatefulWidget {
  const LayananUmumPage({super.key});

  @override
  State<LayananUmumPage> createState() => _LayananUmumPageState();
}

class _LayananUmumPageState extends State<LayananUmumPage> {
  List<dynamic> _listLayanan = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLayananData();
  }

  Future<void> _fetchLayananData() async {
    try {
      final String response = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(response);
      if (mounted) setState(() { _listLayanan = data['layanan_umum']; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);

    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF659287).withValues(alpha: 0.10), blurRadius: 12, offset: const Offset(0, 4))
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text("Layanan Umum", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat')),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _listLayanan.length,
            itemBuilder: (context, index) {
              final layanan = _listLayanan[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: Icon(Icons.phone_in_talk, color: primaryColor, size: 20),
                  ),
                  title: Text(layanan['nama'] ?? '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: textColor)),
                  subtitle: Text(layanan['nomor'] ?? '-', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
              );
            },
          ),
    );
  }
}