import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _keyToken = 'smarttrip_auth_token';
  static const String _keyTimestamp = 'smarttrip_auth_timestamp';
  static const int _sessionValidityDays = 30; // Login session stays valid for 30 days

  /// Save authentication token with current timestamp
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setInt(_keyTimestamp, DateTime.now().millisecondsSinceEpoch);
      debugPrint('💾 [AUTH STORAGE] Token saved successfully');
    } catch (e) {
      debugPrint('❌ [AUTH STORAGE SAVE ERROR] $e');
    }
  }

  /// Get saved token if not expired
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final timestamp = prefs.getInt(_keyTimestamp);

      if (token == null || token.isEmpty || timestamp == null) {
        return null;
      }

      final loginDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final differenceInDays = now.difference(loginDate).inDays;

      if (differenceInDays >= _sessionValidityDays) {
        debugPrint('⚠️ [AUTH STORAGE] Session expired after $differenceInDays days. Clearing token.');
        await clearToken();
        return null;
      }

      debugPrint('🔑 [AUTH STORAGE] Valid cached session found (Age: $differenceInDays days)');
      return token;
    } catch (e) {
      debugPrint('❌ [AUTH STORAGE GET ERROR] $e');
      return null;
    }
  }

  /// Clear token on logout
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyTimestamp);
      debugPrint('🧹 [AUTH STORAGE] Session cleared');
    } catch (e) {
      debugPrint('❌ [AUTH STORAGE CLEAR ERROR] $e');
    }
  }
}
