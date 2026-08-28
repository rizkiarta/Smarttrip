import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/my_reviews_service.dart';
import '../services/profile_service.dart';
import '../services/saved_destinations_service.dart';
import '../services/saved_itinerary_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedSessionAndNavigate();
  }

  Future<void> _checkSavedSessionAndNavigate() async {
    final startTime = DateTime.now();

    try {
      // Check saved auth token from persistent storage
      final savedToken = await AuthStorage.getToken();

      if (savedToken != null && savedToken.isNotEmpty) {
        debugPrint('🚀 [PERSISTENT AUTH] Found valid saved session. Restoring login state...');
        ApiService.instance.setToken(savedToken);

        // Sync user data from server
        await Future.wait([
          ProfileService.instance.fetchProfile(),
          SavedDestinationsService.instance.fetchFavorites(),
          SavedItineraryService.instance.fetchItineraries(),
          MyReviewsService.instance.fetchMyReviews(),
        ]).timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('⚠️ [PERSISTENT AUTH] Data sync timeout, proceeding to main screen...');
          return [];
        });
      }
    } catch (e) {
      debugPrint('⚠️ [PERSISTENT AUTH ERROR] $e');
    }

    final elapsedTime = DateTime.now().difference(startTime);
    final remainingDelay = const Duration(seconds: 2) - elapsedTime;
    if (remainingDelay.inMilliseconds > 0) {
      await Future.delayed(remainingDelay);
    }

    if (!mounted) return;

    if (ApiService.instance.isAuthenticated) {
      debugPrint('✨ [PERSISTENT AUTH] Session active. Directing to MainNavigationScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
          settings: const RouteSettings(name: '/main'),
        ),
      );
    } else {
      debugPrint('🔑 [PERSISTENT AUTH] No session found. Directing to LoginScreen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 95,
            child: IgnorePointer(
              child: Image.asset(
                'assets/images/siger.png',
                height: 220,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: Image.asset(
                'assets/images/smarttrip_logo.png',
                width: 330,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 125,
              child: ClipPath(
                clipper: _SplashWaveClipper(),
                child: Container(
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.moveTo(0, 15);
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.55,
      size.width * 0.35,
      size.height * 0.75,
      size.width * 0.55,
      size.height * 0.65,
    );
    path.cubicTo(
      size.width * 0.72,
      size.height * 0.55,
      size.width * 0.87,
      size.height * 0.40,
      size.width,
      size.height * 0.28,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}