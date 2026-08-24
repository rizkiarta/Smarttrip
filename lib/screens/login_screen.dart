import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'main_navigation_screen.dart';
import 'register_screen.dart';
import '../theme/app_colors.dart';

// ================================================================
// LOGIN SCREEN
// ================================================================
//
// Halaman login "SmartTrip AI" sesuai referensi desain: logo bulat
// (pin lokasi + matahari) di atas, card putih rounded berisi form
// (email/telepon + kata sandi), link "Lupa kata sandi?", tombol
// "Masuk", opsi login Google/Facebook, dan link ke halaman daftar.
// Ada wave biru dekoratif di bawah layar.
//
// STATUS: baru TAMPILAN (UI-only). Validasi input, pemanggilan API
// auth, dan navigasi ke halaman Daftar/Lupa Kata Sandi/halaman utama
// belum diisi -- tinggal disambungkan ke logic aslinya.
//
// ================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ============================================================
  // FORM STATE
  // ============================================================

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // FocusNode dipakai supaya border input bisa "menyala" biru pas lagi
  // aktif diketik -- feedback visual kecil yang bikin form kerasa lebih
  // hidup/rapi, bukan cuma kotak statis.
  final FocusNode _identifierFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // edgeToEdge -- wajib di-set biar body app-nya beneran digambar
    // MELEWATI system navigation bar (bukan cuma berhenti di atasnya),
    // sama kaya di RegisterScreen, supaya wave-nya nyampe ke ujung fisik
    // layar paling bawah tanpa sisa celah putih (dan tinggi wave-nya
    // konsisten sama Register pas pindah halaman).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _identifierFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Biar wave-nya beneran diam fix di bawah layar (sama kaya di
      // SplashScreen/RegisterScreen) dan nggak ikut kegeser ke atas pas
      // keyboard muncul waktu user ngetik di form.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Wave dekoratif di dasar layar -- SAMA PERSIS dengan
          // clipper punya SplashScreen (_SplashWaveClipper), bukan
          // lekukan sendiri lagi, supaya bentuknya konsisten di
          // ketiga layar (Splash/Login/Register).
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 125,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(color: AppColors.primaryBlue),
              ),
            ),
          ),

          // Siger (assets/images/siger.png) -- ditaruh di sini, LANGSUNG
          // anak Stack utama (bukan di dalam Column yang ke-padding
          // horizontal 24), supaya bisa selebar penuh 1 layar kiri-kanan.
          // Posisinya disamain kira-kira sejajar sama logo di bawahnya
          // (SafeArea top + jarak 12 sebelum logo). IgnorePointer biar
          // nggak nge-block tap ke elemen lain, dan logo/form di
          // Positioned/SafeArea sesudah ini otomatis digambar DI ATASNYA
          // (urutan children Stack = urutan tumpukan, yang belakangan
          // digambar di depan).
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                child: Image.asset(
                  'assets/images/siger.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              // Padding luar buat logo + box, sama kaya di RegisterScreen
              // (24 kiri-kanan, 16 atas). Padding bawah keyboard SEKARANG
              // dipindah ke dalam box (lihat _buildFormCard) karena box-
              // nya sendiri yang scroll, bukan halaman ini.
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildLogo(),
                  const SizedBox(height: 26),

                  // Box form-nya dibungkus Expanded -- SAMA PERSIS
                  // dengan RegisterScreen: TINGGINYA NGIKUTIN SISA
                  // RUANG LAYAR (fit ke bawah), bukan cuma setinggi
                  // konten form-nya. Kalau field-nya kepanjangan dan
                  // nggak muat, yang scroll cuma ISI DI DALAM box
                  // (lihat SingleChildScrollView di _buildFormCard) --
                  // box-nya sendiri diam nggak ikut ke-scroll/kegeser.
                  Expanded(child: _buildFormCard()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGO + TAGLINE
  // ============================================================

  Widget _buildLogo() {
    // Logo SAMA PERSIS dengan yang dipakai SplashScreen --
    // assets/images/smarttrip_logo.png (sudah termasuk ikon pin +
    // wordmark "SMART TRIP AI" + tagline jadi satu gambar), bukan
    // lagi dirakit manual dari Icon/Text seperti draf sebelumnya.
    //
    // Siger-nya sekarang ditaruh terpisah di Stack utama (lihat
    // build()) supaya bisa selebar 1 layar penuh -- di sini logo aja,
    // otomatis tergambar DI ATAS siger karena urutannya belakangan.
    return Image.asset(
      'assets/images/smarttrip_logo.png',
      width: 240,
      fit: BoxFit.contain,
    );
  }

  // ============================================================
  // FORM CARD
  // ============================================================

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // clipBehavior WAJIB diisi -- box-nya sendiri ukurannya FIT/tetap
      // (ngikutin Expanded di build()), sedangkan isinya dibungkus
      // SingleChildScrollView di bawah supaya kalau form kepanjangan,
      // yang scroll cuma konten di dalam box ini aja (dan clip di sini
      // motong konten pas discroll biar nggak nembus lengkungan sudut
      // box pas scroll).
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        // Padding bawah ditambah viewInsets.bottom (tinggi keyboard)
        // secara manual -- soalnya resizeToAvoidBottomInset udah
        // dimatikan di Scaffold, jadi nggak otomatis ngasih ruang buat
        // keyboard lagi. Tanpa ini, field yang lagi difokus bisa
        // ketutupan keyboard.
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            'Selamat datang!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Masuk untuk melanjutkan perjalananmu!',
            style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.3),
          ),

          const SizedBox(height: 24),

          _buildTextField(
            controller: _identifierController,
            focusNode: _identifierFocus,
            hint: 'Email atau nomor telepon',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),

          const SizedBox(height: 16),

          _buildPasswordField(),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  // TODO: navigasi ke halaman Lupa Kata Sandi
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    'Lupa kata sandi?',
                    style: TextStyle(fontSize: 12.5, color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                // Sementara langsung lanjut ke halaman utama supaya
                // alur splash -> login -> app bisa langsung dicoba.
                // Nanti diganti validasi input + panggil API auth
                // dulu sebelum pindah halaman.
                //
                // settings: RouteSettings(name: '/main') dipasang di sini
                // supaya layar lain (mis. ItineraryPreviewScreen) bisa
                // popUntil ke route INI secara eksplisit lewat namanya --
                // bukan cuma nebak "yang paling bawah stack pasti Main"
                // (route.isFirst), yang gampang meleset kalau ada layar
                // lain yang kebetulan nangkring di bawah Main.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainNavigationScreen(),
                    settings: const RouteSettings(name: '/main'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'Masuk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: Divider(color: AppColors.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Atau masuk dengan',
                  style: TextStyle(fontSize: 12, color: AppColors.greyText),
                ),
              ),
              Expanded(child: Divider(color: AppColors.borderColor)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSocialButton(
                  label: 'Google',
                  icon: _buildGoogleLogo(),
                  onTap: () {
                    // TODO: login dengan Google
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  label: 'Facebook',
                  icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 20),
                  onTap: () {
                    // TODO: login dengan Facebook
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                children: [
                  const TextSpan(text: 'Belum punya akun? '),
                  TextSpan(
                    text: 'Daftar Sekarang',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ============================================================
  // INPUT FIELD (dipakai bareng buat email/telepon & kata sandi)
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffixIcon,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isFocused ? AppColors.lightBlue.withValues(alpha: 0.35) : Colors.white,
        border: Border.all(
          color: isFocused ? AppColors.primaryBlue : AppColors.borderColor,
          width: isFocused ? 1.4 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFocused ? AppColors.primaryBlue : AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isFocused ? Colors.white : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              cursorColor: AppColors.primaryBlue,
              style: const TextStyle(fontSize: 14, color: AppColors.darkText),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.greyText),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      hint: 'Kata sandi',
      icon: Icons.lock_outline_rounded,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        splashRadius: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        icon: Icon(
          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 19,
          color: AppColors.greyText,
        ),
      ),
    );
  }

  // ============================================================
  // GOOGLE "G" LOGO (resmi, 4 warna -- digambar langsung dari SVG,
  // ga butuh file asset gambar)
  // ============================================================

  Widget _buildGoogleLogo({double size = 18}) {
    return SvgPicture.string(
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
  <path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844c-.209 1.125-.843 2.078-1.796 2.717v2.259h2.908c1.702-1.567 2.684-3.874 2.684-6.617z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332C2.438 15.983 5.482 18 9 18z"/>
  <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.282-1.117-.282-1.71s.102-1.17.282-1.71V4.958H.957C.348 6.173 0 7.548 0 9s.348 2.827.957 4.042l3.007-2.332z"/>
  <path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0 5.482 0 2.438 2.017.957 4.958L3.964 6.68C4.672 4.553 6.656 3.58 9 3.58z"/>
</svg>
''',
      width: size,
      height: size,
    );
  }

  // ============================================================
  // SOCIAL LOGIN BUTTON
  // ============================================================

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.borderColor),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkText),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// WAVE CLIPPER (dekorasi biru di dasar layar)
// ================================================================

class _WaveClipper extends CustomClipper<Path> {
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
    path.lineTo(size.width, size.height);

    // Sisi kiri bawah
    path.lineTo(0, size.height);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}