import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingVouchers = true;
  bool _isLoadingConfig = true;
  bool _isSavingConfig = false;

  List<Map<String, dynamic>> _vouchers = [];

  // Referral config controllers
  String _refereeType = "persen";
  final TextEditingController _refereeNilaiController = TextEditingController(text: "10");
  String _referrerType = "persen";
  final TextEditingController _referrerNilaiController = TextEditingController(text: "10");
  final TextEditingController _maxPenggunaanController = TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refereeNilaiController.dispose();
    _referrerNilaiController.dispose();
    _maxPenggunaanController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchVouchers(),
      _fetchReferralConfig(),
    ]);
  }

  // ==========================================
  // VOUCHER MANAGEMENT
  // ==========================================
  Future<void> _fetchVouchers() async {
    setState(() => _isLoadingVouchers = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        ApiConfig.uri("/api/vouchers"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data["data"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
        if (mounted) {
          setState(() {
            _vouchers = list;
            _isLoadingVouchers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingVouchers = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVouchers = false);
    }
  }

  Future<void> _deleteVoucher(int id, String kode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Voucher", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus voucher '$kode'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();
      final res = await http.delete(
        ApiConfig.uri("/api/vouchers/$id"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Voucher '$kode' berhasil dihapus!"),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchVouchers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus: $e")),
        );
      }
    }
  }

  Future<void> _toggleVoucherStatus(Map<String, dynamic> voucher) async {
    final int currentAktif = voucher["aktif"] == 1 ? 1 : 0;
    final int newAktif = currentAktif == 1 ? 0 : 1;

    try {
      final token = await _getToken();
      final res = await http.put(
        ApiConfig.uri("/api/vouchers/${voucher['id']}"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"aktif": newAktif}),
      );

      if (res.statusCode == 200 && mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          voucher["aktif"] = newAktif;
        });
      }
    } catch (_) {}
  }

  void _showVoucherDialog({Map<String, dynamic>? voucher}) {
    final bool isEdit = voucher != null;
    final kodeCtrl = TextEditingController(text: voucher != null ? voucher["kode"] : "");
    String tipe = voucher != null ? (voucher["tipe"] ?? "persen") : "persen";
    final nilaiCtrl = TextEditingController(text: voucher != null ? "${voucher["nilai"]}" : "10");
    final maksDiskonCtrl = TextEditingController(
        text: voucher != null && voucher["maks_diskon"] != null ? "${voucher["maks_diskon"]}" : "");
    final kuotaCtrl = TextEditingController(text: voucher != null ? "${voucher["kuota"]}" : "100");
    bool aktif = voucher != null ? (voucher["aktif"] == 1) : true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF161D1B);
        final primaryColor = isDark ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? "Edit Voucher" : "Buat Voucher Baru",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Kode Voucher
                    TextField(
                      controller: kodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Kode Voucher",
                        hintText: "Contoh: PROMO-WAPIT",
                        labelStyle: TextStyle(color: primaryColor),
                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: primaryColor),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tipe Diskon Segmented
                    Text("Tipe Diskon", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Persentase (%)")),
                            selected: tipe == "persen",
                            selectedColor: primaryColor.withValues(alpha: 0.2),
                            onSelected: (val) => setModalState(() => tipe = "persen"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text("Nominal (Rp)")),
                            selected: tipe == "nominal",
                            selectedColor: primaryColor.withValues(alpha: 0.2),
                            onSelected: (val) => setModalState(() => tipe = "nominal"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nilai & Maks Diskon
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nilaiCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: tipe == "persen" ? "Diskon (%)" : "Diskon (Rp)",
                              labelStyle: TextStyle(color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                        ),
                        if (tipe == "persen") ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: maksDiskonCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Maks. (Rp opsional)",
                                hintText: "50000",
                                labelStyle: TextStyle(color: primaryColor),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Kuota & Status Aktif
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: kuotaCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: "Kuota Penggunaan",
                              hintText: "100",
                              labelStyle: TextStyle(color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status", style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                            Switch(
                              value: aktif,
                              activeTrackColor: primaryColor,
                              onChanged: (val) => setModalState(() => aktif = val),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Submit
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final kode = kodeCtrl.text.trim().toUpperCase();
                                if (kode.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Kode voucher wajib diisi")),
                                  );
                                  return;
                                }

                                final int nilai = int.tryParse(nilaiCtrl.text) ?? 10;
                                final int? maksDiskon =
                                    maksDiskonCtrl.text.isNotEmpty ? int.tryParse(maksDiskonCtrl.text) : null;
                                final int kuota = int.tryParse(kuotaCtrl.text) ?? 100;

                                setModalState(() => isSaving = true);
                                try {
                                  final token = await _getToken();
                                  final body = jsonEncode({
                                    "kode": kode,
                                    "tipe": tipe,
                                    "nilai": nilai,
                                    "maks_diskon": maksDiskon,
                                    "kuota": kuota,
                                    "aktif": aktif ? 1 : 0,
                                  });

                                  final http.Response res;
                                  if (isEdit) {
                                    res = await http.put(
                                      ApiConfig.uri("/api/vouchers/${voucher['id']}"),
                                      headers: {
                                        "Authorization": "Bearer $token",
                                        "Content-Type": "application/json",
                                      },
                                      body: body,
                                    );
                                  } else {
                                    res = await http.post(
                                      ApiConfig.uri("/api/vouchers"),
                                      headers: {
                                        "Authorization": "Bearer $token",
                                        "Content-Type": "application/json",
                                      },
                                      body: body,
                                    );
                                  }

                                  final resData = jsonDecode(res.body);
                                  if (res.statusCode == 200 && mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(resData["message"] ?? "Berhasil!"),
                                        backgroundColor: const Color(0xFF2E7D32),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                    _fetchVouchers();
                                  } else {
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(resData["detail"] ?? "Gagal menyimpan voucher")),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Terjadi kesalahan: $e")),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isEdit ? "Perbarui Voucher" : "Simpan Voucher",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // REFERRAL CONFIG MANAGEMENT
  // ==========================================
  Future<void> _fetchReferralConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        ApiConfig.uri("/api/referral/config"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)["data"];
        if (data != null && mounted) {
          setState(() {
            _refereeType = data["reward_referee_type"] ?? "persen";
            _refereeNilaiController.text = "${data["reward_referee_nilai"] ?? 10}";
            _referrerType = data["reward_referrer_type"] ?? "persen";
            _referrerNilaiController.text = "${data["reward_referrer_nilai"] ?? 10}";
            _maxPenggunaanController.text = "${data["max_penggunaan"] ?? 0}";
            _isLoadingConfig = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingConfig = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingConfig = false);
    }
  }

  Future<void> _saveReferralConfig() async {
    setState(() => _isSavingConfig = true);
    try {
      final token = await _getToken();
      final int refereeNilai = int.tryParse(_refereeNilaiController.text) ?? 10;
      final int referrerNilai = int.tryParse(_referrerNilaiController.text) ?? 10;
      final int maxPenggunaan = int.tryParse(_maxPenggunaanController.text) ?? 0;

      final res = await http.put(
        ApiConfig.uri("/api/referral/config"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "reward_referee_type": _refereeType,
          "reward_referee_nilai": refereeNilai,
          "reward_referrer_type": _referrerType,
          "reward_referrer_nilai": referrerNilai,
          "max_penggunaan": maxPenggunaan,
        }),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Pengaturan referral berhasil disimpan!"),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["detail"] ?? "Gagal menyimpan pengaturan")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF161D1B);
    final Color primaryColor = isDark ? const Color(0xFF9DC3C2) : const Color(0xFF5E9190);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Panel Administrator",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            fontFamily: 'Montserrat',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
          tabs: const [
            Tab(icon: Icon(Icons.confirmation_number_outlined), text: "Kelola Voucher"),
            Tab(icon: Icon(Icons.card_giftcard_outlined), text: "Pengaturan Referral"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVouchersTab(isDark, cardColor, textColor, primaryColor),
          _buildReferralConfigTab(isDark, cardColor, textColor, primaryColor),
        ],
      ),
    );
  }

  Widget _buildVouchersTab(bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    if (_isLoadingVouchers) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return RefreshIndicator(
      onRefresh: _fetchVouchers,
      color: primaryColor,
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
        children: [
          // Header action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "DAFTAR VOUCHER AKTIF",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 1.2,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      "${_vouchers.length} Total Voucher",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => _showVoucherDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Buat Voucher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_vouchers.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    "Belum ada voucher",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Buat voucher diskon pertama Anda untuk menarik wisatawan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            ..._vouchers.map((v) => _buildVoucherCard(v, isDark, cardColor, textColor, primaryColor)),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(
      Map<String, dynamic> v, bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    final bool isAktif = v["aktif"] == 1;
    final String tipe = v["tipe"] ?? "persen";
    final int nilai = v["nilai"] ?? 0;
    final int kuota = v["kuota"] ?? 0;
    final int terpakai = v["terpakai"] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAktif ? primaryColor.withValues(alpha: 0.3) : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.confirmation_number, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v["kode"] ?? "-",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: 1.1,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      tipe == "persen" ? "Diskon $nilai%" : "Diskon Rp $nilai",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAktif ? const Color(0xFF2E7D32).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAktif ? "AKTIF" : "NONAKTIF",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isAktif ? const Color(0xFF2E7D32) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Metadata Kuota & Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 15, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        "Terpakai: $terpakai / ${kuota == 0 ? '∞' : kuota}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle Switch
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: Icon(
                      isAktif ? Icons.visibility : Icons.visibility_off,
                      color: isAktif ? primaryColor : Colors.grey,
                      size: 20,
                    ),
                    tooltip: isAktif ? "Nonaktifkan" : "Aktifkan",
                    onPressed: () => _toggleVoucherStatus(v),
                  ),
                  const SizedBox(width: 4),
                  // Edit
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                    tooltip: "Edit Voucher",
                    onPressed: () => _showVoucherDialog(voucher: v),
                  ),
                  const SizedBox(width: 4),
                  // Delete
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(6),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: "Hapus Voucher",
                    onPressed: () => _deleteVoucher(v["id"], v["kode"] ?? ""),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralConfigTab(
      bool isDark, Color cardColor, Color textColor, Color primaryColor) {
    if (_isLoadingConfig) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Atur otomatis persentase/nominal diskon yang diperoleh pengguna baru dan pemilik kode referral.",
                    style: TextStyle(fontSize: 12, color: textColor, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Referee (Pengguna Baru)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_add_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Reward Pengguna Baru (Referee)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Voucher diskon otomatis untuk orang yang baru mendaftar pakai kode referral.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),

                // Tipe Segmented
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Persentase (%)")),
                        selected: _refereeType == "persen",
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _refereeType = "persen"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Nominal (Rp)")),
                        selected: _refereeType == "nominal",
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _refereeType = "nominal"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _refereeNilaiController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: _refereeType == "persen" ? "Besar Diskon (%)" : "Besar Diskon (Rp)",
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Referrer (Pemilik Kode)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.military_tech_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Reward Pemilik Kode (Referrer)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Voucher diskon otomatis untuk pemilik kode saat kodenya berhasil dipakai.",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),

                // Tipe Segmented
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Persentase (%)")),
                        selected: _referrerType == "persen",
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _referrerType = "persen"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("Nominal (Rp)")),
                        selected: _referrerType == "nominal",
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        onSelected: (val) => setState(() => _referrerType = "nominal"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _referrerNilaiController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: _referrerType == "persen" ? "Besar Diskon (%)" : "Besar Diskon (Rp)",
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Batas Penggunaan
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed_outlined, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Batas Maksimal Penggunaan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "Isi 0 untuk tanpa batas (unlimited).",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _maxPenggunaanController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Maks. Penggunaan per User (0 = Unlimited)",
                    labelStyle: TextStyle(color: primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isSavingConfig ? null : _saveReferralConfig,
              child: _isSavingConfig
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      "Simpan Pengaturan Referral",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Montserrat',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
