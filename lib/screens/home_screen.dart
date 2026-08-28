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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load fresh dashboard data, user profile & notifications from Laravel API Server
    ProfileService.instance.fetchProfile();
    DestinationService.instance.fetchDashboardData();
    NotificationService.instance.fetchNotifications();
  }


  Future<void> _onRefresh() async {
    await Future.wait([
      ProfileService.instance.fetchProfile(),
      DestinationService.instance.fetchDashboardData(),
      NotificationService.instance.fetchNotifications(),
    ]);
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
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
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
                      'Halo, ${profileData.name.isNotEmpty ? profileData.name : "Traveler"}',
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
              ValueListenableBuilder<int>(
                valueListenable: NotificationService.instance.unreadCount,
                builder: (context, unreadCount, _) {
                  return GestureDetector(
                    onTap: () {
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
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 48,
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
            hintText: 'Cari destinasi wisata...',
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
  // RECOMMENDATION SECTION (SERVER DRIVEN)
  // ============================================================

  Widget _buildRecommendationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    height: 208,
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
                  height: 208,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 25, right: 20),
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
        width: 208,
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
            Stack(
              children: [
                SizedBox(
                  height: 111,
                  width: double.infinity,
                  child: buildSmartImage(
                    destination.mainImage,
                    width: double.infinity,
                    height: 111,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: LoveButton(destinationId: destination.id, size: 30),
                ),
              ],
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
                      fontSize: 15,
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
                          style: const TextStyle(fontSize: 11, color: AppColors.greyText),
                        ),
                      ),
                      const SizedBox(width: 6),
                      CategoryBadge(category: destination.category, compact: true),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.darkBlue, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        '${destination.rating.toStringAsFixed(1)} (${destination.reviewsCount} ulasan)',
                        style: const TextStyle(fontSize: 10, color: AppColors.greyText),
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
      padding: const EdgeInsets.symmetric(horizontal: 25),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinationScreen(
              name: item.name,
              location: item.location,
              rating: '4.8',
              reviews: '100 ulasan',
              mainImage: item.mainImage ?? 'assets/images/pulau_pahawang.jpg',
              description: item.recommendation,
              destinationId: item.destinationId,
            ),
          ),
        );
      },
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.borderColor),
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
            SizedBox(
              width: 80,
              height: double.infinity,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: buildSmartImage(
                      item.mainImage,
                      width: 80,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: LoveButton(destinationId: item.destinationId, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
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
                          item.location,
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
                    color: statusBg,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 7),
                      const SizedBox(width: 4),
                      Text(
                        item.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.time,
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