import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../data/destinations_data.dart';
import 'review_screen.dart';
import 'route_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';
import '../widgets/smart_image.dart';
import '../services/profile_service.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';

class DetailDestinationScreen extends StatefulWidget {
  final String name;
  final String location;
  final String rating;
  final String reviews;
  final String mainImage;
  final String description;
  final double? latitude;
  final double? longitude;

  // Daftar foto tambahan jika destinasi punya lebih dari 1 gambar.
  final List<String>? galleryImages;

  // Dipakai LoveButton & backend API untuk mencatat favorit secara konsisten.
  final String? destinationId;

  const DetailDestinationScreen({
    super.key,
    required this.name,
    required this.location,
    this.rating = '4.8',
    this.reviews = '235 ulasan',
    required this.mainImage,
    required this.description,
    this.latitude,
    this.longitude,
    this.galleryImages,
    this.destinationId,
  });

  @override
  State<DetailDestinationScreen> createState() =>
      _DetailDestinationScreenState();
}

class _DetailDestinationScreenState
    extends State<DetailDestinationScreen> {
  // Pusat Lampung, dipakai jika destinasi belum punya koordinat sendiri.

  static const LatLng _fallbackLocation = LatLng(-5.3971, 105.2668);

  // CROWD PREDICTION DATA (per hari)

  static const List<String> _dayOptions = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _timeLabels = [
    '06.00',
    '08.00',
    '10.00',
    '12.00',
    '14.00',
    '16.00',
    '18.00',
  ];

  static const Map<String, List<int>> _crowdData = {
    'Senin': [0, 0, 1, 1, 1, 0, 0],
    'Selasa': [0, 0, 0, 1, 1, 0, 0],
    'Rabu': [0, 1, 2, 2, 1, 1, 0],
    'Kamis': [0, 0, 1, 1, 1, 0, 0],
    'Jumat': [0, 1, 1, 2, 2, 1, 0],
    'Sabtu': [1, 1, 2, 2, 2, 2, 1],
    'Minggu': [0, 0, 1, 2, 2, 1, 0],
  };

  late String _selectedDay = _todayName();

  // Index batang chart yang sedang dipencet (null = tidak ada
  // tooltip yang tampil).
  int? _tappedBarIndex;

  // DateTime.weekday: 1 = Senin ... 7 = Minggu, sama urutannya dengan _dayOptions.

  static String _todayName() {
    final int todayIndex = DateTime.now().weekday - 1;
    return _dayOptions[todayIndex];
  }

  // ROLLING DAY OPTIONS (hari ini selalu di paling kiri)

  List<String> _rollingDayOptions() {
    final int todayIndex = DateTime.now().weekday - 1;
    return List.generate(
      _dayOptions.length,
      (i) => _dayOptions[(todayIndex + i) % _dayOptions.length],
    );
  }

  // State dynamic dari Laravel Backend DB
  String? _openHour;
  String? _closeHour;
  String? _priceRange;
  String? _dbDescription;
  List<String> _galleryImages = [];
  List<Map<String, dynamic>> _dbReviews = [];
  Map<String, dynamic>? _crowdPredictionData;

  // Prioritas: destinationId dari pemanggil -> cari via findDestinationByName -> fallback ke nama.
  late final String _destinationId =
      widget.destinationId ??
      findDestinationByName(widget.name)?['id'] ??
      widget.name;

  @override
  void initState() {
    super.initState();
    _fetchDestinationBackendDetails();
    _fetchDestinationReviews();
  }

  Future<void> _fetchDestinationBackendDetails() async {
    try {
      final String safeId = Uri.encodeComponent(_destinationId);
      final res = await ApiService.instance.get('destinations/$safeId');
      if (res['data'] != null && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        if (mounted) {
          setState(() {
            _openHour = data['open_hour']?.toString();
            _closeHour = data['close_hour']?.toString();
            _priceRange = data['price_range']?.toString();
            _dbDescription = data['description']?.toString();
            if (data['gallery'] is List) {
              _galleryImages = (data['gallery'] as List).map((e) => e.toString()).toList();
            }
          });
        }
      }

      final crowdRes = await ApiService.instance.get('destinations/$safeId/crowd-prediction');
      if (crowdRes['data'] != null && crowdRes['data'] is Map) {
        if (mounted) {
          setState(() {
            _crowdPredictionData = Map<String, dynamic>.from(crowdRes['data'] as Map);
          });
        }
      }
    } catch (e) {
      debugPrint('Fetch destination details error: $e');
    }
  }

  // Ambil ulasan dari endpoint khusus (sama seperti ReviewScreen) agar
  // data likes/liked konsisten dan tombol like berfungsi dengan benar.
  Future<void> _fetchDestinationReviews() async {
    try {
      final String safeId = Uri.encodeComponent(_destinationId);
      final res = await ApiService.instance.get('destinations/$safeId/reviews');
      if (res['data'] is List) {
        final list = (res['data'] as List).map(_mapReview).toList();
        if (mounted) setState(() => _dbReviews = list);
      }
    } catch (e) {
      debugPrint('Fetch destination reviews error: $e');
    }
  }

  Map<String, dynamic> _mapReview(dynamic r) => {
    'id': r['id'],
    'avatar': r['user_avatar'],
    'name': r['user_name'] ?? 'Pengguna SmartTrip',
    'rating': (r['rating'] as num?)?.toDouble() ?? 5.0,
    'time': r['created_at'] ?? 'Baru saja',
    'text': r['review_text'] ?? '',
    'likes': (r['likes_count'] ?? 0).toString(),
    'liked': r['liked'] == true,
    'photos': r['photos'] is List ? List<String>.from(r['photos']) : <String>[],
  };

  List<int> _getCrowdLevelsForDay(String day) {
    if (_crowdPredictionData != null) {
      final String status = _crowdPredictionData!['status']?.toString() ?? 'Sedang';
      final int peakStart = int.tryParse(_crowdPredictionData!['peak_start']?.toString() ?? '9') ?? 9;
      final int peakEnd = int.tryParse(_crowdPredictionData!['peak_end']?.toString() ?? '15') ?? 15;
      final bool isWeekend = (day == 'Sabtu' || day == 'Minggu');

      final List<int> hours = [6, 8, 10, 12, 14, 16, 18];
      return hours.map((h) {
        if (h >= peakStart && h <= peakEnd) {
          if (status == 'Ramai' || isWeekend) return 2;
          if (status == 'Sedang') return 1;
          return 0;
        }
        if (h == peakStart - 2 || h == peakEnd + 2) {
          return status == 'Ramai' ? 1 : 0;
        }
        return 0;
      }).toList();
    }
    return _crowdData[day] ?? [0, 0, 1, 1, 1, 0, 0];
  }

  // CROWD LEVEL LABEL & COLOR (dipakai untuk tooltip batang)

  String _statusLabelForLevel(int level) {
    switch (level) {
      case 2:
        return 'ramai';
      case 1:
        return 'sedang';
      default:
        return 'sepi';
    }
  }

  Color _colorForCrowdLevel(int level) {
    switch (level) {
      case 2:
        return Colors.red;
      case 1:
        return AppColors.warningYellow;
      default:
        return Colors.green;
    }
  }

  // Teks tooltip untuk batang ke-`index`, contoh:
  // "06.00 - 08.00 diperkirakan sepi"
  String _tooltipTextForBar(int index, List<int> levels) {
    final String status = _statusLabelForLevel(levels[index]);
    final String rangeText = (index < _timeLabels.length - 1)
        ? '${_timeLabels[index]} - ${_timeLabels[index + 1]}'
        : 'Sekitar jam ${_timeLabels[index]}';
    return '$rangeText diperkirakan $status';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // BODY

      body: Stack(
        children: [
          // MAIN SCROLL

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // HERO IMAGE

                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 285,
                      child: SmartImage(
                        imagePathOrUrl: widget.mainImage,
                        fit: BoxFit.cover,
                      ),
                    ),


                    // BACK BUTTON

                    Positioned(
                      top: 50,
                      left: 20,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF555555),
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    // LOVE BUTTON (SIMPAN DESTINASI)

                    Positioned(
                      top: 50,
                      right: 20,
                      child: LoveButton(
                        destinationId: _destinationId,
                        size: 38,
                      ),
                    ),
                  ],
                ),

                // WHITE CONTENT

                Transform.translate(
                  offset: const Offset(0, -45),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(45),
                        topRight: Radius.circular(45),
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 32,
                      bottom: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DESTINATION INFORMATION

                        _buildDestinationHeader(),

                        const SizedBox(height: 20),

                        // DESCRIPTION

                        _buildDescription(),

                        const SizedBox(height: 20),

                        // GALLERY

                        _buildGallery(context),

                        const SizedBox(height: 20),

                        // CROWD PREDICTION

                        _buildCrowdPrediction(),

                        const SizedBox(height: 20),

                        // ROUTE BUTTON

                        _buildRouteButton(context),

                        const SizedBox(height: 20),

                        // REVIEWS

                        _buildReviews(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DESTINATION HEADER

  Widget _buildDestinationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // NAME
              Expanded(
                child: Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              // RATING
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.starGold,
                    size: 18,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    '${widget.rating} (${widget.reviews})',
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

          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 19,
              ),

              const SizedBox(width: 4),

              Text(
                widget.location,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                ),
              ),

              const Spacer(),

              const Text(
                'Tutup',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 5),

              Text(
                '• Buka pukul ${_openHour ?? "08.00"}${_closeHour != null ? " - $_closeHour" : ""}',
                style: const TextStyle(
                  color: AppColors.greyText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // DESCRIPTION

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        (_dbDescription != null && _dbDescription!.isNotEmpty)
            ? _dbDescription!
            : widget.description,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Color(0xFF4F4F4F),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // GALLERY

  Widget _buildGallery(BuildContext context) {
    final List<String> galleryImages = _galleryImages.isNotEmpty
        ? _galleryImages
        : ((widget.galleryImages != null && widget.galleryImages!.isNotEmpty)
            ? widget.galleryImages!
            : [widget.mainImage]);

    return SizedBox(
      height: 75,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: galleryImages.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 12);
        },
        itemBuilder: (context, index) {
          return _buildGalleryImage(
            context,
            galleryImages[index],
            galleryImages,
            index,
          );
        },
      ),
    );
  }

  // GALLERY IMAGE

  Widget _buildGalleryImage(
    BuildContext context,
    String imagePath,
    List<String> galleryImages,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        _showGalleryPreview(
          context,
          galleryImages,
          index,
        );
      },
      child: SmartImage(
        imagePathOrUrl: imagePath,
        width: 130,
        height: 75,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(13),
      ),

    );
  }

  // SHOW GALLERY PREVIEW

  void _showGalleryPreview(
    BuildContext context,
    List<String> galleryImages,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return _GalleryPreview(
          images: galleryImages,
          initialIndex: initialIndex,
        );
      },
    );
  }

  // CROWD PREDICTION

  Widget _buildCrowdPrediction() {
    final List<int> levels = _getCrowdLevelsForDay(_selectedDay);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:  AppColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // TITLE + DROPDOWN

          const Row(
            children: [
              Expanded(
                child: Text(
                  'Prediksi Kepadatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // DAY SELECTOR (SCROLLABLE)

          _buildDaySelector(),

          const SizedBox(height: 16),

          // GRAPH

          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Posisi label jam dihitung dari lebar widget asli, harus selaras dengan konstanta left/right di _CrowdChartPainter.

                const double graphLeft = 85;
                const double graphRight = 5;

                final double graphWidth =
                    constraints.maxWidth - graphLeft - graphRight;

                // Label jam sekarang mengikuti data asli
                // (06.00 - 18.00, 7 titik) supaya posisinya
                // selalu tepat di bawah setiap batang.
                final int barCount = levels.length;
                final double slotWidth =
                    barCount == 0 ? 0 : graphWidth / barCount;

                return CustomPaint(
                  painter: _CrowdChartPainter(
                    levels: levels,
                    pressedIndex: _tappedBarIndex,
                  ),
                  child: Stack(
                    children: [
                      // RAMAI
                      const Positioned(
                        left: 0,
                        top: 22,
                        child: Text(
                          'Ramai',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // SEDANG
                      const Positioned(
                        left: 0,
                        top: 72,
                        child: Text(
                          'Sedang',
                          style: TextStyle(
                            color: AppColors.warningYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // SEPI
                      const Positioned(
                        left: 0,
                        top: 122,
                        child: Text(
                          'Sepi',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // TIMES (satu label persis di bawah tiap
                      // batang, format singkat: 06, 08, 10, ...)
                      for (int i = 0; i < barCount; i++)
                        Positioned(
                          left: graphLeft + slotWidth * i,
                          bottom: 0,
                          width: slotWidth,
                          child: Text(
                            i < _timeLabels.length
                                ? _timeLabels[i].split('.').first
                                : '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      // TAP ZONES: satu per batang, area penuh dari atas sampai bawah grafik

                      for (int i = 0; i < barCount; i++)
                        Positioned(
                          left: graphLeft + slotWidth * i,
                          top: 0,
                          bottom: 0,
                          width: slotWidth,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (_) {
                              setState(() {
                                _tappedBarIndex = i;
                              });
                            },
                            onTapUp: (_) {
                              setState(() {
                                _tappedBarIndex = null;
                              });
                            },
                            onTapCancel: () {
                              setState(() {
                                _tappedBarIndex = null;
                              });
                            },
                          ),
                        ),

                      // TOOLTIP (muncul di atas batang yang dipencet)

                      if (_tappedBarIndex != null &&
                          _tappedBarIndex! < barCount)
                        Positioned(
                          top: 0,
                          left: graphLeft,
                          right: graphRight,
                          child: Align(
                            alignment: Alignment(
                              (((_tappedBarIndex! + 0.5) / barCount) * 2 - 1)
                                  .clamp(-1.0, 1.0),
                              -1,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _colorForCrowdLevel(
                                    levels[_tappedBarIndex!],
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                _tooltipTextForBar(_tappedBarIndex!, levels),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _colorForCrowdLevel(
                                    levels[_tappedBarIndex!],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // RECOMMENDED TIME (di dalam kotak yang sama)

          _buildRecommendedTime(),
        ],
      ),
    );
  }

  // Chip hari yang bisa digeser horizontal, menggantikan dropdown lama.

  Widget _buildDaySelector() {
    final List<String> orderedDays = _rollingDayOptions();
    final String todayName = _todayName();

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: orderedDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final String day = orderedDays[index];
          final bool active = day == _selectedDay;
          final bool isToday = day == todayName;

          return GestureDetector(
            onTap: () {
              if (_selectedDay == day) return;
              setState(() {
                _selectedDay = day;
                _tappedBarIndex = null;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active
                      ? AppColors.primaryBlue
                      : AppColors.borderColor,
                ),
                boxShadow: active
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 5,
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.bold : FontWeight.w600,
                      color: active ? Colors.white : AppColors.greyText,
                    ),
                  ),

                  if (isToday)
                    Text(
                      'Hari ini',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white.withValues(alpha: 0.85)
                            : AppColors.primaryBlue,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // RECOMMENDED TIME

  Widget _buildRecommendedTime() {
    final _CrowdSummary summary =
        _summaryFor(_getCrowdLevelsForDay(_selectedDay));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: summary.containerBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: summary.containerBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.rangeText,
                  style: TextStyle(
                    color: summary.badgeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: summary.badgeBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: summary.badgeColor,
                      size: 7,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      summary.badgeText,
                      style: TextStyle(
                        color: summary.badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            summary.suggestion,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // CROWD SUMMARY (untuk badge + saran waktu, mengikuti hari terpilih)

  _CrowdSummary _summaryFor(List<int> levels) {
    final List<int> ramaiIndices = [];
    final List<int> sedangIndices = [];

    for (int i = 0; i < levels.length; i++) {
      if (levels[i] == 2) ramaiIndices.add(i);
      if (levels[i] == 1) sedangIndices.add(i);
    }

    if (ramaiIndices.isNotEmpty) {
      final String start = _timeLabels[ramaiIndices.first];
      final String end = _timeLabels[ramaiIndices.last];

      return _CrowdSummary(
        rangeText: '$start - $end',
        badgeText: 'Ramai',
        badgeColor: Colors.red,
        badgeBackground: const Color(0xFFFFD7D7),
        containerBackground:  AppColors.errorBg,
        containerBorder: const Color(0xFFF5DCDC),
        suggestion: 'Disarankan datang sebelum $start atau setelah $end',
      );
    }

    if (sedangIndices.isNotEmpty) {
      final String start = _timeLabels[sedangIndices.first];
      final String end = _timeLabels[sedangIndices.last];

      return _CrowdSummary(
        rangeText: '$start - $end',
        badgeText: 'Sedang',
        badgeColor: const Color(0xFFE0A900),
        badgeBackground: const Color(0xFFFFF8DF),
        containerBackground: const Color(0xFFFFFCF2),
        containerBorder: const Color(0xFFF3EACB),
        suggestion:
            'Tidak terlalu padat, tetap nyaman untuk dikunjungi pada rentang ini.',
      );
    }

    return _CrowdSummary(
      rangeText: 'Sepanjang hari',
      badgeText: 'Sepi',
      badgeColor: Colors.green,
      badgeBackground: const Color(0xFFDCF5E3),
      containerBackground: const Color(0xFFF0FBF3),
      containerBorder: const Color(0xFFD3EFDC),
      suggestion: 'Cocok dikunjungi kapan saja, diprediksi sepi sepanjang hari.',
    );
  }

  // ROUTE BUTTON

  Widget _buildRouteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          onPressed: () {
            final LatLng destinationLocation =
                (widget.latitude != null && widget.longitude != null)
                    ? LatLng(widget.latitude!, widget.longitude!)
                    : _fallbackLocation;

            // RouteScreen sekarang menerima daftar stop (dipakai
            // TripScreen untuk rute multi-destinasi hari ini). Di
            // halaman DETAIL SATU destinasi ini, daftarnya cukup
            // berisi 1 stop -- perilakunya sama seperti sebelumnya
            // (rute lokasi user -> destinasi ini saja), cuma lewat
            // API baru.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return RouteScreen(
                    stops: [
                      RouteStop(
                        name: widget.name,
                        coordinate: destinationLocation,
                      ),
                    ],
                    // Halaman detail satu destinasi ini cuma butuh
                    // GAMBARAN rute (preview), bukan navigasi aktif --
                    // jadi tombol "Tandai Sudah Sampai" disembunyikan.
                    readOnly: true,
                  );
                },
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.whiteText,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on,
                size: 22,
              ),

              SizedBox(width: 8),

              Text(
                'Lihat rute',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // REVIEWS

  Widget _buildReviews(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ulasan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              GestureDetector(
                onTap: () async {
                  final double? parsedRating = double.tryParse(widget.rating);
                  final int parsedTotal = _dbReviews.length;

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ReviewScreen(
                          destinationName: widget.name,
                          overallRating: parsedRating ?? 4.8,
                          totalReviews: parsedTotal,
                          destinationId: _destinationId,
                        );
                      },
                    ),
                  );
                  _fetchDestinationBackendDetails();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 17,
                      color: AppColors.greyText,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_dbReviews.isNotEmpty)
            ..._dbReviews.take(2).map((rev) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildReviewCard(rev),
              );
            })
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.rate_review_outlined, color: AppColors.greyText, size: 28),
                  SizedBox(height: 6),
                  Text(
                    'Belum ada ulasan untuk destinasi ini.',
                    style: TextStyle(fontSize: 14, color: AppColors.greyText, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jadilah yang pertama memberikan rating & ulasan!',
                    style: TextStyle(fontSize: 12, color: AppColors.greyText),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // REVIEW CARD

  Future<void> _toggleLike(Map<String, dynamic> review) async {
    if (!requireAuth(context, action: 'menyukai ulasan')) return;
    final dynamic rawId = review['id'];
    final int? reviewId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');
    final bool currentlyLiked = review['liked'] as bool? ?? false;
    final int currentLikes = int.tryParse(review['likes']?.toString() ?? '0') ?? 0;

    setState(() {
      if (currentlyLiked) {
        review['liked'] = false;
        review['likes'] = (currentLikes - 1).clamp(0, 999999).toString();
      } else {
        review['liked'] = true;
        review['likes'] = (currentLikes + 1).toString();
      }
    });

    if (reviewId != null) {
      try {
        final res = await ApiService.instance.post('reviews/$reviewId/like');
        if (res['likes_count'] != null && mounted) {
          setState(() {
            review['liked'] = res['liked'] == true;
            review['likes'] = res['likes_count'].toString();
          });
        }
      } catch (e) {
        debugPrint('Toggle review like API error: $e');
      }
    }
  }

  Widget _buildPhotoImage(String path) {
    return SmartImage(
      imagePathOrUrl: path,
      fit: BoxFit.cover,
    );
  }

  void _openPhotoPreview(List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: PhotoPreviewScreen(
              photos: photos,
              initialIndex: initialIndex,
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final double rating = (review['rating'] as num?)?.toDouble() ?? 5.0;
    final String? avatarUrl = review['avatar'] as String?;
    final String name = review['name'] as String? ?? 'Pengguna SmartTrip';
    final String timeAgo = review['time'] as String? ?? 'Baru saja';
    final String text = review['text'] as String? ?? '';
    final String likes = review['likes']?.toString() ?? '0';
    final bool liked = review['liked'] as bool? ?? false;
    final List<String> photos = review['photos'] is List
        ? List<String>.from(review['photos'] as List)
        : <String>[];
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // USER

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildAvatarImage(avatarUrl, size: 42),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: List.generate(5, (index) {
                        if (index < fullStars) {
                          return const Icon(
                            Icons.star,
                            color: AppColors.starGold,
                            size: 15,
                          );
                        }

                        if (index == fullStars && hasHalfStar) {
                          return const Icon(
                            Icons.star_half,
                            color: AppColors.starGold,
                            size: 15,
                          );
                        }

                        return const Icon(
                          Icons.star_border,
                          color: AppColors.starGold,
                          size: 15,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Text(
                timeAgo,
                style: const TextStyle(fontSize: 12, color: AppColors.greyText),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // REVIEW TEXT

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF444444),
              ),
            ),
          ),

          // PHOTOS + LIKE (satu baris, foto kiri - like kanan)

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (photos.isNotEmpty)
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _openPhotoPreview(photos, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: _buildPhotoImage(photos[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 10),

              GestureDetector(
                onTap: () => _toggleLike(review),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderColor,
                        ),
                      ),
                      child: Icon(
                        liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: liked ? AppColors.primaryBlue : AppColors.mutedText,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      likes,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            liked ? FontWeight.w700 : FontWeight.normal,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// CROWD SUMMARY (helper data class)

class _CrowdSummary {
  final String rangeText;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBackground;
  final Color containerBackground;
  final Color containerBorder;
  final String suggestion;

  const _CrowdSummary({
    required this.rangeText,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBackground,
    required this.containerBackground,
    required this.containerBorder,
    required this.suggestion,
  });
}

// GALLERY PREVIEW

class _GalleryPreview extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _GalleryPreview({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GalleryPreview> createState() => _GalleryPreviewState();
}

class _GalleryPreviewState extends State<_GalleryPreview> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;

    _pageController = PageController(
      initialPage: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // FULLSCREEN IMAGE

          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: SmartImage(
                    imagePathOrUrl: widget.images[index],
                    fit: BoxFit.contain,
                  ),

                ),
              );
            },
          ),

          // CLOSE BUTTON

          Positioned(
            top: 45,
            right: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF333333),
                  size: 24,
                ),
              ),
            ),
          ),

          // IMAGE COUNTER

          Positioned(
            top: 52,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // BOTTOM DOT INDICATOR

          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) {
                  final bool active = index == _currentIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),
                    width: active ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CROWD CHART PAINTER

class _CrowdChartPainter extends CustomPainter {
  final List<int> levels;
  final int? pressedIndex;

  _CrowdChartPainter({required this.levels, this.pressedIndex});

  static const Color _greenColor = Colors.green;
  static const Color _yellowColor = AppColors.warningYellow;
  static const Color _redColor = Colors.red;

  Color _colorForLevel(int level) {
    switch (level) {
      case 2:
        return _redColor;
      case 1:
        return _yellowColor;
      default:
        return _greenColor;
    }
  }

  // Versi lebih muda dari warna batang, dipakai saat batang
  // sedang ditekan (dicampur ke arah putih).
  Color _lightenColor(Color color) {
    return Color.lerp(color, Colors.white, 0.55) ?? color;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color =  AppColors.fieldBorder
      ..strokeWidth = 1;

    // GRAPH AREA

    const double left = 85;
    const double right = 5;
    const double top = 10;
    const double bottom = 30;

    final double graphWidth = size.width - left - right;
    final double graphHeight = size.height - top - bottom;

    // HORIZONTAL GRID (garis Ramai / Sedang / Sepi)

    for (int i = 0; i < 3; i++) {
      final double y = top + (graphHeight / 2) * i;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    if (levels.isEmpty) return;

    // BATANG (level 0 = pendek/Sepi, level 2 = penuh/Ramai)

    final int n = levels.length;
    final double slotWidth = graphWidth / n;

    const double barWidthFraction = 0.5;
    const double minBarHeight = 6;
    const double barRadius = 5;

    for (int i = 0; i < n; i++) {
      final double xCenter = left + slotWidth * (i + 0.5);
      final double barWidth = slotWidth * barWidthFraction;

      final double rawHeight = graphHeight * (levels[i] / 2);
      final double barHeight =
          rawHeight < minBarHeight ? minBarHeight : rawHeight;

      final double barBottom = top + graphHeight;
      final double barTop = barBottom - barHeight;

      final RRect barRect = RRect.fromRectAndCorners(
        Rect.fromLTRB(
          xCenter - barWidth / 2,
          barTop,
          xCenter + barWidth / 2,
          barBottom,
        ),
        topLeft: const Radius.circular(barRadius),
        topRight: const Radius.circular(barRadius),
      );

      final Paint barPaint = Paint()
        ..color = (i == pressedIndex)
            ? _lightenColor(_colorForLevel(levels[i]))
            : _colorForLevel(levels[i]);

      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrowdChartPainter oldDelegate) {
    return oldDelegate.levels.join(',') != levels.join(',') ||
        oldDelegate.pressedIndex != pressedIndex;
  }
}