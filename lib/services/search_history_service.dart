import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService._internal();
  static final SearchHistoryService instance = SearchHistoryService._internal();

  static const String _prefsKey = 'search_history';
  static const int _maxItems = 5;

  final ValueNotifier<List<String>> history = ValueNotifier<List<String>>([]);

  bool _isLoaded = false;

  /// Load riwayat pencarian dari SharedPreferences. Cukup dipanggil sekali
  /// (mis. di initState SearchScreen) -- panggilan berikutnya di-skip
  /// selama data di memory sudah ada, supaya tidak baca storage berkali-kali.
  Future<void> loadHistory() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (saved != null) {
        history.value = saved;
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ [SEARCH HISTORY SERVICE] Gagal load: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, history.value);
    } catch (e) {
      debugPrint('❌ [SEARCH HISTORY SERVICE] Gagal simpan: $e');
    }
  }

  /// Tambah keyword baru ke riwayat.
  /// - Item terbaru selalu di depan (index 0).
  /// - Kalau keyword yang sama (case-insensitive) sudah ada, pindahin ke
  ///   depan, bukan didobelin.
  /// - Maks [_maxItems] item -- yang paling lama otomatis kebuang.
  Future<void> addSearch(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(history.value);
    current.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    current.insert(0, trimmed);

    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }

    history.value = current;
    debugPrint('✅ [SEARCH HISTORY SERVICE] Riwayat diperbarui (${current.length} item)');
    await _persist();
  }

  /// Hapus satu item riwayat.
  Future<void> removeSearch(String keyword) async {
    final current = List<String>.from(history.value);
    current.removeWhere((item) => item == keyword);
    history.value = current;
    await _persist();
  }

  /// Hapus semua riwayat pencarian.
  Future<void> clearAll() async {
    history.value = [];
    await _persist();
  }
}