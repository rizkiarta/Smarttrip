import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/destinations_data.dart';
import '../services/api_service.dart';
import '../services/saved_destinations_service.dart';
import '../services/my_reviews_service.dart';
import '../services/profile_service.dart';

import '../services/language_service.dart';
import '../services/notification_settings_service.dart';
import '../services/auth_guard.dart';
import '../widgets/love_button.dart';
import '../widgets/smart_image.dart';

import 'detail_destination_screen.dart';

import 'edit_profile_screen.dart';
import 'splash_screen.dart';
import '../theme/app_colors.dart';

// ================================================================
// PROFILE SCREEN
// ================================================================
//
// Menu utama profil: data diri, akses ke "Destinasi Favorit", dan
// pengaturan (Edit Profil, Bahasa, Notification, Bantuan dan Pusat
// Informasi) -- semuanya sudah mengarah ke layar sungguhan masing-
// masing (lihat import di atas), tidak ada lagi placeholder
// "Segera hadir".
//
// FavoriteDestinationsScreen (di bawah file ini) menampilkan daftar
// destinasi yang sudah di-"love" lewat tombol love di kartu destinasi
// (home, rekomendasi, pencarian, prediksi kepadatan) — datanya dibaca
// dari SavedDestinationsService di destinations_data.dart supaya
// selalu sinkron.
//
// Selain itu, file ini juga jadi tempat ProfileService, ProfileData,
// dan buildAvatarImage() (lihat bagian bawah file) — sumber data
// profil user (nama, bio, foto) yang dipakai bareng oleh
// ProfileScreen, EditProfileScreen (edit_profile_screen.dart), dan
// ReviewScreen (review_screen.dart) saat kirim ulasan baru.
//
// ================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    if (ApiService.instance.isAuthenticated) {
      ProfileService.instance.fetchProfile();
      SavedDestinationsService.instance.fetchFavorites();
      MyReviewsService.instance.fetchMyReviews();
      NotificationSettingsService.instance.fetchSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ApiService.instance.isAuthenticated) {
      return _buildGuestBody(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ==================================================
          // HEADER: BACKGROUND LANGIT + AVATAR + NAME
          // ==================================================
          //
          // Diambil secara dinamis dari ProfileService supaya
          // langsung sinkron begitu user mengubah nama/bio/foto
          // lewat EditProfileScreen. buildAvatarImage() otomatis
          // menangani foto default (network) maupun foto hasil
          // kamera/galeri (file lokal).
          //
          // Background langit pakai foto yang sama dengan header
          // PlanScreen/TripScreen (lihat _buildHeader di bawah).
          // ==================================================

          ValueListenableBuilder<ProfileData>(
            valueListenable: ProfileService.instance.profile,
            builder: (context, profileData, _) {
              return _buildHeader(context, profileData);
            },
          ),

          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
                children: [
                  _sectionTitle('Profil Saya'),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.person_outline,
                    label: 'Edit Profil',
                    destinationBuilder: (context) {
                      return const EditProfileScreen();
                    },
                  ),

                  const SizedBox(height: 22),

                  _sectionTitle('Perjalanan'),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.favorite_border,
                    label: 'Destinasi Favorit',
                    destinationBuilder: (context) {
                      return const FavoriteDestinationsScreen();
                    },
                  ),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.rate_review_outlined,
                    label: 'Ulasan Saya',
                    destinationBuilder: (context) {
                      return const MyReviewsScreen();
                    },
                  ),

                  const SizedBox(height: 22),

                  _sectionTitle('Pengaturan'),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.language,
                    label: 'Bahasa',
                    destinationBuilder: (context) {
                      return const LanguageScreen();
                    },
                  ),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.notifications_none,
                    label: 'Pengaturan Notifikasi',
                    destinationBuilder: (context) {
                      return const NotificationSettingsScreen();
                    },
                  ),
                  const SizedBox(height: 10),
                  _menuItem(
                    context: context,
                    icon: Icons.help_outline,
                    label: 'Bantuan dan Pusat Informasi',
                    destinationBuilder: (context) {
                      return const HelpCenterScreen();
                    },
                  ),

                  const SizedBox(height: 26),

                  // ==============================================
                  // KELUAR
                  // ==============================================

                  GestureDetector(
                    onTap: () {
                      ApiService.instance.setToken(null);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const SplashScreen(),
                        ),
                        (route) => false,
                      );
                    },

                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Keluar',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.logout, color: Colors.red, size: 17),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER (BACKGROUND LANGIT + AVATAR + NAMA/BIO)
  // ============================================================
  //
  // Background langit pakai assets/images/background_header.png,
  // sama seperti header biru di PlanScreen/TripScreen. Kartu putih
  // rounded (radius 42, disamakan juga) menimpa bagian bawahnya,
  // dan avatar diposisikan pas di garis batas keduanya (setengah
  // di atas langit, setengah masuk ke kartu putih).
  // ============================================================

  Widget _buildGuestBody(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 160,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: MediaQuery.of(context).padding.top + 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background_header.png'), fit: BoxFit.cover)),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 0, right: 0,
                  child: Column(
                    children: [
                      Container(width: 96, height: 96, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.person_outline, size: 48, color: AppColors.primaryBlue)),
                      const SizedBox(height: 10),
                      const Text('Kamu belum masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Column(
                children: [
                  const Text('Masuk untuk mengakses profil, favorit, dan ulasanmu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.greyText, height: 1.4)),
                  const SizedBox(height: 18),
                  SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: () => showLoginRequiredSheet(context, action: 'membuka profil'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF7F9FB), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.fieldBorder)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, size: 16, color: AppColors.greyText), SizedBox(width: 8), Expanded(child: Text('Sebagai tamu kamu tetap bisa melihat destinasi, prediksi kepadatan, dan rute.', style: TextStyle(fontSize: 11, color: AppColors.greyText, height: 1.4)))])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _skyHeight = 170;
  static const double _avatarSize = 136;
  // Seberapa jauh titik tengah avatar berada DI ATAS garis batas
  // langit/kartu putih. Semakin kecil, semakin banyak avatar yang
  // "tenggelam" ke kartu putih di bawahnya.
  static const double _avatarCenterAboveCardTop = 30;

  // ============================================================
  // TINGGI KARTU PUTIH -- DISAMAKAN DENGAN PlanScreen/TripScreen
  // ============================================================
  //
  // SENGAJA dipisah dari perhitungan avatar (avatarTop/nameTop di
  // bawah) supaya foto profil TIDAK ikut bergeser -- yang berubah
  // cuma titik mulai kartu putihnya. Angka ini meniru tinggi blok
  // header teks "Rencana"/"Trip" di PlanScreen/TripScreen sebelum
  // kartu putihnya sendiri dimulai (lihat _buildScaffold di
  // plan_screen.dart / trip_screen.dart): padding atas 30 + judul
  // fontSize 28 bold + jarak 5 + subjudul fontSize 12 + jarak 35
  // sebelum kartu putih.
  //
  // Kalau di HP kamu ternyata masih selisih beberapa piksel (beda
  // rendering font Android/iOS), tinggal disesuaikan angka
  // konstanta ini saja -- tidak perlu ubah bagian lain.
  //
  // ============================================================

  static const double _whiteCardTop = 118;

  Widget _buildHeader(BuildContext context, ProfileData profileData) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final double avatarTop =
        _skyHeight - _avatarCenterAboveCardTop - (_avatarSize / 2);
    final double nameTop = _skyHeight +
        (_avatarSize / 2 - _avatarCenterAboveCardTop) +
        16;

    return SizedBox(
      height: statusBarHeight + nameTop + 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ==============================================
          // BACKGROUND LANGIT
          // ==============================================
          //
          // Disamakan dengan header biru di PlanScreen/TripScreen:
          // pakai foto assets/images/background_header.png, bukan
          // gradient buatan, supaya konsisten satu app.
          // ==============================================
          Container(
            height: statusBarHeight + _skyHeight,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_header.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ==============================================
          // KARTU PUTIH (rounded top)
          // ==============================================
          //
          // top-nya pakai _whiteCardTop (SEJAJAR dengan PlanScreen/
          // TripScreen), BUKAN lagi dari posisi avatar seperti
          // sebelumnya -- avatar di bawah tetap di posisi yang
          // sama persis, cuma jadi "tenggelam" sedikit lebih
          // banyak/sedikit ke kartu putih dibanding sebelumnya.
          //
          // ==============================================
          Positioned(
            top: statusBarHeight + _whiteCardTop,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(42),
                  topRight: Radius.circular(42),
                ),
              ),
            ),
          ),

          // ==============================================
          // AVATAR
          // ==============================================
          Positioned(
            top: statusBarHeight + avatarTop,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: buildAvatarImage(
                  profileData.photoPath,
                  size: _avatarSize - 8,
                ),

              ),
            ),
          ),

          // ==============================================
          // NAMA + BIO
          // ==============================================
          Positioned(
            top: statusBarHeight + nameTop,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  profileData.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profileData.bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _menuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required WidgetBuilder destinationBuilder,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: destinationBuilder),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color:  AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.imagePlaceholderBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 18),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12.5, color: AppColors.darkText),
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.greyText, size: 20),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// FAVORITE DESTINATIONS SCREEN
// ================================================================

class FavoriteDestinationsScreen extends StatefulWidget {
  const FavoriteDestinationsScreen({super.key});

  @override
  State<FavoriteDestinationsScreen> createState() => _FavoriteDestinationsScreenState();
}

class _FavoriteDestinationsScreenState extends State<FavoriteDestinationsScreen> {
  @override
  void initState() {
    super.initState();
    SavedDestinationsService.instance.fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: SavedDestinationsService.instance.savedIds,
          builder: (context, savedIds, _) {
            final savedDestinations =
                SavedDestinationsService.instance.savedDestinations;

            return Column(
              children: [
                _buildHeader(context),

                const SizedBox(height: 8),

                Expanded(
                  child: savedDestinations.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                          itemCount: savedDestinations.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 16);
                          },
                          itemBuilder: (context, index) {
                            return _buildFavoriteCard(
                              context,
                              savedDestinations[index],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),

            const Text(
              'Destinasi Favorit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FAVORITE CARD
  // ============================================================

  Widget _buildFavoriteCard(
    BuildContext context,
    Map<String, String> destination,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DetailDestinationScreen(
                name: destination['name']!,
                location: destination['location']!,
                rating: destination['rating']!,
                reviews: destination['reviews']!,
                mainImage: destination['image']!,
                description: destination['description']!,
              );
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color:  AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // IMAGE + LOVE BUTTON
            // ==================================================

            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: SmartImage(
                    imagePathOrUrl: destination['image']!,
                    fit: BoxFit.cover,
                  ),
                ),


                Positioned(
                  top: 10,
                  right: 10,
                  child: LoveButton(destinationId: destination['id']!),
                ),
              ],
            ),

            // ==================================================
            // INFO
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination['name']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryBlue,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destination['location']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      ..._buildStars(destination['rating']!),
                      const SizedBox(width: 5),
                      Text(
                        '${destination['rating']} (${destination['reviews']})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STAR RATING ICONS
  // ============================================================

  List<Widget> _buildStars(String ratingText) {
    final double rating = double.tryParse(ratingText) ?? 0;
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return List.generate(5, (index) {
      IconData icon;

      if (index < fullStars) {
        icon = Icons.star;
      } else if (index == fullStars && hasHalfStar) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }

      return Icon(icon, color:  AppColors.darkBlue, size: 15);
    });
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color:  AppColors.imagePlaceholderBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.favorite_border,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Belum ada destinasi favorit',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Tap ikon hati di kartu destinasi untuk menyimpannya di sini',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.greyText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// MY REVIEWS SCREEN ("Ulasan Saya")
// ================================================================
//
// Menampilkan semua ulasan yang pernah ditulis user sendiri, lintas
// destinasi (ditulis lewat "Kirim Ulasan" di review_screen.dart).
// Datanya dibaca dari MyReviewsService supaya selalu sinkron begitu
// ada ulasan baru. Tap kartu ulasan mengarah ke detail destinasi
// terkait kalau datanya masih ada di kDestinationsData.
// ================================================================

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    MyReviewsService.instance.fetchMyReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ValueListenableBuilder<List<MyReviewEntry>>(
          valueListenable: MyReviewsService.instance.reviews,
          builder: (context, myReviews, _) {
            return Column(
              children: [
                _buildHeader(context),

                const SizedBox(height: 8),

                Expanded(
                  child: myReviews.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          itemCount: myReviews.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 14);
                          },
                          itemBuilder: (context, index) {
                            return _buildReviewCard(context, myReviews[index]);
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),

            const Text(
              'Ulasan Saya',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  Widget _buildReviewCard(BuildContext context, MyReviewEntry review) {
    final Map<String, String>? destination =
        findDestinationById(review.destinationId);

    return GestureDetector(
      onTap: destination == null
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return DetailDestinationScreen(
                      name: destination['name']!,
                      location: destination['location']!,
                      rating: destination['rating']!,
                      reviews: destination['reviews']!,
                      mainImage: destination['image']!,
                      description: destination['description']!,
                      destinationId: review.destinationId,
                    );
                  },
                ),
              );
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEAEAEA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // DESTINASI
            // ==================================================

            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review.destinationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // USER + RATING
            // ==================================================

            Row(
              children: [
                buildAvatarImage(review.avatar, size: 38),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.name,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(children: _buildStars(review.rating)),
                    ],
                  ),
                ),

                Text(
                  review.time,
                  style: const TextStyle(fontSize: 10, color: AppColors.greyText),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==================================================
            // TEXT
            // ==================================================

            Text(
              review.text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF444444),
              ),
            ),

            // ==================================================
            // PHOTOS (opsional)
            // ==================================================

            if (review.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: List.generate(review.photos.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == review.photos.length - 1 ? 0 : 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 1.3,
                          child: _buildReviewPhoto(review.photos[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RENDER FOTO ULASAN (asset mock, URL network, ATAU file lokal)
  // ============================================================

  Widget _buildReviewPhoto(String path) {
    final Widget fallback = Container(
      color:  AppColors.imagePlaceholderBg,
      child: const Icon(Icons.image_outlined, color: AppColors.primaryBlue, size: 26),
    );

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  List<Widget> _buildStars(double rating) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return List.generate(5, (index) {
      IconData icon;

      if (index < fullStars) {
        icon = Icons.star;
      } else if (index == fullStars && hasHalfStar) {
        icon = Icons.star_half;
      } else {
        icon = Icons.star_border;
      }

      return Icon(icon, color: AppColors.darkBlue, size: 14);
    });
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color:  AppColors.imagePlaceholderBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Belum ada ulasan',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Ulasan yang kamu tulis di destinasi manapun\nakan muncul di sini',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.greyText, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// LANGUAGE SCREEN ("Bahasa")
// ================================================================
//
// Gantiin _ComingSoonScreen yang dulu dipasang di menu 'Bahasa'
// ProfileScreen. Style header/warna disamakan persis dengan
// EditProfileScreen (edit_profile_screen.dart) supaya konsisten
// satu keluarga layar Profil.
//
// LanguageService (di bawah file ini) murni in-memory -- pola sama
// seperti ProfileService di profile_screen.dart -- jadi begitu
// backend/localization system sudah siap, tinggal method di service
// ini yang diisi (mis. simpan ke SharedPreferences + ganti locale
// aplikasi), pemanggil (layar ini) tidak perlu diubah.
//
// CATATAN JUJUR: app ini sekarang semua teksnya hardcoded Bahasa
// Indonesia (belum ada sistem localization/intl beneran), jadi
// milih 'English' di sini BARU menyimpan preferensi user -- belum
// benar-benar menerjemahkan seluruh app. Makanya ada catatan kecil
// di bawah pilihan supaya user tidak salah ekspektasi.
//
// ================================================================

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    'Pilih Bahasa',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ValueListenableBuilder<String>(
                    valueListenable: LanguageService.instance.languageCode,
                    builder: (context, selectedCode, _) {
                      return Column(
                        children: [
                          for (final option in LanguageService.options) ...[
                            _buildLanguageTile(
                              context,
                              option: option,
                              selected: option.code == selectedCode,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // Catatan jujur -- lihat komentar di atas file.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.greyText),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sebagian konten aplikasi masih ditampilkan dalam '
                            'Bahasa Indonesia. Dukungan penuh untuk bahasa '
                            'lain akan menyusul di update berikutnya.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greyText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context, {
    required LanguageOption option,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () {
        LanguageService.instance.select(option.code);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bahasa diubah ke ${option.label}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ?  AppColors.lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.fieldBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.nativeLabel,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.darkText,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.primaryBlue, size: 20)
            else
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBorder, width: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),
            const Text(
              'Bahasa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ================================================================
// NOTIFICATION SETTINGS SCREEN ("Pengaturan Notifikasi")
// ================================================================
//
// Gantiin menu 'Notification' yang sebelumnya langsung membuka
// NotificationScreen (halaman daftar/inbox notifikasi). Menu ini di
// bagian "Pengaturan" seharusnya membuka halaman PENGATURAN
// notifikasi (nyala/mati per jenis notifikasi), bukan inbox-nya --
// inbox-nya sendiri tetap ada, diakses lewat ikon lonceng di
// HomeScreen (lihat home_screen.dart), tidak lewat sini.
//
// NotificationSettingsService (di bawah) murni in-memory, pola sama
// seperti LanguageService di atas -- nanti kalau sudah ada backend/
// push notification system beneran, tinggal method di service ini
// yang diisi (mis. simpan preferensi + daftar/batal topic FCM),
// pemanggil (layar ini) tidak perlu diubah.
//
// ================================================================
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationSettingsService.instance.fetchSettings();
  }

  @override
  Widget build(BuildContext context) {
    final service = NotificationSettingsService.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    'Kelola Notifikasi',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildToggleTile(
                    context,
                    setting: service.crowdAlerts,
                    icon: Icons.groups,
                    title: 'Prediksi Kepadatan',
                    subtitle:
                        'Info saat destinasi favoritmu diprediksi ramai.',
                  ),
                  const SizedBox(height: 10),

                  _buildToggleTile(
                    context,
                    setting: service.recommendationAlerts,
                    icon: Icons.explore_outlined,
                    title: 'Rekomendasi Destinasi',
                    subtitle: 'Info destinasi baru sesuai minat perjalananmu.',
                  ),
                  const SizedBox(height: 10),

                  _buildToggleTile(
                    context,
                    setting: service.itineraryReminders,
                    icon: Icons.route_outlined,
                    title: 'Pengingat Itinerary',
                    subtitle:
                        'Pengingat jadwal & status itinerary yang tersimpan.',
                  ),
                  const SizedBox(height: 10),

                  _buildToggleTile(
                    context,
                    setting: service.promoAlerts,
                    icon: Icons.local_offer_outlined,
                    title: 'Promo dan Info Lainnya',
                    subtitle: 'Info promo dan pembaruan seputar aplikasi.',
                  ),

                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.greyText),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pengaturan ini hanya mengatur jenis notifikasi '
                            'yang kamu terima di dalam aplikasi. Riwayat '
                            'notifikasi tetap bisa dilihat lewat ikon '
                            'lonceng di halaman Beranda.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.greyText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required ValueNotifier<bool> setting,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: setting,
      builder: (context, isOn, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:  AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.greyText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isOn,
                activeColor: AppColors.primaryBlue,
                onChanged: (_) {
                  NotificationSettingsService.instance.toggle(setting);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),
            const Text(
              'Pengaturan Notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// HELP CENTER SCREEN ("Bantuan dan Pusat Informasi")
// ================================================================
//
// Gantiin _ComingSoonScreen yang dulu dipasang di menu ini di
// ProfileScreen. Isinya dua bagian:
// - FAQ (ExpansionTile, bisa dibuka-tutup) seputar fitur-fitur
//   utama app (itinerary, edit profil, destinasi favorit, dst).
// - Kartu "Hubungi Kami" (email & WhatsApp) -- disalin ke clipboard
//   saat di-tap (pola paling sederhana, TIDAK menambah dependency
//   baru seperti url_launcher yang belum ada di pubspec.yaml).
//
// Konten FAQ di bawah masih statis (hardcoded) -- kalau nanti mau
// diambil dari backend/CMS, tinggal ganti _faqItems jadi hasil
// fetch, struktur widget-nya tidak perlu berubah.
//
// ================================================================

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'Bagaimana cara membuat itinerary baru?',
      answer:
          'Buka tab Rencana, tekan tombol "Buat Itinerary", lalu isi data '
          'perjalanan (tanggal, kendaraan, jumlah peserta, dan destinasi). '
          'Kamu bisa menyusun jadwal manual atau memakai bantuan AI.',
    ),
    _FaqItem(
      question: 'Kenapa itinerary saya belum muncul di tab Trip?',
      answer:
          'Tab Trip hanya menampilkan itinerary yang tanggal mulainya '
          'sudah tiba hari ini. Itinerary yang tanggalnya masih di masa '
          'depan tetap bisa dilihat di tab Rencana.',
    ),
    _FaqItem(
      question: 'Apa bedanya menandai hari selesai dengan menghapus itinerary?',
      answer:
          'Menandai hari selesai hanya mencatat progres perjalanan hari '
          'itu -- itinerary tetap tersimpan dan hari berikutnya tetap bisa '
          'berjalan normal. Menghapus itinerary akan menghilangkannya '
          'sepenuhnya dari Rencana, Trip, maupun Riwayat.',
    ),
    _FaqItem(
      question: 'Bagaimana cara mengubah data profil saya?',
      answer:
          'Buka tab Profil, tekan "Edit Profil", lalu ubah nama, username, '
          'tanggal lahir, nomor telepon, email, atau foto profil sesuai '
          'kebutuhan. Tekan "Simpan Perubahan" setelah selesai.',
    ),
    _FaqItem(
      question: 'Di mana saya bisa melihat destinasi yang saya sukai?',
      answer:
          'Tekan ikon hati (love) pada kartu destinasi mana pun untuk '
          'menyimpannya, lalu buka Profil > Destinasi Favorit untuk '
          'melihat semua destinasi yang sudah kamu simpan.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    'Pertanyaan yang Sering Diajukan',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: 	AppColors.borderColor),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionPanelList.radio(
                        elevation: 0,
                        expandedHeaderPadding: EdgeInsets.zero,
                        children: _faqItems.map((item) {
                          return ExpansionPanelRadio(
                            value: item.question,
                            canTapOnHeader: true,
                            backgroundColor: Colors.transparent,
                            headerBuilder: (context, isExpanded) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  item.question,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isExpanded
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              );
                            },
                            body: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                              child: Text(
                                item.answer,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  const Text(
                    'Hubungi Kami',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildContactCard(
                    context: context,
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'support@smarttrip.id',
                  ),
                  const SizedBox(height: 10),
                  _buildContactCard(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    label: 'WhatsApp',
                    value: '+62 812-3456-7890',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label disalin: $value'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: 	AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.imagePlaceholderBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, color: AppColors.greyText),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_outlined, color: AppColors.greyText, size: 17),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),
            const Text(
              'Bantuan dan Pusat Informasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}