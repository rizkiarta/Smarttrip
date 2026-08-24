import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search_screen.dart';
import 'detail_destination_screen.dart';
import 'crowd_prediction_screen.dart';
import 'recommendation_screen.dart';
import 'notification_screen.dart';
import '../data/destinations_data.dart';
import 'profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';
import '../widgets/category_badge.dart';
import '../services/profile_service.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        // Status bar
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,

        // Android navigation bar
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
      ),

      child: Scaffold(
        backgroundColor: Colors.white,

        // ========================================================
        // BODY
        // ========================================================
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),

          child: Stack(
            clipBehavior: Clip.none,

            children: [
              // ==================================================
              // BACKGROUND HEADER
              // ==================================================

              Container(
                height: 425,
                width: double.infinity,

                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background_header.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // ==================================================
              // HEADER + SEARCH
              // ==================================================
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    _buildHeader(context),

                    const SizedBox(height: 22),

                    _buildSearchBar(context),
                  ],
                ),
              ),

              // ==================================================
              // WHITE CONTENT
              //
              // Tidak diubah
              // ==================================================
              Column(
                children: [
                  const SizedBox(height: 255),

                  Container(
                    width: double.infinity,

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(42),
                        topRight: Radius.circular(42),
                      ),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 10),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ======================================
                          // REKOMENDASI
                          // ======================================

                          _buildRecommendationSection(context),

                          const SizedBox(height: 26),

                          // ======================================
                          // PREDIKSI KEPADATAN
                          // ======================================
                          _buildCrowdSection(context),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),

      // Dibungkus ValueListenableBuilder ke ProfileService supaya foto
      // & nama di sini SELALU sinkron dengan ProfileScreen/
      // EditProfileScreen (profile_screen.dart) -- sebelumnya di sini
      // masih avatar & nama hardcode ('Haerin' + URL pravatar tetap),
      // jadi kalau user ganti foto/nama di Edit Profil, Beranda tidak
      // ikut berubah.
      child: ValueListenableBuilder<ProfileData>(
        valueListenable: ProfileService.instance.profile,
        builder: (context, profileData, _) {
          return Row(
            children: [
              // --------------------------------------------------
              // PROFILE IMAGE
              // --------------------------------------------------

              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),

                child: buildAvatarImage(
                  profileData.photoPath ?? ProfileService.defaultAvatarUrl,
                  size: 45,
                ),
              ),

              const SizedBox(width: 12),

              // --------------------------------------------------
              // GREETING
              // --------------------------------------------------
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Halo, ${profileData.name}',

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Ayo jelajahi wisata Lampung',

                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // --------------------------------------------------
              // NOTIFICATION
              // --------------------------------------------------
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const NotificationScreen();
                      },
                    ),
                  );
                },

                child: Container(
                  width: 45,
                  height: 45,

                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.notifications,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),

      child: Container(
        height: 38,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(25),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: TextField(
          // ======================================================
          // SEARCH INPUT
          // ======================================================

          textInputAction: TextInputAction.search,

          // ======================================================
          // SAAT USER MENEKAN SEARCH DI KEYBOARD
          // ======================================================
          onSubmitted: (value) {
            final keyword = value.trim();

            // Jangan pindah kalau kosong
            if (keyword.isEmpty) {
              return;
            }

            // Pindah ke halaman hasil pencarian
            Navigator.push(
              context,

              MaterialPageRoute(
                builder: (context) {
                  return SearchScreen(keyword: keyword);
                },
              ),
            );
          },

          // ======================================================
          // TAMPILAN SEARCH BAR
          // ======================================================
          decoration: const InputDecoration(
            border: InputBorder.none,

            hintText: 'Cari',

            hintStyle: TextStyle(color: Colors.black54, fontSize: 13),

            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 21),

            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),

          style: const TextStyle(color: Colors.black, fontSize: 13),
        ),
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION SECTION
  // ============================================================

  Widget _buildRecommendationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // --------------------------------------------------------
        // TITLE
        // --------------------------------------------------------

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Rekomendasi',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              // ==================================================
              // LIHAT SEMUA REKOMENDASI
              // ==================================================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) {
                        return const RecommendationScreen();
                      },
                    ),
                  );
                },

                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',

                      style: TextStyle(fontSize: 12, color: AppColors.greyText),
                    ),

                    SizedBox(width: 4),

                    Icon(Icons.chevron_right, size: 17, color: AppColors.greyText),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // --------------------------------------------------------
        // CARDS
        // --------------------------------------------------------
        SizedBox(
          height: 208,

          child: ListView(
            scrollDirection: Axis.horizontal,

            physics: const BouncingScrollPhysics(),

            padding: const EdgeInsets.only(left: 25, right: 20),

            children: [
              // Direferensikan lewat 'id' (bukan 'name') supaya sudah
              // cocok dengan cara nanti manggil backend (GET
              // /destinations/{id}).
              for (final id in const [
                'pulau_wayang',
                'air_terjun_curup',
              ]) ...[
                _buildHomeRecommendationCard(context, id),
                const SizedBox(width: 14),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // KARTU REKOMENDASI DARI kDestinationsData
  // ============================================================
  //
  // Galeri foto tambahan per destinasi sekarang datang dari
  // kDestinationGalleryImages (destinations_data.dart) supaya
  // satu sumber yang sama dipakai bareng-bareng oleh semua layar
  // (home, rekomendasi, pencarian), bukan didefinisikan ulang
  // di tiap file.

  Widget _buildHomeRecommendationCard(BuildContext context, String id) {
    final destination = findDestinationById(id);

    if (destination == null) {
      // Ditampilkan jelas alih-alih disembunyikan, supaya id yang
      // tidak/belum ada di kDestinationsData langsung terlihat.
      return SizedBox(
        width: 208,
        child: Text(
          'Destinasi dengan id "$id" tidak ditemukan',
          style: const TextStyle(color: Colors.red, fontSize: 11),
        ),
      );
    }

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
                galleryImages: kDestinationGalleryImages[destination['id']],
                description: destination['description']!,
              );
            },
          ),
        );
      },

      child: _buildRecommendationCard(
        id: destination['id']!,
        imageUrl: destination['image']!,
        title: destination['name']!,
        location: destination['location']!,
        category: destination['category']!,
        reviews: '${destination['rating']} (${destination['reviews']})',
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION CARD
  // ============================================================

  Widget _buildRecommendationCard({
    required String id,
    required String imageUrl,
    required String title,
    required String location,
    required String category,
    required String reviews,
  }) {
    return Container(
      width: 208,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color:  AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // IMAGE + LOVE BUTTON
          // ------------------------------------------------------

          Stack(
            children: [
              SizedBox(
                height: 111,
                width: double.infinity,

                child: Image.asset(
                  imageUrl,

                  fit: BoxFit.cover,

                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color:  AppColors.imagePlaceholderBg,

                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.primaryBlue,
                        size: 35,
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: LoveButton(destinationId: id, size: 30),
              ),
            ],
          ),

          // ------------------------------------------------------
          // INFORMATION
          // ------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // TITLE

                Text(
                  title,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // LOCATION + CATEGORY
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 17),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        location,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(fontSize: 11, color: AppColors.greyText),
                      ),
                    ),

                    const SizedBox(width: 6),

                    CategoryBadge(category: category, compact: true),
                  ],
                ),

                const SizedBox(height: 3),

                // RATING
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.darkBlue, size: 15),

                    const Icon(Icons.star, color: AppColors.darkBlue, size: 15),

                    const Icon(Icons.star, color: AppColors.darkBlue, size: 15),

                    const Icon(Icons.star, color: AppColors.darkBlue, size: 15),

                    const Icon(
                      Icons.star_half,
                      color: AppColors.darkBlue,
                      size: 15,
                    ),

                    const SizedBox(width: 5),

                    Expanded(
                      child: Text(
                        reviews,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(fontSize: 10, color: AppColors.greyText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CROWD PREDICTION SECTION
  // ============================================================

  Widget _buildCrowdSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ------------------------------------------------------
          // TITLE
          // ------------------------------------------------------

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Prediksi kepadatan destinasi',

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              // ==================================================
              // LIHAT SEMUA CROWD
              // ==================================================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) {
                        return const CrowdPredictionScreen();
                      },
                    ),
                  );
                },

                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',

                      style: TextStyle(fontSize: 12, color: AppColors.greyText),
                    ),

                    SizedBox(width: 4),

                    Icon(Icons.chevron_right, size: 17, color: AppColors.greyText),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Waktu ramai ('time') murni informasi prediksi kepadatan,
          // bukan bagian dari data destinasi, jadi tetap didefinisikan
          // lokal di sini. Sisanya diambil dari kDestinationsData
          // lewat 'id'.
          for (final entry in const [
            {'id': 'pulau_pahawang', 'time': '09.00 - 15.00'},
            {'id': 'danau_ranau', 'time': '10.00 - 14.00'},
          ]) ...[
            _buildHomeCrowdCard(
              context: context,
              id: entry['id']!,
              time: entry['time']!,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // KARTU KEPADATAN DARI kDestinationsData
  // ============================================================

  Widget _buildHomeCrowdCard({
    required BuildContext context,
    required String id,
    required String time,
  }) {
    final destination = findDestinationById(id);

    if (destination == null) {
      return Text(
        'Destinasi dengan id "$id" tidak ditemukan',
        style: const TextStyle(color: Colors.red, fontSize: 11),
      );
    }

    return _buildCrowdCard(
      id: id,
      imageUrl: destination['image']!,
      title: destination['name']!,
      location: destination['location']!,
      category: destination['category']!,
      time: time,
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
                galleryImages: kDestinationGalleryImages[destination['id']],
                description: destination['description']!,
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // CROWD CARD
  // ============================================================

  Widget _buildCrowdCard({
    required String id,
    required String imageUrl,
    required String title,
    required String location,
    required String category,
    required String time,

    // ==========================================================
    // ACTION SAAT CARD DIKLIK
    // ==========================================================
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 82,

        padding: const EdgeInsets.all(7),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(15),

          border: Border.all(color:  AppColors.borderColor),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            // ------------------------------------------------------
            // IMAGE + LOVE BUTTON
            // ------------------------------------------------------

            SizedBox(
              width: 80,
              height: double.infinity,

              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),

                    child: SizedBox(
                      width: 80,
                      height: double.infinity,

                      child: Image.asset(
                        imageUrl,

                        fit: BoxFit.cover,

                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color:  AppColors.imagePlaceholderBg,

                            child: const Icon(
                              Icons.image_outlined,
                              color: AppColors.primaryBlue,
                              size: 35,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Positioned(
                    top: 4,
                    right: 4,
                    child: LoveButton(destinationId: id, size: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ------------------------------------------------------
            // NAME + LOCATION + CATEGORY
            // ------------------------------------------------------
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryBlue,
                        size: 13,
                      ),

                      const SizedBox(width: 2),

                      Expanded(
                        child: Text(
                          location,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(fontSize: 10, color: AppColors.greyText),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  CategoryBadge(category: category, compact: true),
                ],
              ),
            ),

            // ------------------------------------------------------
            // STATUS + TIME
            // ------------------------------------------------------
            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color:  AppColors.errorBg,

                    borderRadius: BorderRadius.circular(7),
                  ),

                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 7),

                      SizedBox(width: 4),

                      Text(
                        'Ramai',

                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  time,

                  style: const TextStyle(fontSize: 9, color: AppColors.greyText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}