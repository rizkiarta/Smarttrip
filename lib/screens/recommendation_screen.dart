import 'package:flutter/material.dart';
import '../services/destination_service.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';
import '../widgets/smart_image.dart';
import 'detail_destination_screen.dart';

enum _SortOption { relevansi, ratingTertinggi, namaAZ }

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.ratingTertinggi;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    // Ensure dashboard data is loaded
    if (DestinationService.instance.destinations.value.isEmpty) {
      DestinationService.instance.fetchDashboardData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await DestinationService.instance.fetchDashboardData(
      selectedCategory: _selectedCategory,
      searchQuery: _searchQuery,
    );
  }

  List<DestinationModel> _getFilteredDestinations(List<DestinationModel> rawList) {
    final query = _searchQuery.toLowerCase().trim();

    final filtered = rawList.where((dest) {
      final matchesQuery = query.isEmpty ||
          dest.name.toLowerCase().contains(query) ||
          dest.location.toLowerCase().contains(query) ||
          dest.category.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'Semua' ||
          dest.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case _SortOption.ratingTertinggi:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _SortOption.namaAZ:
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _SortOption.relevansi:
        break;
    }

    return filtered;
  }

  String get _sortLabel {
    switch (_sortOption) {
      case _SortOption.ratingTertinggi:
        return 'Rating';
      case _SortOption.namaAZ:
        return 'A-Z';
      case _SortOption.relevansi:
        return 'Relevansi';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Urutkan Rekomendasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSortTile('Rating Tertinggi', _SortOption.ratingTertinggi),
                _buildSortTile('Nama (A-Z)', _SortOption.namaAZ),
                _buildSortTile('Relevansi', _SortOption.relevansi),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String label, _SortOption option) {
    final selected = _sortOption == option;
    return ListTile(
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(context);
      },
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.primaryBlue : AppColors.darkText,
        ),
      ),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primaryBlue, size: 18) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // HEADER & SEARCH BAR
            // ====================================================
            _buildHeader(context),

            // ====================================================
            // CATEGORY FILTER BAR
            // ====================================================
            _buildCategoryFilter(),

            const SizedBox(height: 10),

            // ====================================================
            // SUB-HEADER (COUNT + SORT)
            // ====================================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  ValueListenableBuilder<List<DestinationModel>>(
                    valueListenable: DestinationService.instance.destinations,
                    builder: (context, rawList, _) {
                      final count = _getFilteredDestinations(rawList).length;
                      return Text(
                        '$count destinasi direkomendasikan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.greyText,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3E3E3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: AppColors.primaryBlue, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _sortLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.darkText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ====================================================
            // DYNAMIC CONTENT (REAL SERVER DATA)
            // ====================================================
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.primaryBlue,
                child: ValueListenableBuilder<bool>(
                  valueListenable: DestinationService.instance.isLoading,
                  builder: (context, isLoading, _) {
                    return ValueListenableBuilder<List<DestinationModel>>(
                      valueListenable: DestinationService.instance.destinations,
                      builder: (context, rawList, _) {
                        final items = _getFilteredDestinations(rawList);

                        if (isLoading && items.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(color: AppColors.primaryBlue),
                          );
                        }

                        if (items.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F4FA),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.search_off_rounded,
                                        color: AppColors.primaryBlue,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tidak ada destinasi ditemukan',
                                      style: TextStyle(
                                        color: AppColors.darkText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Coba gunakan kata kunci pencarian lain',
                                      style: TextStyle(
                                        color: AppColors.greyText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildRecommendationCard(context, items[index]);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER WITH BACK BUTTON & SEARCH INPUT
  // ============================================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderColorLight),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: Color(0xFF555555),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Search Field
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE7E7E7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Cari rekomendasi destinasi...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      style: const TextStyle(color: AppColors.darkText, fontSize: 14),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, color: Colors.grey, size: 18),
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
  // CATEGORY FILTER HORIZONTAL CHIPS
  // ============================================================
  Widget _buildCategoryFilter() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: DestinationService.instance.categories,
      builder: (context, catList, _) {
        return SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: catList.length,
            itemBuilder: (context, index) {
              final cat = catList[index];
              final selected = _selectedCategory == cat;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : const Color(0xFFF4F6F8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? AppColors.primaryBlue : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                      color: selected ? Colors.white : AppColors.darkText,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // RECOMMENDATION CARD (DYNAMIC FROM DESTINATION MODEL)
  // ============================================================
  Widget _buildRecommendationCard(BuildContext context, DestinationModel destination) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinationScreen(
              destinationId: destination.id,
              name: destination.name,
              location: destination.location,
              rating: destination.rating.toStringAsFixed(1),
              reviews: '${destination.reviewsCount} ulasan',
              mainImage: destination.mainImage ?? 'assets/images/pulau_wayang.jpg',
              galleryImages: destination.gallery,
              description: destination.description,
              latitude: destination.latitude != 0.0 ? destination.latitude : null,
              longitude: destination.longitude != 0.0 ? destination.longitude : null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderColor),
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
            // Image + Love Button
            Stack(
              children: [
                SmartImage(
                  imagePathOrUrl: destination.mainImage ?? 'assets/images/pulau_wayang.jpg',
                  width: double.infinity,
                  height: 175,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: LoveButton(destinationId: destination.id),
                ),
              ],
            ),

            // Info Details
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          destination.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.starGold, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${destination.rating.toStringAsFixed(1)} (${destination.reviewsCount})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),

                  // Location + Category Badge
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryBlue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        destination.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('•', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), // CHANGED - padding menyesuaikan font yang lebih besar
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          destination.category,
                          style: const TextStyle(
                            fontSize: 12, // CHANGED - font terkecil jadi 12
                            color: Color(0xFF1689D5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    destination.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
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