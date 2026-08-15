import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  bool _isOfflineTickets = false;

  @override
  void initState() {
    super.initState();
    _fetchPendingBookings();
    _fetchMyTickets();
  }

  // --- SINKRONISASI TIKET DARI BACKEND DENGAN OFFLINE CACHE ---
  Future<void> _fetchMyTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      
      // 1. Muat data dari Cache Lokal terlebih dahulu (agar instan/offline ready)
      final String? cachedJson = prefs.getString('cached_user_tickets_json');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final List<dynamic> cachedList = jsonDecode(cachedJson);
        if (mounted) {
          globalRiwayat.value = List<Map<String, dynamic>>.from(cachedList);
        }
      }

      if (token == null || token.isEmpty) return;

      // 2. Fetch data terbaru dari Backend
      final res = await http.get(
        ApiConfig.uri('/api/tickets/my'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 && mounted) {
        final body = jsonDecode(res.body);
        final List<dynamic> tickets = body['data'] ?? [];
        final converted = List<Map<String, dynamic>>.from(tickets);
        
        globalRiwayat.value = converted;
        // Simpan ke Cache Offline
        await prefs.setString('cached_user_tickets_json', jsonEncode(converted));
        setState(() => _isOfflineTickets = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isOfflineTickets = true);
      }
    }
  }

  Future<void> _fetchPendingBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        ApiConfig.uri('/api/booking'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        final List<dynamic> bookings = data['data'] ?? [];
        final currentList = List<Map<String, dynamic>>.from(globalCart.value);
        bool updated = false;

        for (var b in bookings) {
          final int bookingId = b['id'];
          final exists = currentList.any((item) => item['booking_id'] == bookingId);
          if (!exists) {
            currentList.add({
              'kategori': 'PAKET',
              'booking_id': bookingId,
              'nama': b['nama_paket'],
              'jumlah_orang': b['jumlah_orang'],
              'tanggal_mulai': b['tanggal_mulai'],
              'tanggal_akhir': b['tanggal_akhir'],
              'malam_tambahan': b['malam_tambahan'],
              'diskon': b['diskon'],
              'total_harga': b['total_harga'],
              'harga': b['total_harga'],
              'order_id': b['order_id'],
              'qty': 1,
            });
            updated = true;
          }
        }

        if (updated && mounted) {
          globalCart.value = currentList;
        }
      }
    } catch (_) {}
  }

  String formatRupiah(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  // --- LOGIKA PEMBAYARAN & PINDAH TAB ---
  void _prosesPembayaranMidtrans(int grandTotal) {
    if (grandTotal <= 0) return;
    _showPaymentOptionsModal(grandTotal);
  }

  void _showPaymentOptionsModal(int grandTotal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final Color cardColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
        final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
        final Color textColor = isDarkMode ? Colors.white : const Color(0xFF161d1b);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text("Pilih Metode Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'Montserrat')),
              const SizedBox(height: 8),
              Text("Total Pembayaran: ${formatRupiah(grandTotal)}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primaryColor)),
              const SizedBox(height: 20),

              // 1. OPSI SIMULASI SUKSES (INSTAN)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: primaryColor, width: 1.5)),
                leading: CircleAvatar(backgroundColor: primaryColor.withValues(alpha: 0.15), child: Icon(Icons.flash_on, color: primaryColor)),
                title: Text("Simulasi Bayar Instan (Sukses)", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                subtitle: const Text("Pengujian langsung tanpa bayar riil. Tiket langsung aktif.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _eksekusiSelesaiBayar(grandTotal, isSimulasi: true);
                },
              ),
              const SizedBox(height: 12),

              // 2. OPSI MIDTRANS ONLINE
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.payment, color: Colors.blue)),
                title: Text("Midtrans Online Gateway", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                subtitle: const Text("Bayar via QRIS, Bank Transfer, GoPay di halaman Midtrans.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  _eksekusiSelesaiBayar(grandTotal, isSimulasi: false);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _eksekusiSelesaiBayar(int grandTotal, {required bool isSimulasi}) async {
    setState(() => _isPaying = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final currentCart = List<Map<String, dynamic>>.from(globalCart.value);
      final currentRiwayat = List<Map<String, dynamic>>.from(globalRiwayat.value);
      String generatedOrderId = "INV/${DateTime.now().year}/${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

      // 1. Eksekusi bayar untuk setiap item PAKET (booking_id) ke backend jika ada
      for (var item in currentCart) {
        if (item['kategori'] == 'PAKET' && item['booking_id'] != null && token != null) {
          final int bookingId = item['booking_id'];
          try {
            final payRes = await http.post(
              ApiConfig.uri('/api/booking/$bookingId/pay'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({
                'mode': isSimulasi ? 'simulasi' : 'midtrans',
              }),
            );

            if (payRes.statusCode == 200 && !isSimulasi) {
              final payData = jsonDecode(payRes.body);
              final String? redirectUrl = payData['redirect_url'];
              if (redirectUrl != null && redirectUrl.isNotEmpty) {
                final Uri paymentUri = Uri.parse(redirectUrl);
                if (await canLaunchUrl(paymentUri)) {
                  await launchUrl(paymentUri, mode: LaunchMode.externalApplication);
                }
              }
            }
          } catch (_) {}
        }
      }

      // 2. Jika ada item kuliner dan bayar via Midtrans online, buat transaksi Midtrans checkout umum
      int totalKulinerQty = 0;
      int totalKulinerHarga = 0;
      List<String> namaKulinerList = [];

      for (var item in currentCart) {
        if (item['kategori'] == 'KULINER') {
          int hargaItem = int.tryParse(item['harga'].toString()) ?? 0;
          int qty = item['qty'] ?? 1;
          totalKulinerQty += qty;
          totalKulinerHarga += (hargaItem * qty);
          namaKulinerList.add(item['nama']);
        }
      }

      if (totalKulinerQty > 0 && !isSimulasi) {
        try {
          final orderData = {
            "order_id": "WPT-KULINER-${DateTime.now().millisecondsSinceEpoch}", 
            "gross_amount": totalKulinerHarga, 
            "customer_details": {
              "first_name": "Petualang Wapit", 
              "email": "petualang@gmail.com"
            }
          };
          final response = await http.post(
            ApiConfig.uri('/api/checkout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(orderData),
          );
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            final String? redirectUrl = responseData['redirect_url'];
            if (redirectUrl != null && redirectUrl.isNotEmpty) {
              final Uri paymentUri = Uri.parse(redirectUrl);
              if (await canLaunchUrl(paymentUri)) {
                await launchUrl(paymentUri, mode: LaunchMode.externalApplication); 
              }
            }
          }
        } catch (_) {}
      }

      // 3. Masukkan item-item ke Riwayat E-Tiket
      for (var item in currentCart) {
        if (item['kategori'] == 'PAKET') {
          String tglPakai = item['tanggal_mulai'] ?? 'Berlaku Hari Ini';
          if (item['tanggal_akhir'] != null && item['tanggal_akhir'].toString().isNotEmpty) {
            tglPakai = "${item['tanggal_mulai']} s/d ${item['tanggal_akhir']}";
          }
          final int itemTotal = int.tryParse((item['total_harga'] ?? item['harga'] ?? 0).toString()) ?? 0;
          final int orang = item['jumlah_orang'] ?? item['qty'] ?? 1;

          currentRiwayat.insert(0, { 
            'kategori': 'PAKET',
            'nama': item['nama'],
            'tanggal_pakai': tglPakai,
            'order_id': item['order_id'] ?? generatedOrderId,
            'qty': orang,
            'total_harga': formatRupiah(itemTotal),
            'status': 'Aktif', 
          });
        }
      }

      if (totalKulinerQty > 0) {
        String namaMenuGabungan = "";
        if (namaKulinerList.length <= 2) {
          namaMenuGabungan = namaKulinerList.join(', ');
        } else {
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

      globalRiwayat.value = currentRiwayat; 
      globalCart.value = []; 

      if (mounted) {
        setState(() {
          _selectedTab = 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pembayaran Berhasil! E-Tiket Anda telah terbit.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    final Color dividerColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text("Keranjang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Montserrat')),
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
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    final Color tagBgColor = isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFeef5f2);
    final Color dividerColor = isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey.shade200;
    final List<BoxShadow> ambientShadow = isDarkMode ? [] : [BoxShadow(color: const Color(0xFF5E9190).withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 6))];

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
        int totalDiskon = 0;

        for (var item in cartItems) {
          int harga = int.tryParse((item['total_harga'] ?? item['harga'] ?? 0).toString()) ?? 0;
          int qty = item['qty'] ?? 1;
          totalHargaBarang += (harga * qty);
          totalBarang += (item['kategori'] == 'PAKET' ? (item['jumlah_orang'] ?? qty) : qty) as int;
          if (item['diskon'] != null) {
            totalDiskon += (item['diskon'] as num).toInt();
          }
        }

        int biayaLayanan = 2000;
        int grandTotal = totalHargaBarang + biayaLayanan;

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
                  _buildSummaryRow("Total Harga ($totalBarang Item/Tiket)", formatRupiah(totalHargaBarang + totalDiskon), textColor),
                  if (totalDiskon > 0) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow("Diskon Voucher", "- ${formatRupiah(totalDiskon)}", const Color(0xFF4CAF50)),
                  ],
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
  // SECTION 2: BERHASIL (E-TIKET DINAMIS DENGAN OFFLINE CACHE)
  // ===========================================================================
  Widget _buildBerhasilSection(bool isDarkMode, Color primaryColor) {
    return RefreshIndicator(
      onRefresh: _fetchMyTickets,
      color: primaryColor,
      child: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: globalRiwayat,
        builder: (context, riwayatItems, child) {
          if (riwayatItems.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 80, color: primaryColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text("Belum ada tiket yang dibayar.", style: TextStyle(color: primaryColor, fontFamily: 'Inter')),
                    ],
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 120),
            itemCount: riwayatItems.length + (_isOfflineTickets ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isOfflineTickets && index == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.offline_bolt_rounded, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Mode Offline: E-Tiket tersimpan di memori HP & tetap siap di-scan.",
                          style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final actualIndex = _isOfflineTickets ? index - 1 : index;
              return BerhasilTicketCard(
                data: riwayatItems[actualIndex],
                isDarkMode: isDarkMode,
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET CART ITEM (Mendukung PAKET & KULINER) ---
  Widget _buildCartItem(
    int index, Map<String, dynamic> item, bool isDarkMode, Color cardColor, Color textColor, 
    Color subTextColor, Color primaryColor, Color tagBgColor, Color dividerColor, List<BoxShadow> shadow
  ) {
    final bool isPaket = item['kategori'] == 'PAKET';
    final int harga = int.tryParse((item['total_harga'] ?? item['harga'] ?? 0).toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: shadow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar / Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isPaket
                ? Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.confirmation_number_outlined, color: primaryColor, size: 36),
                  )
                : Image.asset(
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
                // Tag & Tombol Hapus
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(item['kategori'] ?? 'ITEM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor, letterSpacing: 0.5)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // Jika item paket dengan booking_id, batalkan ke backend
                        if (isPaket && item['booking_id'] != null) {
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('jwt_token');
                          if (token != null) {
                            try {
                              await http.delete(
                                ApiConfig.uri('/api/booking/${item['booking_id']}'),
                                headers: {'Authorization': 'Bearer $token'},
                              );
                            } catch (_) {}
                          }
                        }
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

                // Subtitle / Info Detail
                if (isPaket) ...[
                  Text(
                    item['tanggal_akhir'] != null && item['tanggal_akhir'].toString().isNotEmpty
                        ? "📅 ${item['tanggal_mulai']} s/d ${item['tanggal_akhir']}"
                        : "📅 ${item['tanggal_mulai'] ?? '-'}",
                    style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text("👥 ${item['jumlah_orang'] ?? 1} Orang", style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter')),
                      if (item['malam_tambahan'] != null && item['malam_tambahan'] > 0) ...[
                        const SizedBox(width: 6),
                        Text("• ⛺ ${item['malam_tambahan']} Malam", style: TextStyle(fontSize: 11, color: subTextColor, fontFamily: 'Inter')),
                      ],
                    ],
                  ),
                  if (item['diskon'] != null && item['diskon'] > 0) ...[
                    const SizedBox(height: 2),
                    Text("🏷️ Hemat ${formatRupiah(item['diskon'])}", style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                  ],
                ] else ...[
                  Text(item['kedai'] ?? item['subtitle'] ?? '-', style: TextStyle(fontSize: 11, color: subTextColor)),
                ],

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatRupiah(harga), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryColor)),
                    if (isPaket)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(8)),
                        child: Text("${item['jumlah_orang'] ?? 1} Tiket", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
                      )
                    else
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
      onTap: () {
        setState(() => _selectedTab = index);
        if (index == 0) {
          _fetchPendingBookings();
        } else if (index == 1) {
          _fetchMyTickets();
        }
      },
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
                const SizedBox(height: 20),
                
                // --- KODE QR DINAMIS DENGAN QR_FLUTTER ---
                Container(
                  width: 210,
                  height: 210,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFB3D89C), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: QrImageView(
                      data: data['ticket_code'] ?? data['order_id'] ?? 'WPT-TICKET',
                      version: QrVersions.auto,
                      size: 186,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                
                // Kode Tiket
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F6F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['ticket_code'] ?? data['order_id'] ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: primaryColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                
                Divider(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, thickness: 1),
                const SizedBox(height: 14),
                
                // Rincian Pesanan
                _buildDetailRow("Kategori", data['kategori'] ?? '-', subTextColor, textColor),
                const SizedBox(height: 12),
                _buildDetailRow("Item", data['nama'] ?? '-', subTextColor, textColor),
                const SizedBox(height: 12),
                _buildDetailRow("Jumlah", "${data['qty']} ${data['kategori'] == 'PAKET' ? 'Orang' : 'Item'}", subTextColor, textColor),
                const SizedBox(height: 12),
                _buildDetailRow("Tanggal", data['tanggal_pakai'] ?? '-', subTextColor, textColor),
                
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
    final Color primaryColor = isDarkMode ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);
    const Color successColor = Color(0xFF4CAF50);
    final Color dividerColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200;
    final bool isAktif = data['status'] == 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(color: const Color(0xFF5E9190).withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
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
                      Text("${data['qty']} ${data['kategori'] == 'PAKET' ? 'Orang' : 'Item'} • ${data['total_harga']}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor, fontFamily: 'Inter')),
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