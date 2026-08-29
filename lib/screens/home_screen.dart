import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'search_screen.dart';
import 'detail_destination_screen.dart';
import 'crowd_prediction_screen.dart';
import 'recommendation_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';
import '../widgets/category_badge.dart';
import '../services/profile_service.dart';
import '../services/destination_service.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller buat search bar -- dibutuhkan supaya tombol "X" (clear)
  // bisa tau kapan ada teks atau tidak, sama seperti di SearchScreen.
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Dashboard data is public, profile/notifications only if logged in (guest mode)
    DestinationService.instance.fetchDashboardData();
    if (ApiService.instance.isAuthenticated) {
      ProfileService.instance.fetchProfile();
      NotificationService.instance.fetchNotifications();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _onRefresh() async {
    final futures = <Future>[
      DestinationService.instance.fetchDashboardData(),
    ];
    if (ApiService.instance.isAuthenticated) {
      futures.addAll([
        ProfileService.instance.fetchProfile(),
        NotificationService.instance.fetchNotifications(),
      ]);
    }
    await Future.wait(futures);
  }



  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primaryBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // BACKGROUND HEADER
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

                // HEADER + SEARCH
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

                // WHITE CONTENT
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
                        padding: const EdgeInsets.only(top: 40, bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRecommendationSection(context),
                            const SizedBox(height: 26),
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
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: ValueListenableBuilder<ProfileData>(
        valueListenable: ProfileService.instance.profile,
        builder: (context, profileData, _) {
          return Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: buildAvatarImage(
                  profileData.photoPath,
                  size: 45,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApiService.instance.isAuthenticated
                          ? 'Halo, ${profileData.name.isNotEmpty ? profileData.name : "Traveler"}'
                          : 'Halo, Traveler',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (!ApiService.instance.isAuthenticated)
                      GestureDetector(
                        onTap: () => showLoginRequiredSheet(context, action: 'masuk ke akunmu'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.5)),
                          ),
                          child: const Text('Masuk / Daftar', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      const Text(
                        'Ayo jelajahi wisata Lampung',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                  ],
                ),
              ),
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.instance.unreadCount,
                builder: (context, unreadCount, _) {
                  return GestureDetector(
                    onTap: () {
                      if (!requireAuth(context, action: 'membuka notifikasi')) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
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
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: const Color(0xFFEFEFEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.greyText,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  final keyword = value.trim();
                  if (keyword.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchScreen(keyword: keyword),
                    ),
                  );
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  hintText: 'Cari destinasi wisata...',
                  hintStyle: TextStyle(color: Colors.black45, fontSize: 14),
                ),
                style: const TextStyle(color: AppColors.darkText, fontSize: 14),
              ),
            ),

            // ==================================================
            // CLEAR KEYWORD -- cuma muncul kalau ada teksnya,
            // sama seperti tombol "X" di SearchScreen.
            // ==================================================

            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox();
                }

                return GestureDetector(
                  onTap: () {
                    _searchController.clear();
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.close,
                      color: AppColors.greyText,
                      size: 18,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECOMMENDATION SECTION (SERVER DRIVEN)
  // ============================================================

  Widget _buildRecommendationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecommendationScreen(),
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
        ValueListenableBuilder<bool>(
          valueListenable: DestinationService.instance.isLoading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<List<DestinationModel>>(
              valueListenable: DestinationService.instance.destinations,
              builder: (context, destinations, _) {
                if (isLoading && destinations.isEmpty) {
                  return const SizedBox(
                    height: 220, // CHANGED - mengikuti tinggi card baru
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.primaryBlue),
                    ),
                  );
                }

                if (destinations.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Belum ada data destinasi dari server.',
                        style: TextStyle(color: AppColors.greyText, fontSize: 12),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 220, // CHANGED - mengikuti tinggi card baru
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 15, right: 15),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final item = destinations[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: _buildHomeRecommendationCard(context, item),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeRecommendationCard(BuildContext context, DestinationModel destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinationScreen(
              name: destination.name,
              location: destination.location,
              rating: destination.rating.toStringAsFixed(1),
              reviews: '${destination.reviewsCount} ulasan',
              mainImage: destination.mainImage ?? 'assets/images/pulau_wayang.jpg',
              galleryImages: destination.gallery,
              description: destination.description,
              destinationId: destination.id,
            ),
          ),
        );
      },
      child: Container(
        width: 140, // CHANGED - card dibuat sedikit lebih kecil
        height: 220, // CHANGED - card dibuat sedikit lebih kecil
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor),
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
            Expanded( // CHANGED - gambar mengisi sisa ruang setelah bagian teks, sesuai tinggi card baru
              child: Stack(
                fit: StackFit.expand, // CHANGED
                children: [
                  buildSmartImage(
                    destination.mainImage,
                    width: double.infinity,
                    height: double.infinity, // CHANGED
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CategoryBadge(category: destination.category, compact: true),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: LoveButton(destinationId: destination.id, size: 26), // CHANGED - mengikuti card yang lebih kecil
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14, // CHANGED - nama destinasi jadi 14
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 17),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          destination.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.greyText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.darkBlue, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${destination.rating.toStringAsFixed(1)} (${destination.reviewsCount} ulasan)',
                        style: const TextStyle(fontSize: 12, color: AppColors.greyText), // CHANGED - font terkecil jadi 12
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
  // CROWD PREDICTION SECTION (SERVER DRIVEN)
  // ============================================================

  Widget _buildCrowdSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CrowdPredictionScreen(),
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
          ValueListenableBuilder<List<CrowdPredictionModel>>(
            valueListenable: DestinationService.instance.crowdPredictions,
            builder: (context, predictions, _) {
              if (predictions.isEmpty) {
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'Belum ada data prediksi kepadatan.',
                      style: TextStyle(color: AppColors.greyText, fontSize: 12),
                    ),
                  ),
                );
              }

              return Column(
                children: predictions.take(5).map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildCrowdCardFromModel(context, item),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrowdCardFromModel(BuildContext context, CrowdPredictionModel item) {
    final isRamai = item.status == 'Ramai';
    final isSedang = item.status == 'Sedang';

    final statusBg = isRamai
        ? AppColors.errorBg
        : (isSedang ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1));
    final statusColor = isRamai
        ? Colors.red
        : (isSedang ? Colors.orange[800]! : Colors.green[800]!);

    final destList = DestinationService.instance.destinations.value;
    DestinationModel? matched;
    try {
      matched = destList.firstWhere((d) => d.id == item.destinationId);
    } catch (_) {}
    final ratingText = matched != null ? matched.rating.toStringAsFixed(1) : '4.8';
    final reviewsText = matched != null ? '${matched.reviewsCount} ulasan' : '100 ulasan';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinationScreen(
              name: item.name,
              location: item.location,
              rating: ratingText,
              reviews: reviewsText,
              mainImage: item.mainImage ?? 'assets/images/pulau_pahawang.jpg',
              galleryImages: matched?.gallery,
              description: matched?.description ?? item.recommendation,
              destinationId: item.destinationId,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
              height: 88, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: buildSmartImage(
                      item.mainImage,
                      width: 88,
                      height: 88,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: LoveButton(destinationId: item.destinationId, size: 24), // CHANGED - sedikit lebih besar mengikuti gambar
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // CHANGED - menyesuaikan font yang lebih besar
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 12, // CHANGED - font terkecil jadi 12
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.greyText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.grey, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Jam Ramai: ${item.time}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.darkBlue, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '$ratingText ($reviewsText)',
                        style: const TextStyle(fontSize: 12, color: AppColors.greyText), // CHANGED - font terkecil jadi 12
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
}

Widget buildSmartImage(String? url, {required double width, required double height, BoxFit fit = BoxFit.cover}) {
  if (url == null || url.isEmpty) {
    return Container(
      width: width,
      height: height,
      color: AppColors.imagePlaceholderBg,
      child: const Icon(Icons.image_outlined, color: AppColors.primaryBlue, size: 30),
    );
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: AppColors.imagePlaceholderBg,
          child: const Icon(Icons.image_outlined, color: AppColors.primaryBlue, size: 30),
        );
      },
    );
  }

  return Image.asset(
    url,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return Container(
        width: width,
        height: height,
        color: AppColors.imagePlaceholderBg,
        child: const Icon(Icons.image_outlined, color: AppColors.primaryBlue, size: 30),
      );
    },
  );
}