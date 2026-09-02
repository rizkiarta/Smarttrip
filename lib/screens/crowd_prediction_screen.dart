import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/destination_service.dart';
import '../theme/app_colors.dart';
import '../widgets/smart_image.dart';
import '../widgets/love_button.dart';
import 'detail_destination_screen.dart';

class CrowdPredictionScreen extends StatefulWidget {
  const CrowdPredictionScreen({super.key});

  @override
  State<CrowdPredictionScreen> createState() => _CrowdPredictionScreenState();
}

class _CrowdPredictionScreenState extends State<CrowdPredictionScreen> {
  int selectedDateIndex = 0;
  late final List<DateTime> dates;
  List<CrowdPredictionModel> _datePredictions = [];
  bool _isLoadingDate = false;

  @override
  void initState() {
    super.initState();
    dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
    // Initialize date predictions from service if available
    _datePredictions = DestinationService.instance.crowdPredictions.value;
    if (_datePredictions.isEmpty) {
      DestinationService.instance.fetchDashboardData();
    }
  }

  Future<void> _fetchPredictionForDate(DateTime date) async {
    setState(() => _isLoadingDate = true);
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dynamic res = await ApiService.instance.get('crowd-predictions', queryParams: {'date': dateStr});
      if (res is Map && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => CrowdPredictionModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        setState(() {
          _datePredictions = list;
        });
      }
    } catch (e) {
      debugPrint('❌ [CROWD DATE FETCH ERROR] $e');
    } finally {
      setState(() => _isLoadingDate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 18),
            Expanded(
              child: _isLoadingDate
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                  : ValueListenableBuilder<List<CrowdPredictionModel>>(
                      valueListenable: DestinationService.instance.crowdPredictions,
                      builder: (context, globalPredictions, _) {
                        final currentList = selectedDateIndex == 0 && _datePredictions.isEmpty
                            ? globalPredictions
                            : _datePredictions;

                        if (currentList.isEmpty) {
                          return const Center(
                            child: Text(
                              'Belum ada data prediksi kepadatan dari server.',
                              style: TextStyle(color: AppColors.greyText, fontSize: 14),
                            ),
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 25, right: 25, bottom: 30),
                          itemCount: currentList.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = currentList[index];
                            return _buildCrowdCard(context, item);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 25, right: 25, top: 12),
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
                    border: Border.all(color: AppColors.borderColor),
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
              'Prediksi Kepadatan',
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

  Widget _buildDateSelector() {
    return SizedBox(
      height: 65,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 25),
        itemCount: dates.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = dates[index];
          final bool isActive = index == selectedDateIndex;

          return _buildDateItem(
            day: index == 0 ? 'Hari ini' : _dayName(date.weekday),
            date: '${date.day} ${_monthName(date.month)}',
            active: isActive,
            onTap: () {
              setState(() {
                selectedDateIndex = index;
              });
              _fetchPredictionForDate(date);
            },
          );
        },
      ),
    );
  }

  Widget _buildDateItem({
    required String day,
    required String date,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? AppColors.primaryBlue : const Color(0xFFE5E7EB),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white70 : AppColors.greyText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrowdCard(BuildContext context, CrowdPredictionModel item) {
    Color statusColor;
    Color statusBg;
    if (item.status == 'Ramai') {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
    } else if (item.status == 'Sedang') {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
    } else {
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
    }

    final destList = DestinationService.instance.destinations.value;
    DestinationModel? matched;
    try {
      matched = destList.firstWhere((d) => d.id == item.destinationId);
    } catch (_) {}
    final ratingText = matched != null ? matched.rating.toStringAsFixed(1) : '4.5';
    final reviewsText = matched != null ? '${matched.reviewsCount} ulasan' : '100 ulasan';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailDestinationScreen(
              destinationId: item.destinationId,
              name: item.name,
              location: item.location,
              rating: ratingText,
              reviews: reviewsText,
              mainImage: item.mainImage ?? 'assets/images/pulau_wayang.jpg',
              galleryImages: matched?.gallery,
              description: matched?.description ?? item.recommendation,
              latitude: matched != null && matched.latitude != 0.0 ? matched.latitude : null,
              longitude: matched != null && matched.longitude != 0.0 ? matched.longitude : null,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
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
                  SmartImage(
                    imagePathOrUrl: item.mainImage ?? 'assets/images/pulau_wayang.jpg',
                    width: 88,
                    height: 88,
                    borderRadius: BorderRadius.circular(12),
                    fit: BoxFit.cover,
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
                      Text(
                        item.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
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
                      const Icon(Icons.star, color: AppColors.starGold, size: 15),
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

  String _dayName(int weekday) {
    const names = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month - 1];
  }
}