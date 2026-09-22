import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;
  final Duration ttl;

  _CacheEntry({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });

  bool get isExpired => DateTime.now().isAfter(timestamp.add(ttl));

  Map<String, dynamic> toJson() => {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'ttl_ms': ttl.inMilliseconds,
      };

  factory _CacheEntry.fromJson(Map<String, dynamic> json) {
    return _CacheEntry(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      ttl: Duration(milliseconds: json['ttl_ms'] ?? 60000),
    );
  }
}

/// Service Cache 2-Layer (Memory L1 + SharedPreferences L2) untuk Flutter Client
class ApiCache {
  ApiCache._();
  static final ApiCache instance = ApiCache._();

  final Map<String, _CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // TTL Defaults
  static const Duration destinasiTTL = Duration(minutes: 15);
  static const Duration paketTTL = Duration(hours: 24);
  static const Duration layananUmumTTL = Duration(days: 7);
  static const Duration weatherTTL = Duration(minutes: 15);
  static const Duration userProfileTTL = Duration(seconds: 60);
  static const Duration userTTL = userProfileTTL;
  static const Duration userVouchersTTL = Duration(minutes: 5);
  static const Duration slotTTL = Duration(seconds: 60);
  static const Duration ulasanTTL = Duration(minutes: 3);

  static const String _diskPrefix = "gowapit_cache_";

  /// Inisialisasi awal (panggil di main())
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
    } catch (e) {
      debugPrint("ApiCache init error: $e");
    }
  }

  /// Mengambil data dari cache (Memory -> Disk fallback)
  dynamic get(String key, {Duration? ttl}) {
    // 1. Cek L1 Memory Cache
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        return entry.data;
      } else {
        _memoryCache.remove(key);
      }
    }

    // 2. Cek L2 Disk Cache (SharedPreferences)
    if (_prefs != null) {
      final raw = _prefs!.getString("$_diskPrefix$key");
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          final entry = _CacheEntry.fromJson(decoded);
          if (!entry.isExpired) {
            // Restore ke memory cache
            _memoryCache[key] = entry;
            return entry.data;
          } else {
            _prefs!.remove("$_diskPrefix$key");
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Menyimpan data ke L1 Memory Cache & L2 Disk Cache
  Future<void> set(String key, dynamic data, {Duration ttl = const Duration(minutes: 15)}) async {
    final entry = _CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      ttl: ttl,
    );

    // Simpan ke Memory
    _memoryCache[key] = entry;

    // Simpan ke Disk (Background)
    if (_prefs != null) {
      try {
        final jsonStr = jsonEncode(entry.toJson());
        await _prefs!.setString("$_diskPrefix$key", jsonStr);
      } catch (e) {
        debugPrint("ApiCache disk save error for key $key: $e");
      }
    }
  }

  /// Menghapus cache berdasarkan key spesifik atau awalan prefix
  Future<void> invalidate(String keyOrPrefix) async {
    // Hapus dari memory
    final memKeys = _memoryCache.keys.where((k) => k.startsWith(keyOrPrefix) || k == keyOrPrefix).toList();
    for (final k in memKeys) {
      _memoryCache.remove(k);
    }

    // Hapus dari disk
    if (_prefs != null) {
      final allDiskKeys = _prefs!.getKeys().where((k) => k.startsWith("$_diskPrefix$keyOrPrefix")).toList();
      for (final k in allDiskKeys) {
        await _prefs!.remove(k);
      }
    }
    debugPrint("ApiCache invalidated: $keyOrPrefix");
  }

  /// Bersihkan seluruh cache aplikasi
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final allDiskKeys = _prefs!.getKeys().where((k) => k.startsWith(_diskPrefix)).toList();
      for (final k in allDiskKeys) {
        await _prefs!.remove(k);
      }
    }
  }

  /// Helper fetch API dengan strategi Cache-First / Stale-While-Revalidate
  Future<dynamic> getOrFetch({
    required String cacheKey,
    required Uri uri,
    Map<String, String>? headers,
    Duration ttl = const Duration(minutes: 15),
    bool forceRefresh = false,
    Function(dynamic cachedData)? onCachedData,
  }) async {
    // Jika tidak force refresh, coba ambil cache
    if (!forceRefresh) {
      final cached = get(cacheKey);
      if (cached != null) {
        if (onCachedData != null) {
          onCachedData(cached);
        }
        return cached;
      }
    }

    // Request ke server
    try {
      final effectiveHeaders = {
        ...?headers,
        "Bypass-Tunnel-Reminder": "true",
      };
      final response = await http.get(uri, headers: effectiveHeaders);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map && decoded.containsKey('data') ? decoded['data'] : decoded;
        await set(cacheKey, data, ttl: ttl);
        return data;
      }
    } catch (e) {
      debugPrint("ApiCache network fetch failed for $uri: $e");
      // Jika network gagal tapi ada cache kedaluwarsa di disk, fallback ke disk
      final staleData = _getStale(cacheKey);
      if (staleData != null) {
        return staleData;
      }
      rethrow;
    }
    return null;
  }

  /// Ambil data stale bahkan jika sudah kedaluwarsa (untuk offline fallback)
  dynamic _getStale(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key]!.data;
    }
    if (_prefs != null) {
      final raw = _prefs!.getString("$_diskPrefix$key");
      if (raw != null) {
        try {
          final decoded = jsonDecode(raw);
          return decoded['data'];
        } catch (_) {}
      }
    }
    return null;
  }
}
