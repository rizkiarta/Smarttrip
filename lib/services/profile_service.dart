import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// ================================================================
// PROFILE SERVICE
// ================================================================
//
// Sumber kebenaran tunggal (single source of truth) untuk data
// profil user: nama, bio, dan foto profil. Disimpan di memori
// (in-memory) selama aplikasi berjalan lewat ValueNotifier bawaan
// Flutter, polanya sama seperti SavedDestinationsService, jadi
// tidak perlu package state management tambahan.
//
// Dipakai oleh:
// - ProfileScreen: menampilkan avatar/nama/bio
// - EditProfileScreen (edit_profile_screen.dart): mengubah
//   avatar/nama/bio
// - ReviewScreen (review_screen.dart): mengambil nama & foto user
//   saat kirim ulasan baru
//
// buildAvatarImage (di bawah) juga ikut dipindah ke sini karena
// dipakai di tempat-tempat yang sama dengan ProfileService, supaya
// screens/ tidak perlu tahu detail cara avatar dirender.
//
// ================================================================

class ProfileData {
  final String name;
  final String bio;
  final String username;
  final DateTime? birthDate;
  final String phone;
  final String email;

  // Path foto profil. Bisa berupa:
  // - null / kosong -> pakai avatar default (network placeholder)
  // - path file lokal (hasil kamera/galeri) -> ditampilkan lewat
  //   Image.file
  final String? photoPath;

  const ProfileData({
    required this.name,
    required this.bio,
    this.username = '',
    this.birthDate,
    this.phone = '',
    this.email = '',
    this.photoPath,
  });

  ProfileData copyWith({
    String? name,
    String? bio,
    String? username,
    DateTime? birthDate,
    String? phone,
    String? email,
    String? photoPath,
  }) {
    return ProfileData(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      username: username ?? this.username,
      birthDate: birthDate ?? this.birthDate,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

class ProfileService {
  ProfileService._internal();

  static final ProfileService instance = ProfileService._internal();

  // Avatar default (dipakai sebelum user pernah ganti foto profil).
  static const String defaultAvatarUrl = 'https://i.pravatar.cc/150?img=47';

  final ValueNotifier<ProfileData> profile = ValueNotifier<ProfileData>(
    ProfileData(
      name: 'Kang Hearin',
      bio: 'Traveler',
      username: 'green_meowww',
      birthDate: DateTime(2006, 10, 7),
      phone: '088736492071',
      email: 'hearin777@gmail.com',
      photoPath: null,
    ),
  );

  void updateProfile({
    required String name,
    String? bio,
    String? username,
    DateTime? birthDate,
    String? phone,
    String? email,
    String? photoPath,
  }) {
    profile.value = profile.value.copyWith(
      name: name,
      bio: bio,
      username: username,
      birthDate: birthDate,
      phone: phone,
      email: email,
      photoPath: photoPath,
    );
  }

  // Foto profil yang dipakai saat menulis ulasan baru. Kalau user
  // belum pernah ganti foto, fallback ke avatar default supaya
  // konsisten dengan avatar yang tampil di ProfileScreen.
  String get currentAvatarForReview =>
      profile.value.photoPath ?? defaultAvatarUrl;
}

// ================================================================
// SHARED AVATAR RENDERER
// ================================================================
//
// Dipakai di mana pun avatar user ditampilkan (ProfileScreen di atas,
// EditProfileScreen, kartu ulasan di review_screen.dart, & kartu
// "Ulasan Saya" di atas). Avatar bisa berupa:
// - URL network (avatar mock/default, mis. dari pravatar.cc)
// - path file lokal (hasil kamera/galeri lewat image_picker)
//
// Sebelumnya beberapa layar langsung pakai NetworkImage untuk semua
// avatar, padahal path file lokal bukan URL -> crash. Fungsi ini
// otomatis memilih Image.network atau Image.file berdasarkan
// bentuk path-nya, mirip pola _buildPhotoImage di review_screen.dart
// untuk foto ulasan.
// ================================================================

Widget buildAvatarImage(
  String avatarPathOrUrl, {
  double size = 42,
  Color backgroundColor =  AppColors.imagePlaceholderBg,
  Color iconColor =  AppColors.primaryBlue,
}) {
  final Widget fallback = Container(
    color: backgroundColor,
    alignment: Alignment.center,
    child: Icon(Icons.person, color: iconColor, size: size * 0.55),
  );

  final bool isNetwork = avatarPathOrUrl.startsWith('http');

  final Widget image = isNetwork
      ? Image.network(
          avatarPathOrUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        )
      : Image.file(
          File(avatarPathOrUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        );

  return ClipOval(
    child: SizedBox(width: size, height: size, child: image),
  );
}
