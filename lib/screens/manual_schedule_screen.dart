import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'itinerary_preview_screen.dart';
import '../data/destinations_data.dart';
import '../theme/app_colors.dart';
import '../widgets/smart_image.dart';



class ManualScheduleScreen extends StatefulWidget {
  // ============================================================
  // DATA PERJALANAN
  // ============================================================

  final String startLocation;

  // ============================================================
  // KOORDINAT LOKASI AWAL
  // ============================================================
  //
  // Dipakai supaya peta rute di ItineraryDetailScreen tahu titik
  // keberangkatan sebenarnya (bukan cuma teks nama lokasinya).
  // Kalau null (mis. user tidak sempat pilih lokasi lewat peta/GPS),
  // dibuatkan titik dummy di sini (lihat _handlePreview) yang jatuh
  // di wilayah kabupaten/kota TUJUAN (travelData['destination']),
  // BUKAN titik dummy tetap di satu tempat seperti sebelumnya --
  // supaya startLatitude/startLongitude yang tersimpan selalu masuk
  // akal walau user tidak sempat memilih lokasi awal lewat peta/GPS.
  //
  // ============================================================

  final LatLng? startCoordinate;

  // Format:
  // {
  //   1: [destinasi hari 1],
  //   2: [destinasi hari 2],
  //   3: [destinasi hari 3],
  // }
  final Map<int, List<Map<String, dynamic>>> destinationsByDay;

  // ------------------------------------------------------------
  // BACKWARD COMPATIBILITY
  // ------------------------------------------------------------
  // Ini dibuat supaya kalau dari file lama masih mengirim
  // destinations: [...] tidak langsung error.
  final List<Map<String, dynamic>>? destinations;

  // ============================================================
  // DATA PERJALANAN LENGKAP (DARI TRAVEL INFORMATION SCREEN)
  // ============================================================
  //
  // tripName, startDate, endDate, participants, vehicle,
  // destination, dst. Digabungkan ke setiap hari di dailySchedules
  // supaya PlanScreen & ItineraryDetailScreen tidak lagi jatuh ke
  // nilai default/placeholder.
  //
  // ============================================================

  final Map<String, dynamic>? travelData;

  // ============================================================
  // PREFILL WAKTU (DIPAKAI SAAT MODE EDIT)
  // ============================================================
  //
  // Kalau user menekan "Edit Itinerary" dari PlanScreen atas
  // itinerary yang sumbernya 'manual', waktu berangkat/tiba/pulang
  // yang sudah diisi sebelumnya diteruskan lagi ke sini lewat 3
  // parameter ini (di-parse dari String "HH:mm" yang tersimpan di
  // SavedItineraryService, lihat plan_screen.dart -> _editItinerary).
  // Kalau null (alur normal dari DestinationSelectionScreen, belum
  // pernah diisi), semua waktu tetap dimulai kosong seperti biasa.
  //
  // ============================================================

  final Map<int, TimeOfDay?>? initialDepartureTimesByDay;

  final Map<int, List<TimeOfDay?>>? initialArrivalTimesByDay;

  final Map<int, List<TimeOfDay?>>? initialReturnTimesByDay;

  const ManualScheduleScreen({
    super.key,
    this.startLocation = 'Lokasi awal belum ditentukan',
    this.startCoordinate,
    this.destinationsByDay = const {},
    this.destinations,
    this.travelData,
    this.initialDepartureTimesByDay,
    this.initialArrivalTimesByDay,
    this.initialReturnTimesByDay,
  });

  @override
  State<ManualScheduleScreen> createState() => _ManualScheduleScreenState();
}

class _ManualScheduleScreenState extends State<ManualScheduleScreen> {
  // ============================================================
  // DAY YANG SEDANG AKTIF
  // ============================================================

  int selectedDay = 1;

  // ============================================================
  // WAKTU KEBERANGKATAN SETIAP HARI
  // ============================================================

  late Map<int, TimeOfDay?> departureTimesByDay;

  // ============================================================
  // WAKTU TIBA DAN PULANG SETIAP DESTINASI
  // ============================================================

  late Map<int, List<TimeOfDay?>> arrivalTimesByDay;

  late Map<int, List<TimeOfDay?>> returnTimesByDay;

  // ============================================================
  // DATA DESTINASI YANG SUDAH DINORMALISASI
  // ============================================================

  late Map<int, List<Map<String, dynamic>>> normalizedDestinations;

  @override
  void initState() {
    super.initState();

    normalizedDestinations = _prepareDestinations();

    departureTimesByDay = {};

    arrivalTimesByDay = {};

    returnTimesByDay = {};

    for (final entry in normalizedDestinations.entries) {
      final int day = entry.key;

      final int destinationCount = entry.value.length;

      // Prioritas: waktu yang sudah pernah diisi (mode edit, lihat
      // initialDepartureTimesByDay dkk di atas). Kalau tidak ada
      // untuk hari ini, tetap kosong seperti alur normal.

      departureTimesByDay[day] = widget.initialDepartureTimesByDay?[day];

      final List<TimeOfDay?>? initialArrivals =
          widget.initialArrivalTimesByDay?[day];

      final List<TimeOfDay?>? initialReturns =
          widget.initialReturnTimesByDay?[day];

      arrivalTimesByDay[day] =
          (initialArrivals != null && initialArrivals.length == destinationCount)
              ? List<TimeOfDay?>.from(initialArrivals)
              : List<TimeOfDay?>.filled(destinationCount, null);

      returnTimesByDay[day] =
          (initialReturns != null && initialReturns.length == destinationCount)
              ? List<TimeOfDay?>.from(initialReturns)
              : List<TimeOfDay?>.filled(destinationCount, null);
    }

    if (normalizedDestinations.isNotEmpty) {
      selectedDay = normalizedDestinations.keys.first;
    }
  }

  // ============================================================
  // NORMALISASI DATA
  // ============================================================

  Map<int, List<Map<String, dynamic>>> _prepareDestinations() {
    final Map<int, List<Map<String, dynamic>>> result = {};

    // ------------------------------------------------------------
    // PRIORITAS:
    // destinationsByDay
    // ------------------------------------------------------------

    if (widget.destinationsByDay.isNotEmpty) {
      for (final entry in widget.destinationsByDay.entries) {
        result[entry.key] = entry.value
            .map((destination) => Map<String, dynamic>.from(destination))
            .toList();
      }
    }
    // ------------------------------------------------------------
    // BACKWARD COMPATIBILITY
    // ------------------------------------------------------------
    // Kalau masih mengirim:
    //
    // destinations: [...]
    //
    // maka semuanya dianggap Hari 1.
    // ------------------------------------------------------------
    else if (widget.destinations != null && widget.destinations!.isNotEmpty) {
      result[1] = widget.destinations!
          .map((destination) => Map<String, dynamic>.from(destination))
          .toList();
    }

    return result;
  }

  // ============================================================
  // TUKAR POSISI DESTINASI (NAIK/TURUN)
  // ============================================================
  //
  // Ganti dari drag & drop (SliverReorderableList) ke skema "tukar
  // tempat" lewat tombol naik/turun -- lebih sederhana dan tidak
  // bergantung pada gesture drag yang gampang bikin state internal
  // list kacau (lihat riwayat bug sebelumnya: null-check exception +
  // list jadi tidak bisa discroll setelah drag).
  //
  // direction: -1 untuk naik (tukar dengan destinasi di atasnya),
  // +1 untuk turun (tukar dengan destinasi di bawahnya).
  //
  // Waktu tiba/pulang (arrivalTimesByDay, returnTimesByDay) disimpan
  // terpisah dari destinasi dan hanya berpasangan lewat INDEX, jadi
  // keduanya harus ikut ditukar bersamaan dengan destinasinya supaya
  // jam yang sudah diisi tidak tertukar antar destinasi.
  //
  // ============================================================

  void _swapDestination(int day, int index, int direction) {
    setState(() {
      final List<Map<String, dynamic>> destinations =
          normalizedDestinations[day] ?? [];

      final List<TimeOfDay?> arrivals = arrivalTimesByDay[day] ?? [];

      final List<TimeOfDay?> returns = returnTimesByDay[day] ?? [];

      final int targetIndex = index + direction;

      if (targetIndex < 0 || targetIndex >= destinations.length) {
        return;
      }

      final Map<String, dynamic> temp = destinations[index];
      destinations[index] = destinations[targetIndex];
      destinations[targetIndex] = temp;

      if (index < arrivals.length && targetIndex < arrivals.length) {
        final TimeOfDay? tempArrival = arrivals[index];
        arrivals[index] = arrivals[targetIndex];
        arrivals[targetIndex] = tempArrival;
      }

      if (index < returns.length && targetIndex < returns.length) {
        final TimeOfDay? tempReturn = returns[index];
        returns[index] = returns[targetIndex];
        returns[targetIndex] = tempReturn;
      }
    });
  }

  // ============================================================
  // FORMAT WAKTU
  // ============================================================

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return '--:--';
    }

    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // PILIH WAKTU
  // ============================================================

  Future<void> _selectTime({
    required TimeOfDay? initialTime,
    required Function(TimeOfDay) onSelected,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      onSelected(picked);
    });
  }

  // ============================================================
  // TOMBOL PANAH NAIK/TURUN (TUKAR POSISI DESTINASI)
  // ============================================================

  Widget _reorderArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 26,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFFF1F8FE) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ?  AppColors.mediumBlue : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  // ============================================================
  // TIME BUTTON
  // ============================================================

  Widget _timeButton({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        height: 50, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E3E3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF999999)), // CHANGED - font terkecil jadi 12
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION CARD
  // ============================================================

  Widget _locationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color:  AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.mediumBlue,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lokasi Awal',
                  style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                ),

                const SizedBox(height: 4),

                Text(
                  widget.startLocation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
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
  // DESTINATION CARD
  // ============================================================

  Widget _destinationCard(
    int day,
    int index,
    Map<String, dynamic> destination, {
    Key? key,
    required bool isFirst,
    required bool isLast,
  }) {
    final String name = destination['name']?.toString() ?? 'Destinasi';

    final String image = destination['image']?.toString() ?? '';

    final List<TimeOfDay?> arrivalTimes = arrivalTimesByDay[day] ?? [];

    final List<TimeOfDay?> returnTimes = returnTimesByDay[day] ?? [];

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color:  AppColors.borderColorLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // IMAGE + NAME
          // ======================================================

          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 78,
                  height: 78,
                  child: SmartImage(
                    imagePathOrUrl: image,
                    fit: BoxFit.cover,
                  ),

                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ),

              // ==================================================
              // TOMBOL NAIK/TURUN -- TUKAR POSISI DENGAN DESTINASI
              // TETANGGA (GANTI DARI DRAG & DROP, LIHAT
              // _swapDestination)
              // ==================================================

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _reorderArrowButton(
                    icon: Icons.keyboard_arrow_up,
                    enabled: !isFirst,
                    onTap: () => _swapDestination(day, index, -1),
                  ),
                  const SizedBox(height: 2),
                  _reorderArrowButton(
                    icon: Icons.keyboard_arrow_down,
                    enabled: !isLast,
                    onTap: () => _swapDestination(day, index, 1),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ======================================================
          // WAKTU TIBA
          // ======================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _timeButton(
                label: 'Tiba',
                time: arrivalTimes.length > index ? arrivalTimes[index] : null,
                onTap: () {
                  _selectTime(
                    initialTime: arrivalTimes.length > index
                        ? arrivalTimes[index]
                        : null,
                    onSelected: (time) {
                      arrivalTimesByDay[day]![index] = time;
                    },
                  );
                },
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  's/d',
                  style: TextStyle(fontSize: 14, color: AppColors.greyText),
                ),
              ),

              // ==================================================
              // WAKTU PULANG
              // ==================================================
              _timeButton(
                label: 'Pulang',
                time: returnTimes.length > index ? returnTimes[index] : null,
                onTap: () {
                  _selectTime(
                    initialTime: returnTimes.length > index
                        ? returnTimes[index]
                        : null,
                    onSelected: (time) {
                      returnTimesByDay[day]![index] = time;
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAY TAB
  // ============================================================

  Widget _buildDayTabs() {
    final List<int> days = normalizedDestinations.keys.toList()..sort();

    if (days.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 18),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) {
          return const SizedBox(width: 6);
        },
        itemBuilder: (context, index) {
          final int day = days[index];

          final bool isSelected = selectedDay == day;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDay = day;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ?  AppColors.mediumBlue
                    :  AppColors.lightGrey,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                'Hari $day',
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
  // DAY CONTENT
  // ============================================================

  // ============================================================
  // DAY CONTENT -- HEADER (SEMUA BAGIAN SEBELUM DAFTAR DESTINASI)
  // ============================================================

  Widget _buildDayContent() {
    final List<Map<String, dynamic>> destinations =
        normalizedDestinations[selectedDay] ?? [];

    final TimeOfDay? departureTime = departureTimesByDay[selectedDay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ========================================================
        // TITLE
        // ========================================================

        Text(
          'Hari $selectedDay',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          'Atur waktu perjalanan untuk hari ini',
          style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
        ),

        const SizedBox(height: 14),

        // ========================================================
        // TITIK KEBERANGKATAN
        // ========================================================
        const Text(
          'Titik Keberangkatan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),

        const SizedBox(height: 10),

        _locationCard(),

        const SizedBox(height: 12),

        // ========================================================
        // WAKTU BERANGKAT
        // ========================================================
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:  AppColors.lightBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppColors.mediumBlue,
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu keberangkatan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Berangkat dari lokasi awal',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText), // CHANGED - font terkecil jadi 12
                    ),
                  ],
                ),
              ),

              _timeButton(
                label: 'Berangkat',
                time: departureTime,
                onTap: () {
                  _selectTime(
                    initialTime: departureTime,
                    onSelected: (time) {
                      departureTimesByDay[selectedDay] = time;
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ========================================================
        // DESTINATION TITLE
        // ========================================================
        Row(
          children: [
            const Expanded(
              child: Text(
                'Destinasi Perjalanan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:  AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${destinations.length} lokasi',
                style: const TextStyle(
                  fontSize: 12, // CHANGED - font terkecil jadi 12
                  fontWeight: FontWeight.w600,
                  color: AppColors.mediumBlue,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ========================================================
        // DESTINATIONS -- TOMBOL NAIK/TURUN UNTUK UBAH URUTAN
        // (LIHAT _swapDestination)
        // ========================================================
        if (destinations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color:  AppColors.borderColorLight),
            ),
            child: const Column(
              children: [
                Icon(Icons.location_off, size: 32, color: Color(0xFFAAAAAA)),
                SizedBox(height: 8),
                Text(
                  'Belum ada destinasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
          )
        else
          ...List.generate(destinations.length, (index) {
            return _destinationCard(
              selectedDay,
              index,
              destinations[index],
              isFirst: index == 0,
              isLast: index == destinations.length - 1,
            );
          }),
      ],
    );
  }

  // ============================================================
  // VALIDASI WAKTU
  // ============================================================

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  bool _isTimeAfter(TimeOfDay first, TimeOfDay second) {
    return _timeToMinutes(first) > _timeToMinutes(second);
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> _handlePreview() async {
    // ------------------------------------------------------------
    // VALIDASI SETIAP HARI
    // ------------------------------------------------------------

    for (final entry in normalizedDestinations.entries) {
      final int day = entry.key;

      final List<Map<String, dynamic>> destinations = entry.value;

      final TimeOfDay? dayDeparture = departureTimesByDay[day];

      if (dayDeparture == null) {
        setState(() {
          selectedDay = day;
        });

        _showMessage('Tentukan waktu keberangkatan untuk Hari $day.');

        return;
      }

      for (int index = 0; index < destinations.length; index++) {
        final TimeOfDay? arrival = arrivalTimesByDay[day]![index];

        final TimeOfDay? returnTime = returnTimesByDay[day]![index];

        final String name =
            destinations[index]['name']?.toString() ?? 'destinasi';

        if (arrival == null || returnTime == null) {
          setState(() {
            selectedDay = day;
          });

          _showMessage(
            'Lengkapi waktu tiba dan pulang untuk $name di Hari $day.',
          );

          return;
        }

        if (_isTimeAfter(arrival, returnTime)) {
          setState(() {
            selectedDay = day;
          });

          _showMessage('Waktu tiba $name tidak boleh setelah waktu pulang.');

          return;
        }

        if (index == 0 && _isTimeAfter(dayDeparture, arrival)) {
          setState(() {
            selectedDay = day;
          });

          _showMessage(
            'Waktu tiba destinasi pertama tidak boleh sebelum waktu berangkat.',
          );

          return;
        }

        if (index > 0) {
          final TimeOfDay? previousReturn = returnTimesByDay[day]![index - 1];

          if (previousReturn != null && _isTimeAfter(previousReturn, arrival)) {
            setState(() {
              selectedDay = day;
            });

            _showMessage(
              'Waktu tiba $name harus setelah waktu pulang destinasi sebelumnya.',
            );

            return;
          }
        }
      }
    }

    // ------------------------------------------------------------
    // BENTUK DATA UNTUK PREVIEW
    // ------------------------------------------------------------

    final List<Map<String, dynamic>> dailySchedules = [];

// ------------------------------------------------------------
// DATA PERJALANAN (tripName, startDate, endDate, participants,
// vehicle, destination, dst) YANG DIGABUNG KE SETIAP HARI
// ------------------------------------------------------------
//
// Diletakkan sebelum field spesifik-hari di bawah (day,
// startLocation, departureTime, destinations) supaya kalau ada
// nama field yang sama, field spesifik-hari yang menang.
//
// ------------------------------------------------------------

final Map<String, dynamic> tripInfo = widget.travelData != null
    ? Map<String, dynamic>.from(widget.travelData!)
    : {};

// Fallback kalau layar ini dibuka tanpa lewat
// DestinationSelectionScreen (belum ditandai 'source' di sana) --
// lihat komentar initialDepartureTimesByDay dkk di atas untuk
// kegunaan field ini.
tripInfo.putIfAbsent('source', () => 'manual');

// ------------------------------------------------------------
// KOORDINAT LOKASI AWAL YANG DIPAKAI DI JADWAL
// ------------------------------------------------------------
//
// Prioritas: koordinat asli hasil pilih di peta/GPS
// (widget.startCoordinate). Kalau user tidak sempat memilihnya,
// dibuatkan titik dummy yang tetap jatuh di wilayah kabupaten/kota
// TUJUAN (tripInfo['destination'], mis. "Kabupaten Pesawaran") --
// bukan titik dummy tetap di satu tempat seperti sebelumnya --
// supaya peta rute di ItineraryPreviewScreen/ItineraryDetailScreen
// tetap masuk akal walau lokasi awal belum dipilih.
//
// Dihitung sekali di sini (bukan per hari) supaya titik dummy-nya
// konsisten di semua hari dalam satu jadwal yang sama.
// ------------------------------------------------------------

final LatLng effectiveStartCoordinate =
    widget.startCoordinate ??
    coordinateForRegency(
      tripInfo['destination'] as String?,
      seed: tripInfo['tripName'] ?? tripInfo['destination'],
    );

for (final entry in normalizedDestinations.entries) {
  final int day = entry.key;

  final List<Map<String, dynamic>> destinations = entry.value;

  dailySchedules.add({
    ...tripInfo,
    'day': day,
    'startLocation': widget.startLocation,
    // Koordinat lokasi awal, dipakai ItineraryDetailScreen untuk
    // menggambar titik + garis rute keberangkatan di peta. Disimpan
    // sebagai String supaya format-nya konsisten dengan
    // 'latitude'/'longitude' pada tiap item di 'destinations'
    // (lihat destinations_data.dart). Selalu diisi (lihat
    // effectiveStartCoordinate di atas) supaya peta rute tidak lagi
    // bergantung pada titik dummy tetap di ItineraryDetailScreen.
    'startLatitude': effectiveStartCoordinate.latitude.toString(),
    'startLongitude': effectiveStartCoordinate.longitude.toString(),
    'departureTime': _formatTime(
      departureTimesByDay[day],
    ),
    'destinations': List.generate(
      destinations.length,
      (index) {
        return {
          ...destinations[index],
          'arrivalTime': _formatTime(
            arrivalTimesByDay[day]![index],
          ),
          'departureTime': _formatTime(
            returnTimesByDay[day]![index],
          ),
        };
      },
    ),
  });
}

    // ------------------------------------------------------------
    // BUKA HALAMAN PREVIEW
    // ------------------------------------------------------------

final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) {
      return ItineraryPreviewScreen(
        dailySchedules: dailySchedules,
      );
    },
  ),
);

if (result != null) {
  Navigator.pop(
    context,
    result,
  );
}
  }

  // void _saveSchedule() {
  //   // ------------------------------------------------------------
  //   // VALIDASI SETIAP HARI
  //   // ------------------------------------------------------------

  //   for (final entry in normalizedDestinations.entries) {
  //     final int day = entry.key;

  //     final List<Map<String, dynamic>> destinations = entry.value;

  //     final TimeOfDay? dayDeparture = departureTimesByDay[day];

  //     // ----------------------------------------------------------
  //     // CEK WAKTU BERANGKAT
  //     // ----------------------------------------------------------

  //     if (dayDeparture == null) {
  //       setState(() {
  //         selectedDay = day;
  //       });

  //       _showMessage('Tentukan waktu keberangkatan untuk Hari $day.');

  //       return;
  //     }

  //     // ----------------------------------------------------------
  //     // CEK SETIAP DESTINASI
  //     // ----------------------------------------------------------

  //     for (int index = 0; index < destinations.length; index++) {
  //       final TimeOfDay? arrival = arrivalTimesByDay[day]![index];

  //       final TimeOfDay? returnTime = returnTimesByDay[day]![index];

  //       final String name =
  //           destinations[index]['name']?.toString() ?? 'destinasi';

  //       if (arrival == null || returnTime == null) {
  //         setState(() {
  //           selectedDay = day;
  //         });

  //         _showMessage(
  //           'Lengkapi waktu tiba dan pulang untuk $name di Hari $day.',
  //         );

  //         return;
  //       }

  //       // --------------------------------------------------------
  //       // TIBA TIDAK BOLEH SETELAH PULANG
  //       // --------------------------------------------------------

  //       if (_isTimeAfter(arrival, returnTime)) {
  //         setState(() {
  //           selectedDay = day;
  //         });

  //         _showMessage('Waktu tiba $name tidak boleh setelah waktu pulang.');

  //         return;
  //       }

  //       // --------------------------------------------------------
  //       // DESTINASI PERTAMA:
  //       // TIBA TIDAK BOLEH SEBELUM BERANGKAT
  //       // --------------------------------------------------------

  //       if (index == 0 && _isTimeAfter(dayDeparture, arrival)) {
  //         setState(() {
  //           selectedDay = day;
  //         });

  //         _showMessage(
  //           'Waktu tiba destinasi pertama tidak boleh sebelum waktu berangkat.',
  //         );

  //         return;
  //       }

  //       // --------------------------------------------------------
  //       // DESTINASI BERIKUTNYA:
  //       // TIDAK BOLEH TIBA SEBELUM DESTINASI SEBELUMNYA PULANG
  //       // --------------------------------------------------------

  //       if (index > 0) {
  //         final TimeOfDay? previousReturn = returnTimesByDay[day]![index - 1];

  //         if (previousReturn != null && _isTimeAfter(previousReturn, arrival)) {
  //           setState(() {
  //             selectedDay = day;
  //           });

  //           _showMessage(
  //             'Waktu tiba $name harus setelah waktu pulang destinasi sebelumnya.',
  //           );

  //           return;
  //         }
  //       }
  //     }
  //   }

  //   // ============================================================
  //   // BENTUK DATA HASIL
  //   // ============================================================

  //   final Map<String, dynamic> result = {
  //     'startLocation': widget.startLocation,

  //     'days': normalizedDestinations.map((day, destinations) {
  //       return MapEntry(day.toString(), {
  //         'departureTime': _formatTime(departureTimesByDay[day]),
  //         'destinations': List.generate(destinations.length, (index) {
  //           return {
  //             ...destinations[index],
  //             'arrivalTime': _formatTime(arrivalTimesByDay[day]![index]),
  //             'departureTime': _formatTime(returnTimesByDay[day]![index]),
  //           };
  //         }),
  //       });
  //     }),
  //   };

  //   // ============================================================
  //   // KEMBALI KE DESTINATION SELECTION
  //   // ============================================================

  //   Navigator.pop(context, result);
  // }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool hasDestinations = normalizedDestinations.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF333333),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        centerTitle: true,

        title: const Text(
          'Atur Waktu Perjalanan',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: !hasDestinations
            ? _buildEmptyPage()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        // ----------------------------------------
                        // DAY TABS
                        // ----------------------------------------

                        _buildDayTabs(),

                        // ----------------------------------------
                        // DAY CONTENT
                        // ----------------------------------------
                        _buildDayContent(),
                      ],
                    ),
                  ),

                  // ----------------------------------------------
                  // SAVE BUTTON
                  // ----------------------------------------------
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handlePreview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:  AppColors.mediumBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Lihat Preview',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // EMPTY PAGE
  // ============================================================

  Widget _buildEmptyPage() {
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
                Icons.location_off,
                color: AppColors.mediumBlue,
                size: 34,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Belum ada destinasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Silakan pilih destinasi terlebih dahulu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:  AppColors.mediumBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}