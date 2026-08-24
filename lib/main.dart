import 'package:flutter/material.dart';

import 'screens/main_navigation_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SmartTripApp());
}

// ================================================================
// TANPA ANIMASI PINDAH HALAMAN
// ================================================================
//
// Builder transisi custom yang langsung menampilkan halaman
// berikutnya apa adanya, tanpa efek slide/fade. Dipasang lewat
// `pageTransitionsTheme` di bawah, jadi otomatis berlaku untuk
// SEMUA Navigator.push(MaterialPageRoute(...)) di seluruh
// halaman -- tidak perlu mengubah satu per satu tiap layar.
//
// ================================================================

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class SmartTripApp extends StatelessWidget {
  const SmartTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'SmartTrip',

      // =========================================================
      // THEME
      // =========================================================
      //
      // pageTransitionsTheme di sini yang bikin semua perpindahan
      // halaman jadi instan (tanpa animasi), di semua platform.
      //
      // =========================================================

      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _InstantPageTransitionsBuilder(),
            TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
            TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
            TargetPlatform.windows: _InstantPageTransitionsBuilder(),
            TargetPlatform.linux: _InstantPageTransitionsBuilder(),
            TargetPlatform.fuchsia: _InstantPageTransitionsBuilder(),
          },
        ),
      ),

      // =========================================================
      // HALAMAN UTAMA APLIKASI
      // =========================================================
      //
      // Splash screen tampil dulu 3 detik, baru pindah otomatis
      // ke MainNavigationScreen (lihat logic-nya di splash_screen.dart).
      //
      // =========================================================

      home: const SplashScreen(),
    );
  }
}