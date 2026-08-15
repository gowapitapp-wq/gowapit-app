# AGENTS.md

## Cek realita (baca dulu)

- **Repo ini BUKAN proyek Go dan BUKAN monorepo yang dijelaskan di `go-wapit-monorepo.txt`.** File itu (Hono.js/Cloudflare + Expo + Next.js) hanyalah rencana aspirasional — abaikan.
- Stack sebenarnya: **`gowapit-backend/`** = Python **FastAPI** (bukan Flask) + SQLAlchemy + SQLite; **`gowapit_frontend/`** = aplikasi mobile Flutter (Material 3) untuk objek wisata "Hutan Pinus Wapit" (Umbul Jumprit, Temanggung). Spesifikasi produk: `PRD Project GO WAPIT APP.txt`.

## Tata letak git (jebakan)

- Dua repo git terpisah. Repo root melacak `gowapit-backend` sebagai **gitlink tanpa `.gitmodules`** (entri submodule rusak). Perubahan backend harus di-commit di dalam `gowapit-backend/`; perubahan frontend/root di repo root. `git status` di root hanya menampilkan backend sebagai hash gitlink, bukan diff file.

## Backend (`gowapit-backend/`)

- Jalankan (sudah ada `venv/` lokal): `venv\Scripts\python -m uvicorn main:app --reload` atau `venv\Scripts\activate; uvicorn main:app --reload`. Produksi: `uvicorn main:app` (`Procfile` meneruskan `$PORT`).
- **`app_flask_lama.py` adalah kode mati legacy** (API mock Flask lama). Hanya `main.py`, `models.py`, `database.py` yang aktif.
- DB SQLite `gowapit.db` dibuat otomatis; tabel dan data seed (destinasi, paket, kuliner, layanan-umum) diisi saat startup dan idempoten. Perubahan skema dilakukan lewat `ALTER TABLE` hacky di `run_db_migrations()` (try/except yang menelan error) — tambahkan migrasi baru dengan cara yang sama.
- Secret berasal dari env var dengan fallback dev yang di-hardcode: `JWT_SECRET_KEY`, `MIDTRANS_SERVER_KEY` (sandbox Snap default). Jangan "perbaiki" default ini tanpa mengecek bagaimana instance Railway yang di-deploy mengatur env.
- Hash password sengaja mendukung bcrypt + fallback legacy pbkdf2/plaintext (`verify_password`) — pertahankan kompatibilitas mundur saat menyentuh auth.
- Endpoint API: `/api/register`, `/api/login`, `/api/users/me` (GET/PUT, JWT Bearer), `/api/destinasi`, `/api/paket`, `/api/kuliner?kedai=`, `/api/layanan-umum`, `/api/checkout` (Midtrans Snap). Body respons: `{"status":"success","data":...}`.

## Frontend (`gowapit_frontend/`)

- Perintah (jalankan dari `gowapit_frontend/`): `flutter run`, `flutter analyze`, `flutter test`.
- **Base URL API di-hardcode di `lib/config/api_config.dart`**, default-nya URL Railway produksi. Untuk dev lokal, panggil `ApiConfig.setBaseUrl("http://10.0.2.2:8000")` (emulator) atau IP LAN Anda, atau edit filenya. Android sudah mengizinkan HTTP cleartext (`usesCleartextTraffic="true"`).
- Semua screen ada di `lib/screens/`; navigasi pakai `Navigator`/`MaterialPageRoute` biasa + bottom nav hardcoded di `main.dart` (tanpa paket routing).
- Shell aplikasi memakai gradient global yang disuntikkan lewat `MaterialApp.builder`; **scaffold harus tetap `backgroundColor: Colors.transparent`** atau gradient tidak tampil.
- i18n lewat `easy_localization` (`assets/translations/en-US.json`, `id-ID.json`; default `id`). String UI dan komentar kode berbahasa **Indonesia** — ikuti gaya itu.
- Satu-satunya test (`test/widget_test.dart`) adalah test smoke template "counter" Flutter yang tidak diubah dan tidak sesuai aplikasi; abaikan pass/fail-nya.
- Ikon launcher dibuat dari `assets/images/Logo.png` lewat konfigurasi `flutter_launcher_icons` di `pubspec.yaml`.
