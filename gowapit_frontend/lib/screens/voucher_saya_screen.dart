import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class VoucherSayaScreen extends StatefulWidget {
  const VoucherSayaScreen({super.key});

  @override
  State<VoucherSayaScreen> createState() => _VoucherSayaScreenState();
}

class _VoucherSayaScreenState extends State<VoucherSayaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _allVouchers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token');

      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        ApiConfig.uri("/api/user/vouchers"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200 && mounted) {
        final resData = jsonDecode(response.body);
        setState(() {
          _allVouchers = resData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final Color primaryColor = const Color(0xFF5E9190);

    final List<dynamic> vouchersTersedia = _allVouchers.where((v) => v['status'] == 'tersedia').toList();
    final List<dynamic> vouchersRiwayat = _allVouchers.where((v) => v['status'] != 'tersedia').toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER APPS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Voucher Saya",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: primaryColor, size: 22),
                    onPressed: _fetchVouchers,
                  ),
                ],
              ),
            ),

            // --- TAB BAR SEGMENTED ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2926) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: subTextColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Montserrat'),
                tabs: [
                  Tab(text: "Tersedia (${vouchersTersedia.length})"),
                  Tab(text: "Riwayat (${vouchersRiwayat.length})"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- TAB BAR VIEW CONTENT ---
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildVoucherList(vouchersTersedia, isAvailable: true, isDark: isDark, primaryColor: primaryColor, textColor: textColor, subTextColor: subTextColor),
                        _buildVoucherList(vouchersRiwayat, isAvailable: false, isDark: isDark, primaryColor: primaryColor, textColor: textColor, subTextColor: subTextColor),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherList(
    List<dynamic> vouchers, {
    required bool isAvailable,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    if (vouchers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.confirmation_num_outlined,
                  size: 56,
                  color: isDark ? Colors.white54 : primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isAvailable ? "Belum Ada Voucher Tersedia" : "Tidak Ada Riwayat Voucher",
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAvailable
                    ? "Ajak teman bergabung menggunakan kode referral Anda untuk mendapatkan voucher diskon tiket!"
                    : "Voucher yang telah digunakan atau kedaluwarsa akan tercatat di sini.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchVouchers,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final v = vouchers[index];
          final String kode = v['kode'] ?? '-';
          final String tipe = v['tipe'] ?? 'persen';
          final int nilai = v['nilai'] ?? 0;
          final int? maksDiskon = v['maks_diskon'];
          final bool isPersonal = v['is_personal'] == true;
          final String status = v['status'] ?? 'tersedia';

          String titleDiskon;
          if (tipe == 'persen') {
            titleDiskon = "Diskon $nilai%";
          } else {
            titleDiskon = "Potongan Rp ${nilai.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
          }

          String subtitleDiskon;
          if (tipe == 'persen' && maksDiskon != null && maksDiskon > 0) {
            subtitleDiskon = "Maks. potongan Rp ${maksDiskon.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
          } else {
            subtitleDiskon = "Tanpa batas minimum";
          }

          final Color cardBg = isDark ? const Color(0xFF24332D) : Colors.white;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isAvailable ? cardBg : (isDark ? const Color(0xFF1E2623) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAvailable
                    ? (isPersonal ? primaryColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)))
                    : (isDark ? Colors.white10 : const Color(0xFFCBD5E1)),
                width: isPersonal ? 1.5 : 1,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Voucher Icon Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? (isPersonal ? primaryColor.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.15))
                              : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPersonal ? Icons.card_giftcard_rounded : Icons.local_offer_rounded,
                          color: isAvailable ? (isPersonal ? primaryColor : Colors.amber.shade700) : Colors.grey,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Text Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isPersonal)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "REWARD REFERRAL",
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "PROMO PUBLIK",
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (!isAvailable)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              titleDiskon,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isAvailable ? textColor : Colors.grey,
                              ),
                            ),
                            Text(
                              subtitleDiskon,
                              style: TextStyle(
                                fontSize: 11,
                                color: isAvailable ? subTextColor : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Dashed separator line
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(
                      30,
                      (i) => Expanded(
                        child: Container(
                          height: 1,
                          color: i.isEven
                              ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
                              : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Code & Copy Action
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, size: 14, color: isAvailable ? primaryColor : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            kode,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 1.1,
                              color: isAvailable ? (isDark ? Colors.white : const Color(0xFF0F172A)) : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      if (isAvailable)
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: kode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Kode voucher $kode berhasil disalin!"),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, color: primaryColor, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  "Salin Kode",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Text(
                          "Tidak dapat digunakan",
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
