import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

// ============================================================================
// STATE KERANJANG & RIWAYAT GLOBAL
// ============================================================================
final ValueNotifier<List<Map<String, dynamic>>> globalCart = ValueNotifier([]);
final ValueNotifier<List<Map<String, dynamic>>> globalRiwayat = ValueNotifier([]); 

class TiketPage extends StatefulWidget {
  const TiketPage({super.key});

  @override
  State<TiketPage> createState() => _TiketPageState();
}

class _TiketPageState extends State<TiketPage> {
  int _selectedTab = 0; 
  bool _isPaying = false; 

  String formatRupiah(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // --- LOGIKA PEMBAYARAN & PINDAH TAB ---
  Future<void> _prosesPembayaranMidtrans(int grandTotal) async {
    if (grandTotal <= 0) return;
    setState(() => _isPaying = true);

    try {
      final orderData = {
        "order_id": "WPT-${DateTime.now().millisecondsSinceEpoch}", 
        "gross_amount": grandTotal, 
        "customer_details": {
          "first_name": "Petualang Wapit", 
          "email": "petualang@gmail.com"
        }
      };

      // 1. Tembak API Backend
      final response = await http.post(
        ApiConfig.uri('/api/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String redirectUrl = responseData['redirect_url'];

        // 2. Buka halaman pembayaran Midtrans
        final Uri paymentUri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(paymentUri)) {
          await launchUrl(paymentUri, mode: LaunchMode.externalApplication); 
        }

        // ===========================================================
        // 3. LOGIKA MEMINDAHKAN KERANJANG KE TAB BERHASIL (PENGGABUNGAN KULINER)
        // ===========================================================
        final currentRiwayat = List<Map<String, dynamic>>.from(globalRiwayat.value);
        final currentCart = List<Map<String, dynamic>>.from(globalCart.value);
        
        String generatedOrderId = "INV/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

        // Variabel penampung khusus untuk KULINER
        int totalKulinerQty = 0;
        int totalKulinerHarga = 0;
        List<String> namaKulinerList = [];

        // Evaluasi isi keranjang
        for (var item in currentCart) {
          int hargaItem = int.tryParse(item['harga'].toString()) ?? 0;
          int qty = item['qty'] ?? 1;

          if (item['kategori'] == 'KULINER') {
            // Jika Kuliner, kumpulkan datanya (jangan langsung dibuatkan tiket)
            totalKulinerQty += qty;
            totalKulinerHarga += (hargaItem * qty);
            namaKulinerList.add(item['nama']);
          } else {
            // Jika BUKAN Kuliner (Misal: Paket), buatkan tiket terpisah langsung
            currentRiwayat.insert(0, { 
              'kategori': item['kategori'],
              'nama': item['nama'],
              'tanggal_pakai': 'Berlaku Hari Ini',
              'order_id': generatedOrderId,
              'qty': qty,
              'total_harga': formatRupiah(hargaItem * qty),
              'status': 'Aktif', 
            });
          }
        }

        // Jika ternyata ada pesanan Kuliner, gabungkan semuanya jadi 1 Tiket
        if (totalKulinerQty > 0) {
          String namaMenuGabungan = "";
          
          // Jika pesan 1 atau 2 menu, tuliskan namanya utuh
          if (namaKulinerList.length <= 2) {
            namaMenuGabungan = namaKulinerList.join(', ');
          } 
          // Jika pesanan lebih dari 2 jenis, berikan teks tambahan "+ X lainnya" agar UI rapi
          else {
            namaMenuGabungan = "${namaKulinerList[0]}, ${namaKulinerList[1]}, +${namaKulinerList.length - 2} Lainnya";
          }

          currentRiwayat.insert(0, {
            'kategori': 'KULINER',
            'nama': namaMenuGabungan,
            'tanggal_pakai': 'Berlaku Hari Ini',
            'order_id': generatedOrderId,
            'qty': totalKulinerQty,
            'total_harga': formatRupiah(totalKulinerHarga),
            'status': 'Aktif',
          });
        }

        // Update State
        globalRiwayat.value = currentRiwayat; 
        globalCart.value = []; 

        if (mounted) {
          setState(() {
            _selectedTab = 1;
          });
        }

      } else {
        throw "Server Error: ${response.statusCode}";
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    final Color dividerColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text("Keranjang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Montserrat')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildTabButton("Menunggu", 0, isDarkMode, primaryColor)),
                  Expanded(child: _buildTabButton("Berhasil", 1, isDarkMode, primaryColor)),
                ],
              ),
            ),
          ),
          Expanded(
            child: _selectedTab == 0 
                ? _buildMenungguSection(isDarkMode)
                : _buildBerhasilSection(isDarkMode, primaryColor),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 1: MENUNGGU (KERANJANG)
  // ===========================================================================
  Widget _buildMenungguSection(bool isDarkMode) {
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    final Color tagBgColor = isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFeef5f2);
    final Color dividerColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200;
    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [BoxShadow(color: const Color(0xFF659287).withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 6))];

    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: globalCart,
      builder: (context, cartItems, child) {
        if (cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: primaryColor.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text("Keranjangmu masih kosong", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
                const SizedBox(height: 8),
                Text("Yuk, eksplorasi destinasi dan menu lezat!", style: TextStyle(color: subTextColor, fontFamily: 'Inter')),
              ],
            ),
          );
        }

        int totalHargaBarang = 0;
        int totalBarang = 0;
        for (var item in cartItems) {
          int harga = int.tryParse(item['harga'].toString()) ?? 0;
          int qty = item['qty'] ?? 1;
          totalHargaBarang += (harga * qty);
          totalBarang += qty;
        }

        int diskon = 0; 
        int biayaLayanan = 2000;
        int grandTotal = totalHargaBarang - diskon + biayaLayanan;

        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          children: [
            ...List.generate(cartItems.length, (index) {
              final item = cartItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildCartItem(index, item, isDarkMode, cardColor, textColor, subTextColor, primaryColor, tagBgColor, dividerColor, ambientShadow),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: subTextColor, size: 20),
                      const SizedBox(width: 8),
                      Text("Ringkasan Belanja", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow("Total Harga ($totalBarang Barang)", formatRupiah(totalHargaBarang), textColor),
                  const SizedBox(height: 8),
                  _buildSummaryRow("Diskon", "- ${formatRupiah(diskon)}", const Color(0xFF4CAF50)),
                  const SizedBox(height: 8),
                  _buildSummaryRow("Biaya Layanan", formatRupiah(biayaLayanan), textColor),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: dividerColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: ambientShadow),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Bayar", style: TextStyle(fontSize: 12, color: subTextColor)),
                      Text(formatRupiah(grandTotal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Montserrat')),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isPaying ? null : () => _prosesPembayaranMidtrans(grandTotal),
                    child: _isPaying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Row(
                            children: [
                              Text("Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 16),
                            ],
                          ),
                  )
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  // ===========================================================================
  // SECTION 2: BERHASIL (E-TIKET DINAMIS)
  // ===========================================================================
  Widget _buildBerhasilSection(bool isDarkMode, Color primaryColor) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: globalRiwayat,
      builder: (context, riwayatItems, child) {
        if (riwayatItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.confirmation_number_outlined, size: 80, color: primaryColor.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text("Belum ada tiket yang dibayar.", style: TextStyle(color: primaryColor, fontFamily: 'Inter')),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
          itemCount: riwayatItems.length,
          itemBuilder: (context, index) {
            return BerhasilTicketCard(
              data: riwayatItems[index],
              isDarkMode: isDarkMode,
            );
          },
        );
      },
    );
  }

  // --- WIDGET PELENGKAP ---
  Widget _buildCartItem(
    int index, Map<String, dynamic> item, bool isDarkMode, Color cardColor, Color textColor, 
    Color subTextColor, Color primaryColor, Color tagBgColor, Color dividerColor, List<BoxShadow> shadow
  ) {
    int harga = int.tryParse(item['harga'].toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              ((item['gambar'] ?? 'assets/images/placeholder.jpeg').toString().startsWith('assets/'))
                  ? item['gambar']
                  : 'assets/${item['gambar']}',
              width: 70, height: 70, fit: BoxFit.cover, 
              errorBuilder: (c, e, s) => Container(width: 70, height: 70, color: dividerColor, child: Icon(Icons.image_outlined, color: subTextColor))
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(item['kategori'] ?? 'ITEM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5)),
                    ),
                    GestureDetector(
                      onTap: () {
                        final currentList = List<Map<String, dynamic>>.from(globalCart.value);
                        currentList.removeAt(index);
                        globalCart.value = currentList; 
                      },
                      child: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade400),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(item['nama'] ?? '-', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: textColor, fontFamily: 'Montserrat'), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item['kedai'] ?? item['subtitle'] ?? '-', style: TextStyle(fontSize: 11, color: subTextColor)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah(harga), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (item['qty'] > 1) {
                                final currentList = List<Map<String, dynamic>>.from(globalCart.value);
                                currentList[index]['qty']--;
                                globalCart.value = currentList;
                              }
                            },
                            child: Icon(Icons.remove, size: 16, color: subTextColor)
                          ),
                          const SizedBox(width: 12),
                          Text("${item['qty']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              final currentList = List<Map<String, dynamic>>.from(globalCart.value);
                              currentList[index]['qty']++;
                              globalCart.value = currentList;
                            },
                            child: Icon(Icons.add, size: 16, color: primaryColor)
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  Widget _buildTabButton(String title, int index, bool isDarkMode, Color primaryColor) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
            color: isSelected ? (isDarkMode ? const Color(0xFF121212) : Colors.white) : Colors.grey, 
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// WIDGET KARTU E-TIKET & POP-UP DIALOG TIKET
// ===========================================================================
class BerhasilTicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDarkMode;

  const BerhasilTicketCard({super.key, required this.data, required this.isDarkMode});

  // --- FUNGSI MEMUNCULKAN POP-UP E-TIKET ---
  void _tampilkanETiket(BuildContext context, Color primaryColor, Color textColor, Color subTextColor) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min, 
              children: [
                // Header
                Text(
                  "E-Tiket Go Wapit", 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Montserrat')
                ),
                const SizedBox(height: 24),
                
                // --- KODE QR DIPERBESAR & WARNA HITAM ---
                Container(
                  width: 200,  // Diperbesar dari 160 ke 200
                  height: 200, // Diperbesar dari 160 ke 200
                  decoration: BoxDecoration(
                    color: Colors.white, // Wajib putih agar alat scan bisa membacanya
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2) // Tambahan garis tepi tipis
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_2, 
                      size: 180, // Diperbesar dari 120 ke 180
                      color: Colors.black // Diubah menjadi hitam pekat
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(data['order_id'] ?? '-', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: subTextColor, fontFamily: 'Inter')),
                const SizedBox(height: 24),
                
                Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1),
                const SizedBox(height: 16),
                
                // Rincian Pesanan
                _buildDetailRow("Kategori", data['kategori'] ?? '-', subTextColor, textColor),
                const SizedBox(height: 12),
                _buildDetailRow("Item", data['nama'] ?? '-', subTextColor, textColor),
                const SizedBox(height: 12),
                _buildDetailRow("Jumlah", "${data['qty']} Item", subTextColor, textColor),
                
                const SizedBox(height: 24),
                
                // --- PERINGATAN PEMAKAIAN 1 KALI ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3))
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Perhatian: E-Tiket ini hanya berlaku untuk 1 (satu) kali penggunaan atau penukaran di lokasi.", 
                          style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.orange.shade300 : Colors.orange.shade800, fontFamily: 'Inter', height: 1.4)
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tombol Tutup
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  // Widget pembantu untuk baris rincian di dalam Pop-up
  Widget _buildDetailRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 13, fontFamily: 'Inter')),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value, 
            textAlign: TextAlign.right, 
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13, fontFamily: 'Inter')
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : const Color(0xFF404846);
    final Color primaryColor = isDarkMode ? const Color(0xFF88BDA4) : const Color(0xFF659287);
    const Color successColor = Color(0xFF4CAF50);
    final Color dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final bool isAktif = data['status'] == 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(color: const Color(0xFF659287).withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE6F2DD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.confirmation_number_outlined, color: primaryColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey.shade800 : const Color(0xFFE6F2DD),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(data['kategori'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Inter', letterSpacing: 0.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAktif ? successColor.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(data['status'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAktif ? successColor : Colors.grey, fontFamily: 'Inter')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['nama'] ?? '-', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat'),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(data['tanggal_pakai'] ?? '-', style: TextStyle(fontSize: 12, color: subTextColor, fontFamily: 'Inter')),
                      const SizedBox(height: 8),
                      Text("${data['qty']} Item • ${data['total_harga']}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Row(
            children: [
              SizedBox(height: 20, width: 10, child: DecoratedBox(decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD), borderRadius: const BorderRadius.horizontal(right: Radius.circular(20))))),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dashCount = (constraints.constrainWidth() / 10).floor();
                    return Flex(
                      direction: Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(dashCount, (_) => SizedBox(width: 5.0, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: dividerColor)))),
                    );
                  },
                ),
              ),
              SizedBox(height: 20, width: 10, child: DecoratedBox(decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6F2DD), borderRadius: const BorderRadius.horizontal(left: Radius.circular(20))))),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order ID", style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter')),
                    const SizedBox(height: 2),
                    Text(data['order_id'] ?? '-', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Inter')),
                  ],
                ),
                if (isAktif) 
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _tampilkanETiket(context, primaryColor, textColor, subTextColor), 
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text("E-Tiket", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                  )
                else 
                   ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                      foregroundColor: subTextColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {},
                    child: const Text("Beli Lagi", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}