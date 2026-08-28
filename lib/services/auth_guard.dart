import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../theme/app_colors.dart';
import 'api_service.dart';

/// Guard helper for guest mode.
/// Returns true if authenticated, otherwise shows login sheet and returns false.
bool requireAuth(BuildContext context, {String action = 'menggunakan fitur ini'}) {
  if (ApiService.instance.isAuthenticated) return true;
  showLoginRequiredSheet(context, action: action);
  return false;
}

void showLoginRequiredSheet(BuildContext context, {String action = 'menggunakan fitur ini'}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Masuk untuk melanjutkan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 6),
              Text(
                'Kamu perlu masuk untuk $action.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                  child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Nanti', style: TextStyle(color: AppColors.greyText, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
