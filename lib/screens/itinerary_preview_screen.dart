import 'package:flutter/material.dart';
import '../services/saved_itinerary_service.dart';
import '../widgets/smart_image.dart';
import '../data/destinations_data.dart';
import 'itinerary_detail_screen.dart';
import 'main_navigation_screen.dart';
import 'detail_destination_screen.dart';
import '../theme/app_colors.dart';


class ItineraryPreviewScreen extends StatefulWidget {
  // ============================================================
  // DATA
  // ============================================================

  final List<Map<String, dynamic>> dailySchedules;

  const ItineraryPreviewScreen({super.key, required this.dailySchedules});

  @override
  State<ItineraryPreviewScreen> createState() =>
      _ItineraryPreviewScreenState();
}

class _ItineraryPreviewScreenState extends State<ItineraryPreviewScreen> {
  // ============================================================
  // DAY YANG SEDANG AKTIF (index di dalam dailySchedules)
  // ============================================================

  int selectedIndex = 0;

  // ============================================================
  // FORMAT VALUE
  // ============================================================

  String _value(Map<String, dynamic> data, String key, {String fallback = ''}) {
    final value = data[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  // ============================================================
  // GET DESTINATION NAME
  // ============================================================

  String _destinationName(Map<String, dynamic> destination) {
    return _value(destination, 'name', fallback: 'Destinasi');
  }

  // ============================================================
  // GET DESTINATION IMAGE
  // ============================================================

  String _destinationImage(Map<String, dynamic> destination) {
    for (final key in ['image', 'main_image', 'mainImage', 'photo', 'cover_image', 'image_url']) {
      final val = destination[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val != 'null') {
        return val;
      }
    }
    final destId = destination['id']?.toString() ?? '';
    final destName = destination['name']?.toString() ?? '';
    final liveDest = findDestinationById(destId) ?? findDestinationByName(destName);
    if (liveDest != null && liveDest['image'] != null && liveDest['image']!.isNotEmpty) {
      return liveDest['image']!;
    }
    return '';
  }

  // ============================================================
  // GET RATING & JUMLAH ULASAN
  // ============================================================

  String _destinationRating(Map<String, dynamic> destination) {
    return _value(destination, 'rating', fallback: '0.0');
  }

  String _destinationReviewsCount(Map<String, dynamic> destination) {
    return _value(destination, 'reviewsCount', fallback: '0');
  }

  // ============================================================
  // PREDIKSI KEPADATAN (DUMMY, DETERMINISTIK PER DESTINASI)
  // ============================================================
  //
  // Disamakan formatnya ('Sepi'/'Sedang'/'Ramai') dan cara hitungnya
  // (hash id/nama, bukan acak) dengan ManualScheduleScreen /
  // AIItineraryScreen supaya konsisten -- destinasi yang sama akan
  // selalu menunjukkan status kepadatan yang sama di layar manapun.
  //
  // ============================================================

  static const List<String> _crowdStatusCycle = ['Sepi', 'Sedang', 'Ramai'];

  String _crowdStatusFor(Map<String, dynamic> destination) {
    final String key = destination['id']?.toString() ??
        destination['name']?.toString() ??
        '';

    final int hash = key.hashCode.abs();

    return _crowdStatusCycle[hash % _crowdStatusCycle.length];
  }

  // ============================================================
  // BADGE TINGKAT KEPADATAN
  // ============================================================
  //
  // Warnanya disamakan dengan badge status di ManualScheduleScreen /
  // AIItineraryScreen (Sepi = hijau, Sedang = kuning, Ramai = merah)
  // supaya artinya konsisten di seluruh aplikasi.
  //
  // ============================================================

  Widget _buildCrowdBadge(String status) {
    Color textColor;
    Color backgroundColor;

    switch (status) {
      case 'Sepi':
        textColor = Colors.green;
        backgroundColor = AppColors.successBg;
        break;

      case 'Sedang':
        textColor = const Color(0xFFE0A900);
        backgroundColor = const Color(0xFFFFF8DF);
        break;

      case 'Ramai':
      default:
        textColor = Colors.red;
        backgroundColor = AppColors.errorBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: textColor, size: 6),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUKA DETAIL DESTINASI
  // ============================================================
  //
  // Dipakai kalau kartu destinasi diketuk -- membuka layar detail
  // yang sama dengan yang dipakai di ManualScheduleScreen /
  // DestinationSelectionScreen, supaya user bisa lihat info lengkap
  // destinasi tanpa harus balik ke layar pemilihan destinasi.
  //
  // ============================================================

  void _openDestinationDetail(Map<String, dynamic> destination) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return DetailDestinationScreen(
            name: destination['name']?.toString() ?? 'Destinasi',
            location: destination['location']?.toString() ?? '',
            rating: destination['rating']?.toString() ?? '0.0',
            reviews: destination['reviews']?.toString() ?? '0 ulasan',
            mainImage: _destinationImage(destination),
            description: destination['description']?.toString() ?? '',
          );
        },
      ),
    );
  }

  // ============================================================
  // GET ARRIVAL TIME
  // ============================================================

  String _arrivalTime(Map<String, dynamic> destination) {
    return _value(destination, 'arrivalTime', fallback: '--:--');
  }

  // ============================================================
  // GET DEPARTURE TIME
  // ============================================================

  String _destinationDepartureTime(Map<String, dynamic> destination) {
    return _value(destination, 'departureTime', fallback: '--:--');
  }

  // ============================================================
  // CALCULATE DURATION
  // ============================================================

  String _calculateDuration(String arrival, String departure) {
    try {
      if (arrival == '--:--' || departure == '--:--') {
        return '';
      }

      final arrivalParts = arrival.split(':');
      final departureParts = departure.split(':');

      if (arrivalParts.length != 2 || departureParts.length != 2) {
        return '';
      }

      int arrivalHour = int.parse(arrivalParts[0]);
      int arrivalMinute = int.parse(arrivalParts[1]);

      int departureHour = int.parse(departureParts[0]);
      int departureMinute = int.parse(departureParts[1]);

      int arrivalTotal = arrivalHour * 60 + arrivalMinute;

      int departureTotal = departureHour * 60 + departureMinute;

      if (departureTotal < arrivalTotal) {
        departureTotal += 24 * 60;
      }

      final difference = departureTotal - arrivalTotal;

      final hours = difference ~/ 60;
      final minutes = difference % 60;

      if (hours > 0 && minutes > 0) {
        return '$hours jam $minutes menit';
      }

      if (hours > 0) {
        return '$hours jam';
      }

      return '$minutes menit';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // START LOCATION
  // ============================================================

  String _getStartLocation(Map<String, dynamic> schedule) {
    final location = schedule['startLocation'];

    if (location != null && location.toString().trim().isNotEmpty) {
      return location.toString();
    }

    return 'Lokasi awal';
  }

  // ============================================================
  // DEPARTURE TIME
  // ============================================================

  String _getDepartureTime(Map<String, dynamic> schedule) {
    final time = schedule['departureTime'];

    if (time != null && time.toString().trim().isNotEmpty) {
      return time.toString();
    }

    return '--:--';
  }

  // ============================================================
  // DAY LABEL
  // ============================================================

  String _getDayLabel(Map<String, dynamic> schedule, int index) {
    final day = schedule['day'];

    if (day != null) {
      return 'Hari $day';
    }

    return 'Hari ${index + 1}';
  }

  // ============================================================
  // HEADER
  // ============================================================

  // Header ini sekarang mengikuti pola AppBar yang dipakai di
  // ManualScheduleScreen & layar lain (back button bulat dengan
  // border AppColors.borderColor, judul center bold 18px), supaya
  // tampilannya konsisten satu app -- sebelumnya pakai IconButton
  // polos tanpa border dan warna ikon hardcode 0xFF555555.

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leadingWidth: 58,
      leading: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: GestureDetector(
          onTap: () {
            // ------------------------------------------------
            // POP TANPA HASIL (null)
            // ------------------------------------------------
            //
            // Sengaja TIDAK mengirim `false` atau nilai lain,
            // karena ManualScheduleScreen (_handlePreview) cuma
            // mengecek `if (result != null)` untuk memutuskan
            // apakah harus ikut pop ke atas. Kalau di sini kirim
            // `false`, itu dianggap "ada hasil" sehingga
            // ManualScheduleScreen ikut ke-pop juga, dan
            // berantai lagi ke layar-layar di atasnya -- padahal
            // maksudnya cuma mau balik SATU langkah ke Manual
            // Schedule.
            //
            // ------------------------------------------------

            Navigator.pop(context);
          },
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 17,
              color: AppColors.greyText,
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: const Text(
        'Preview Perjalanan',
        style: TextStyle(
          color: AppColors.darkText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // DAY TABS
  // ============================================================

  Widget _buildDayTabs() {
    final schedules = widget.dailySchedules;

    // Jumlah tab di sini otomatis mengikuti jumlah hari yang
    // sudah ditentukan pengguna di "Informasi Perjalanan"
    // (travelDuration), karena dailySchedules dibentuk dari
    // destinationsByDay yang panjangnya = travelDuration.
    if (schedules.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 18),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: schedules.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },
        itemBuilder: (context, index) {
          final bool isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    :  AppColors.lightGrey,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                _getDayLabel(schedules[index], index),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white :  AppColors.greyText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TIMELINE DOT + GARIS
  // ============================================================
  //
  // Dipakai bareng oleh titik keberangkatan & tiap destinasi.
  // Trik-nya: seluruh Row di-stretch (IntrinsicHeight +
  // CrossAxisAlignment.stretch) supaya kolom titik/garis ini
  // otomatis setinggi card di sampingnya -- termasuk jarak
  // (bottom padding) yang ditaruh DI DALAM card, bukan di luar
  // Row. Jadi garis benar-benar menyambung sampai ke titik
  // berikutnya, tidak ada celah.
  // ============================================================

  Widget _buildTimelineDotColumn({required bool isLast}) {
    return SizedBox(
      width: 30,
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBlue, width: 3),
            ),
            child: const Center(
              child: CircleAvatar(radius: 5, backgroundColor: AppColors.primaryBlue),
            ),
          ),

          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                color: AppColors.primaryBlue.withValues(alpha: 0.55),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // START POINT (TITIK BERANGKAT)
  // ============================================================

  Widget _buildStartPoint({
    required String time,
    required String location,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineDotColumn(isLast: isLast),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primaryBlue,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Berangkat',
                            style: TextStyle(fontSize: 12, color: AppColors.greyText),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            location,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESTINATION ITEM (TITIK + CARD DESTINASI)
  // ============================================================

  Widget _buildDestinationItem({
    required int index,
    required Map<String, dynamic> destination,
    required bool isLast,
  }) {
    final name = _destinationName(destination);
    final image = _destinationImage(destination);
    final arrival = _arrivalTime(destination);
    final departure = _destinationDepartureTime(destination);
    final rating = _destinationRating(destination);
    final reviewsCount = _destinationReviewsCount(destination);
    final crowdStatus = _crowdStatusFor(destination);

    final duration = _calculateDuration(arrival, departure);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTimelineDotColumn(isLast: isLast),

          const SizedBox(width: 8),

          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              // ==================================================
              // BUKA DETAIL DESTINASI KALAU KARTUNYA DIKETUK
              // ==================================================
              //
              // Sama seperti pola di ManualScheduleScreen -- kartu
              // destinasi di preview ini juga bisa diketuk untuk
              // membuka DetailDestinationScreen.
              //
              // ==================================================
              child: GestureDetector(
                onTap: () => _openDestinationDetail(destination),
                child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.035),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SmartImage(
                              imagePathOrUrl: image,
                              width: 88, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
                              height: 88, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
                              fit: BoxFit.cover,
                            ),
                          ),

                          const SizedBox(width: 11),

                          // NAME
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destinasi ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 12, // CHANGED - font terkecil jadi 12
                                    color: AppColors.greyText,
                                  ),
                                ),

                                const SizedBox(height: 3),

                                Text(
                                  name,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.25,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                // ==================================
                                // RATING + KEPADATAN
                                // ==================================
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: AppColors.starGold,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$rating ($reviewsCount)',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.greyText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _buildCrowdBadge(crowdStatus),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ------------------------------------------
                      // TIME
                      // ------------------------------------------
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: AppColors.primaryBlue,
                            ),

                            const SizedBox(width: 7),

                            Text(
                              '$arrival - $departure',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkText,
                              ),
                            ),

                            if (duration.isNotEmpty) ...[
                              const Spacer(),

                              Text(
                                duration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY TIMELINE (HANYA UNTUK HARI YANG DIPILIH)
  // ============================================================

  Widget _buildDayTimeline() {
    final schedule = widget.dailySchedules[selectedIndex];

    final destinationsRaw = schedule['destinations'];

    final List<Map<String, dynamic>> destinations = [];

    if (destinationsRaw is List) {
      for (final item in destinationsRaw) {
        if (item is Map) {
          destinations.add(Map<String, dynamic>.from(item));
        }
      }
    }

    final startLocation = _getStartLocation(schedule);

    final departureTime = _getDepartureTime(schedule);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // TITIK BERANGKAT
        // --------------------------------------------------------
        _buildStartPoint(
          time: departureTime,
          location: startLocation,
          isLast: destinations.isEmpty,
        ),

        // --------------------------------------------------------
        // DESTINASI
        // --------------------------------------------------------
        for (int i = 0; i < destinations.length; i++)
          _buildDestinationItem(
            index: i,
            destination: destinations[i],
            isLast: i == destinations.length - 1,
          ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.route_outlined,
                size: 34,
                color: AppColors.primaryBlue,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Belum ada jadwal perjalanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'Silakan atur destinasi dan waktu perjalanan terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.greyText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUCCESS POPUP
  // ============================================================
  //
  // Ditampilkan saat "Simpan Jadwal" ditekan. Ini murni tampilan
  // konfirmasi tambahan sebelum melanjutkan alur pop data yang
  // sudah ada -- tidak mengubah data/logic yang dikembalikan.
  // ============================================================

  void _showSaveSuccessDialog() {
    // ==========================================================
    // SIMPAN KE SERVICE PUSAT LEBIH DULU
    // ==========================================================
    //
    // Disimpan di sini (sebelum popup tampil) supaya data itinerary
    // sudah pasti tersimpan terlepas dari tombol mana yang nanti
    // ditekan user di popup ("Lihat Itinerary" atau "Kembali ke
    // Beranda"). PlanScreen mendengarkan service ini, jadi kartu
    // itinerary di sana otomatis ter-update.
    //
    // ==========================================================

    SavedItineraryService.instance.save(widget.dailySchedules);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ----------------------------------------------
                // ICON SUKSES
                // ----------------------------------------------
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3F6E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF3FAE5C),
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------
                // JUDUL
                // ----------------------------------------------
                const Text(
                  'Itinerary berhasil dibuat!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),

                const SizedBox(height: 22),

                // ----------------------------------------------
                // LIHAT ITINERARY
                // ----------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Tutup popup.
                      Navigator.pop(dialogContext);

                      // ------------------------------------------
                      // KEMBALI KE PLAN SCREEN (root alur ini),
                      // LALU BUKA ITINERARY DETAIL DI ATASNYA.
                      // ------------------------------------------
                      //
                      // Data itinerary sudah tersimpan di
                      // SavedItineraryService (lihat
                      // _showSaveSuccessDialog), jadi PlanScreen di
                      // bawah sudah otomatis ter-update. Menekan
                      // "back" dari ItineraryDetailScreen akan
                      // membawa user ke PlanScreen ini.
                      //
                      // Reset tab MainNavigationScreen ke Rencana
                      // (index 1) DULU, sebelum popUntil, supaya
                      // kalau user nanti pencet back dari
                      // ItineraryDetailScreen, dia mendarat di tab
                      // Rencana -- bukan tab lama yang kebetulan
                      // aktif sebelum masuk alur bikin itinerary.
                      //
                      // ------------------------------------------

                      MainNavigationScreen.selectedTab.value = 1;

                      // Dulu ini popUntil((route) => route.isFirst), yang
                      // asumsinya "route paling bawah stack pasti Main" --
                      // meleset kalau ada layar lain (mis. LoginScreen lama
                      // akibat bug navigasi di tempat lain) yang kebetulan
                      // nangkring di bawah Main. Sekarang cari route '/main'
                      // secara eksplisit (lihat RouteSettings di
                      // login_screen.dart), fallback ke isFirst kalau route
                      // itu entah kenapa tidak ketemu (mis. app dibuka lewat
                      // jalur lain yang belum kasih nama '/main').
                      Navigator.of(context).popUntil(
                        (route) =>
                            route.settings.name == '/main' || route.isFirst,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            return ItineraryDetailScreen(
                              itinerary: widget.dailySchedules,
                            );
                          },
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Lihat Itinerary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // KEMBALI KE BERANDA
                // ----------------------------------------------
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    // --------------------------------------------
                    // LANGSUNG KE HALAMAN AWAL (BERANDA/PLAN)
                    // --------------------------------------------
                    //
                    // Data itinerary sudah tersimpan di
                    // SavedItineraryService (lihat
                    // _showSaveSuccessDialog) SEBELUM popup ini
                    // muncul, jadi popUntil di sini aman -- kartu
                    // itinerary di PlanScreen akan otomatis
                    // ter-update walau kita melompati semua layar
                    // form di tengah jalan.
                    //
                    // FIX: popUntil TIDAK membuat instance baru
                    // MainNavigationScreen, cuma menampilkan lagi
                    // instance lama -- jadi _currentIndex (private,
                    // punya State) tidak ikut ter-reset ke 0 walau
                    // tombolnya bertuliskan "Kembali ke Beranda".
                    // Set selectedTab DULU sebelum popUntil supaya
                    // State-nya ikut pindah ke tab Beranda beneran.
                    //
                    // --------------------------------------------

                    MainNavigationScreen.selectedTab.value = 0;

                    // Sama seperti fix di tombol "Lihat Itinerary" di
                    // atas -- cari route '/main' secara eksplisit,
                    // bukan asumsi "paling bawah stack pasti Main".
                    Navigator.popUntil(
                      context,
                      (route) =>
                          route.settings.name == '/main' || route.isFirst,
                    );
                  },
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        children: [
          // ------------------------------------------------------
          // KEMBALI ATUR JADWAL
          // ------------------------------------------------------

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                // Lihat komentar di header back button: pop TANPA
                // hasil supaya tidak ikut memicu relay pop di
                // ManualScheduleScreen.
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Kembali Atur Jadwal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ------------------------------------------------------
          // SIMPAN
          // ------------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _showSaveSuccessDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Simpan Jadwal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final schedules = widget.dailySchedules;

    return Scaffold(
      // CHANGED - disamakan dengan layar lain (manual schedule, travel
      // information, dst) yang semuanya pakai background putih, bukan
      // abu-abu 0xFFF8F9FA.
      backgroundColor: Colors.white,

      appBar: _buildAppBar(context),

      body: SafeArea(
        child: Column(
          children: [
            // ====================================================
            // CONTENT
            // ====================================================
            Expanded(
              child: schedules.isEmpty
                  ? _buildEmptyState()
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),

                      // CHANGED - padding atas disamakan dengan pola
                      // layar lain (20, 16, 20, ...)
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 25),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // ------------------------------------
                          // TAB HARI
                          // ------------------------------------
                          _buildDayTabs(),

                          // ------------------------------------
                          // TIMELINE HARI YANG DIPILIH
                          // ------------------------------------
                          _buildDayTimeline(),
                        ],
                      ),
                    ),
            ),

            // ====================================================
            // BUTTON
            // ====================================================
            if (schedules.isNotEmpty) _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }
}