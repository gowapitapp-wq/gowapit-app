import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthResult {
  final bool isSuccess;
  final String message;
  final String? role;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? referralRewards;

  AuthResult({
    required this.isSuccess,
    required this.message,
    this.role,
    this.userData,
    this.referralRewards,
  });
}

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Mendapatkan Firebase ID Token untuk autentikasi ke backend
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken(forceRefresh);
    } catch (_) {
      return null;
    }
  }

  /// Sinkronisasi profil & role dari backend GoWapit
  Future<AuthResult> ensureBackendSynced({
    String? namaLengkap,
    String? referralCode,
    String? fotoProfil,
    int maxRetries = 2,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return AuthResult(isSuccess: false, message: "Pengguna belum login di Firebase.");
    }

    String? idToken = await getToken();
    if (idToken == null || idToken.isEmpty) {
      return AuthResult(isSuccess: false, message: "Gagal mendapatkan token autentikasi.");
    }

    final String? effectiveName = (namaLengkap != null && namaLengkap.isNotEmpty)
        ? namaLengkap
        : (user.displayName != null && user.displayName!.isNotEmpty ? user.displayName : null);
    
    final String? effectiveFoto = (fotoProfil != null && fotoProfil.isNotEmpty)
        ? fotoProfil
        : (user.photoURL != null && user.photoURL!.isNotEmpty ? user.photoURL : null);

    final Uri syncUri = ApiConfig.uri("/api/auth/firebase");
    final Map<String, dynamic> bodyData = {
      if (effectiveName != null && effectiveName.isNotEmpty) "nama_lengkap": effectiveName,
      if (referralCode != null && referralCode.isNotEmpty) "referral_code": referralCode,
      if (effectiveFoto != null && effectiveFoto.isNotEmpty) "foto_profil": effectiveFoto,
    };

    int attempts = 0;
    while (attempts <= maxRetries) {
      attempts++;
      try {
        final response = await http.post(
          syncUri,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $idToken",
          },
          body: jsonEncode(bodyData),
        );

        Map<String, dynamic> resData = {};
        try {
          resData = jsonDecode(response.body);
        } catch (_) {}

        if (response.statusCode == 200) {
          final String role = (resData["user"] != null && resData["user"]["role"] != null)
              ? resData["user"]["role"]
              : "user";

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', role);

          return AuthResult(
            isSuccess: true,
            message: resData["message"] ?? "Sinkronisasi berhasil",
            role: role,
            userData: resData["user"],
            referralRewards: resData["referral_rewards"],
          );
        } else if (response.statusCode == 409) {
          String detailMessage = ApiConfig.extractErrorMessage(
            resData["detail"] ?? resData["message"],
            fallback: "Terjadi konflik akun.",
          );
          return AuthResult(isSuccess: false, message: detailMessage);
        } else {
          if (attempts > maxRetries) {
            String detailMessage = ApiConfig.extractErrorMessage(
              resData["detail"] ?? resData["message"],
              fallback: "Gagal menghubungkan ke server (Kode: ${response.statusCode})",
            );
            return AuthResult(isSuccess: false, message: detailMessage);
          }
        }
      } catch (e) {
        if (attempts > maxRetries) {
          return AuthResult(
            isSuccess: false,
            message: "Gangguan koneksi internet saat sinkronisasi: ${e.toString()}",
          );
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return AuthResult(isSuccess: false, message: "Sinkronisasi ke server gagal.");
  }

  /// 1. Login dengan Email & Password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        return await ensureBackendSynced();
      }
      return AuthResult(isSuccess: false, message: "Gagal masuk ke akun.");
    } on FirebaseAuthException catch (e) {
      return AuthResult(isSuccess: false, message: _mapFirebaseAuthError(e));
    } catch (e) {
      return AuthResult(isSuccess: false, message: "Terjadi kesalahan: ${e.toString()}");
    }
  }

  /// 2. Pendaftaran Akun Baru dengan Email & Password (+ Referral)
  Future<AuthResult> signUpWithEmail(
    String email,
    String password,
    String namaLengkap, {
    String? referralCode,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        try {
          await credential.user!.updateDisplayName(namaLengkap.trim());
        } catch (_) {}

        return await ensureBackendSynced(
          namaLengkap: namaLengkap.trim(),
          referralCode: referralCode?.trim(),
        );
      }
      return AuthResult(isSuccess: false, message: "Gagal membuat akun.");
    } on FirebaseAuthException catch (e) {
      return AuthResult(isSuccess: false, message: _mapFirebaseAuthError(e));
    } catch (e) {
      return AuthResult(isSuccess: false, message: "Terjadi kesalahan: ${e.toString()}");
    }
  }

  /// 3. Login dengan Google (Android Native + Web Popup & Redirect)
  Future<AuthResult> signInWithGoogle() async {
    try {
      UserCredential? credential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        try {
          credential = await _auth.signInWithPopup(googleProvider);
        } catch (popupError) {
          // Fallback ke redirect jika popup diblokir browser
          await _auth.signInWithRedirect(googleProvider);
          return AuthResult(isSuccess: true, message: "Mengarahkan ke halaman Google...");
        }
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: null,
          serverClientId: ApiConfig.googleWebClientId,
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return AuthResult(isSuccess: false, message: "Login Google dibatalkan pengguna.");
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential oAuthCred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        credential = await _auth.signInWithCredential(oAuthCred);
      }

      if (credential.user != null) {
        return await ensureBackendSynced(
          namaLengkap: credential.user!.displayName,
          fotoProfil: credential.user!.photoURL,
        );
      }
      return AuthResult(isSuccess: false, message: "Gagal login dengan akun Google.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return AuthResult(
          isSuccess: false,
          message: "Email ini sudah terdaftar dengan metode masuk lain. Silakan login dengan email & password terlebih dahulu.",
        );
      }
      return AuthResult(isSuccess: false, message: _mapFirebaseAuthError(e));
    } catch (e) {
      return AuthResult(isSuccess: false, message: "Kesalahan Google Sign-In: ${e.toString()}");
    }
  }

  /// 4. Mengirim Email Reset Password (Lupa Password)
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult(
        isSuccess: true,
        message: "Tautan pemulihan kata sandi telah dikirim ke ${email.trim()}.",
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(isSuccess: false, message: _mapFirebaseAuthError(e));
    } catch (e) {
      return AuthResult(isSuccess: false, message: "Gagal mengirim email reset: ${e.toString()}");
    }
  }

  /// 5. Logout & Bersihkan Session
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      await prefs.remove('jwt_token');
    } catch (_) {}
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return "Email atau kata sandi tidak sesuai.";
      case 'email-already-in-use':
        return "Email ini sudah digunakan oleh akun lain.";
      case 'invalid-email':
        return "Format alamat email tidak valid.";
      case 'weak-password':
        return "Kata sandi terlalu lemah (minimal 6 karakter).";
      case 'user-disabled':
        return "Akun ini telah dinonaktifkan.";
      case 'too-many-requests':
        return "Terlalu banyak percobaan gagal. Silakan coba lagi beberapa saat.";
      case 'network-request-failed':
        return "Gagal terhubung ke server. Periksa koneksi internet Anda.";
      default:
        return e.message ?? "Terjadi kesalahan autentikasi (${e.code}).";
    }
  }
}
