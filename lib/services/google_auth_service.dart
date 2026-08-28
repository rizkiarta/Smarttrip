import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class GoogleAuthService {
  GoogleAuthService._privateConstructor();
  static final GoogleAuthService instance = GoogleAuthService._privateConstructor();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Menjalankan workflow Google Sign-In dan mengirimkan data ke backend Laravel
  Future<Map<String, dynamic>> signIn() async {
    try {
      debugPrint('🔑 [GOOGLE SIGN-IN] Triggering Google Sign In modal...');

      // Check desktop platforms where native SDK is unsupported
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        throw ApiException('Login Google di platform Desktop belum didukung. Silakan gunakan Login/Register Email biasa.');
      }
      
      // Logout dulu jika ada sisa sesi lokal agar user bisa memilih akun
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('⚠️ [GOOGLE SIGN-IN] Pengguna membatalkan proses login Google.');
        throw ApiException('Proses masuk dengan Google dibatalkan.');
      }

      debugPrint('👤 [GOOGLE USER DATA] ID: ${googleUser.id} | Email: ${googleUser.email} | Name: ${googleUser.displayName}');

      final res = await ApiService.instance.post('auth/google', body: {
        'google_id': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? 'Google User',
        'photo_url': googleUser.photoUrl,
      });

      if (res != null && res['token'] != null) {
        ApiService.instance.setToken(res['token'].toString());
      }

      debugPrint('✅ [GOOGLE AUTH SUCCESS] Respon: $res');
      return res;
    } catch (e) {
      if (e is ApiException) rethrow;
      final errStr = e.toString();
      debugPrint('❌ [GOOGLE SIGN-IN ERROR] $errStr');

      if (errStr.contains('ApiException: 10') || 
          errStr.contains('10:') || 
          errStr.contains('12500') ||
          errStr.contains('DEVELOPER_ERROR')) {
        throw ApiException('Google Sign-In Error (10): Pastikan SHA-1 sudah terdaftar di Firebase dan file google-services.json terbaru sudah didownload ulang ke android/app/.');
      }

      if (errStr.contains('Unimplemented') || errStr.contains('Unsupported')) {
        throw ApiException('Google Sign-In tidak didukung pada platform ini. Silakan gunakan Login/Register Email biasa.');
      }

      throw ApiException('Gagal terhubung dengan layanan Google ($e)');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
