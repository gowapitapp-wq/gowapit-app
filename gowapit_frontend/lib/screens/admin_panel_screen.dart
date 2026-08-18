import 'dart:convert';
import 'package:flutter/material.dart';
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

  List<dynamic> _vouchers = [];

  // Referral Config State
  String _refereeType = "persen";
  final TextEditingController _refereeNilaiCtrl = TextEditingController();
  String _referrerType = "persen";
  final TextEditingController _referrerNilaiCtrl = TextEditingController();
  final TextEditingController _maxPenggunaanCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchVouchers();
    _fetchReferralConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refereeNilaiCtrl.dispose();
    _referrerNilaiCtrl.dispose();
    _maxPenggunaanCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> _fetchVouchers() async {
    setState(() => _isLoadingVouchers = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        ApiConfig.uri("/api/vouchers"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        setState(() {
          _vouchers = data['data'] ?? [];
          _isLoadingVouchers = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingVouchers = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingVouchers = false);
    }
  }

  Future<void> _fetchReferralConfig() async {
    setState(() => _isLoadingConfig = true);
    try {
      final token = await _getToken();
      if (token == null) return;

      final res = await http.get(
        ApiConfig.uri("/api/referral/config"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body)['data'] ?? {};
        setState(() {
          _refereeType = data['reward_referee_type'] ?? "persen";
          _refereeNilaiCtrl.text = (data['reward_referee_nilai'] ?? 10).toString();
          _referrerType = data['reward_referrer_type'] ?? "persen";
          _referrerNilaiCtrl.text = (data['reward_referrer_nilai'] ?? 10).toString();
          _maxPenggunaanCtrl.text = (data['max_penggunaan'] ?? 0).toString();
          _isLoadingConfig = false;
        });
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
      if (token == null) return;

      final body = {
        "reward_referee_type": _refereeType,
        "reward_referee_nilai": int.tryParse(_refereeNilaiCtrl.text) ?? 10,
        "reward_referrer_type": _referrerType,
        "reward_referrer_nilai": int.tryParse(_referrerNilaiCtrl.text) ?? 10,
        "max_penggunaan": int.tryParse(_maxPenggunaanCtrl.text) ?? 0,
      };

      final res = await http.put(
        ApiConfig.uri("/api/referral/config"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konfigurasi referral berhasil disimpan!")),
        );
      } else {
        if (mounted) {
          try {
            final err = jsonDecode(res.body);
            final msg = ApiConfig.extractErrorMessage(err['detail'], fallback: "Gagal menyimpan konfigurasi referral.");
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Gagal menyimpan konfigurasi referral.")),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: ${ApiConfig.extractErrorMessage(e)}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingConfig = false);
    }
  }

  Future<void> _deleteVoucher(int voucherId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Voucher"),
        content: const Text("Apakah Anda yakin ingin menghapus voucher ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
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
      if (token == null) return;

      final res = await http.delete(
        ApiConfig.uri("/api/vouchers/$voucherId"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Voucher berhasil dihapus!")),
        );
        _fetchVouchers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus voucher: $e")),
        );
      }
    }
  }

  void _showVoucherModal({Map<String, dynamic>? editVoucher}) {
    final bool isEdit = editVoucher != null;
    final kodeCtrl = TextEditingController(text: isEdit ? editVoucher['kode'] : "");
    String tipe = isEdit ? (editVoucher['tipe'] ?? "persen") : "persen";
    final nilaiCtrl = TextEditingController(text: isEdit ? editVoucher['nilai'].toString() : "");
    final maksDiskonCtrl = TextEditingController(text: isEdit ? (editVoucher['maks_diskon']?.toString() ?? "") : "");
    final kuotaCtrl = TextEditingController(text: isEdit ? (editVoucher['kuota']?.toString() ?? "100") : "100");
    final userIdCtrl = TextEditingController(text: isEdit ? (editVoucher['user_id']?.toString() ?? "") : "");
    bool aktif = isEdit ? (editVoucher['aktif'] == 1) : true;
    bool isSavingModal = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bool isDark = Theme.of(ctx).brightness == Brightness.dark;
        final Color cardBg = isDark ? const Color(0xFF1E2623) : Colors.white;
        final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
        final Color primaryColor = const Color(0xFF5E9190);

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: cardBg,
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
                      isEdit ? "Edit Voucher" : "Tambah Voucher Baru",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kode Voucher
                    TextField(
                      controller: kodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "Kode Voucher (contoh: DISKON50)",
                        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tipe & Nilai
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: tipe,
                            dropdownColor: cardBg,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Tipe",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: const [
                              DropdownMenuItem(value: "persen", child: Text("Persen (%)")),
                              DropdownMenuItem(value: "nominal", child: Text("Nominal (Rp)")),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => tipe = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: nilaiCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: tipe == "persen" ? "Nilai (cth: 20)" : "Nilai Rp (cth: 15000)",
                              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade700),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Maks Diskon & Kuota
                    Row(
                      children: [
                        if (tipe == "persen") ...[
                          Expanded(
                            child: TextField(
                              controller: maksDiskonCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(color: textColor),
                              decoration: InputDecoration(
                                labelText: "Maks. Diskon (Rp)",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: TextField(
                            controller: kuotaCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              labelText: "Kuota Pakai",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User ID Target
                    TextField(
                      controller: userIdCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: "User ID Pemilik (Kosongkan = Global Publik)",
                        hintText: "cth: 12 untuk voucher privat",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Status Aktif", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                      value: aktif,
                      activeColor: primaryColor,
                      onChanged: (val) => setModalState(() => aktif = val),
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isSavingModal
                            ? null
                            : () async {
                                final kode = kodeCtrl.text.trim().toUpperCase();
                                final nilai = int.tryParse(nilaiCtrl.text) ?? 0;
                                if (kode.isEmpty || nilai <= 0) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    const SnackBar(content: Text("Kode dan nilai voucher wajib diisi valid!")),
                                  );
                                  return;
                                }

                                setModalState(() => isSavingModal = true);
                                try {
                                  final token = await _getToken();
                                  final payload = {
                                    "kode": kode,
                                    "tipe": tipe,
                                    "nilai": nilai,
                                    "maks_diskon": int.tryParse(maksDiskonCtrl.text),
                                    "kuota": int.tryParse(kuotaCtrl.text) ?? 100,
                                    "aktif": aktif ? 1 : 0,
                                    "user_id": int.tryParse(userIdCtrl.text),
                                  };

                                  http.Response res;
                                  if (isEdit) {
                                    res = await http.put(
                                      ApiConfig.uri("/api/vouchers/${editVoucher['id']}"),
                                      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
                                      body: jsonEncode(payload),
                                    );
                                  } else {
                                    res = await http.post(
                                      ApiConfig.uri("/api/vouchers"),
                                      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
                                      body: jsonEncode(payload),
                                    );
                                  }

                                  if (res.statusCode == 200) {
                                    Navigator.pop(modalCtx);
                                    _fetchVouchers();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(isEdit ? "Voucher berhasil diperbarui!" : "Voucher berhasil dibuat!")),
                                    );
                                  } else {
                                    final errData = jsonDecode(res.body);
                                    final msg = ApiConfig.extractErrorMessage(errData['detail'], fallback: "Gagal menyimpan voucher");
                                    ScaffoldMessenger.of(modalCtx).showSnackBar(
                                      SnackBar(content: Text(msg)),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(modalCtx).showSnackBar(
                                    SnackBar(content: Text("Error: ${ApiConfig.extractErrorMessage(e)}")),
                                  );
                                } finally {
                                  setModalState(() => isSavingModal = false);
                                }
                              },
                        child: isSavingModal
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(isEdit ? "Simpan Perubahan" : "Buat Voucher", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final Color primaryColor = const Color(0xFF5E9190);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
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
                      "Panel Admin Wapit",
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- TAB BAR ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
                tabs: const [
                  Tab(text: "Kelola Voucher"),
                  Tab(text: "Pengaturan Referral"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- CONTENT ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVouchersTab(isDark, primaryColor, textColor, subTextColor),
                  _buildReferralTab(isDark, primaryColor, textColor, subTextColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVouchersTab(bool isDark, Color primaryColor, Color textColor, Color subTextColor) {
    return Column(
      children: [
        // Action Add Voucher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Daftar Voucher (${_vouchers.length})",
                style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showVoucherModal(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Tambah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoadingVouchers
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _vouchers.isEmpty
                  ? Center(child: Text("Belum ada voucher yang dibuat", style: TextStyle(color: subTextColor)))
                  : RefreshIndicator(
                      onRefresh: _fetchVouchers,
                      color: primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _vouchers.length,
                        itemBuilder: (context, index) {
                          final v = _vouchers[index];
                          final String kode = v['kode'] ?? '-';
                          final String tipe = v['tipe'] ?? 'persen';
                          final int nilai = v['nilai'] ?? 0;
                          final int terpakai = v['terpakai'] ?? 0;
                          final int kuota = v['kuota'] ?? 0;
                          final bool isAktif = (v['aktif'] == 1);
                          final int? userId = v['user_id'];
                          final String? userNama = v['user_nama'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF24332D) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            kode,
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isAktif ? Colors.green.shade600 : Colors.red.shade600,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isAktif ? "AKTIF" : "NONAKTIF",
                                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tipe == 'persen' ? "Diskon $nilai%" : "Diskon Rp $nilai",
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: primaryColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "Terpakai: $terpakai / $kuota kali",
                                        style: TextStyle(fontSize: 11, color: subTextColor),
                                      ),
                                      if (userId != null)
                                        Text(
                                          "Khusus User: ${userNama ?? 'ID $userId'}",
                                          style: const TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, color: primaryColor, size: 20),
                                  onPressed: () => _showVoucherModal(editVoucher: v),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteVoucher(v['id']),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildReferralTab(bool isDark, Color primaryColor, Color textColor, Color subTextColor) {
    if (_isLoadingConfig) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    final Color cardBg = isDark ? const Color(0xFF24332D) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reward Pengguna Baru (Referee)",
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "Voucher yang diterima pengguna yang memasukkan kode referral",
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _refereeType,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: "Tipe",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "persen", child: Text("Persen (%)")),
                          DropdownMenuItem(value: "nominal", child: Text("Nominal (Rp)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _refereeType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _refereeNilaiCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _refereeType == "persen" ? "Nilai (%)" : "Nilai (Rp)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reward Pemilik Kode (Referrer)",
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "Voucher yang diterima pemilik kode referral saat temannya bergabung",
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _referrerType,
                        dropdownColor: cardBg,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: "Tipe",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "persen", child: Text("Persen (%)")),
                          DropdownMenuItem(value: "nominal", child: Text("Nominal (Rp)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _referrerType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: TextField(
                        controller: _referrerNilaiCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: _referrerType == "persen" ? "Nilai (%)" : "Nilai (Rp)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Batas Maksimum Penggunaan",
                  style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  "Isi 0 untuk tanpa batas (unlimited claim per akun)",
                  style: TextStyle(fontSize: 11, color: subTextColor),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _maxPenggunaanCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: "Maks. Penggunaan (cth: 0 atau 10)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Simpan Pengaturan Referral", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
