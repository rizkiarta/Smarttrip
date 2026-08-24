import 'package:flutter/material.dart';
import 'detail_destination_screen.dart';
import '../data/destinations_data.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';


class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // HEADER
            // ====================================================

            _buildHeader(context),

            // ====================================================
            // CONTENT
            // ====================================================

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(
                  25,
                  5,
                  25,
                  30,
                ),

                children: [


                  const SizedBox(height: 6),

                  const Text(
                    'Rekomendasi yang cocok untuk perjalananmu',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.greyText,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Destinasi yang ditonjolkan di layar ini, direferensikan
                  // lewat 'id' (bukan 'name') supaya cara mengambil data ini
                  // sudah sama seperti nanti manggil backend (GET
                  // /destinations/{id}), bukan ikut berubah kalau nama
                  // destinasinya di-rename.
                  for (final id in const [
                    'pulau_wayang',
                    'air_terjun_curup',
                    'pulau_pahawang',
                    'danau_ranau',
                  ])
                    _buildRecommendationCardFromData(
                      context: context,
                      id: id,
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
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        10,
      ),

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
                    border: Border.all(
                      color:  AppColors.borderColorLight,
                    ),
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
              'Rekomendasi Destinasi',
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
  // RECOMMENDATION CARD (dari kDestinationsData)
  // ============================================================

  Widget _buildRecommendationCardFromData({
    required BuildContext context,
    required String id,
  }) {
    final destination = findDestinationById(id);

    if (destination == null) {
      // Sengaja ditampilkan jelas alih-alih disembunyikan, supaya id yang
      // tidak/belum ada di kDestinationsData langsung terlihat saat
      // testing, bukan hilang begitu saja.
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          'Destinasi dengan id "$id" tidak ditemukan',
          style: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildRecommendationCard(
        context: context,
        id: id,
        imageUrl: destination['image']!,
        title: destination['name']!,
        location: destination['location']!,
        category: destination['category']!,
        rating: destination['rating']!,
        reviews: destination['reviews']!,
        description: destination['description']!,
        mainImage: destination['image']!,
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION CARD
  // ============================================================

  Widget _buildRecommendationCard({
    required BuildContext context,
    required String id,
    required String imageUrl,
    required String title,
    required String location,
    required String category,
    required String rating,
    required String reviews,
    required String description,
    required String mainImage,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,

          MaterialPageRoute(
            builder: (context) {
              return DetailDestinationScreen(
                name: title,
                location: location,
                rating: rating,
                reviews: reviews,
                mainImage: mainImage,
                galleryImages: kDestinationGalleryImages[id],
                description: description,
              );
            },
          ),
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

          border: Border.all(
            color:  AppColors.borderColor,
          ),

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
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE + LOVE BUTTON
            // ==================================================

            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 175,

                  child: Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return Container(
                        color:  AppColors.imagePlaceholderBg,

                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.primaryBlue,
                          size: 45,
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: LoveButton(destinationId: id),
                ),
              ],
            ),

            // ==================================================
            // INFORMATION
            // ==================================================

            Padding(
              padding: const EdgeInsets.all(15),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  // TITLE + RATING

                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Expanded(
                        child: Text(
                          title,

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.darkBlue,
                        size: 16,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        '$rating ($reviews)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // LOCATION

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: AppColors.primaryBlue,
                        size: 17,
                      ),

                      const SizedBox(width: 4),

                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
                        ),
                      ),

                      const SizedBox(width: 6),

                      const Text(
                        '•',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(width: 6),

                      // CATEGORY

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color:
                               AppColors.categoryBadgeBg,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),

                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF2486C5),
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),


                  // DESCRIPTION

                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: AppColors.greyText,
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
}