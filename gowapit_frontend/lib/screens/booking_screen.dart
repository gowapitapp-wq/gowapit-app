import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../config/api_config.dart';
import 'tiket_screen.dart';
import 'login_screen.dart';

class BookingScreen extends StatefulWidget {
  /// Jika [paket] diberikan, selector paket langsung pre-filled.
  final Map<String, dynamic>? paket;
  const BookingScreen({super.key, this.paket});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ── Data Paket ────────────────────────────────────────────────
  List<Map<String, dynamic>> _paketList = [];
  bool _loadingPaket = true;
  Map<String, dynamic>? _selectedPaket;

  // ── Jumlah Orang (Bisa Tap & Ketik) ──────────────────────────
  int _jumlahOrang = 1;
  late final TextEditingController _orangCtrl;

  // ── Kalender & Slot (Swipeable per bulan) ──────────────────────
  final DateTime _calendarStart = DateTime.now();
  late final PageController _pageController;
  int _currentMonthIndex = 0;
  static const int _maxMonthPages = 6; // Bisa geser hingga 6 bulan ke depan

  bool _loadingSlot = false;
  Map<String, int> _slotMap = {};
  DateTime? _selectedStart;
  DateTime? _selectedEnd;
  bool get _isPlatinum =>
      _selectedPaket != null &&
      _selectedPaket!['nama'].toString().toLowerCase().contains('platinum');

  // ── Voucher ───────────────────────────────────────────────────
  final TextEditingController _voucherCtrl = TextEditingController();
  bool _checkingVoucher = false;
  String? _voucherError;
  int? _voucherDiskon;
  String? _voucherKodeValid;

  // ── Booking ───────────────────────────────────────────────────
  bool _booking = false;

  // ── Helpers ───────────────────────────────────────────────────
  Color get _themeColor {
    if (_selectedPaket == null) return const Color(0xFF5E9190);
    final n = _selectedPaket!['nama'].toString().toLowerCase();
    if (n.contains('platinum')) return const Color(0xFF607D8B);
    if (n.contains('gold')) return const Color(0xFFC5A059);
    if (n.contains('silver')) return const Color(0xFF9E9E9E);
    return const Color(0xFF5E9190);
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  String _fmtDisplayShort(DateTime d) {
    const bln = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${d.day} ${bln[d.month]} ${d.year}";
  }

  String _formatRupiah(int amount) => "Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.',
      )}";

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isBetween(DateTime d, DateTime s, DateTime e) {
    final dd = DateTime(d.year, d.month, d.day);
    return dd.isAfter(DateTime(s.year, s.month, s.day)) &&
        dd.isBefore(DateTime(e.year, e.month, e.day));
  }

  int get _durasiMalam =>
      (_isPlatinum && _selectedStart != null && _selectedEnd != null)
          ? _selectedEnd!.difference(_selectedStart!).inDays
          : 0;

  int get _malamTambahan =>
      (_isPlatinum && _durasiMalam > 1) ? (_durasiMalam - 1) : 0;

  int get _hargaPaket => (_selectedPaket?['harga'] as num?)?.toInt() ?? 0;
  int get _subtotal => _hargaPaket * _jumlahOrang + _malamTambahan * 150000;
  int get _diskon => _voucherDiskon ?? 0;
  int get _total => _subtotal - _diskon;

  bool get _tanggalOk {
    if (_isPlatinum) return _selectedStart != null && _selectedEnd != null;
    return _selectedStart != null;
  }

  bool get _siapBooking => _selectedPaket != null && _tanggalOk;

  // ── Lifecycle ─────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _orangCtrl = TextEditingController(text: "$_jumlahOrang");
    _pageController = PageController(initialPage: 0);
    _fetchPaket();
  }

  @override
  void dispose() {
    _orangCtrl.dispose();
    _pageController.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  // ── Fetch Paket ───────────────────────────────────────────────
  Future<void> _fetchPaket() async {
    try {
      final res = await http.get(ApiConfig.uri('/api/paket'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final List<dynamic> raw = jsonDecode(res.body)['data'] ?? [];
        final list = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        setState(() {
          _paketList = list;
          _loadingPaket = false;
          if (widget.paket != null) {
            _selectedPaket = list.firstWhere(
              (p) => p['id'] == widget.paket!['id'],
              orElse: () => list.first,
            );
          }
        });
        if (_selectedPaket != null) _fetchSlot();
      } else {
        if (mounted) setState(() => _loadingPaket = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPaket = false);
    }
  }

  // ── Fetch Slot ────────────────────────────────────────────────
  Future<void> _fetchSlot() async {
    if (_selectedPaket == null) return;
    setState(() { _loadingSlot = true; _slotMap = {}; });
    try {
      final start = _fmtDate(_calendarStart);
      // Fetch 180 hari ke depan (6 bulan)
      final end = _fmtDate(_calendarStart.add(const Duration(days: 180)));
      final id = _selectedPaket!['id'];
      final res = await http.get(ApiConfig.uri('/api/paket/$id/slot?start=$start&end=$end'));
      if (res.statusCode == 200 && mounted) {
        final Map<String, dynamic> raw = jsonDecode(res.body)['data'] ?? {};
        setState(() {
          _slotMap = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
          _loadingSlot = false;
        });
      } else {
        if (mounted) setState(() => _loadingSlot = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSlot = false);
    }
  }

  // ── Voucher ───────────────────────────────────────────────────
  Future<void> _applyVoucher() async {
    final kode = _voucherCtrl.text.trim().toUpperCase();
    if (kode.isEmpty) return;
    setState(() { _checkingVoucher = true; _voucherError = null; _voucherDiskon = null; });
    try {
      final res = await http.get(ApiConfig.uri('/api/voucher/$kode?subtotal=$_subtotal'));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body)['data'];
        setState(() {
          _voucherDiskon = d['diskon'] as int;
          _voucherKodeValid = kode;
          _checkingVoucher = false;
        });
      } else {
        final rawDetail = jsonDecode(res.body)['detail'];
        setState(() {
          _voucherError = ApiConfig.extractErrorMessage(rawDetail, fallback: 'Voucher tidak valid');
          _checkingVoucher = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _voucherError = 'Gagal memeriksa voucher'; _checkingVoucher = false; });
    }
  }

  // ── Booking ───────────────────────────────────────────────────
  Future<void> _masukkanKeranjang() async {
    if (!_siapBooking) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    setState(() => _booking = true);
    try {
      final body = <String, dynamic>{
        'paket_id': _selectedPaket!['id'],
        'jumlah_orang': _jumlahOrang,
        'tanggal_mulai': _fmtDate(_selectedStart!),
        if (_isPlatinum && _selectedEnd != null) 'tanggal_akhir': _fmtDate(_selectedEnd!),
        if (_voucherKodeValid != null) 'voucher_kode': _voucherKodeValid,
      };
      final res = await http.post(
        ApiConfig.uri('/api/booking'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final bookingId = jsonDecode(res.body)['data']['id'];
        final currentList = List<Map<String, dynamic>>.from(globalCart.value);
        currentList.add({
          'kategori': 'PAKET',
          'booking_id': bookingId,
          'nama': _selectedPaket!['nama'],
          'jumlah_orang': _jumlahOrang,
          'tanggal_mulai': _fmtDate(_selectedStart!),
          'tanggal_akhir': _isPlatinum && _selectedEnd != null ? _fmtDate(_selectedEnd!) : null,
          'malam_tambahan': _malamTambahan,
          'diskon': _diskon,
          'total_harga': _total,
          'harga': _total,
          'order_id': jsonDecode(res.body)['data']['order_id'],
          'qty': 1,
        });
        globalCart.value = currentList;
        if (mounted) {
          Navigator.pop(context, 'success');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Booking berhasil! Lanjutkan pembayaran di Keranjang."),
              backgroundColor: _themeColor,
            ),
          );
        }
      } else {
        final errBody = jsonDecode(res.body);
        final msg = ApiConfig.extractErrorMessage(errBody['detail'], fallback: 'Gagal membuat booking');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: ${ApiConfig.extractErrorMessage(e)}"), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  // ── Calendar tap ─────────────────────────────────────────────
  void _onTapDay(DateTime day) {
    final sisa = _slotMap[_fmtDate(day)] ?? 100;
    final isPast = day.isBefore(DateTime(_calendarStart.year, _calendarStart.month, _calendarStart.day));
    if (isPast || sisa < _jumlahOrang) return;
    setState(() {
      if (!_isPlatinum) {
        _selectedStart = day;
        _selectedEnd = null;
      } else {
        if (_selectedStart == null || (_selectedStart != null && _selectedEnd != null)) {
          _selectedStart = day;
          _selectedEnd = null;
        } else {
          if (day.isBefore(_selectedStart!)) {
            _selectedEnd = _selectedStart;
            _selectedStart = day;
          } else if (_isSameDay(day, _selectedStart!)) {
            _selectedStart = null;
          } else {
            _selectedEnd = day;
          }
        }
      }
      _resetVoucher();
    });
  }

  void _resetVoucher() {
    _voucherDiskon = null;
    _voucherKodeValid = null;
    _voucherError = null;
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color card = dark ? const Color(0xFF1C1C1E) : Colors.white;
    final Color text = dark ? Colors.white : const Color(0xFF161d1b);
    final Color sub = dark ? Colors.grey.shade400 : const Color(0xFF5A6B66);
    final Color divider = dark ? const Color(0xFF2C2C2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: _themeColor),
        centerTitle: true,
        title: const Text(
          "Pilih Paket",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Montserrat', fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. PILIH PAKET ──────────────────────────────────
                  _buildCard(
                    dark: dark, card: card, divider: divider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel("🎫 Pilih Paket Wisata", text),
                        const SizedBox(height: 12),
                        _loadingPaket
                            ? Center(child: CircularProgressIndicator(color: _themeColor))
                            : Column(
                                children: _paketList.map((p) => _buildPaketOption(p, dark, text, sub, divider)).toList(),
                              ),
                      ],
                    ),
                  ),

                  // ── FASILITAS PAKET (TAMPIL KETIKA PAKET SUDAH DIPILIH) ──
                  if (_selectedPaket != null) ...[
                    _buildFasilitasCard(dark, card, text, sub, divider),
                  ],

                  // ── 2. PILIH UNTUK BERAPA ORANG (BISA KETIK / STEPPER) ──
                  _buildCard(
                    dark: dark, card: card, divider: divider,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel("👥 Jumlah Orang", text),
                              const SizedBox(height: 4),
                              Text("Ketik angka atau gunakan tombol + / -", style: TextStyle(fontSize: 12, color: sub, fontFamily: 'Inter')),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _stepBtn(Icons.remove, () {
                              if (_jumlahOrang > 1) {
                                setState(() {
                                  _jumlahOrang--;
                                  _orangCtrl.text = "$_jumlahOrang";
                                  _resetVoucher();
                                });
                              }
                            }, dark),
                            const SizedBox(width: 6),
                            // Input field ketik langsung
                            Container(
                              width: 62,
                              height: 42,
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _orangCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: text,
                                  fontFamily: 'Montserrat',
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  filled: true,
                                  fillColor: dark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: _themeColor, width: 1.5),
                                  ),
                                ),
                                onChanged: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed != null && parsed >= 1) {
                                    setState(() {
                                      _jumlahOrang = parsed;
                                      _resetVoucher();
                                    });
                                  }
                                },
                                onSubmitted: (val) {
                                  final parsed = int.tryParse(val);
                                  if (parsed == null || parsed < 1) {
                                    setState(() {
                                      _jumlahOrang = 1;
                                      _orangCtrl.text = "1";
                                      _resetVoucher();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            _stepBtn(Icons.add, () {
                              setState(() {
                                _jumlahOrang++;
                                _orangCtrl.text = "$_jumlahOrang";
                                _resetVoucher();
                              });
                            }, dark),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── 3. KALENDER PER BULAN (BISA DIGESER DENGAN SWIPE) ────
                  _buildCard(
                    dark: dark, card: card, divider: divider,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionLabel(_isPlatinum ? "📅 Pilih Range Camping" : "📅 Pilih Tanggal Kunjungan", text),
                            if (_loadingSlot)
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: _themeColor, strokeWidth: 2)),
                          ],
                        ),
                        if (_selectedPaket == null) ...[
                          const SizedBox(height: 16),
                          Center(child: Text("Pilih paket terlebih dahulu", style: TextStyle(color: sub, fontFamily: 'Inter', fontSize: 13))),
                        ] else ...[
                          if (_isPlatinum) ...[
                            const SizedBox(height: 4),
                            Text("Pilih tanggal mulai → tanggal selesai (min. 1 malam)", style: TextStyle(fontSize: 12, color: sub, fontFamily: 'Inter')),
                          ],
                          const SizedBox(height: 12),
                          // Keterangan Legenda Jelas
                          _buildLegendSection(sub),
                          const SizedBox(height: 12),
                          // Kalender Swipeable PageView per bulan
                          _buildMonthCarousel(dark, text, sub),
                          if (_selectedStart != null) ...[
                            const SizedBox(height: 12),
                            _buildSelectedBanner(text, sub),
                          ],
                        ],
                      ],
                    ),
                  ),

                  // ── 4. RINGKASAN HARGA (2 baris) ─────────────────────
                  if (_siapBooking) ...[
                    _buildCard(
                      dark: dark, card: card, divider: divider,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel("🧾 Ringkasan Pemesanan", text),
                          const SizedBox(height: 12),
                          // Baris 1 — subtotal
                          _buildPriceRow(
                            _isPlatinum
                                ? "${_selectedPaket!['nama']} (${_durasiMalam + 1}H${_durasiMalam}M) × $_jumlahOrang orang${_malamTambahan > 0 ? ' + $_malamTambahan malam' : ''}"
                                : "${_selectedPaket!['nama']} × $_jumlahOrang orang",
                            _formatRupiah(_subtotal + _diskon),
                            text, sub,
                          ),
                          const SizedBox(height: 8),
                          // Baris 2 — voucher input atau diskon
                          if (_voucherDiskon != null) ...[
                            _buildPriceRow("Diskon Voucher ($_voucherKodeValid)", "− ${_formatRupiah(_diskon)}", text, Colors.green),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _voucherCtrl,
                                    textCapitalization: TextCapitalization.characters,
                                    style: TextStyle(color: text, fontFamily: 'Inter', fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: "Kode voucher (opsional)",
                                      hintStyle: TextStyle(color: sub, fontSize: 12, fontFamily: 'Inter'),
                                      isDense: true,
                                      filled: true,
                                      fillColor: dark ? const Color(0xFF2C2C2E) : Colors.grey.shade50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: divider)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: divider)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _themeColor, width: 1.5)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      suffixIcon: _voucherError != null ? Icon(Icons.error_outline, color: Colors.red.shade400, size: 18) : null,
                                    ),
                                    onSubmitted: (_) => _applyVoucher(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: _checkingVoucher ? null : _applyVoucher,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _themeColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                      elevation: 0,
                                    ),
                                    child: _checkingVoucher
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Text("Pakai", style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ),
                              ],
                            ),
                            if (_voucherError != null) ...[
                              const SizedBox(height: 6),
                              Text(_voucherError!, style: TextStyle(fontSize: 11, color: Colors.red.shade500, fontFamily: 'Inter')),
                            ],
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Divider(color: divider, height: 1),
                          ),
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total", style: TextStyle(fontWeight: FontWeight.bold, color: text, fontFamily: 'Montserrat', fontSize: 15)),
                              Text(_formatRupiah(_total), style: TextStyle(fontWeight: FontWeight.w800, color: _themeColor, fontFamily: 'Montserrat', fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── 5. TOMBOL CTA ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1C1C1E) : Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                if (_siapBooking) ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Total Bayar", style: TextStyle(fontSize: 11, color: sub, fontFamily: 'Inter')),
                        Text(_formatRupiah(_total), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _themeColor, fontFamily: 'Montserrat')),
                      ],
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      _selectedPaket == null
                          ? "Pilih paket untuk melanjutkan"
                          : "Pilih tanggal untuk melanjutkan",
                      style: TextStyle(fontSize: 13, color: sub, fontFamily: 'Inter'),
                    ),
                  ),
                ],
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_siapBooking && !_booking) ? _masukkanKeranjang : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: dark ? Colors.grey.shade800 : Colors.grey.shade200,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      elevation: 0,
                    ),
                    child: _booking
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 18),
                              SizedBox(width: 8),
                              Text("Masukkan Keranjang", style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER WIDGETS ────────────────────────────────────────────
  Widget _buildCard({required bool dark, required Color card, required Color divider, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: dark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String label, Color color) => Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'Montserrat'),
      );

  Widget _buildPaketOption(Map<String, dynamic> p, bool dark, Color text, Color sub, Color divider) {
    final bool selected = _selectedPaket != null && _selectedPaket!['id'] == p['id'];
    final Color tc = _paketThemeColor(p['nama'].toString());
    final int harga = (p['harga'] as num).toInt();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaket = p;
          _selectedStart = null;
          _selectedEnd = null;
          _resetVoucher();
        });
        _fetchSlot();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? tc : (dark ? const Color(0xFF2C2C2E) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? tc : divider, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.white : Colors.transparent,
                border: Border.all(color: selected ? Colors.white : (dark ? Colors.grey.shade600 : Colors.grey.shade400), width: 2),
              ),
              child: selected ? Icon(Icons.check, size: 12, color: tc) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    p['nama'].toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: selected ? Colors.white : text,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  Text(
                    _formatRupiah(harga),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? Colors.white.withValues(alpha: 0.9) : tc,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CARD FASILITAS PAKET ──────────────────────────────────────
  Widget _buildFasilitasCard(bool dark, Color card, Color text, Color sub, Color divider) {
    final String nama = _selectedPaket!['nama'] ?? '';
    final String fasilitasStr = _selectedPaket!['fasilitas'] ?? '';
    final List<String> lines = fasilitasStr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return _buildCard(
      dark: dark,
      card: card,
      divider: divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: _themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Fasilitas Paket $nama",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: text, fontFamily: 'Montserrat'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_rounded, color: _themeColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: text.withValues(alpha: 0.85),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Color _paketThemeColor(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('platinum')) return const Color(0xFF607D8B);
    if (n.contains('gold')) return const Color(0xFFC5A059);
    if (n.contains('silver')) return const Color(0xFF9E9E9E);
    return const Color(0xFF5E9190);
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap, bool dark) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2C2C2E) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _themeColor, size: 20),
        ),
      );

  Widget _buildPriceRow(String label, String value, Color text, Color valueColor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: text.withValues(alpha: 0.7), fontFamily: 'Inter'))),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor, fontFamily: 'Inter')),
        ],
      );

  Widget _buildSelectedBanner(Color text, Color sub) {
    final Color tc = _themeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tc.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tc.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_outlined, color: tc, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPlatinum
                      ? (_selectedEnd != null
                          ? "Camping ${_durasiMalam + 1} Hari $_durasiMalam Malam"
                          : "Pilih Tanggal Selesai Camping")
                      : "Tanggal Kunjungan",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: sub,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPlatinum && _selectedEnd != null
                      ? "${_fmtDisplayShort(_selectedStart!)} → ${_fmtDisplayShort(_selectedEnd!)}"
                      : _fmtDisplayShort(_selectedStart!),
                  style: TextStyle(
                    color: tc,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    fontSize: 14,
                  ),
                ),
                if (_isPlatinum && _selectedStart != null && _selectedEnd == null) ...[
                  const SizedBox(height: 3),
                  Text(
                    "👉 Silakan tap tanggal selesai camping di kalender",
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
                if (_isPlatinum && _malamTambahan > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    "+$_malamTambahan malam tambahan (${_formatRupiah(_malamTambahan * 150000)})",
                    style: TextStyle(
                      color: tc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── LEGENDA KETERANGAN TERSEDIA / PENUH ────────────────────────
  Widget _buildLegendSection(Color sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          _legendBadge(const Color(0xFFE8F5E9), Colors.green.shade700, "🟢 Tersedia"),
          _legendBadge(const Color(0xFFFFEBEE), Colors.red.shade700, "🔴 Penuh / Tidak Cukup"),
          _legendBadge(Colors.grey.shade200, Colors.grey.shade600, "⚪ Lampau"),
        ],
      ),
    );
  }

  Widget _legendBadge(Color bg, Color textCol, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textCol, fontFamily: 'Inter'),
      ),
    );
  }

  // ── KALENDER BULANAN (SWIPEABLE PER BULAN DENGAN HEADER NAVIGATOR) ──
  Widget _buildMonthCarousel(bool dark, Color text, Color sub) {
    const monthNames = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    final currentTarget = DateTime(_calendarStart.year, _calendarStart.month + _currentMonthIndex, 1);

    return Column(
      children: [
        // Header Navigasi Bulan (< Bulan Tahun >)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              color: _currentMonthIndex > 0 ? _themeColor : Colors.grey.shade400,
              onPressed: _currentMonthIndex > 0
                  ? () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
            Text(
              "${monthNames[currentTarget.month]} ${currentTarget.year}",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: text,
                fontFamily: 'Montserrat',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              color: _currentMonthIndex < _maxMonthPages - 1 ? _themeColor : Colors.grey.shade400,
              onPressed: _currentMonthIndex < _maxMonthPages - 1
                  ? () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    }
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Header Hari Statis (Sen, Sel, Rab, Kam, Jum, Sab, Min)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: dayNames
                .map((h) => Expanded(
                      child: Center(
                        child: Text(
                          h,
                          style: TextStyle(
                            fontSize: 11,
                            color: sub,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // PageView Swipeable Month (Grid Tanggal 6 baris)
        SizedBox(
          height: 275,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _maxMonthPages,
            onPageChanged: (idx) {
              setState(() => _currentMonthIndex = idx);
            },
            itemBuilder: (context, pageIdx) {
              final monthDate = DateTime(_calendarStart.year, _calendarStart.month + pageIdx, 1);
              return _buildSingleMonthGrid(monthDate, dark, text, sub);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleMonthGrid(DateTime monthDate, bool dark, Color text, Color sub) {
    final today = DateTime.now();

    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final days = List.generate(
      daysInMonth,
      (i) => DateTime(monthDate.year, monthDate.month, i + 1),
    );

    final firstDay = days.first;
    final offset = (firstDay.weekday - 1) % 7;

    final cells = <Widget>[
      ...List.generate(offset, (_) => const SizedBox()),
      ...days.map((d) => _dayCell(d, today, dark, text)),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: cells,
    );
  }

  Widget _dayCell(DateTime day, DateTime today, bool dark, Color text) {
    final dateStr = _fmtDate(day);
    final sisa = _slotMap[dateStr] ?? 100;
    final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
    final isFull = sisa < _jumlahOrang;
    final disabled = isPast || isFull;

    final isStart = _selectedStart != null && _isSameDay(day, _selectedStart!);
    final isEnd = _selectedEnd != null && _isSameDay(day, _selectedEnd!);
    final inRange = _isPlatinum &&
        _selectedStart != null &&
        _selectedEnd != null &&
        _isBetween(day, _selectedStart!, _selectedEnd!);

    final tc = _themeColor;

    Color bg;
    Color fg;
    BoxBorder? border;

    if (isStart || isEnd) {
      bg = tc;
      fg = Colors.white;
    } else if (inRange) {
      bg = tc.withValues(alpha: 0.18);
      fg = tc;
    } else if (isPast) {
      bg = Colors.transparent;
      fg = Colors.grey.shade400;
    } else if (isFull) {
      bg = Colors.red.withValues(alpha: 0.08);
      fg = Colors.red.shade400;
      border = Border.all(color: Colors.red.withValues(alpha: 0.2));
    } else {
      bg = Colors.green.withValues(alpha: 0.06);
      fg = dark ? Colors.white : const Color(0xFF161d1b);
      border = Border.all(color: Colors.green.withValues(alpha: 0.25));
    }

    return GestureDetector(
      onTap: disabled ? null : () => _onTapDay(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
        ),
        child: Center(
          child: isFull && !isPast
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: fg,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Penuh",
                      style: TextStyle(
                        fontSize: 7.5,
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                )
              : Text(
                  "${day.day}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.w600,
                    color: fg,
                    fontFamily: 'Montserrat',
                  ),
                ),
        ),
      ),
    );
  }
}
