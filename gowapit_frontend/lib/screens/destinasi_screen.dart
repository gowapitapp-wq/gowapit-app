import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../config/api_cache.dart';
import '../config/map_config.dart';
import '../design/tokens.dart';
import 'detail_destinasi_screen.dart';

class DestinasiPage extends StatefulWidget {
  const DestinasiPage({super.key});

  @override
  State<DestinasiPage> createState() => _DestinasiPageState();
}

class _DestinasiPageState extends State<DestinasiPage> {
  List<dynamic> _listDestinasi = [];
  bool _isLoading = true;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _getUserLocation();
    await _fetchDestinasiData();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (mounted) {
        setState(() => _userPosition = position);
      }
    } catch (_) {}
  }

  Future<void> _fetchDestinasiData({bool forceRefresh = false}) async {
    try {
      final cached = ApiCache.instance.get("destinasi");
      if (cached is List && cached.isNotEmpty && !forceRefresh) {
        setState(() {
          _listDestinasi = cached;
          _isLoading = false;
        });
      }

      final data = await ApiCache.instance.getOrFetch(
        cacheKey: "destinasi",
        uri: ApiConfig.uri("/api/destinasi"),
        ttl: ApiCache.destinasiTTL,
        forceRefresh: forceRefresh,
      );

      if (data is List && mounted) {
        setState(() {
          _listDestinasi = data;
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
    final bool isDark = context.isDarkMode;
    final Color primaryPine = context.primaryAccent;
    final Color textColor = context.textPrimary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Destinasi Wisata",
          style: AppTokens.tagline.copyWith(color: textColor),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryPine))
          : _listDestinasi.isEmpty
              ? Center(
                  child: Text(
                    "Data destinasi kosong.",
                    style: AppTokens.caption.copyWith(color: context.textMuted),
                  ),
                )
              : RefreshIndicator(
                  color: primaryPine,
                  onRefresh: () => _fetchDestinasiData(forceRefresh: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.sLG, vertical: AppTokens.sSM),
                    itemCount: _listDestinasi.length,
                    itemBuilder: (context, index) {
                      final item = _listDestinasi[index];
                      return HoverableDestinasiCard(
                        item: item,
                        allDestinasi: _listDestinasi,
                        isDarkMode: isDark,
                        userPosition: _userPosition,
                        onRefresh: _fetchDestinasiData,
                      );
                    },
                  ),
                ),
    );
  }
}

class HoverableDestinasiCard extends StatefulWidget {
  final dynamic item;
  final List<dynamic> allDestinasi;
  final bool isDarkMode;
  final Position? userPosition;
  final VoidCallback onRefresh;

  const HoverableDestinasiCard({
    super.key,
    required this.item,
    required this.allDestinasi,
    required this.isDarkMode,
    this.userPosition,
    required this.onRefresh,
  });

  @override
  State<HoverableDestinasiCard> createState() => _HoverableDestinasiCardState();
}

class _HoverableDestinasiCardState extends State<HoverableDestinasiCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = context.surfaceCard;
    final Color primaryPine = context.primaryAccent;
    final Color textColor = context.textPrimary;
    final Color subTextColor = context.textMuted;

    final String nama = widget.item['name'] ?? widget.item['nama'] ?? '-';
    final String deskripsi =
        widget.item['deskripsi_pendek'] ?? widget.item['deskripsi_singkat'] ?? widget.item['deskripsi_panjang'] ?? '-';
    String rawGambar = widget.item['image'] ?? widget.item['gambar'] ?? 'assets/images/placeholder.jpeg';
    final String gambarPath = rawGambar.startsWith('assets/') ? rawGambar : 'assets/$rawGambar';
    final num ratingNum = (widget.item['rating'] is num) ? widget.item['rating'] : 0.0;
    final int jmlUlasan =
        (widget.item['jumlah_ulasan'] is num) ? (widget.item['jumlah_ulasan'] as num).toInt() : 0;

    double? distKm;
    if (widget.userPosition != null && widget.item['latitude'] != null && widget.item['longitude'] != null) {
      double? lat = double.tryParse(widget.item['latitude'].toString());
      double? lon = double.tryParse(widget.item['longitude'].toString());
      if (lat != null && lon != null) {
        distKm = MapConfig.haversineDistanceKm(widget.userPosition!.latitude, widget.userPosition!.longitude, lat, lon);
      }
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinasiPage(
              data: widget.item,
              allDestinasi: widget.allDestinasi,
            ),
          ),
        );
        widget.onRefresh();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTokens.sSM),
          constraints: const BoxConstraints(minHeight: 118),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppTokens.r18,
            border: Border.all(color: context.hairlineBorder, width: 1),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    bottomLeft: Radius.circular(17),
                  ),
                  child: Image.asset(
                    gambarPath,
                    width: 104,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 104,
                      color: context.surfaceParchment,
                      child: Icon(Icons.image_outlined, color: subTextColor),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTokens.sSM, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                nama,
                                style: AppTokens.bodyStrong.copyWith(color: textColor, fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ratingNum > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: AppTokens.statusAmber),
                                  const SizedBox(width: 2),
                                  Text(
                                    ratingNum.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTokens.statusAmber,
                                      fontFamily: AppTokens.fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          deskripsi,
                          style: AppTokens.finePrint.copyWith(color: subTextColor, height: 1.25),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (distKm != null)
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: primaryPine.withValues(alpha: 0.10),
                                    borderRadius: AppTokens.pill,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.near_me_rounded, size: 10, color: primaryPine),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          "${MapConfig.formatDistance(distKm)} (${MapConfig.estimateDuration(distKm)})",
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: primaryPine,
                                            fontFamily: AppTokens.fontFamily,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (distKm != null && jmlUlasan > 0) const SizedBox(width: 6),
                            if (jmlUlasan > 0)
                              Text(
                                "$jmlUlasan ulasan",
                                style: AppTokens.microLegal.copyWith(color: subTextColor),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Center(
                    child: Icon(Icons.arrow_forward_ios_rounded, color: primaryPine, size: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}