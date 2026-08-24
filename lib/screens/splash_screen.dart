import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // SPLASH DURATION
    // ==========================================================

    Timer(
      const Duration(seconds: 3),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [

          // ====================================================
          // SINGER / SIGER IMAGE
          // ====================================================
          //
          // Nanti gambar Siger kamu taruh di sini.
          //
          // Contoh:
          // assets/images/siger.png
          //
          // ====================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 95,

            child: IgnorePointer(
              child: Image.asset(
                'assets/images/siger.png',

                height: 220,

                fit: BoxFit.contain,

                alignment:
                    Alignment.bottomCenter,
              ),
            ),
          ),

          // ====================================================
          // LOGO SMARTTRIP AI
          // ====================================================

          Center(
            child: Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 120,
              ),

              child: Image.asset(
                'assets/images/smarttrip_logo.png',

                width: 330,

                fit: BoxFit.contain,
              ),
            ),
          ),

          // ====================================================
          // BOTTOM BLUE AREA
          // ====================================================

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


// ============================================================
// WAVE CLIPPER
// ============================================================

class _SplashWaveClipper
    extends CustomClipper<Path> {

  @override
  Path getClip(Size size) {

    final Path path = Path();

    // Mulai dari kiri atas
    path.moveTo(0, 15);

    // Gelombang pertama
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.55,

      size.width * 0.35,
      size.height * 0.75,

      size.width * 0.55,
      size.height * 0.65,
    );

    // Gelombang kedua
    path.cubicTo(
      size.width * 0.72,
      size.height * 0.55,

      size.width * 0.87,
      size.height * 0.40,

      size.width,
      size.height * 0.28,
    );

    // Sisi kanan bawah
    path.lineTo(
      size.width,
      size.height,
    );

    // Sisi kiri bawah
    path.lineTo(
      0,
      size.height,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    covariant CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}