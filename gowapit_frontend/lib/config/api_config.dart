/// Konfigurasi URL Server API Backend Go Wapit Terpusat
class ApiConfig {
  /// Base URL Default untuk Backend:
  /// - Untuk Android Emulator: "http://10.0.2.2:8000"
  /// - Untuk HP Android Fisik via Wi-Fi: "http://<IP_LAPTOP_ANDA>:8000" (contoh: "http://192.168.1.5:8000")
  /// - Untuk Server Production (Railway/Cloud): "https://gowapit-backend-production-59b7.up.railway.app"
  static String _overrideBaseUrl = "http://10.0.2.2:8000";

  /// Mengambil Base URL aktif
  static String get baseUrl => _overrideBaseUrl;

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
}
