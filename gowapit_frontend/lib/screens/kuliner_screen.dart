import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../design/tokens.dart';
import 'tiket_screen.dart';

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

  String _bersihkanPathGambar(String? rawPath) {
    if (rawPath == null || rawPath.isEmpty) {
      return 'assets/images/placeholder_food.jpeg';
    }
    String namaFile = rawPath.split('/').last;
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
            if (kategori['menu_manual_brew'] != null) {
              namaKategori = 'Manual Brew';
            } else if (kategori['milk_base'] != null) {
              namaKategori = 'Milk Base';
            } else {
              namaKategori = 'Kategori Lainnya';
            }
          }

          if (!kategoriTemp.contains(namaKategori)) {
            kategoriTemp.add(namaKategori);
          }

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
                'gambar': _bersihkanPathGambar(menu['image'] ?? menu['gambar'])
              });
            }
          }

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
    final bool isDark = context.isDarkMode;
    final Color cardColor = context.surfaceCard;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;
    final Color primaryPine = context.primaryAccent;

    final filteredList = _filteredMenu;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Kuliner Wapit",
          style: AppTokens.tagline.copyWith(color: textColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPine))
          : Column(
              children: [
                // --- FILTER KATEGORI PILL CHIPS ---
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: AppTokens.sXS),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryPine : cardColor,
                            borderRadius: AppTokens.pill,
                            border: Border.all(
                              color: isSelected ? primaryPine : context.hairlineBorder,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              kat,
                              style: TextStyle(
                                color: isSelected
                                    ? (isDark ? AppTokens.surfaceBlack : AppTokens.canvas)
                                    : textColor,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                fontFamily: AppTokens.fontFamily,
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
                      ? Center(
                          child: Text(
                            "Menu tidak ditemukan.",
                            style: AppTokens.caption.copyWith(color: subTextColor),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: 8)
                              .copyWith(bottom: 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: AppTokens.sMD,
                            mainAxisSpacing: AppTokens.sMD,
                          ),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final item = filteredList[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: AppTokens.r18,
                                border: Border.all(color: context.hairlineBorder, width: 1),
                              ),
                              padding: const EdgeInsets.all(AppTokens.sMD),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Container(
                                      height: 96,
                                      width: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: context.surfaceParchment,
                                        boxShadow: AppTokens.productShadow,
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          item['gambar'],
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Icon(Icons.restaurant, color: primaryPine, size: 36);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppTokens.sMD),
                                  Text(
                                    item['nama_menu'],
                                    style: AppTokens.bodyStrong.copyWith(
                                      color: textColor,
                                      fontSize: 14,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['kedai'],
                                    style: AppTokens.microLegal.copyWith(color: subTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Rp${item['harga']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: primaryPine,
                                          fontFamily: AppTokens.fontFamily,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          final currentList =
                                              List<Map<String, dynamic>>.from(globalCart.value);

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
                                              'gambar': item['gambar'],
                                            });
                                          }

                                          globalCart.value = currentList;

                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                            content: Text("${item['nama_menu']} ditambahkan ke keranjang"),
                                            duration: const Duration(seconds: 1),
                                            backgroundColor: primaryPine,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(borderRadius: AppTokens.r11),
                                          ));
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: primaryPine,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
                                            size: 16,
                                          ),
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