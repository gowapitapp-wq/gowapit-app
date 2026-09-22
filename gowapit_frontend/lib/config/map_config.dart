import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Konfigurasi Terpusat untuk Peta Interaktif & Navigasi Go Wapit
///
/// File ini adalah SATU-SATUNYA titik perubahan konfigurasi tile map.
/// - Produksi: Menggunakan OpenStreetMap standar (tile.openstreetmap.org) tanpa API key.
/// - Dev/R&D: Mendukung MapTiler via `--dart-define=MAP_TILE_KEY=<key>` (free plan non-komersial).
class MapConfig {
  /// URL resmi Google Maps kawasan Wisata Alam Umbul Jumprit / Hutan Pinus Wapit
  static const String googleMapsKawasanUrl = 'https://maps.app.goo.gl/KczqeqZqWx93JHWG8';

  /// Membaca key dari environment variable saat build / run
  static const String mapTileKey = String.fromEnvironment('MAP_TILE_KEY');

  /// Apakah API key MapTiler disediakan
  static bool get hasMapTilerKey => mapTileKey.isNotEmpty;

  /// URL template tile layer
  static String get tileTemplateUrl {
    if (hasMapTilerKey) {
      return 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTileKey';
    }
    return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  }

  /// User Agent package name agar request tile OSM diizinkan dan tidak diblokir
  static const String userAgentPackageName = 'com.example.gowapit_frontend';

  /// Koordinat Pusat Kawasan Wisata Hutan Pinus Umbul Jumprit / Wapit
  static const LatLng defaultCenter = LatLng(-7.2558, 110.0183);

  /// Nilai zoom default kawasan
  static const double defaultZoom = 16.2;
  static const double minZoom = 12.0;
  static const double maxZoom = 18.5;

  /// Daftar teks atribusi lisensi peta
  static List<String> get attributionTexts {
    if (hasMapTilerKey) {
      return const ['© OpenStreetMap contributors', '© MapTiler'];
    }
    return const ['© OpenStreetMap contributors'];
  }

  /// Menampilkan logo MapTiler jika key aktif
  static bool get showLogo => hasMapTilerKey;

  /// Rumus Haversine untuk jarak garis lurus (km) antara dua koordinat
  static double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371.0; // Radius bumi dalam km
    final double dLat = (lat2 - lat1) * (pi / 180.0);
    final double dLon = (lon2 - lon1) * (pi / 180.0);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) *
        sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  /// Format jarak ke string yang mudah dibaca (misal: "350 m", "14.2 km")
  static String formatDistance(double distKm) {
    if (distKm < 0.1) {
      return "Di lokasi";
    }
    if (distKm < 1.0) {
      return "${(distKm * 1000).round()} m";
    }
    return "${distKm.toStringAsFixed(1)} km";
  }

  /// Estimasi durasi tempuh kendaraan kawasan perbukitan (rata-rata 35 km/jam)
  static String estimateDuration(double distKm) {
    if (distKm < 0.1) {
      return "Tiba";
    }
    int mins = max(1, (distKm / 35.0 * 60.0).round());
    if (mins >= 60) {
      int hours = mins ~/ 60;
      int remMins = mins % 60;
      return remMins > 0 ? "± $hours jam $remMins mnt" : "± $hours jam";
    }
    return "± $mins mnt";
  }

  /// Membuka Google Maps kawasan langsung di aplikasi atau browser
  static Future<void> openGoogleMapsKawasan() async {
    final Uri uri = Uri.parse(googleMapsKawasanUrl);
    try {
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }
}
