import 'package:flutter/material.dart';

/// Sumber warna terpusat SmartTrip. Import ini di semua screen,
/// ganti pemakaian warna lokal dengan AppColors.xxx.
class AppColors {
  AppColors._();

  // Brand
  static const Color primaryBlue = Color(0xFF55B8F4);
  static const Color darkBlue = Color(0xFF164B9B); // dulu ada juga 0xFF06459B di beberapa file, disatukan ke sini
  static const Color mediumBlue = Color(0xFF42B5F5);

  // Teks
  static const Color darkText = Color(0xFF111111); // dulu ada juga 0xFF222222 & 0xFF555555, disatukan ke sini
  static const Color greyText = Color(0xFF666666); // dulu ada juga 0xFF777777, disatukan ke sini
  static const Color mutedText = Color(0xFF888888);

  // Border
  static const Color borderColor = Color(0xFFE8E8E8);
  static const Color borderColorLight = Color(0xFFE5E5E5);
  static const Color fieldBorder = Color(0xFFE2E2E2);
  static const Color borderColorSoft = Color(0xFFE7E7E7);

  // Background / surface
  static const Color lightBlue = Color(0xFFEAF7FF);
  static const Color imagePlaceholderBg = Color(0xFFE8F4FA);
  static const Color categoryBadgeBg = Color(0xFFE2F3FF);
  static const Color paleBlue = Color(0xFFC7E6F8);
  static const Color lightGrey = Color(0xFFF1F1F1);

  // Status
  static const Color successGreen = Color(0xFF2E9E5B);
  static const Color successBg = Color(0xFFEAF8EE);
  static const Color errorRed = Color(0xFFE53935);
  static const Color errorBg = Color(0xFFFFF0F0);
  static const Color warningYellow = Color(0xFFFFC400);
  static const Color warningText = Color(0xFFD9A900);

  // Netral lain
  static const Color doneGrey = Color(0xFFBFBFBF);
}