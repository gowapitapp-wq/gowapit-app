import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/api_cache.dart';
import '../config/map_config.dart';
import '../design/tokens.dart';

class PetaScreen extends StatefulWidget {
  final int? initialDestinasiId;
  const PetaScreen({super.key, this.initialDestinasiId});

  @override
  State<PetaScreen> createState() => _PetaScreenState();
}

class _PetaScreenState extends State<PetaScreen> {
  final MapController _mapController = MapController();

  LatLng _currentLocation = MapConfig.defaultCenter;
  bool _isLocationAvailable = false;
  bool _isLoadingLocation = true;
  String? _locationStatusBanner;

  List<Map<String, dynamic>> _destinasiList = [];
  bool _isLoadingDestinasi = true;

  Map<String, dynamic>? _selectedDestinasi;
  String? _routeDistance;
  String? _routeDuration;
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([
      _determineUserPosition(),
      _fetchDestinasiData(),
    ]);
  }

  /// Mendapatkan lokasi terkini pengguna dengan batas waktu (timeout 8 detik)
  Future<void> _determineUserPosition() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _currentLocation = MapConfig.defaultCenter;
            _isLocationAvailable = false;
            _isLoadingLocation = false;
            _locationStatusBanner = "GPS / Layanan lokasi tidak aktif. Perkiraan dihitung dari pusat kawasan.";
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _currentLocation = MapConfig.defaultCenter;
              _isLocationAvailable = false;
              _isLoadingLocation = false;
              _locationStatusBanner = "Izin lokasi ditolak. Perkiraan dihitung dari pusat kawasan Wapit.";
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _currentLocation = MapConfig.defaultCenter;
            _isLocationAvailable = false;
            _isLoadingLocation = false;
            _locationStatusBanner = "Izin lokasi ditolak permanen. Menggunakan koordinat pusat kawasan.";
          });
        }
        return;
      }

      // Ambil posisi dengan timeout 8 detik
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocationAvailable = true;
          _isLoadingLocation = false;
          _locationStatusBanner = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentLocation = MapConfig.defaultCenter;
          _isLocationAvailable = false;
          _isLoadingLocation = false;
          _locationStatusBanner = "Lokasi tidak tersedia saat ini. Menggunakan posisi pusat kawasan.";
        });
      }
    }
  }

  /// Mengambil data destinasi dari backend dengan cache klien
  Future<void> _fetchDestinasiData() async {
    setState(() => _isLoadingDestinasi = true);
    try {
      final cached = ApiCache.instance.get("destinasi_list");
      if (cached is List && cached.isNotEmpty && mounted) {
        _applyDestinasiList(cached);
      }

      final res = await ApiCache.instance.getOrFetch(
        cacheKey: "destinasi_list",
        uri: ApiConfig.uri("/api/destinasi"),
        ttl: ApiCache.destinasiTTL,
      );

      if (res is List && mounted) {
        _applyDestinasiList(res);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingDestinasi = false);
    }
  }

  void _applyDestinasiList(List rawList) {
    List<Map<String, dynamic>> valid = [];
    for (var item in rawList) {
      if (item is Map) {
        final lat = item['latitude'];
        final lon = item['longitude'];
        if (lat != null && lon != null) {
          double? latD = double.tryParse(lat.toString());
          double? lonD = double.tryParse(lon.toString());
          if (latD != null && lonD != null) {
            Map<String, dynamic> copy = Map<String, dynamic>.from(item);
            copy['latitude'] = latD;
            copy['longitude'] = lonD;
            valid.add(copy);
          }
        }
      }
    }
    setState(() {
      _destinasiList = valid;
      _isLoadingDestinasi = false;
    });

    // Otomatis pilih dan fokus destinasi awal jika ada initialDestinasiId
    if (widget.initialDestinasiId != null && valid.isNotEmpty) {
      try {
        final target = valid.firstWhere(
          (d) => d['id'] == widget.initialDestinasiId || d['id'].toString() == widget.initialDestinasiId.toString(),
        );
        _calculateRouteTo(target);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(LatLng(target['latitude'], target['longitude']), 16.5);
          }
        });
      } catch (_) {}
    }
  }

  /// Menghitung jarak & durasi tempuh via OSRM publik dengan fallback Haversine
  Future<void> _calculateRouteTo(Map<String, dynamic> dest) async {
    setState(() {
      _selectedDestinasi = dest;
      _isLoadingRoute = true;
      _routeDistance = null;
      _routeDuration = null;
    });

    final LatLng origin = _currentLocation;
    final LatLng destination = LatLng(dest['latitude'], dest['longitude']);

    // Pembulatan 3 digit desimal untuk key cache OSRM
    final double oLat = (origin.latitude * 1000).round() / 1000;
    final double oLon = (origin.longitude * 1000).round() / 1000;
    final String cacheKey = "osrm:${oLat}_${oLon}_${dest['id']}";

    // Cek cache lokal
    final cachedRoute = ApiCache.instance.get(cacheKey);
    if (cachedRoute is Map) {
      if (mounted) {
        setState(() {
          _routeDistance = cachedRoute['distance'];
          _routeDuration = cachedRoute['duration'];
          _isLoadingRoute = false;
        });
      }
      return;
    }

    try {
      // Panggilan ke OSRM publik (Format: {lon},{lat};{lon},{lat})
      final Uri osrmUri = Uri.parse(
        "https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=false",
      );

      final response = await http.get(osrmUri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distanceMeters = (route['distance'] as num).toDouble();
          final double durationSeconds = (route['duration'] as num).toDouble();

          String distStr = distanceMeters >= 1000
              ? "${(distanceMeters / 1000).toStringAsFixed(1)} km"
              : "${distanceMeters.round()} m";
          
          int mins = (durationSeconds / 60).round();
          String durStr = mins > 0 ? "$mins menit" : "< 1 menit";

          final resultData = {
            "distance": distStr,
            "duration": durStr,
            "is_estimated": false,
          };
          ApiCache.instance.set(cacheKey, resultData, ttl: const Duration(minutes: 30));

          if (mounted) {
            setState(() {
              _routeDistance = distStr;
              _routeDuration = durStr;
              _isLoadingRoute = false;
            });
          }
          return;
        }
      }
    } catch (_) {
      // OSRM gagal / timeout / ditolak CORS pada Web -> Lanjut ke fallback Haversine
    }

    // Fallback: Haversine garis lurus berlabel "perkiraan"
    final double distKm = _haversineDistance(origin, destination);
    String distStr = distKm >= 1.0 ? "${distKm.toStringAsFixed(1)} km" : "${(distKm * 1000).round()} m";
    // Asumsi kecepatan rata-rata kendaraan kawasan perbukitan 30 km/jam
    int approxMins = max(1, (distKm / 30 * 60).round());
    String durStr = "$approxMins menit";

    final fallbackData = {
      "distance": "$distStr (perkiraan)",
      "duration": "$durStr (perkiraan)",
      "is_estimated": true,
    };
    ApiCache.instance.set(cacheKey, fallbackData, ttl: const Duration(minutes: 30));

    if (mounted) {
      setState(() {
        _routeDistance = "$distStr (perkiraan)";
        _routeDuration = "$durStr (perkiraan)";
        _isLoadingRoute = false;
      });
    }
  }

  /// Rumus Haversine untuk jarak garis lurus (km)
  double _haversineDistance(LatLng p1, LatLng p2) {
    const double R = 6371; // Radius bumi dalam km
    double dLat = (p2.latitude - p1.latitude) * (pi / 180.0);
    double dLon = (p2.longitude - p1.longitude) * (pi / 180.0);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * (pi / 180.0)) * cos(p2.latitude * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Membuka aplikasi Google Maps untuk navigasi langsung
  Future<void> _openGoogleMaps(Map<String, dynamic> dest) async {
    final double lat = dest['latitude'];
    final double lon = dest['longitude'];
    final String name = Uri.encodeComponent(dest['name'] ?? 'Wisata Wapit');
    final Uri mapsUri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&destination_place_id=$name");

    try {
      bool launched = await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(mapsUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Membuka rute: $lat, $lon")),
        );
      }
    }
  }

  Color _getKategoriColor(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'alam':
        return const Color(0xFF2E7D6A);
      case 'sejarah':
        return const Color(0xFF8D6E63);
      case 'satwa':
        return const Color(0xFFE65100);
      case 'wahana':
        return const Color(0xFFC2185B);
      case 'budaya':
        return const Color(0xFF5E35B1);
      default:
        return const Color(0xFF1E524D);
    }
  }

  IconData _getKategoriIcon(String? kategori) {
    switch ((kategori ?? '').toLowerCase()) {
      case 'alam':
        return Icons.park_outlined;
      case 'sejarah':
        return Icons.account_balance_outlined;
      case 'satwa':
        return Icons.pets_outlined;
      case 'wahana':
        return Icons.attractions_outlined;
      case 'budaya':
        return Icons.palette_outlined;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDarkMode ? AppTokens.tileDark : AppTokens.tileLight;
    final Color textColor = isDarkMode ? AppTokens.labelPrimaryDark : AppTokens.labelPrimaryLight;
    final Color subTextColor = isDarkMode ? AppTokens.labelSecondaryDark : AppTokens.labelSecondaryLight;
    final Color primaryColor = isDarkMode ? AppTokens.actionPineDark : AppTokens.actionPineLight;
    final Color hairlineColor = isDarkMode ? AppTokens.hairlineDark : AppTokens.hairlineLight;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: primaryColor, size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          "Peta Wisata Interaktif",
          style: TextStyle(
            color: textColor,
            fontWeight: AppTokens.wBold,
            fontFamily: AppTokens.fontFamily,
            fontSize: AppTokens.fsTitleLg,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // --- 1. BANNER STATUS LOKASI (JIKA ADA FALLBACK) ---
            if (_locationStatusBanner != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.amber.shade900.withValues(alpha: 0.25) : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationStatusBanner!,
                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.amber.shade200 : Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),

            // --- 2. CONTAINER PETA INTERAKTIF FLUTTER MAP ---
            Container(
              height: 380,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppTokens.rLg),
                border: Border.all(color: hairlineColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.rLg),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: MapConfig.defaultCenter,
                        initialZoom: MapConfig.defaultZoom,
                        minZoom: MapConfig.minZoom,
                        maxZoom: MapConfig.maxZoom,
                        interactionOptions: InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        // Tile Layer (OSM / MapTiler)
                        TileLayer(
                          urlTemplate: MapConfig.tileTemplateUrl,
                          userAgentPackageName: MapConfig.userAgentPackageName,
                        ),

                        // Marker Layer
                        MarkerLayer(
                          markers: [
                            // Marker Posisi Pengguna
                            if (_isLocationAvailable)
                              Marker(
                                point: _currentLocation,
                                width: 44,
                                height: 44,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blue.withValues(alpha: 0.25),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue.shade600,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Marker Seluruh Destinasi
                            ..._destinasiList.map((dest) {
                              final LatLng point = LatLng(dest['latitude'], dest['longitude']);
                              final bool isSelected = _selectedDestinasi?['id'] == dest['id'];
                              final Color catColor = _getKategoriColor(dest['kategori']);

                              return Marker(
                                point: point,
                                width: isSelected ? 52 : 42,
                                height: isSelected ? 52 : 42,
                                child: GestureDetector(
                                  onTap: () {
                                    _calculateRouteTo(dest);
                                    _mapController.move(point, 17.0);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? catColor : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : catColor,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: catColor.withValues(alpha: 0.35),
                                          blurRadius: isSelected ? 12 : 6,
                                          offset: const Offset(0, 3),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getKategoriIcon(dest['kategori']),
                                        size: isSelected ? 24 : 18,
                                        color: isSelected ? Colors.white : catColor,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                        // Atribusi Lisensi (teks simpel tanpa logo asset)
                        SimpleAttributionWidget(
                          source: Text(
                            MapConfig.attributionTexts.join(' | '),
                            style: const TextStyle(fontSize: 10, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),

                    // Tombol Kontrol Peta Cepat
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Column(
                        children: [
                          // Tombol Pusatkan ke Lokasi Saya
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: hairlineColor),
                            ),
                            child: FloatingActionButton.small(
                              heroTag: "btn_my_location",
                              backgroundColor: cardColor,
                              foregroundColor: primaryColor,
                              elevation: 0,
                              highlightElevation: 0,
                              tooltip: "Lokasi Saya",
                              onPressed: () {
                                _mapController.move(_currentLocation, 16.5);
                              },
                              child: const Icon(Icons.my_location, size: 18),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tombol Reset Kawasan Umbul Jumprit
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: hairlineColor),
                            ),
                            child: FloatingActionButton.small(
                              heroTag: "btn_reset_center",
                              backgroundColor: cardColor,
                              foregroundColor: primaryColor,
                              elevation: 0,
                              highlightElevation: 0,
                              tooltip: "Pusatkan Kawasan",
                              onPressed: () {
                                _mapController.move(MapConfig.defaultCenter, MapConfig.defaultZoom);
                              },
                              child: const Icon(Icons.forest_outlined, size: 18),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tombol Buka Google Maps Resmi Kawasan
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: hairlineColor),
                            ),
                            child: FloatingActionButton.small(
                              heroTag: "btn_open_gmaps_kawasan",
                              backgroundColor: cardColor,
                              foregroundColor: primaryColor,
                              elevation: 0,
                              highlightElevation: 0,
                              tooltip: "Buka Google Maps",
                              onPressed: MapConfig.openGoogleMapsKawasan,
                              child: const Icon(Icons.directions_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indikator Loading
                    if (_isLoadingDestinasi || _isLoadingLocation)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppTokens.rPill),
                            border: Border.all(color: hairlineColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Memuat peta...",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: textColor,
                                  fontWeight: AppTokens.wSemiBold,
                                  fontFamily: AppTokens.fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- 3. KARTU JARAK KE HUTAN PINUS WAPIT (PUSAT) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppTokens.rLg),
                border: Border.all(color: hairlineColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTokens.rMd),
                        ),
                        child: Icon(Icons.near_me_outlined, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Jarak ke Hutan Pinus Wapit",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: AppTokens.wSemiBold,
                                    color: subTextColor,
                                    fontFamily: AppTokens.fontFamily,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _isLocationAvailable
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(AppTokens.rPill),
                                  ),
                                  child: Text(
                                    _isLocationAvailable ? "GPS Aktif" : "Pusat Kawasan",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: AppTokens.wBold,
                                      fontFamily: AppTokens.fontFamily,
                                      color: _isLocationAvailable ? Colors.green.shade700 : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isLocationAvailable
                                  ? "${MapConfig.formatDistance(MapConfig.haversineDistanceKm(_currentLocation.latitude, _currentLocation.longitude, MapConfig.defaultCenter.latitude, MapConfig.defaultCenter.longitude))} · ${MapConfig.estimateDuration(MapConfig.haversineDistanceKm(_currentLocation.latitude, _currentLocation.longitude, MapConfig.defaultCenter.latitude, MapConfig.defaultCenter.longitude))} perjalanan"
                                  : "± 0 m (Titik Pusat Kawasan Wisata)",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: AppTokens.wBold,
                                color: primaryColor,
                                fontFamily: AppTokens.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rPill)),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      onPressed: MapConfig.openGoogleMapsKawasan,
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: Text(
                        "Buka Kawasan di Google Maps",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: AppTokens.wBold,
                          fontFamily: AppTokens.fontFamily,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. SELECTOR DESTINASI HORIZONTAL DENGAN JARAK ---
            if (_destinasiList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _destinasiList.length,
                    itemBuilder: (context, index) {
                      final dest = _destinasiList[index];
                      final bool isSelected = _selectedDestinasi?['id'] == dest['id'];
                      final Color catColor = _getKategoriColor(dest['kategori']);
                      final double dKm = MapConfig.haversineDistanceKm(
                        _currentLocation.latitude,
                        _currentLocation.longitude,
                        dest['latitude'],
                        dest['longitude'],
                      );

                      return GestureDetector(
                        onTap: () {
                          _calculateRouteTo(dest);
                          _mapController.move(LatLng(dest['latitude'], dest['longitude']), 17.2);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? catColor : cardColor,
                            borderRadius: BorderRadius.circular(AppTokens.rPill),
                            border: Border.all(
                              color: isSelected ? catColor : hairlineColor,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getKategoriIcon(dest['kategori']),
                                size: 15,
                                color: isSelected ? Colors.white : catColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                dest['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? AppTokens.wBold : AppTokens.wSemiBold,
                                  fontFamily: AppTokens.fontFamily,
                                  color: isSelected ? Colors.white : textColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "• ${MapConfig.formatDistance(dKm)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: AppTokens.wSemiBold,
                                  fontFamily: AppTokens.fontFamily,
                                  color: isSelected ? Colors.white.withValues(alpha: 0.9) : primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // --- 5. KARTU DETAIL DESTINASI YANG DIPILIH ---
            if (_selectedDestinasi != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppTokens.rLg),
                  border: Border.all(
                    color: _getKategoriColor(_selectedDestinasi!['kategori']).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Destinasi
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTokens.rMd),
                          child: Image.asset(
                            _selectedDestinasi!['image'] ?? 'assets/images/HutanPinus.jpeg',
                            width: 65,
                            height: 65,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 65,
                              height: 65,
                              color: primaryColor.withValues(alpha: 0.1),
                              child: Icon(Icons.landscape, color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getKategoriColor(_selectedDestinasi!['kategori']).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(AppTokens.rPill),
                                ),
                                child: Text(
                                  _selectedDestinasi!['kategori'] ?? 'Wisata',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: AppTokens.wBold,
                                    fontFamily: AppTokens.fontFamily,
                                    color: _getKategoriColor(_selectedDestinasi!['kategori']),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDestinasi!['name'] ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: AppTokens.wBold,
                                  color: textColor,
                                  fontFamily: AppTokens.fontFamily,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedDestinasi!['deskripsi_pendek'] ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subTextColor,
                                  fontFamily: AppTokens.fontFamily,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(height: 1, color: hairlineColor),
                    const SizedBox(height: 12),

                    // Badge Jarak & Estimasi Waktu Tempuh
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppTokens.rMd),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.directions_car_outlined, size: 18, color: primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _isLoadingRoute
                                      ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Jarak & Waktu Tempuh",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: subTextColor,
                                                fontWeight: AppTokens.wRegular,
                                                fontFamily: AppTokens.fontFamily,
                                              ),
                                            ),
                                            Text(
                                              "${_routeDistance ?? '-'} · ${_routeDuration ?? '-'}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: AppTokens.wBold,
                                                color: primaryColor,
                                                fontFamily: AppTokens.fontFamily,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tombol Navigasi Google Maps
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.rPill)),
                            elevation: 0,
                          ),
                          onPressed: () => _openGoogleMaps(_selectedDestinasi!),
                          icon: const Icon(Icons.navigation_outlined, size: 16),
                          label: Text(
                            "Rute",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: AppTokens.wBold,
                              fontFamily: AppTokens.fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // --- 6. KARTU INFORMASI KAWASAN JUMPRIIT ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppTokens.rLg),
                border: Border.all(color: hairlineColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: Icon(Icons.location_on, color: primaryColor, size: 24),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Wisata Alam Umbul Jumprit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: AppTokens.wBold,
                                color: textColor,
                                fontFamily: AppTokens.fontFamily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Ketinggian 1.280 mdpl (Kaki Gn. Sindoro)",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryColor,
                                fontWeight: AppTokens.wSemiBold,
                                fontFamily: AppTokens.fontFamily,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: hairlineColor),
                  ),
                  Text(
                    "Alamat Lengkap",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: AppTokens.wBold,
                      color: textColor,
                      fontFamily: AppTokens.fontFamily,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Jl. Ngadirejo, Jumprit, Tegalrejo, Temanggung, Jawa Tengah 56255.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: subTextColor,
                      fontFamily: AppTokens.fontFamily,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}