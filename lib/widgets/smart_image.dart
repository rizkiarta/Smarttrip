import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class SmartImage extends StatelessWidget {
  final String? imagePathOrUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  const SmartImage({
    super.key,
    required this.imagePathOrUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  static String resolveUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return '';

    // 0. Local filesystem file (e.g. from camera/gallery image_picker)
    if (File(trimmed).existsSync()) {
      return trimmed;
    }

    // 1. Full HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    // 2. Local asset path
    if (trimmed.startsWith('assets/')) {
      return trimmed;
    }

    // 3. Relative server path from backend (e.g. storage/..., uploads/..., destinations/..., reviews/...)
    if (trimmed.startsWith('storage/') ||
        trimmed.startsWith('/storage/') ||
        trimmed.startsWith('uploads/') ||
        trimmed.startsWith('/uploads/') ||
        trimmed.startsWith('destinations/') ||
        trimmed.startsWith('/destinations/') ||
        trimmed.startsWith('reviews/') ||
        trimmed.startsWith('/reviews/')) {
      try {
        final String rawBase = ApiService.baseUrl;
        final Uri baseUri = Uri.parse(rawBase);
        final String origin = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';
        final String cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
        return '$origin$cleanPath';
      } catch (_) {
        return trimmed;
      }
    }

    // 4. Filename with image extension (e.g. pantai_mutun.jpg) -> maps to assets/images/ if not absolute file path
    if (trimmed.contains('.') && !trimmed.contains('/') && !trimmed.contains('\\')) {
      return 'assets/images/$trimmed';
    }

    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final Widget defaultFallback = fallback ??
        Container(
          width: width,
          height: height,
          color: AppColors.imagePlaceholderBg,
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),
        );

    final String raw = imagePathOrUrl?.trim() ?? '';
    if (raw.isEmpty || raw.toLowerCase() == 'null') {
      return _clip(defaultFallback);
    }

    final String resolved = resolveUrl(raw);
    Widget imageWidget;

    int? getCacheDimension(double? dim) {
      if (dim == null || !dim.isFinite || dim <= 0) return null;
      return (dim * 2).toInt();
    }

    final int? memCacheW = getCacheDimension(width);
    final int? memCacheH = getCacheDimension(height);

    if (resolved.startsWith('http://') || resolved.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheW,
        memCacheHeight: memCacheH,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: AppColors.imagePlaceholderBg,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
            ),
          ),
        ),
        errorWidget: (context, url, error) => defaultFallback,
      );
    } else if (resolved.startsWith('assets/')) {
      imageWidget = Image.asset(
        resolved,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: memCacheW,
        cacheHeight: memCacheH,
        errorBuilder: (context, error, stackTrace) => defaultFallback,
      );
    } else {
      final file = File(resolved);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: memCacheW,
          cacheHeight: memCacheH,
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        );
      } else {
        imageWidget = defaultFallback;
      }
    }

    return _clip(imageWidget);
  }

  Widget _clip(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: child,
      );
    }
    return child;
  }
}

