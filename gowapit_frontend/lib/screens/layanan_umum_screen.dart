import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

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
      // 1. Coba dari API Backend
      final response = await http.get(ApiConfig.uri("/api/layanan-umum"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty && mounted) {
          setState(() {
            _listLayanan = (data['data'] as List).map((item) => {
              'nama': item['nama_layanan'] ?? item['nama'],
              'nomor': item['kontak'] ?? item['nomor']
            }).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback dari JSON lokal jika offline
    try {
      final String jsonString = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(jsonString);
      if (mounted) {
        setState(() {
          _listLayanan = data['layanan_umum'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _panggilNomor(String nomor) async {
    String cleanNomor = nomor.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanNomor.isEmpty) return;

    final Uri phoneUri = Uri.parse("tel:$cleanNomor");
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Mendial nomor: $nomor")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F9F4);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF9DC3C2).withValues(alpha: 0.16), blurRadius: 12, offset: const Offset(0, 4))
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Layanan & Kontak Darurat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 18)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : _listLayanan.isEmpty
            ? Center(child: Text("Data layanan tidak tersedia.", style: TextStyle(color: textColor)))
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _listLayanan.length,
                itemBuilder: (context, index) {
                  final layanan = _listLayanan[index];
                  String nama = layanan['nama'] ?? layanan['nama_layanan'] ?? '-';
                  String nomor = layanan['nomor'] ?? layanan['kontak'] ?? '-';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      onTap: () => _panggilNomor(nomor),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(Icons.phone_in_talk, color: primaryColor, size: 22),
                      ),
                      title: Text(nama, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(nomor, style: TextStyle(fontSize: 13, color: primaryColor, fontWeight: FontWeight.w600)),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                        child: const Text("Panggil", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}