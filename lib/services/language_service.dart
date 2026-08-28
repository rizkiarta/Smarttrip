import 'package:flutter/material.dart';
import 'api_service.dart';

// ================================================================
// LANGUAGE SERVICE
// ================================================================
//
// LanguageService menyimpan pilihan bahasa pengguna dan menyinkronkannya
// dengan server Laravel backend (/api/v1/profile).
//
// ================================================================

class LanguageOption {
  final String code;
  final String label;
  final String nativeLabel;

  const LanguageOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });
}

class LanguageService {
  LanguageService._internal();

  static final LanguageService instance = LanguageService._internal();

  static const List<LanguageOption> options = [
    LanguageOption(code: 'id', label: 'Bahasa Indonesia', nativeLabel: 'Bahasa Indonesia'),
    LanguageOption(code: 'en', label: 'English', nativeLabel: 'English'),
  ];

  final ValueNotifier<String> languageCode = ValueNotifier<String>('id');

  LanguageOption get current => options.firstWhere(
        (option) => option.code == languageCode.value,
        orElse: () => options.first,
      );

  Future<void> select(String code) async {
    languageCode.value = code;
    if (ApiService.instance.isAuthenticated) {
      try {
        await ApiService.instance.put('profile', body: {'language': code});
      } catch (e) {
        debugPrint('Sync language selection error: $e');
      }
    }
  }
}
