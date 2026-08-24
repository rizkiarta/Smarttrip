import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

// ================================================================
// REGISTER SCREEN
// ================================================================
//
// Halaman "Buat akun baru" SmartTrip AI, satu paket sama LoginScreen
// (logo asset yang sama, gaya card/input/tombol yang sama). Field:
// Nama lengkap, Email, Nomor telepon, Kata sandi, Konfirmasi kata
// sandi, checkbox setuju Syarat & Ketentuan + Kebijakan Privasi,
// tombol "Daftar", opsi Google/Facebook, dan link balik ke Masuk.
//
// STATUS: baru TAMPILAN (UI-only). Validasi input (termasuk cek
// kata sandi & konfirmasi cocok, checkbox wajib dicentang) dan
// pemanggilan API register belum diisi -- tinggal disambungkan.
//
// ================================================================

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Tinggi wave dekoratif di dasar layar -- dipakai di DUA tempat (tinggi
  // SizedBox pembungkus ClipPath, dan jatah ruang kosong di akhir Column
  // biar box form berhenti sebelum wave). Satu konstanta ini SUMBER
  // TUNGGAL-nya, biar dua tempat itu ga pernah beda angka lagi.
  static const double _waveHeight = 125;

  // ============================================================
  // FORM STATE
  // ============================================================

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    // edgeToEdge -- wajib di-set biar body app-nya beneran digambar
    // MELEWATI system navigation bar (bukan cuma berhenti di atasnya),
    // sama kaya di LoginScreen, supaya wave-nya nyampe ke ujung fisik
    // layar paling bawah tanpa sisa celah putih.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // VALIDASI + SUBMIT REGISTER
  // ============================================================
  //
  // Validasi ringan di sisi UI dulu (belum panggil API beneran --
  // itu nanti tinggal ganti bagian "TODO: panggil API register" di
  // bawah). Kalau semua valid, tampilkan pesan sukses lalu balik
  // ke LoginScreen supaya user login manual pakai akun barunya.
  //
  // ============================================================

  void _handleRegister() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    final RegExp emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    String? errorMessage;

    if (name.isEmpty) {
      errorMessage = 'Nama lengkap wajib diisi';
    } else if (email.isEmpty) {
      errorMessage = 'Email wajib diisi';
    } else if (!emailRegex.hasMatch(email)) {
      errorMessage = 'Format email tidak valid';
    } else if (phone.isEmpty) {
      errorMessage = 'Nomor telepon wajib diisi';
    } else if (password.isEmpty) {
      errorMessage = 'Kata sandi wajib diisi';
    } else if (password.length < 6) {
      errorMessage = 'Kata sandi minimal 6 karakter';
    } else if (confirmPassword.isEmpty) {
      errorMessage = 'Konfirmasi kata sandi wajib diisi';
    } else if (password != confirmPassword) {
      errorMessage = 'Kata sandi dan konfirmasi tidak cocok';
    } else if (!_agreeToTerms) {
      errorMessage = 'Kamu harus menyetujui Syarat & Ketentuan terlebih dahulu';
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // TODO: panggil API register di sini (name, email, phone, password).
    // Kalau responsnya sukses, baru lanjut ke bagian bawah ini.
    // Kalau gagal (mis. email sudah terdaftar), tampilkan errornya lewat
    // SnackBar seperti di atas dan JANGAN panggil Navigator di bawah.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pendaftaran berhasil! Silakan masuk.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Dulu ini Navigator.pushReplacement(...LoginScreen()) -- bikin
    // LoginScreen BARU ditumpuk di atas, sementara LoginScreen yang lama
    // (tempat awal RegisterScreen ini di-push) tetap nangkring di bawah
    // stack, ga pernah kehapus. Efeknya: begitu user sudah login dan
    // pencet tombol back sistem, dia nyasar balik ke LoginScreen lama itu
    // -- keliatan kaya logout padahal bukan.
    //
    // Fix: cukup pop balik ke LoginScreen yang SUDAH ADA di bawah,
    // ga perlu bikin instance baru.
    Navigator.pop(context);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Biar wave-nya beneran diam fix di bawah layar (kayak di
      // SplashScreen/LoginScreen) dan nggak ikut kegeser ke atas pas
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
              height: _waveHeight,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: Container(color: AppColors.primaryBlue),
              ),
            ),
          ),

          // Siger (assets/images/siger.png) -- SAMA PERSIS dengan
          // LoginScreen: ditaruh langsung sebagai anak Stack utama
          // (bukan di dalam Column yang ke-padding horizontal 24),
          // supaya bisa selebar penuh 1 layar kiri-kanan. Posisinya
          // sejajar sama logo di bawahnya (SafeArea top + jarak 12
          // sebelum logo). IgnorePointer biar nggak nge-block tap ke
          // elemen lain, dan logo/form di SafeArea sesudah ini otomatis
          // digambar DI ATASNYA (urutan children Stack = urutan
          // tumpukan, yang belakangan digambar di depan).
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
              // Padding luar buat logo + box, sama kaya sebelumnya (24
              // kiri-kanan, 16 atas). Padding bawah keyboard SEKARANG
              // dipindah ke dalam box (lihat _buildFormCard) karena box-
              // nya sendiri yang scroll, bukan halaman ini.
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildLogo(),
                  const SizedBox(height: 22),

                  // Box form-nya dibungkus Expanded -- jadi TINGGINYA
                  // NGIKUTIN SISA RUANG LAYAR (fit ke bawah, kaya di
                  // desain), bukan cuma setinggi konten form-nya. Kalau
                  // field-nya kepanjangan dan nggak muat, yang scroll
                  // cuma ISI DI DALAM box (lihat SingleChildScrollView
                  // di _buildFormCard) -- box-nya sendiri diam nggak
                  // ikut ke-scroll/kegeser.
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
  // LOGO
  // ============================================================

  Widget _buildLogo() {
    // Sama persis dengan LoginScreen/SplashScreen --
    // assets/images/smarttrip_logo.png (ikon + wordmark + tagline
    // sudah jadi satu gambar).
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
            'Buat akun baru',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            'Daftar untuk mulai merencanakan perjalananmu!',
            style: TextStyle(fontSize: 12, color: AppColors.greyText),
          ),

          const SizedBox(height: 20),

          _buildTextField(
            controller: _nameController,
            hint: 'Nama lengkap',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _emailController,
            hint: 'Email',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _phoneController,
            hint: 'Nomor telepon',
            icon: Icons.call_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _passwordController,
            hint: 'Kata sandi',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: AppColors.greyText,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Konfirmasi kata sandi',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscureConfirmPassword,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              child: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 19,
                color: AppColors.greyText,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _buildTermsCheckbox(),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                'Daftar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: Divider(color: AppColors.borderColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    // TODO: daftar/login dengan Google
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSocialButton(
                  label: 'Facebook',
                  icon: const Icon(Icons.facebook_rounded, color: Color(0xFF1877F2), size: 20),
                  onTap: () {
                    // TODO: daftar/login dengan Facebook
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                children: [
                  const TextSpan(text: 'Sudah punya akun? '),
                  TextSpan(
                    text: 'Masuk Sekarang',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // Sama seperti fix di _handleRegister: pop balik ke
                        // LoginScreen yang sudah ada di bawah stack, jangan
                        // pushReplacement bikin instance baru (lihat catatan
                        // di atas kenapa itu bikin balik-ke-login "kaya logout").
                        Navigator.pop(context);
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
  // CHECKBOX SYARAT & KETENTUAN
  // ============================================================
  //
  // "Syarat & Ketentuan" dan "Kebijakan Privasi" ditulis sebagai
  // link (warna AppColors.primaryBlue) di dalam satu kalimat -- pakai
  // RichText+TapGestureRecognizer sama seperti link "Masuk
  // Sekarang"/"Daftar Sekarang", supaya masing-masing bisa dipasangi
  // navigasi ke halaman Syarat/Kebijakan-nya sendiri nanti.
  //
  // ============================================================

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            activeColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.borderColor, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4),
                children: [
                  const TextSpan(text: 'Saya setuju dengan '),
                  TextSpan(
                    text: 'Syarat & Ketentuan',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: navigasi/tampilkan halaman Syarat & Ketentuan
                      },
                  ),
                  const TextSpan(text: ' dan '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: navigasi/tampilkan halaman Kebijakan Privasi
                      },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT FIELD (dipakai bareng buat semua field teks)
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.lightBlue, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
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
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.borderColor),
        padding: const EdgeInsets.symmetric(vertical: 12),
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
    );
  }
}

// ================================================================
// WAVE CLIPPER (dekorasi biru di dasar layar -- sama dengan LoginScreen)
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