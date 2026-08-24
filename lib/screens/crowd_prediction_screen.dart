import 'package:flutter/material.dart';
import '../data/destinations_data.dart';
import 'detail_destination_screen.dart';
import '../theme/app_colors.dart';


class CrowdPredictionScreen extends StatefulWidget {
  const CrowdPredictionScreen({super.key});

  @override
  State<CrowdPredictionScreen> createState() =>
      _CrowdPredictionScreenState();
}

class _CrowdPredictionScreenState extends State<CrowdPredictionScreen> {
  // ============================================================
  // TANGGAL YANG SEDANG DIPILIH
  // ============================================================

  int selectedDateIndex = 0;

  @override
  Widget build(BuildContext context) {
    final crowdData = _generateCrowdData(selectedDateIndex);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(context),

            const SizedBox(height: 12),

            // ==================================================
            // DATE SELECTOR
            // ==================================================

            _buildDateSelector(),

            const SizedBox(height: 18),

            // ==================================================
            // DESTINATION LIST
            // ==================================================

            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 25,
                  right: 25,
                  bottom: 30,
                ),
                itemCount: crowdData.length,
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemBuilder: (context, index) {
                  final crowdEntry = crowdData[index];
                  final destination =
                      findDestinationById(crowdEntry['id']!);

                  if (destination == null) {
                    // Ditampilkan jelas alih-alih disembunyikan, supaya id
                    // yang tidak/belum ada di kDestinationsData langsung
                    // terlihat.
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Destinasi dengan id "${crowdEntry['id']}" tidak ditemukan',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }

                  return _buildCrowdCard(
                    imageUrl: destination['image']!,
                    title: destination['name']!,
                    location: destination['location']!,
                    status: crowdEntry['status']!,
                    time: crowdEntry['time']!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailDestinationScreen(
                            destinationId: destination['id'],
                            name: destination['name']!,
                            location: destination['location']!,
                            rating: destination['rating'] ?? '-',
                            reviews: destination['reviews'] ?? '-',
                            mainImage: destination['image']!,
                            galleryImages:
                                kDestinationGalleryImages[destination['id']],
                            description: destination['description'] ?? '',
                          ),
                        ),
                      );
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 25,
        right: 25,
        top: 12,
      ),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==================================================
            // BACK BUTTON
            // ==================================================

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
                      color:  AppColors.borderColor,
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

            // ==================================================
            // TITLE
            // ==================================================

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

  // ============================================================
  // DATE SELECTOR
  // ============================================================

  Widget _buildDateSelector() {
    final List<DateTime> dates = List.generate(
      7,
      (i) => DateTime.now().add(Duration(days: i)),
    );

    return SizedBox(
      height: 65,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(
          left: 25,
          right: 25,
        ),
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
            },
          );
        },
      ),
    );
  }

  // ============================================================
  // NAMA HARI & BULAN (INDONESIA)
  // ============================================================

  String _dayName(int weekday) {
    const names = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return names[month - 1];
  }

  // ============================================================
  // DATE ITEM
  // ============================================================

  Widget _buildDateItem({
    required String day,
    required String date,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 64,
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primaryBlue
              :  AppColors.lightGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: active
                    ? Colors.white
                    : const Color(0xFF555555),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              date,
              style: TextStyle(
                fontSize: 10,
                color: active
                    ? Colors.white
                    :  AppColors.greyText,
                fontWeight: active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CROWD CARD
  // ============================================================

  Widget _buildCrowdCard({
    required String imageUrl,
    required String title,
    required String location,
    required String status,
    required String time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      height: 70,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:  AppColors.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ==================================================
          // IMAGE
          // ==================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: SizedBox(
              width: 80,
              height: 56,
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
                      size: 28,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ==================================================
          // NAME + LOCATION
          // ==================================================

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
                    color: AppColors.darkText,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primaryBlue,
                      size: 14,
                    ),

                    const SizedBox(width: 2),

                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // ==================================================
          // STATUS + TIME
          // ==================================================

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildStatusBadge(status),

              const SizedBox(height: 5),

              Text(
                time,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color backgroundColor;

    switch (status) {
      case 'Sepi':
        textColor = Colors.green;
        backgroundColor =  AppColors.successBg;
        break;

      case 'Sedang':
        textColor = const Color(0xFFE0A900);
        backgroundColor = const Color(0xFFFFF8DF);
        break;

      case 'Ramai':
      default:
        textColor = Colors.red;
        backgroundColor =  AppColors.errorBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: textColor,
            size: 7,
          ),

          const SizedBox(width: 4),

          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESTINATION DATA (DUMMY, BERVARIASI PER TANGGAL)
  // ============================================================
  //
  // 'id' di sini harus persis sama dengan 'id' di kDestinationsData
  // (destinations_data.dart) supaya lookup-nya berhasil. Dipakai 'id'
  // (bukan 'name') supaya referensinya sudah cocok dengan cara nanti
  // manggil backend (mis. GET /crowd-prediction?destination_id=...&date=...).
  //
  // TODO(backend): ganti isi _generateCrowdData() dengan pemanggilan
  // API prediksi kepadatan sungguhan, kirim tanggal yang dipilih
  // sebagai parameter. Struktur return-nya (List<Map<String,String>>
  // dengan key 'id', 'status', 'time') bisa dipertahankan sama persis
  // supaya UI di atas tidak perlu diubah lagi.
  // ============================================================

  static const List<String> _destinationIds = [
    'pulau_pahawang',
    'danau_ranau',
    'pantai_klara',
    'pulau_wayang',
    'air_terjun_curup',
    'teluk_kiluan',
    'pantai_mutun',
    'taman_nasional_way_kambas',
    'puncak_mas',
    'lembah_hijau',
  ];

  static const List<String> _statusCycle = ['Ramai', 'Sedang', 'Sepi'];

  static const List<List<String>> _timeSlots = [
    ['08.00', '11.00'],
    ['09.00', '15.00'],
    ['10.00', '14.00'],
    ['13.00', '17.00'],
    ['07.00', '10.00'],
    ['11.00', '16.00'],
  ];

  List<Map<String, String>> _generateCrowdData(int dateIndex) {
    final int n = _destinationIds.length;

    // Urutan daftar destinasi digeser (rotate) sesuai tanggal yang
    // dipilih -- supaya yang berubah tiap hari bukan cuma status &
    // jamnya, tapi urutan kemunculan destinasinya juga (mis. yang
    // tadinya paling atas di "Hari ini" bisa geser ke bawah di
    // tanggal lain).
    final List<String> rotatedIds = List.generate(
      n,
      (i) => _destinationIds[(i + dateIndex) % n],
    );

    return List.generate(n, (i) {
      // Digeser pakai dateIndex supaya hasilnya beda tiap tanggal
      // dipilih -- bukan cuma daftar diam yang sama terus.
      final status = _statusCycle[(i + dateIndex) % _statusCycle.length];

      final timeSlot = _timeSlots[(i + dateIndex * 2) % _timeSlots.length];

      return {
        'id': rotatedIds[i],
        'status': status,
        'time': '${timeSlot[0]} - ${timeSlot[1]}',
      };
    });
  }
}