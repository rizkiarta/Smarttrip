import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../data/destinations_data.dart';
import 'review_screen.dart';
import 'route_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/love_button.dart';


class DetailDestinationScreen extends StatefulWidget {
  final String name;
  final String location;
  final String rating;
  final String reviews;
  final String mainImage;
  final String description;
  final double? latitude;
  final double? longitude;

  // ============================================================
  // GALLERY IMAGES (opsional)
  //
  // Kalau destinasi punya lebih dari 1 foto, isi list ini saat
  // memanggil DetailDestinationScreen, contoh:
  //   galleryImages: [
  //     'assets/images/danau_ranau.jpg',
  //     'assets/images/danau_ranau_2.jpg',
  //   ],
  //
  // Kalau tidak diisi (default), gallery otomatis hanya
  // menampilkan mainImage milik destinasi ini sendiri.
  // ============================================================

  final List<String>? galleryImages;

  // ============================================================
  // DESTINATION ID (untuk tombol Love / simpan)
  // ============================================================
  //
  // Opsional. Kalau pemanggil sudah punya id destinasi (dari
  // kDestinationsData), kirim di sini supaya LoveButton langsung
  // pakai id yang benar.
  //
  // Kalau tidak dikirim (null), id otomatis dicari lewat
  // findDestinationByName(name) -- lihat _resolvedDestinationId
  // di bawah -- jadi layar-layar yang sudah memanggil
  // DetailDestinationScreen sebelum ada field ini tetap jalan
  // tanpa perlu diubah.
  // ============================================================

  final String? destinationId;

  const DetailDestinationScreen({
    super.key,
    required this.name,
    required this.location,
    required this.rating,
    required this.reviews,
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
  // ============================================================
  // FALLBACK COORDINATE (pusat Lampung, dipakai jika destinasi
  // belum punya koordinat sendiri)
  // ============================================================

  static const LatLng _fallbackLocation = LatLng(-5.3971, 105.2668);

  // ============================================================
  // CROWD PREDICTION DATA (per hari)
  // ============================================================
  //
  // Level: 0 = Sepi, 1 = Sedang, 2 = Ramai
  // Titik waktu tetap: 06.00, 08.00, 10.00, 12.00, 14.00, 16.00, 18.00
  //
  // ============================================================

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

  String _selectedDay = 'Minggu';

  // ============================================================
  // RESOLVED DESTINATION ID
  // ============================================================
  //
  // Prioritas: widget.destinationId (kalau pemanggil sudah kirim)
  // -> cari lewat findDestinationByName(widget.name) sebagai
  // fallback -> kalau tetap tidak ketemu, pakai widget.name apa
  // adanya supaya LoveButton tetap bisa dipakai (statusnya cuma
  // tidak akan sinkron dengan data pusat kalau sampai ke sini).
  // ============================================================

  late final String _destinationId =
      widget.destinationId ??
      findDestinationByName(widget.name)?['id'] ??
      widget.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // BODY
      // ========================================================

      body: Stack(
        children: [
          // ====================================================
          // MAIN SCROLL
          // ====================================================

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ==================================================
                // HERO IMAGE
                // ==================================================

                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 285,
                      child: Image.asset(
                        widget.mainImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color:  AppColors.imagePlaceholderBg,
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 60,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // ==================================================
                    // BACK BUTTON
                    // ==================================================

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

                    // ==================================================
                    // LOVE BUTTON (SIMPAN DESTINASI)
                    // ==================================================

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

                // ==================================================
                // WHITE CONTENT
                // ==================================================

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
                      top: 42,
                      bottom: 35,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // DESTINATION INFORMATION
                        // ==================================================

                        _buildDestinationHeader(),

                        const SizedBox(height: 25),

                        // ==================================================
                        // DESCRIPTION
                        // ==================================================

                        _buildDescription(),

                        const SizedBox(height: 25),

                        // ==================================================
                        // GALLERY
                        // ==================================================

                        _buildGallery(context),

                        const SizedBox(height: 32),

                        // ==================================================
                        // CROWD PREDICTION
                        // ==================================================

                        _buildCrowdPrediction(),

                        const SizedBox(height: 18),

                        // ==================================================
                        // RECOMMENDED TIME
                        // ==================================================

                        _buildRecommendedTime(),

                        const SizedBox(height: 32),

                        // ==================================================
                        // ROUTE BUTTON
                        // ==================================================

                        _buildRouteButton(context),

                        const SizedBox(height: 32),

                        // ==================================================
                        // REVIEWS
                        // ==================================================

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

  // ============================================================
  // DESTINATION HEADER
  // ============================================================

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
                    fontSize: 19,
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
                    color: AppColors.darkBlue,
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

              const Text(
                '• Buka pukul 08.00',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        widget.description,
        textAlign: TextAlign.left,
        style: const TextStyle(
          fontSize: 13,
          height: 1.5,
          color: Color(0xFF4F4F4F),
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  // ============================================================
  // GALLERY
  // ============================================================

  Widget _buildGallery(BuildContext context) {
    // Pakai foto milik destinasi ini sendiri (widget.galleryImages).
    // Kalau destinasi belum punya galleryImages sendiri, fallback ke
    // mainImage-nya saja — bukan lagi 3 foto tetap untuk semua tempat.
    final List<String> galleryImages =
        (widget.galleryImages != null && widget.galleryImages!.isNotEmpty)
        ? widget.galleryImages!
        : [widget.mainImage];

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

  // ============================================================
  // GALLERY IMAGE
  // ============================================================

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 130,
          height: 75,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color:  AppColors.imagePlaceholderBg,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primaryBlue,
                  size: 30,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHOW GALLERY PREVIEW
  // ============================================================

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

  // ============================================================
  // CROWD PREDICTION
  // ============================================================

  Widget _buildCrowdPrediction() {
    final List<int> levels = _crowdData[_selectedDay]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        22,
      ),
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
          // ==================================================
          // TITLE + DROPDOWN
          // ==================================================

          Row(
            children: [
              const Expanded(
                child: Text(
                  'Prediksi Kepadatan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              _buildDaySelector(),
            ],
          ),

          const SizedBox(height: 25),

          // ==================================================
          // GRAPH
          // ==================================================

          SizedBox(
            height: 180,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // ==========================================
                // Posisi label jam dihitung dari lebar asli
                // widget (bukan angka tebakan), supaya tidak
                // pernah bertabrakan di lebar layar berapa pun.
                // Nilainya harus selaras dengan konstanta
                // left/right pada _CrowdChartPainter.
                // ==========================================

                const double graphLeft = 85;
                const double graphRight = 5;

                final double graphWidth =
                    constraints.maxWidth - graphLeft - graphRight;

                const List<String> timeMarks = [
                  '06.00',
                  '09.00',
                  '12.00',
                  '18.00',
                ];

                return CustomPaint(
                  painter: _CrowdChartPainter(levels: levels),
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
                            fontSize: 13,
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
                            fontSize: 13,
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // TIMES (0, 1/3, 2/3 dari graphWidth: rata kiri;
                      // titik terakhir (1.0): rata kanan ke tepi grafik)
                      for (int i = 0; i < timeMarks.length - 1; i++)
                        Positioned(
                          left: graphLeft + (graphWidth / 3) * i,
                          bottom: 0,
                          child: Text(
                            timeMarks[i],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.greyText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      Positioned(
                        right: graphRight,
                        bottom: 0,
                        child: Text(
                          timeMarks.last,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY SELECTOR (DROPDOWN)
  // ============================================================

  Widget _buildDaySelector() {
    return PopupMenuButton<String>(
      initialValue: _selectedDay,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      onSelected: (value) {
        setState(() {
          _selectedDay = value;
        });
      },
      itemBuilder: (context) {
        return _dayOptions.map((day) {
          final bool active = day == _selectedDay;

          return PopupMenuItem<String>(
            value: day,
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    active ? FontWeight.bold : FontWeight.w500,
                color: active ? AppColors.primaryBlue : AppColors.darkText,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color:  AppColors.borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedDay,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.greyText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RECOMMENDED TIME
  // ============================================================

  Widget _buildRecommendedTime() {
    final _CrowdSummary summary =
        _summaryFor(_crowdData[_selectedDay]!);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 18,
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
                        fontSize: 11,
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
              fontSize: 11,
              color: AppColors.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CROWD SUMMARY (untuk badge + saran waktu, mengikuti hari terpilih)
  // ============================================================

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

  // ============================================================
  // ROUTE BUTTON
  // ============================================================

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
            foregroundColor: AppColors.darkBlue,
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

  // ============================================================
  // REVIEWS
  // ============================================================

  final List<Map<String, dynamic>> _mockReviews = [
    {
      'avatar': 'https://i.pravatar.cc/150?img=47',
      'name': 'Amara Tasya',
      'rating': 4.5,
      'time': '2 minggu lalu',
      'text': 'Tempatnya bagus banget dan estetik, suasananya juga nyaman',
      'likes': '102',
      'liked': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=12',
      'name': 'Bagas Pratama',
      'rating': 5.0,
      'time': '1 bulan lalu',
      'text':
          'Pemandangannya luar biasa, worth it banget buat healing akhir pekan.',
      'likes': '76',
      'liked': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=32',
      'name': 'Citra Ayu',
      'rating': 4.0,
      'time': '1 bulan lalu',
      'text': 'Aksesnya lumayan jauh, tapi kebersihan tempatnya terjaga.',
      'likes': '54',
      'liked': false,
    },
    {
      'avatar': 'https://i.pravatar.cc/150?img=5',
      'name': 'Dimas Saputra',
      'rating': 4.5,
      'time': '2 bulan lalu',
      'text': 'Cocok buat foto-foto, mending datang pagi biar tidak ramai.',
      'likes': '41',
      'liked': false,
    },
  ];

  Widget _buildReviews(BuildContext context) {
    final Map<String, dynamic> firstReview = _mockReviews.first;

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

              // ==============================================
              // LIHAT SEMUA
              // ==============================================

              GestureDetector(
                onTap: () {
                  final double? parsedRating =
                      double.tryParse(widget.rating);

                  final int parsedTotal = int.tryParse(
                        widget.reviews.replaceAll(
                          RegExp(r'[^0-9]'),
                          '',
                        ),
                      ) ??
                      _mockReviews.length;

                  Navigator.push(
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

          const SizedBox(height: 14),

          _buildReviewCard(firstReview),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  void _toggleLike(Map<String, dynamic> review) {

    setState(() {
      final bool currentlyLiked = review['liked'] as bool? ?? false;
      final int currentLikes = int.tryParse(review['likes'] as String) ?? 0;

      if (currentlyLiked) {
        review['liked'] = false;
        review['likes'] = (currentLikes - 1).clamp(0, 999999).toString();
      } else {
        review['liked'] = true;
        review['likes'] = (currentLikes + 1).toString();
      }
    });
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final double rating = review['rating'] as double;
    final String avatarUrl = review['avatar'] as String;
    final String name = review['name'] as String;
    final String timeAgo = review['time'] as String;
    final String text = review['text'] as String;
    final String likes = review['likes'] as String;
    final bool liked = review['liked'] as bool? ?? false;
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Container(
      width: double.infinity,
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
          // ==================================================
          // USER
          // ==================================================

          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

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
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: List.generate(5, (index) {
                        if (index < fullStars) {
                          return const Icon(
                            Icons.star,
                            color: AppColors.darkBlue,
                            size: 16,
                          );
                        }

                        if (index == fullStars && hasHalfStar) {
                          return const Icon(
                            Icons.star_half,
                            color: AppColors.darkBlue,
                            size: 16,
                          );
                        }

                        return const Icon(
                          Icons.star_border,
                          color: AppColors.darkBlue,
                          size: 16,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Text(
                timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ==================================================
          // REVIEW TEXT
          // ==================================================

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

          const SizedBox(height: 15),

          // ==================================================
          // LIKE
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleLike(review),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: liked
                            ? AppColors.primaryBlue.withValues(alpha: 0.12)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: liked
                              ? AppColors.primaryBlue
                              :  AppColors.borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.04,
                            ),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: liked ? AppColors.primaryBlue : AppColors.darkBlue,
                        size: 18,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      likes,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            liked ? FontWeight.w700 : FontWeight.normal,
                        color: liked ? AppColors.primaryBlue : AppColors.greyText,
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

// ================================================================
// CROWD SUMMARY (helper data class)
// ================================================================

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

// ================================================================
// GALLERY PREVIEW
// ================================================================

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
          // ======================================================
          // FULLSCREEN IMAGE
          // ======================================================

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
                  child: Image.asset(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // ======================================================
          // CLOSE BUTTON
          // ======================================================

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

          // ======================================================
          // IMAGE COUNTER
          // ======================================================

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

          // ======================================================
          // BOTTOM DOT INDICATOR
          // ======================================================

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

// ================================================================
// CROWD CHART PAINTER
// ================================================================

class _CrowdChartPainter extends CustomPainter {
  final List<int> levels;

  _CrowdChartPainter({required this.levels});

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

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color =  AppColors.fieldBorder
      ..strokeWidth = 1;

    // ============================================================
    // GRAPH AREA
    // ============================================================

    const double left = 85;
    const double right = 5;
    const double top = 10;
    const double bottom = 30;

    final double graphWidth = size.width - left - right;
    final double graphHeight = size.height - top - bottom;

    // ============================================================
    // HORIZONTAL GRID
    // ============================================================

    for (int i = 0; i < 3; i++) {
      final double y = top + (graphHeight / 2) * i;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    // ============================================================
    // VERTICAL GRID
    // ============================================================

    for (int i = 0; i < 4; i++) {
      final double x = left + (graphWidth / 3) * i;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, size.height - bottom),
        gridPaint,
      );
    }

    if (levels.isEmpty) return;

    // ============================================================
    // DATA POINTS (level 0 = bawah/Sepi, level 2 = atas/Ramai)
    // ============================================================

    final int n = levels.length;

    final List<Offset> points = List.generate(n, (i) {
      final double x = n == 1 ? left : left + graphWidth * (i / (n - 1));
      final double fraction = 1 - (levels[i] / 2);
      final double y = top + graphHeight * fraction;
      return Offset(x, y);
    });

    // ============================================================
    // SMOOTH SEGMENTED LINE (warna mengikuti level tertinggi
    // di antara dua titik yang dihubungkan)
    // ============================================================

    for (int i = 0; i < n - 1; i++) {
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];

      final double dx = (p2.dx - p1.dx) / 3;

      final Path segmentPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..cubicTo(
          p1.dx + dx,
          p1.dy,
          p2.dx - dx,
          p2.dy,
          p2.dx,
          p2.dy,
        );

      final int segmentLevel =
          levels[i] > levels[i + 1] ? levels[i] : levels[i + 1];

      final Paint segmentPaint = Paint()
        ..color = _colorForLevel(segmentLevel)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(segmentPath, segmentPaint);
    }

    // ============================================================
    // POINTS
    // ============================================================

    for (int i = 0; i < n; i++) {
      final Paint pointPaint = Paint()..color = _colorForLevel(levels[i]);

      canvas.drawCircle(points[i], 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CrowdChartPainter oldDelegate) {
    return oldDelegate.levels.join(',') != levels.join(',');
  }
}