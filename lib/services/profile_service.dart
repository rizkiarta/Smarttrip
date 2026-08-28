import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'api_service.dart';
import 'language_service.dart';

class ProfileData {
  final String name;
  final String bio;
  final String username;
  final DateTime? birthDate;
  final String phone;
  final String email;
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

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    DateTime? bDate;
    if (json['birth_date'] != null) {
      try {
        bDate = DateTime.parse(json['birth_date']);
      } catch (_) {}
    }

    return ProfileData(
      name: json['name'] ?? '',
      bio: json['bio'] ?? 'Traveler',
      username: json['username'] ?? '',
      birthDate: bDate,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      photoPath: json['photo_url'],
    );
  }
}

class ProfileService {
  ProfileService._internal();
  static final ProfileService instance = ProfileService._internal();

  final ValueNotifier<ProfileData> profile = ValueNotifier<ProfileData>(
    const ProfileData(
      name: '',
      bio: 'Traveler',
      username: '',
      email: '',
      photoPath: null,
    ),
  );

  /// Fetch profile data from Laravel API backend
  Future<void> fetchProfile() async {
    if (!ApiService.instance.isAuthenticated) return;
    try {
      final res = await ApiService.instance.get('profile');
      if (res != null && res['data'] != null) {
        final dataMap = Map<String, dynamic>.from(res['data'] as Map);
        profile.value = ProfileData.fromJson(dataMap);
        if (dataMap['language'] != null) {
          LanguageService.instance.languageCode.value = dataMap['language'].toString();
        }
        debugPrint('👤 [PROFILE FETCHED] Name: ${profile.value.name}, Photo: ${profile.value.photoPath}');
      }
    } catch (e) {
      debugPrint('Fetch profile error: $e');
    }
  }

  /// Update profile data and sync with Laravel backend
  Future<void> updateProfile({
    required String name,
    String? bio,
    String? username,
    DateTime? birthDate,
    String? phone,
    String? email,
    String? photoPath,
  }) async {
    // 1. Update local state immediately for instant UI feedback
    profile.value = profile.value.copyWith(
      name: name,
      bio: bio,
      username: username,
      birthDate: birthDate,
      phone: phone,
      email: email,
      photoPath: photoPath,
    );

    // 2. Sync to Laravel backend if authenticated
    if (ApiService.instance.isAuthenticated) {
      try {
        final body = {
          'name': name,
          if (bio != null) 'bio': bio,
          if (username != null) 'username': username,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (birthDate != null) 'birth_date': birthDate.toIso8601String().split('T').first,
        };
        await ApiService.instance.put('profile', body: body);

        // Upload photo if a new local file is selected
        if (photoPath != null && !photoPath.startsWith('http')) {
          final file = File(photoPath);
          if (file.existsSync()) {
            final photoRes = await ApiService.instance.multipartPost(
              'profile/photo',
              fileField: 'photo',
              file: file,
            );
            if (photoRes != null && photoRes['photo_url'] != null) {
              profile.value = profile.value.copyWith(photoPath: photoRes['photo_url']);
            }
          }
        }

        // Re-fetch profile to ensure 100% server sync
        await fetchProfile();
      } catch (e) {
        debugPrint('Sync update profile error: $e');
      }
    }
  }

  String? get currentAvatarForReview => profile.value.photoPath;
}

String _resolveAvatarUrl(String url) {
  if (url.trim().isEmpty) return url;
  if (url.startsWith('assets/')) return url;

  // Clean double storage prefix if present
  if (url.contains('/storage/storage/')) {
    url = url.replaceAll('/storage/storage/', '/storage/');
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    try {
      final parsed = Uri.parse(url);
      final baseUri = Uri.parse(ApiService.baseUrl);

      // Always align host/port with active ApiService.baseUrl unless external URL
      if (parsed.host == 'localhost' ||
          parsed.host == '127.0.0.1' ||
          parsed.host == 'smarttrip-backend.test' ||
          parsed.host == baseUri.host) {
        return Uri(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: baseUri.port,
          path: parsed.path,
        ).toString();
      }
    } catch (_) {}
    return url;
  }
  final file = File(url);
  if (file.existsSync()) {
    return url;
  }
  try {
    final baseUri = Uri.parse(ApiService.baseUrl);
    String cleanPath = url;
    if (cleanPath.startsWith('/storage/')) {
      cleanPath = cleanPath;
    } else if (cleanPath.startsWith('storage/')) {
      cleanPath = '/$cleanPath';
    } else {
      cleanPath = '/storage/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
    }
    return '${baseUri.scheme}://${baseUri.host}:${baseUri.port}$cleanPath';
  } catch (_) {}
  return url;
}


Widget buildAvatarImage(
  String? avatarPathOrUrl, {
  double size = 42,
  Color backgroundColor = AppColors.imagePlaceholderBg,
  Color iconColor = AppColors.primaryBlue,
}) {
  final Widget fallback = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Icon(Icons.person_rounded, color: iconColor, size: size * 0.55),
  );

  if (avatarPathOrUrl == null || avatarPathOrUrl.trim().isEmpty) {
    return fallback;
  }

  final String resolved = _resolveAvatarUrl(avatarPathOrUrl);
  final bool isNetwork = resolved.startsWith('http://') || resolved.startsWith('https://');
  final bool isAsset = resolved.startsWith('assets/');

  Widget imageWidget;
  if (isNetwork) {
    imageWidget = Image.network(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ [AVATAR IMAGE ERROR] Failed to load network image: $resolved | Error: $error');
        return fallback;
      },
    );
  } else if (isAsset) {

    imageWidget = Image.asset(
      resolved,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  } else {
    final file = File(resolved);
    if (file.existsSync()) {
      imageWidget = Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    } else {
      imageWidget = fallback;
    }
  }

  return ClipOval(
    child: SizedBox(width: size, height: size, child: imageWidget),
  );
}
