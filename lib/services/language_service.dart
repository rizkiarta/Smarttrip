import 'package:flutter/material.dart';

// ================================================================
// LANGUAGE SERVICE
// ================================================================
//
// LanguageService murni in-memory -- pola sama seperti
// ProfileService -- jadi begitu backend/localization system sudah
// siap, tinggal method di service ini yang diisi (mis. simpan ke
// SharedPreferences + ganti locale aplikasi), pemanggil (LanguageScreen
// di profile_screen.dart) tidak perlu diubah.
//
// CATATAN JUJUR: app ini sekarang semua teksnya hardcoded Bahasa
// Indonesia (belum ada sistem localization/intl beneran), jadi
// milih 'English' di sini BARU menyimpan preferensi user -- belum
// benar-benar menerjemahkan seluruh app.
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

  void select(String code) {
    languageCode.value = code;
  }
}
