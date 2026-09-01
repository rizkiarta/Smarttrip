import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

import 'home_screen.dart';
import 'plan_screen.dart';
import 'trip_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  // =============================================================
  // NOTIFIER TAB AKTIF (BISA DIUBAH DARI LUAR WIDGET INI)
  // =============================================================
  //
  // _currentIndex di bawah adalah private (punya State), jadi
  // layar lain (mis. ItineraryPreviewScreen saat tombol "Kembali
  // ke Beranda"/"Lihat Itinerary" ditekan) tidak punya cara
  // memberi tahu instance MainNavigationScreen yang SUDAH ADA di
  // navigation stack untuk pindah ke tab tertentu. Navigator.pop/
  // popUntil cuma menampilkan lagi instance lama itu apa adanya --
  // tidak membuat widget baru, jadi _currentIndex tidak ikut
  // ter-reset.
  //
  // Solusinya: expose ValueNotifier statis ini sebagai "pintu
  // masuk" dari luar. Sebelum popUntil ke MainNavigationScreen,
  // caller tinggal set `MainNavigationScreen.selectedTab.value = 0`
  // dan State di bawah yang listen akan ikut pindah tab.
  //
  // Polanya sama seperti SavedItineraryService: ValueNotifier
  // sebagai single source of truth, tidak bergantung pada rantai
  // Navigator.pop(result) yang gampang putus kalau ada
  // popUntil/pushReplacement di tengah jalan.
  //
  // =============================================================

  static final ValueNotifier<int> selectedTab = ValueNotifier<int>(0);

  @override
  State<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState
    extends State<MainNavigationScreen> {

  int _currentIndex = 0;

  // =============================================================
  // INIT / DISPOSE — LISTEN KE selectedTab
  // =============================================================

  @override
  void initState() {
    super.initState();
    MainNavigationScreen.selectedTab.addListener(_onExternalTabChange);
  }

  @override
  void dispose() {
    MainNavigationScreen.selectedTab.removeListener(_onExternalTabChange);
    super.dispose();
  }

  // Dipanggil kalau ada layar LAIN yang mengubah
  // MainNavigationScreen.selectedTab.value (mis. saat "Kembali ke
  // Beranda" ditekan dari ItineraryPreviewScreen).
  void _onExternalTabChange() {
    final int index = MainNavigationScreen.selectedTab.value;

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });
  }

  // =============================================================
  // HALAMAN UTAMA
  // =============================================================

  // Tab 'Trip' dan 'Riwayat' belum ada layarnya sendiri, jadi untuk
  // sementara diisi _ComingSoonPage supaya tab-nya tetap bisa dibuka
  // (tidak crash) sambil menunggu TripScreen/HistoryScreen dibuat.
  //
  // CATATAN: list ini SENGAJA tidak const -- HomeScreen(),
  // PlanScreen(), dst bukan const constructor (butuh state/listener
  // internal seperti ValueListenableBuilder ke SavedItineraryService,
  // dsb), jadi memaksa 'const [...]' di sini yang bikin analyzer
  // gagal resolve dan malah salah baca 'HomeScreen' sebagai identifier
  // biasa alih-alih constructor widget -- itu sumber kedua error di
  // Problems panel (non_constant_list_element & method HomeScreen
  // isn't defined).
  final List<Widget> _pages = [
    HomeScreen(),
    PlanScreen(),
    TripScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  // =============================================================
  // GANTI HALAMAN
  // =============================================================

  void _changePage(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    // Sinkronkan balik ke notifier statis supaya nilainya tidak
    // pernah "basi" (stale) dibanding tab yang benar-benar aktif
    // di layar. _onExternalTabChange tidak akan memicu setState
    // ganda karena _currentIndex sudah sama dengan index di titik
    // ini.
    MainNavigationScreen.selectedTab.value = index;
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      // =========================================================
      // BOTTOM NAVBAR
      // =========================================================

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 68, 
          padding: const EdgeInsets.symmetric(horizontal: 20), 
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06), // CHANGED: shadow tipis buat kasih batas navbar
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                iconPath: 'assets/icons/home.svg',
                activeIconPath: 'assets/icons/home_filled.svg', // CHANGED: icon versi solid saat aktif
                label: 'Beranda',
              ),

              _buildNavItem(
                index: 1,
                iconPath: 'assets/icons/plan.svg',
                activeIconPath: 'assets/icons/plan_filled.svg', // CHANGED: icon versi solid saat aktif
                label: 'Rencana',
              ),

              _buildNavItem(
                index: 2,
                iconPath: 'assets/icons/trip.svg',
                activeIconPath: 'assets/icons/trip_filled.svg', // CHANGED: icon versi solid saat aktif
                label: 'Trip',
              ),

              _buildNavItem(
                index: 3,
                iconPath: 'assets/icons/riwayat.svg',
                activeIconPath: 'assets/icons/riwayat_filled.svg', // CHANGED: icon versi solid saat aktif
                label: 'Riwayat',
              ),

              _buildNavItem(
                index: 4,
                iconPath: 'assets/icons/profile.svg',
                activeIconPath: 'assets/icons/profile_filled.svg', // CHANGED: icon versi solid saat aktif
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // NAVBAR ITEM
  // =============================================================

  Widget _buildNavItem({
    required int index,
    required String iconPath,
    required String activeIconPath, // CHANGED: path icon versi filled/solid untuk state aktif
    required String label,
  }) {
    final bool isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        onTap: () {
          _changePage(index);
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              isActive ? activeIconPath : iconPath, // CHANGED: pakai versi filled kalau tab ini aktif

              width: 22, // CHANGED: sebelumnya 29 -> diperkecil jadi 22
              height: 22, // CHANGED: sebelumnya 29 -> diperkecil jadi 22

              colorFilter: ColorFilter.mode(
                isActive
                    ? AppColors.primaryBlue
                    : AppColors.darkText,
                BlendMode.srcIn,
              ),
            ),

            const SizedBox(height: 3), // CHANGED: sebelumnya 5 -> diperkecil jadi 3

            Text(
              label,
              style: TextStyle(
                fontSize: 12, 

                fontWeight: isActive
                    ? FontWeight.w600
                    : FontWeight.w500,

                color: isActive
                    ? AppColors.primaryBlue
                    : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}