# AGENTS.md

## Cek realita (baca dulu)

- **Repo ini BUKAN proyek Go dan BUKAN monorepo yang dijelaskan di `go-wapit-monorepo.txt`.** File itu (Hono.js/Cloudflare + Expo + Next.js) hanyalah rencana aspirasional — abaikan.
- Stack sebenarnya: **`gowapit-backend/`** = Python **FastAPI** (bukan Flask) + SQLAlchemy + SQLite; **`gowapit_frontend/`** = aplikasi mobile Flutter (Material 3) untuk objek wisata "Hutan Pinus Wapit" (Umbul Jumprit, Temanggung). Spesifikasi produk: `PRD Project GO WAPIT APP.txt`.

## Tata letak git (jebakan)

- Dua repo git terpisah. Repo root melacak `gowapit-backend` sebagai **gitlink tanpa `.gitmodules`** (entri submodule rusak). Perubahan backend harus di-commit di dalam `gowapit-backend/`; perubahan frontend/root di repo root. `git status` di root hanya menampilkan backend sebagai hash gitlink, bukan diff file. Ada juga isu "dubious ownership" (Windows); gunakan `git -c safe.directory='<path>'` agar command berjalan.

## Backend (`gowapit-backend/`)

- Jalankan (sudah ada `venv/` lokal): `venv\Scripts\python -m uvicorn main:app --reload` atau `venv\Scripts\activate; uvicorn main:app --reload`. Produksi: `uvicorn main:app` (`Procfile` meneruskan `$PORT`). File deploy yang lain juga ada: `render.yaml` (Render) dan `Dockerfile` — keduanya valid.
- **`app_flask_lama.py` adalah kode mati legacy** (API mock Flask lama). Hanya `main.py`, `models.py`, `database.py` yang aktif.
- DB SQLite **`gowapit.db` ikut ter-commit/lacak** di repo backend (bukan di-ignore). Jangan sunting DB manual; skema diubah lewat migrasi di bawah.
- Tabel dan data seed (destinasi, paket, kuliner, layanan-umum) diisi saat startup dan idempoten. Perubahan skema dilakukan lewat `ALTER TABLE` hacky di `run_db_migrations()` (try/except yang menelan error) — tambahkan migrasi baru dengan cara yang sama.
- Akun seed default (jangan diubah, dipakai login untuk tes endpoint ber-role): `admin@gowapit.com` / `AkunGoWapit` (role `admin`, akses endpoint `require_admin`) dan `petugas@gowapit.com` / `petugas123` (role `petugas`, untuk alur scanner/redeem tiket).
- **Redis OPSIONAL** (`REDIS_URL`): jika tidak tersedia, semua fungsi `redis_*` fallback senyap ke baca DB (main.py:28-38). Redis mati/lokal bukan error.

## Backend (`gowapit-backend/`) — Auth & API

- **Firebase Authentication**: Autentikasi backend sekarang divalidasi via Firebase Admin SDK (ID Token Firebase). Kredensial Firebase dikonfigurasi via env var `FIREBASE_SERVICE_ACCOUNT_JSON` (isi JSON) atau `FIREBASE_SERVICE_ACCOUNT_PATH` (path file).
- **Mode Dev & Fallback**: Jika kredensial service account belum diisi di dev lokal (`APP_ENV=dev`), backend menggunakan dev mock token verifier untuk pengujian lokal (`dev-token-<email>`). Di lingkungan produksi (seperti Render / Railway), backend menerapkan *fail-closed* — jika kredensial tidak valid, server gagal start.
- **Skrip Migrasi User**: `scripts/import_users_to_firebase.py` mendukung opsi `--dry-run`, batching $\le 1000$ user, impor passwordless untuk akun email legacy, dan pengesetan password akun seed admin/petugas melalui env var `ADMIN_TEMP_PASSWORD` dan `PETUGAS_TEMP_PASSWORD`.
- Hash password lama & tabel `users.password` sekarang nullable; `users.firebase_uid` menjadi identitas utama yang unik.
- Daftar endpoint di bawah parsial; daftar lengkap = `grep '@app\.' main.py`. Endpoint publik menampilkan `{"status":"success","data":...}`.
- Auth: `POST /api/auth/firebase` (sinkronisasi/registrasi user Firebase ke DB lokal + klaim referral jika ada), `/api/users/me` (GET/PUT, Firebase Bearer token). Token ID diverifikasi langsung ke Firebase Admin Auth.
- Data: `/api/destinasi`, `/api/destinasi/{id}/ulasan` (GET/POST/PUT/DELETE + balasan admin), `/api/paket`, `/api/paket/{id}/slot`, `/api/kuliner?kedai=`, `/api/layanan-umum`, `/api/pesan`, `/api/checkout` (Midtrans Snap).
- Booking/e-tiket: `/api/booking` (POST/GET/DELETE + `/pay`), `/api/tickets/my`, `/api/tickets/validate`, `/api/tickets/redeem`, `/api/kuliner/orders`. **Pembayaran booking punya `mode: "simulasi"`** untuk menandai PAID tanpa Midtrans — gunakan itu saat tes tanpa server key valid.
- Voucher & referral: `/api/vouchers` (admin CRUD), `/api/voucher/{kode}`, `/api/user/vouchers`, `/api/referral/my-code`, `/api/referral/use`, `/api/referral/config` (admin).

## Frontend (`gowapit_frontend/`)

- Perintah (jalankan dari `gowapit_frontend/`): `flutter run`, `flutter analyze`, `flutter test`.
- **Base URL API di `lib/config/api_config.dart`, default-nya BUKAN Railway.** Mobile/emulator: `http://157.10.161.228`. Web: memakai origin saat ini, dan `vercel.json` me-rewrite `/api/*` serta `/docs` ke `http://157.10.161.228`. Untuk dev lokal, panggil `ApiConfig.setBaseUrl("http://10.0.2.2:8000")` (emulator) atau IP LAN Anda, atau edit filenya. Android sudah mengizinkan HTTP cleartext (`usesCleartextTraffic="true"`).
- **Ada cache sisi klien** (`lib/config/api_cache.dart`): respons API di-cache di memory + SharedPreferences dengan TTL hardcoded (cache-first/stale-while-revalidate), contoh destinasi 15 menit, paket 24 jam. Setelah mengubah data backend, aplikasi bisa menampilkan data lama sampai TTL habis atau `ApiCache.instance.invalidate()` dipanggil.
- Semua screen ada di `lib/screens/`; navigasi pakai `Navigator`/`MaterialPageRoute` biasa + bottom nav `FloatingDock` (`lib/widgets/floating_dock.dart`) yang item-nya di-wire di `main.dart` (tanpa paket routing). Role `petugas`/`staff` dialihkan langsung ke `ScannerScreen(isStaffPortal: true)`.
- Shell aplikasi memakai logo emboss + gradient global yang disuntikkan lewat `MaterialApp.builder`; **scaffold harus tetap `backgroundColor: Colors.transparent`** atau efek background tidak tampil. Dark mode lewat `theme_notifier.dart` (`isDarkModeGlobal`).
- i18n lewat `easy_localization` (`assets/translations/en-US.json`, `id-ID.json`; default `id`). String UI dan komentar kode berbahasa **Indonesia** — ikuti gaya itu.
- **Deploy web**: hasil `flutter build web` di-commit ke `public/` (root & frontend). Untuk taruh perubahan web ke produksi (Vercel), jalankan `flutter build web` lalu salin isi `build/web` ke `public/`. Alternatif deploy Railway: `railway.toml`/`Procfile` (`npx serve build/web -l $PORT -s`).
- Satu-satunya test (`test/widget_test.dart`) adalah test smoke template "counter" Flutter yang tidak dimodifikasi dan tidak sesuai aplikasi; abaikan pass/fail-nya.
- Ikon launcher dibuat dari `assets/images/Logo.png` lewat konfigurasi `flutter_launcher_icons` di `pubspec.yaml`.
- **Peta Interaktif & Navigasi**:
  - Menggunakan `flutter_map` + `latlong2` + `geolocator`.
  - Konfigurasi tile terpusat di `lib/config/map_config.dart`. Produksi memakai OpenStreetMap standar (`tile.openstreetmap.org`, no-key, gratis). Dev/R&D mendukung MapTiler via `--dart-define=MAP_TILE_KEY=<key>`.
  - Perhitungan jarak & estimasi waktu tempuh menggunakan OSRM publik (`router.project-osrm.org`) dengan fallback rumus Haversine berlabel "perkiraan".
  - Koordinat destinasi disimpan di kolom `latitude` & `longitude` pada tabel `destinasi` (`models.DestinasiModel`) dan diserialisasi di `/api/destinasi`.
  - Izin lokasi dikonfigurasi di `AndroidManifest.xml` (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) dan `ios/Runner/Info.plist` (`NSLocationWhenInUseUsageDescription`). Fallback otomatis ke pusat kawasan (`-7.2558, 110.0183`) jika izin tidak diberikan.
- **Halaman Berita & Pengumuman Statis**:
  - Sumber data: `assets/data_berita.json` (format JSON murni tanpa komentar).
  - Skema data: `id` (int), `kategori` ("Promo" | "Event" | "Informasi" | "Pengumuman"), `judul` (string), `tanggal` (ISO YYYY-MM-DD), `ringkasan` (string), `isi` (string), `gambar` (opsional asset path atau null), `berlaku_hingga` (opsional ISO YYYY-MM-DD atau null), `todo` (opsional string catatan editor untuk konfirmasi ke pengelola).
  - Penyaringan kedaluwarsa: Fungsi `isExpired(String? iso, {DateTime? now})` di `lib/screens/berita_screen.dart` membandingkan tanggal terhadap awal hari ini (`DateTime(now.year, now.month, now.day)`).
  - Navigasi: Berada di Tab ke-5 `FloatingDock` pada `lib/main.dart` (Home · Tiket · Peta · Berita · Profil). Pastikan list `_pages` dan `FloatingDock.items` selalu sinkron secara posisi.
  - **Checklist Rilis**: Sebelum `flutter build` produksi, jalankan pemeriksaan `rg -i "todo" assets/data_berita.json` — 0 hasil = aman; bila ada, selesaikan atau ekspektasikan dulu agar catatan draft internal pengelola tidak terbawa ke pengguna akhir.
- **Sistem Desain & Tipografi (DESIGN.md / Apple Photography-First)**:
  - Sumber kebenaran terpusat: `lib/design/tokens.dart` (`AppTokens`) & `lib/config/app_theme.dart` (`AppTheme`).
  - **Single Interactive Accent**: Aksen warna interaktif tunggal Action Pine (`#1E524D` light / `#76B3AC` dark). Amber (`#E59819`) didegradasi menjadi pasif rating/status/chip saja.
  - **No Drop-Shadow di Kromo**: Semua kromo, bottom bar, app bar, dan kartu memakai `AppTokens.noShadow` + 1px hairline border (`hairlineLight` / `hairlineDark`). Satu-satunya drop-shadow resmi adalah `AppTokens.productShadow` untuk foto produk/destinasi yang bersandar di kanvas.
  - **Font Inter Offline**: Ter-bundle di `assets/fonts/Inter-*.ttf` (bobot 300, 400, 600, 700 — tanpa 500). Jangan gunakan package eksternal `google_fonts` agar offline-ready.
  - **Radius & Tombol**: Mengikuti skala ketat `r5` (5px), `r8` (8px), `r11` (11px), `r18` (18px), dan `pill` (9999px). Tombol aksi utama berbentuk pill (`rPill`).
  - **Emboss Background**: Background global di `MaterialApp.builder` (`main.dart`) tetap dipertahankan dengan `Scaffold(backgroundColor: Colors.transparent)`.