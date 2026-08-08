import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'detail_destinasi_screen.dart';
import 'kuliner_screen.dart';
import 'paket_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allSearchItems = [];
  List<Map<String, dynamic>> _filteredResults = [];
  bool _isLoading = true;
  String _selectedCategory = "Semua";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(jsonString);

      List<Map<String, dynamic>> items = [];

      // 1. Destinasi
      if (data['wisata'] != null) {
        for (var item in data['wisata']) {
          items.add({
            'type': 'Destinasi',
            'nama': item['nama'],
            'deskripsi': item['deskripsi_singkat'] ?? item['deskripsi_panjang'] ?? '',
            'gambar': item['gambar'] ?? 'assets/images/placeholder.jpeg',
            'raw': item,
            'allWisata': data['wisata']
          });
        }
      }

      // 2. Paket Wisata
      if (data['paket_wisata'] != null) {
        for (var item in data['paket_wisata']) {
          items.add({
            'type': 'Tiket',
            'nama': "Paket ${item['nama']}",
            'deskripsi': "Harga: ${item['harga']}. Fasilitas wisata & wahana lengkap.",
            'gambar': 'assets/images/HighRope.jpg',
            'raw': item
          });
        }
      }

      // 3. Kuliner
      if (data['kuliner'] != null && data['kuliner']['kategori'] != null) {
        for (var cat in data['kuliner']['kategori']) {
          if (cat['daftar'] != null) {
            for (var m in cat['daftar']) {
              String namaFile = (m['image'] ?? '').toString().split('/').last;
              items.add({
                'type': 'Kuliner',
                'nama': m['nama'],
                'deskripsi': "Harga: ${m['harga']} (${cat['nama']})",
                'gambar': namaFile.isNotEmpty ? 'assets/images/$namaFile' : 'assets/images/placeholder_food.jpeg',
                'raw': m
              });
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _allSearchItems = items;
          _filteredResults = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    _filterData(query, _selectedCategory);
  }

  void _filterData(String query, String category) {
    String cleanQuery = query.toLowerCase().trim();
    setState(() {
      _selectedCategory = category;
      _filteredResults = _allSearchItems.where((item) {
        bool matchCategory = (category == "Semua") || (item['type'] == category);
        bool matchQuery = cleanQuery.isEmpty ||
            item['nama'].toString().toLowerCase().contains(cleanQuery) ||
            item['deskripsi'].toString().toLowerCase().contains(cleanQuery);
        return matchCategory && matchQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF4F9F4);
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: textColor, fontSize: 15),
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "Cari destinasi, tiket, kuliner...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: subTextColor),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged("");
              },
            )
        ],
      ),
      body: Column(
        children: [
          // Filter Kategori Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Semua", "Destinasi", "Tiket", "Kuliner"].map((cat) {
                  bool isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      selectedColor: primaryColor,
                      backgroundColor: isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
                      onSelected: (_) => _filterData(_searchController.text, cat),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // List Hasil Pencarian
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _filteredResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text("Tidak ada hasil yang ditemukan", style: TextStyle(color: subTextColor, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredResults.length,
                        itemBuilder: (context, index) {
                          final item = _filteredResults[index];
                          String rawGambar = item['gambar'].toString();
                          String gambarPath = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  gambarPath,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(width: 60, height: 60, color: Colors.grey.shade300, child: const Icon(Icons.image)),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                    child: Text(item['type'], style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(item['nama'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(item['deskripsi'], style: TextStyle(fontSize: 12, color: subTextColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              onTap: () {
                                if (item['type'] == 'Destinasi') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => DetailDestinasiPage(data: item['raw'], allDestinasi: item['allWisata'])));
                                } else if (item['type'] == 'Kuliner') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const KulinerPage()));
                                } else if (item['type'] == 'Tiket') {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PaketWisataPage()));
                                }
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
