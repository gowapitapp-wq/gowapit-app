import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'tiket_screen.dart'; // MENGHUBUNGKAN KE STATE KERANJANG GLOBAL

class KulinerPage extends StatefulWidget {
  const KulinerPage({super.key});

  @override
  State<KulinerPage> createState() => _KulinerPageState();
}

class _KulinerPageState extends State<KulinerPage> {
  List<Map<String, dynamic>> _semuaMenu = [];
  List<String> _kategoriList = ['Semua'];
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchKulinerData();
  }

// --- FUNGSI PINTAR UNTUK MEMBERSIHKAN PATH GAMBAR JSON ---
  String _bersihkanPathGambar(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) {
      return 'assets/images/placeholder_food.jpeg';
    }
    // Mengambil nama filenya saja (misal dari "assets/image/Mie.jpeg" menjadi "Mie.jpeg")
    String namaFile = rawPath.split('/').last;
    
    // Menggabungkannya dengan folder yang pasti benar
    return 'assets/images/$namaFile';
  }

  Future<void> _fetchKulinerData() async {
    try {
      final String response = await rootBundle.loadString('assets/data_pariwisata.json');
      final data = jsonDecode(response);
      List<Map<String, dynamic>> menuTemp = [];
      List<String> kategoriTemp = ['Semua'];

      if (data['kuliner'] != null && data['kuliner']['kategori'] != null) {
        for (var kategori in data['kuliner']['kategori']) {
          String namaKategori = kategori['nama'] ?? '';
          if (namaKategori.isEmpty) {
            if (kategori['menu_manual_brew'] != null) namaKategori = 'Manual Brew';
            else if (kategori['milk_base'] != null) namaKategori = 'Milk Base';
            else namaKategori = 'Kategori Lainnya';
          }

          if (!kategoriTemp.contains(namaKategori)) {
            kategoriTemp.add(namaKategori);
          }

          // 1. Ekstrak Daftar Makanan & Kopi
          if (kategori['daftar'] != null) {
            for (var menu in kategori['daftar']) {
              String hargaFinal = "0";
              if (menu['harga'] is String) {
                hargaFinal = menu['harga'].replaceAll(RegExp(r'[^0-9]'), '');
              } else if (menu['harga'] is Map) {
                hargaFinal = menu['harga'].values.first.toString(); 
              }
              menuTemp.add({
                'nama_menu': menu['nama'] ?? menu['jenis_kopi'] ?? 'Menu',
                'kedai': namaKategori,
                'harga': hargaFinal,
                // PERBAIKAN: Menggunakan fungsi pintar dan kata kunci "image" (tanpa s)
                'gambar': _bersihkanPathGambar(menu['image'] ?? menu['gambar'])
              });
            }
          }
          
          // 2. Ekstrak Milk Base
          if (kategori['milk_base'] != null) {
            for (var menu in kategori['milk_base']) {
              menuTemp.add({
                'nama_menu': menu['nama_menu'] ?? '-', 
                'kedai': namaKategori, 
                'harga': menu['harga'].toString(),
                'gambar': _bersihkanPathGambar(menu['image'] ?? menu['gambar'])
              });
            }
          }

          // 3. Ekstrak Manual Brew
          if (kategori['menu_manual_brew'] != null) {
            for (var menu in kategori['menu_manual_brew']) {
               menuTemp.add({
                 'nama_menu': "${menu['jenis_kopi']} (Manual)", 
                 'kedai': namaKategori, 
                 'harga': (menu['harga'] as Map).values.first.toString(),
                 'gambar': _bersihkanPathGambar(menu['image'] ?? menu['gambar'])
               });
            }
          }
        }
      }
      
      if (mounted) {
        setState(() { 
          _semuaMenu = menuTemp; 
          _kategoriList = kategoriTemp;
          _isLoading = false; 
        });
      }
    } catch (e) {
      debugPrint("Error Load Kuliner: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredMenu {
    if (_selectedCategoryIndex == 0) return _semuaMenu;
    return _semuaMenu.where((item) => item['kedai'] == _kategoriList[_selectedCategoryIndex]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF121E1C);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF4A5D5A);
    final Color primaryColor = isDarkMode ? const Color(0xFF76B3AC) : const Color(0xFF1E524D);
    final Color secondaryColor = const Color(0xFF2E7D6A); 

    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [
      BoxShadow(color: const Color(0xFF1E524D).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))
    ];

    final filteredList = _filteredMenu;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
        title: Text("Kuliner", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 20)),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : Column(
            children: [
              // --- FILTER KATEGORI ---
              Container(
                height: 50,
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _kategoriList.length,
                  itemBuilder: (context, index) {
                    final kat = _kategoriList[index];
                    final isSelected = _selectedCategoryIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategoryIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor : cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected ? [BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : ambientShadow,
                          border: Border.all(
                            color: isSelected ? primaryColor : (isDarkMode ? Colors.grey.shade800 : const Color(0xFFE5EBE8)),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            kat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : subTextColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontFamily: 'Montserrat',
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- GRID DAFTAR MAKANAN / MINUMAN ---
              Expanded(
                child: filteredList.isEmpty
                  ? Center(child: Text("Menu tidak ditemukan.", style: TextStyle(color: subTextColor)))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10).copyWith(bottom: 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        debugPrint("Cek Gambar ${item['nama_menu']}: ${item['gambar']}");
                        return Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: ambientShadow,
                            border: Border.all(color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE5EBE8)),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              
                              // --- GAMBAR MENU ---
                              Center(
                                child: Container(
                                  height: 100, width: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE6F2DD),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))]
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      item['gambar'], // Memuat gambar dari asset
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover, // Memastikan gambar memenuhi lingkaran
                                      
                                      // --- PERLINDUNGAN JIKA GAMBAR ERROR / BELUM ADA ---
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(Icons.restaurant, color: primaryColor.withValues(alpha: 0.5), size: 40);
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              Text(
                                item['nama_menu'], 
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor, fontFamily: 'Montserrat', height: 1.2),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              
                              Text(
                                item['kedai'], 
                                style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter'),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              
                              const Spacer(),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("Rp${item['harga']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryColor, fontFamily: 'Montserrat')),
                                  
                                  // --- TOMBOL TAMBAH KE KERANJANG DINAMIS ---
                                  GestureDetector(
                                    onTap: () {
                                      final currentList = List<Map<String, dynamic>>.from(globalCart.value);
                                      
                                      bool exists = false;
                                      for (var c in currentList) {
                                        if (c['nama'] == item['nama_menu']) {
                                          c['qty']++; 
                                          exists = true;
                                          break;
                                        }
                                      }

                                      if (!exists) {
                                        currentList.add({
                                          'kategori': 'KULINER',
                                          'nama': item['nama_menu'],
                                          'subtitle': item['kedai'],
                                          'harga': int.tryParse(item['harga'].toString()) ?? 0,
                                          'qty': 1,
                                          // --- MENGIRIM GAMBAR JUGA KE KERANJANG ---
                                          'gambar': item['gambar'], 
                                        });
                                      }

                                      globalCart.value = currentList;

                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text("${item['nama_menu']} ditambahkan ke keranjang!"), 
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: primaryColor,
                                      ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                                    ),
                                  )
                                ],
                              )
                            ],
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