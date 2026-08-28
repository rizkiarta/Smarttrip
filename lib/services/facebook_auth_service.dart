import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'api_service.dart';

class FacebookAuthService {
  FacebookAuthService._privateConstructor();
  static final FacebookAuthService instance = FacebookAuthService._privateConstructor();

  /// Menjalankan workflow Facebook Login dan mengirimkan data ke backend Laravel
  Future<Map<String, dynamic>> signIn() async {
    try {
      debugPrint('🔑 [FACEBOOK SIGN-IN] Triggering Facebook Login modal...');

      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();

        debugPrint('👤 [FACEBOOK USER DATA] ID: ${userData['id']} | Email: ${userData['email']} | Name: ${userData['name']}');

        final String? photoUrl = userData['picture'] != null &&
                userData['picture']['data'] != null
            ? userData['picture']['data']['url']
            : null;

        final res = await ApiService.instance.post('auth/facebook', body: {
          'facebook_id': userData['id'],
          'email': userData['email'],
          'name': userData['name'] ?? 'Facebook User',
          'photo_url': photoUrl,
        });

        debugPrint('✅ [FACEBOOK AUTH SUCCESS] Respon: $res');
        return res;
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint('⚠️ [FACEBOOK SIGN-IN] Pengguna membatalkan login Facebook.');
        throw ApiException('Proses masuk dengan Facebook dibatalkan.');
      } else {
        debugPrint('❌ [FACEBOOK SIGN-IN ERROR] ${result.message}');
        throw ApiException('Gagal terhubung dengan Facebook (${result.message})');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      final errStr = e.toString();
      debugPrint('❌ [FACEBOOK SIGN-IN EXCEPTION] $errStr');

      if (errStr.contains('Facebook') || errStr.contains('App ID') || errStr.contains('Missing')) {
        throw ApiException('Login Facebook memerlukan pendaftaran Facebook App ID di Meta for Developers. Silakan gunakan Login/Register Email biasa.');
      }

      throw ApiException('Gagal terhubung dengan layanan Facebook ($e)');
    }
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
