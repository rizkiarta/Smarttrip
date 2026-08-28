import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {}
  // Jangan await lama biar splash tetap cepat, tapi Firebase sudah ready untuk getToken
  PushNotificationService.instance.initialize();

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

        // =======================================================
        // FONT GLOBAL — INTER
        // =======================================================
        //
        // textTheme di sini jadi acuan default font untuk SEMUA
        // widget Text() di seluruh halaman, selama widget Text
        // tersebut tidak dikasih `style: TextStyle(...)` manual
        // yang override-nya (mis. fontFamily beda atau dari
        // GoogleFonts lain langsung). Kalau masih ada halaman yang
        // fontnya belum ikut berubah, kemungkinan besar itu karena
        // ada TextStyle hardcode di file screen-nya masing-masing
        // yang perlu diganti agar merujuk ke Theme.of(context)
        // .textTheme, bukan bikin TextStyle baru.
        //
        // =======================================================

        textTheme: GoogleFonts.interTextTheme(),
        fontFamily: GoogleFonts.inter().fontFamily,
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