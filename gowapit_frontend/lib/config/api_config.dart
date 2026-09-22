import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi URL Server API Backend Go Wapit Terpusat
class ApiConfig {
  /// Base URL Default untuk Backend:
  /// - Untuk Web (Vercel/Browser): otomatis menggunakan origin saat ini (HTTPS)
  /// - Untuk Mobile/Emulator: "http://157.10.161.228"
  static String _overrideBaseUrl = "";

  /// Mengambil Base URL aktif
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.startsWith("file://")) {
          // Jika berjalan di localhost/127.0.0.1 (Flutter Web Dev server),
          // arahkan ke backend FastAPI lokal port 8000 agar tidak 404
          if (origin.contains("localhost") || origin.contains("127.0.0.1")) {
            return "http://127.0.0.1:8000";
          }
          return origin;
        }
      } catch (_) {}
    }
    return "http://157.10.161.228";
  }

  /// Mengubah Base URL secara dinamis jika diperlukan
  static void setBaseUrl(String newUrl) {
    if (newUrl.isNotEmpty) {
      // Pastikan memiliki skema http:// atau https://
      if (!newUrl.startsWith("http://") && !newUrl.startsWith("https://")) {
        _overrideBaseUrl = "http://$newUrl";
      } else {
        _overrideBaseUrl = newUrl;
      }
    }
  }

  /// Membuat URL lengkap untuk endpoint API
  /// Contoh: ApiConfig.url("/api/login") -> "http://10.0.2.2:8000/api/login"
  static Uri uri(String path) {
    String base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$cleanPath');
  }

  /// Google OAuth Web Client ID (serverClientId untuk verifikasi ID token di backend)
  static const String googleWebClientId = "568161780177-9hmv16a8fncdfoltp5bhc0t0or8koumf.apps.googleusercontent.com";
  
  /// Google OAuth Android Client ID (clientId khusus untuk aplikasi Android tanpa google-services.json)
  static const String googleAndroidClientId = "568161780177-hlrqi1rbb05k40fur17ujfmf6j9p2876.apps.googleusercontent.com";

  /// String URL sederhana
  static String urlString(String path) {
    return uri(path).toString();
  }

  /// Mengekstrak pesan error secara aman dari respon API backend (menangani String, Map, atau List FastAPI 422)
  static String extractErrorMessage(dynamic detail, {String fallback = 'Terjadi kesalahan pada server.'}) {
    if (detail == null) return fallback;
    if (detail is String) return detail.isNotEmpty ? detail : fallback;
    if (detail is List) {
      if (detail.isEmpty) return fallback;
      final List<String> msgs = [];
      for (var item in detail) {
        if (item is Map) {
          if (item.containsKey('msg')) {
            msgs.add(item['msg'].toString());
          } else {
            msgs.add(item.toString());
          }
        } else {
          msgs.add(item.toString());
        }
      }
      return msgs.isNotEmpty ? msgs.join(', ') : fallback;
    }
    if (detail is Map) {
      if (detail.containsKey('msg')) return detail['msg'].toString();
      if (detail.containsKey('detail')) return extractErrorMessage(detail['detail'], fallback: fallback);
      if (detail.containsKey('message')) return detail['message'].toString();
      return detail.toString();
    }
    return detail.toString();
  }
}
