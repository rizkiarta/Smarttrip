import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:latlong2/latlong.dart';
import 'itinerary_preview_screen.dart';
import 'detail_destination_screen.dart';
import '../data/destinations_data.dart';
import '../services/route_service.dart';
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

  // ============================================================
  // STATUS "SEDANG MENGHITUNG JAM TIBA" PER HARI
  // ============================================================
  //
  // true selagi _recalculateArrivalTimes(day) menunggu hasil rute
  // asli dari fetchRealRoute (route_service.dart) -- dipakai untuk
  // menampilkan indikator loading di jam tiba supaya user tahu
  // angkanya belum final, bukan cuma jam lama yang nyangkut. Lihat
  // _buildDestinationCard.
  //
  // ============================================================

  late Map<int, bool> isCalculatingByDay;

  // Token generasi per hari -- setiap kali _recalculateArrivalTimes
  // dipanggil ulang untuk hari yang sama (mis. user ganti jam
  // berangkat lagi sebelum fetch sebelumnya kelar), token dinaikkan.
  // Hasil dari pemanggilan yang lebih lama dibuang begitu selesai,
  // supaya tidak menimpa hasil dari pemanggilan yang lebih baru.
  final Map<int, int> _recalculateGenerationByDay = {};

  @override
  void initState() {
    super.initState();

    normalizedDestinations = _prepareDestinations();

    departureTimesByDay = {};

    arrivalTimesByDay = {};

    returnTimesByDay = {};

    isCalculatingByDay = {};

    // ============================================================
    // WAKTU KEBERANGKATAN DARI TRAVEL INFORMATION SCREEN
    // ============================================================
    //
    // Jam keberangkatan yang sudah diisi user di TravelInformationScreen
    // (widget.travelData['startTime']) dipakai sebagai nilai awal untuk
    // Hari 1, supaya user tidak perlu mengisi ulang jam yang sama di
    // sini. Hari-hari berikutnya tetap kosong seperti biasa karena
    // TravelInformationScreen hanya menanyakan jam keberangkatan untuk
    // hari pertama perjalanan.
    //
    // ============================================================

    final TimeOfDay? travelStartTime =
        widget.travelData?['startTime'] as TimeOfDay?;

    for (final entry in normalizedDestinations.entries) {
      final int day = entry.key;

      final int destinationCount = entry.value.length;

      // Prioritas: waktu yang sudah pernah diisi (mode edit, lihat
      // initialDepartureTimesByDay dkk di atas). Kalau tidak ada,
      // untuk Hari 1 dipakai jam keberangkatan dari Travel Information.
      // Hari lainnya tetap kosong seperti alur normal.

      departureTimesByDay[day] = widget.initialDepartureTimesByDay?[day] ??
          (day == 1 ? travelStartTime : null);

      final List<TimeOfDay?>? initialReturns =
          widget.initialReturnTimesByDay?[day];

      returnTimesByDay[day] =
          (initialReturns != null && initialReturns.length == destinationCount)
              ? List<TimeOfDay?>.from(initialReturns)
              : List<TimeOfDay?>.filled(destinationCount, null);

      // ==========================================================
      // WAKTU TIBA -- TIDAK LAGI DIISI MANUAL
      // ==========================================================
      //
      // Waktu tiba sekarang dihitung otomatis (lihat
      // _recalculateArrivalTimes di bawah) berdasarkan jarak tempuh
      // riil dari titik sebelumnya (lokasi awal / destinasi
      // sebelumnya) ke destinasi ini, dipadukan dengan jam
      // berangkat/pulang yang berlaku. initialArrivalTimesByDay
      // (mis. dari mode edit) sengaja tidak dipakai lagi supaya
      // waktu tiba selalu konsisten dengan jarak & jam yang berlaku
      // sekarang, bukan nilai lama yang mungkin sudah tidak akurat.
      //
      // ==========================================================

      arrivalTimesByDay[day] = List<TimeOfDay?>.filled(destinationCount, null);
    }

    if (normalizedDestinations.isNotEmpty) {
      selectedDay = normalizedDestinations.keys.first;
    }

    // ============================================================
    // HITUNG WAKTU TIBA AWAL UNTUK SEMUA HARI
    // ============================================================

    for (final int day in normalizedDestinations.keys) {
      _recalculateArrivalTimes(day);
    }
  }

  // ============================================================
  // HITUNG OTOMATIS WAKTU TIBA SETIAP DESTINASI (BERDASARKAN JARAK
  // TEMPUH SESUAI MAPS)
  // ============================================================
  //
  // Dijalankan ulang tiap kali ada yang bisa mengubah hasil hitungan:
  // jam berangkat berubah, jam pulang salah satu destinasi berubah,
  // atau urutan destinasi ditukar (lihat pemanggilnya masing-masing).
  //
  // Logikanya menyusuri destinasi satu per satu:
  // - Destinasi pertama: waktu tiba = jam berangkat dari lokasi awal
  //   + durasi rute ASLI (fetchRealRoute, route_service.dart -- SAMA
  //   PERSIS dengan yang dipakai peta preview rute di RouteScreen)
  //   dari koordinat lokasi awal ke koordinat destinasi pertama.
  // - Destinasi berikutnya: waktu tiba = jam PULANG dari destinasi
  //   sebelumnya + durasi rute asli dari koordinat destinasi
  //   sebelumnya ke destinasi ini.
  //
  // Kalau jam pulang destinasi sebelumnya belum diisi user, rantai
  // perhitungan berhenti di situ (destinasi berikutnya jadi '--:--'
  // sampai jam pulang yang jadi acuannya diisi).
  //
  // Kalau koordinat salah satu titik tidak diketahui, dipakai waktu
  // tempuh fallback (1 jam untuk destinasi pertama, 30 menit untuk
  // destinasi berikutnya). Kalau koordinat diketahui tapi
  // fetchRealRoute gagal total (offline dkk), route_service.dart
  // sendiri yang jatuh ke estimasi garis lurus -- supaya fallback-nya
  // konsisten dengan fallback yang dipakai RouteScreen.
  //
  // ASYNC karena sekarang benar-benar fetch ke backend/OSRM (bukan
  // rumus lokal lagi) -- lihat isCalculatingByDay untuk indikator
  // loading & _recalculateGenerationByDay untuk pengaman kalau
  // dipanggil ulang sebelum fetch sebelumnya selesai.
  //
  // ============================================================

  Future<void> _recalculateArrivalTimes(int day) async {
    final List<Map<String, dynamic>> destinations =
        normalizedDestinations[day] ?? [];

    if (destinations.isEmpty) {
      return;
    }

    final int myGeneration = (_recalculateGenerationByDay[day] ?? 0) + 1;
    _recalculateGenerationByDay[day] = myGeneration;

    if (mounted) {
      setState(() {
        isCalculatingByDay[day] = true;
      });
    }

    final String? vehicle = widget.travelData?['vehicle'] as String?;

    final List<TimeOfDay?> returns = returnTimesByDay[day] ??
        List<TimeOfDay?>.filled(destinations.length, null);

    final List<TimeOfDay?> arrivals =
        List<TimeOfDay?>.filled(destinations.length, null);

    LatLng? previousCoordinate = widget.startCoordinate;

    TimeOfDay? previousTime = departureTimesByDay[day];

    for (int i = 0; i < destinations.length; i++) {
      if (previousTime == null) {
        break;
      }

      final LatLng? destinationCoordinate =
          coordinateOfDestination(destinations[i]);

      Duration travelTime;

      if (previousCoordinate != null && destinationCoordinate != null) {
        final RouteResult route = await fetchRealRoute(
          previousCoordinate,
          destinationCoordinate,
          vehicle: vehicle,
        );

        travelTime = route.duration;
      } else {
        travelTime = Duration(minutes: i == 0 ? 60 : 30);
      }

      // Sudah ada pemanggilan yang lebih baru untuk hari ini selagi
      // fetch di atas berjalan (mis. user keburu ganti jam lagi) --
      // buang hasil ini, biarkan pemanggilan yang lebih baru yang
      // menang.
      if (_recalculateGenerationByDay[day] != myGeneration) {
        return;
      }

      arrivals[i] = _addDurationToTime(previousTime, travelTime);

      previousCoordinate = destinationCoordinate;
      previousTime = i < returns.length ? returns[i] : null;
    }

    if (_recalculateGenerationByDay[day] != myGeneration) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      arrivalTimesByDay[day] = arrivals;
      isCalculatingByDay[day] = false;
    });
  }

  // ============================================================
  // TAMBAHKAN DURASI KE SEBUAH JAM (DIBUNGKUS 24 JAM)
  // ============================================================

  TimeOfDay _addDurationToTime(TimeOfDay time, Duration duration) {
    const int minutesPerDay = 24 * 60;

    final int totalMinutes = time.hour * 60 + time.minute + duration.inMinutes;

    final int normalized = totalMinutes % minutesPerDay;

    final int wrapped = normalized < 0 ? normalized + minutesPerDay : normalized;

    return TimeOfDay(hour: wrapped ~/ 60, minute: wrapped % 60);
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
    final List<Map<String, dynamic>> destinations =
        normalizedDestinations[day] ?? [];

    final List<TimeOfDay?> returns = returnTimesByDay[day] ?? [];

    final int targetIndex = index + direction;

    if (targetIndex < 0 || targetIndex >= destinations.length) {
      return;
    }

    setState(() {
      // Waktu tiba TIDAK ikut ditukar manual di sini lagi -- akan
      // dihitung ulang dari nol oleh _recalculateArrivalTimes di
      // bawah begitu urutan destinasinya berubah.

      final Map<String, dynamic> temp = destinations[index];
      destinations[index] = destinations[targetIndex];
      destinations[targetIndex] = temp;

      if (index < returns.length && targetIndex < returns.length) {
        final TimeOfDay? tempReturn = returns[index];
        returns[index] = returns[targetIndex];
        returns[targetIndex] = tempReturn;
      }
    });

    // Urutan berubah -> jarak tempuh antar destinasi ikut berubah,
    // jadi waktu tiba perlu dihitung ulang. Dipanggil DI LUAR
    // setState di atas karena sekarang async (fetch rute asli) dan
    // sudah mengatur setState-nya sendiri (lihat isCalculatingByDay).
    _recalculateArrivalTimes(day);
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
  //
  // Tampilan & cara pilih jam di sini disamakan dengan yang dipakai
  // di TravelInformationScreen (_selectStartTime) -- bottom sheet
  // dengan scroll wheel jam/menit -- supaya pengalaman memilih jam
  // konsisten di seluruh alur perencanaan perjalanan, bukan dialog
  // jam bawaan Flutter lagi.
  //
  // ============================================================

  // Return value: jam yang dipilih user, atau null kalau bottom sheet
  // ditutup tanpa memilih (batal). Dipakai pemanggil untuk tahu kapan
  // perlu memicu _recalculateArrivalTimes lagi -- supaya batal pilih
  // jam tidak ikut memicu fetch rute ulang yang sia-sia.
  Future<TimeOfDay?> _selectTime({
    required TimeOfDay? initialTime,
    required Function(TimeOfDay) onSelected,
    String title = 'Pilih Waktu',
  }) async {
    final TimeOfDay initial = initialTime ?? const TimeOfDay(hour: 8, minute: 0);

    int selectedHour = initial.hour;
    int selectedMinute = (initial.minute ~/ 5) * 5;

    final FixedExtentScrollController hourController =
        FixedExtentScrollController(initialItem: selectedHour);
    final FixedExtentScrollController minuteController =
        FixedExtentScrollController(initialItem: selectedMinute ~/ 5);

    final TimeOfDay? picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.greyText,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Atur waktu sendiri',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            IgnorePointer(
                              child: Container(
                                height: 40,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: hourController,
                                    itemExtent: 40,
                                    looping: true,
                                    selectionOverlay: const SizedBox.shrink(),
                                    onSelectedItemChanged: (index) {
                                      setSheetState(() => selectedHour = index);
                                    },
                                    children: List.generate(24, (i) {
                                      return Center(
                                        child: Text(
                                          i.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                                const Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: minuteController,
                                    itemExtent: 40,
                                    looping: true,
                                    selectionOverlay: const SizedBox.shrink(),
                                    onSelectedItemChanged: (index) {
                                      setSheetState(
                                        () => selectedMinute = index * 5,
                                      );
                                    },
                                    children: List.generate(12, (i) {
                                      final int m = i * 5;
                                      return Center(
                                        child: Text(
                                          m.toString().padLeft(2, '0'),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.pop(
                              context,
                              TimeOfDay(
                                hour: selectedHour,
                                minute: selectedMinute,
                              ),
                            );
                          },
                          child: const Text(
                            'Pilih Jam Ini',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    hourController.dispose();
    minuteController.dispose();

    if (picked == null) {
      return null;
    }

    setState(() {
      onSelected(picked);
    });

    return picked;
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
          color: enabled ? AppColors.lightBlue : AppColors.lightGrey,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primaryBlue : AppColors.doneGrey,
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
          border: Border.all(color: AppColors.fieldBorder),
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
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText), // CHANGED - font terkecil jadi 12
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TIME DISPLAY (VERSI TIDAK BISA DIKETUK, UNTUK WAKTU TIBA YANG
  // DIHITUNG OTOMATIS)
  // ============================================================

  Widget _timeDisplay({
    required String label,
    required TimeOfDay? time,
    bool isCalculating = false,
  }) {
    return Container(
      width: 92,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
          const SizedBox(height: 2),
          // ==============================================================
          // SEDANG DIHITUNG (fetch rute asli ke backend/OSRM) -- tampilkan
          // spinner kecil menggantikan teks jam supaya user tahu angkanya
          // belum final, bukan sekadar '--:--' yang terlihat seperti error.
          // ==============================================================
          isCalculating
              ? const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryBlue,
                  ),
                )
              : Text(
                  _formatTime(time),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
        ],
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
        border: Border.all(color: AppColors.borderColor),
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
              color: AppColors.imagePlaceholderBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on,
              color: AppColors.primaryBlue,
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
                    color: AppColors.darkText,
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
  // PREDIKSI KEPADATAN (DUMMY, DETERMINISTIK PER DESTINASI)
  // ============================================================
  //
  // TODO(backend): ganti dengan pemanggilan API prediksi kepadatan
  // sungguhan. Disamakan formatnya ('Sepi'/'Sedang'/'Ramai') dan cara
  // hitungnya (hash id/nama, bukan acak) dengan yang dipakai di
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
  // Warnanya disamakan dengan badge status di AIItineraryScreen /
  // CrowdPredictionScreen (Sepi = hijau, Sedang = kuning, Ramai =
  // merah) supaya artinya konsisten di seluruh aplikasi.
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
  // yang sama dengan yang dipakai di DestinationSelectionScreen
  // (lihat _openDetail di sana), supaya user bisa lihat info
  // lengkap destinasi tanpa harus balik ke layar pemilihan destinasi.
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
            mainImage: destination['image']?.toString() ?? '',
            description: destination['description']?.toString() ?? '',
          );
        },
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

    final String rating = destination['rating']?.toString() ?? '0.0';

    final String reviewsCount = destination['reviewsCount']?.toString() ?? '0';

    final String crowdStatus = _crowdStatusFor(destination);

    final List<TimeOfDay?> arrivalTimes = arrivalTimesByDay[day] ?? [];

    final List<TimeOfDay?> returnTimes = returnTimesByDay[day] ?? [];

    return GestureDetector(
      // ========================================================
      // BUKA DETAIL DESTINASI KALAU KARTUNYA DIKETUK
      // ========================================================
      //
      // Tombol naik/turun & tombol jam di dalam kartu ini punya
      // GestureDetector sendiri-sendiri, jadi tetap berfungsi normal
      // (tidak ikut membuka detail) meskipun kartunya sekarang bisa
      // diketuk juga.
      //
      // ========================================================
      onTap: () => _openDestinationDetail(destination),
      child: Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColorLight),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ==============================================
                    // RATING + KEPADATAN
                    // ==============================================
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
              // ==================================================
              // WAKTU TIBA -- DIHITUNG OTOMATIS, TIDAK BISA DIKETUK
              // ==================================================
              //
              // Dihitung dari jarak tempuh sesuai maps (lihat
              // _recalculateArrivalTimes), jadi bukan lagi input
              // manual seperti waktu pulang di sebelahnya.
              //
              // ==================================================
              _timeDisplay(
                label: 'Tiba',
                time: arrivalTimes.length > index ? arrivalTimes[index] : null,
                isCalculating: isCalculatingByDay[day] ?? false,
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
                    title: 'Waktu Pulang dari $name',
                    onSelected: (time) {
                      returnTimesByDay[day]![index] = time;
                    },
                  ).then((picked) {
                    // Jam pulang destinasi ini jadi acuan waktu tiba
                    // destinasi berikutnya, jadi perlu dihitung ulang
                    // -- tapi cuma kalau user benar-benar memilih jam
                    // (bukan batal).
                    if (picked != null) {
                      _recalculateArrivalTimes(day);
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 6),

          const Center(
            child: Text(
              'Waktu tiba dihitung otomatis dari jarak tempuh',
              style: TextStyle(fontSize: 10, color: AppColors.mutedText),
            ),
          ),
        ],
      ),
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
                    ? AppColors.primaryBlue
                    : AppColors.lightGrey,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                'Hari $day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.greyText,
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
        // TITIK KEBERANGKATAN
        // ========================================================
        //
        // Judul "Hari X" dan subjudul "Atur waktu perjalanan untuk
        // hari ini" sengaja dihapus dari sini -- info hari sudah ada
        // di tab hari di atas (_buildDayTabs), jadi langsung masuk ke
        // konten supaya tidak ada pengulangan informasi.
        // ========================================================
        const Text(
          'Titik Keberangkatan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
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
            color: AppColors.lightBlue,
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
                  color: AppColors.primaryBlue,
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
                        color: AppColors.darkText,
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
                    title: 'Waktu Berangkat',
                    onSelected: (time) {
                      departureTimesByDay[selectedDay] = time;
                    },
                  ).then((picked) {
                    // Jam berangkat berubah -> waktu tiba destinasi
                    // pertama (dan yang lain lewat rantai jam pulang)
                    // perlu dihitung ulang -- tapi cuma kalau user
                    // benar-benar memilih jam (bukan batal).
                    if (picked != null) {
                      _recalculateArrivalTimes(selectedDay);
                    }
                  });
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
                  color: AppColors.darkText,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${destinations.length} lokasi',
                style: const TextStyle(
                  fontSize: 12, // CHANGED - font terkecil jadi 12
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
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
              border: Border.all(color: AppColors.borderColorLight),
            ),
            child: const Column(
              children: [
                Icon(Icons.location_off, size: 32, color: AppColors.mutedText),
                SizedBox(height: 8),
                Text(
                  'Belum ada destinasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
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

        if (returnTime == null) {
          setState(() {
            selectedDay = day;
          });

          _showMessage(
            'Tentukan waktu pulang untuk $name di Hari $day.',
          );

          return;
        }

        if (arrival == null) {
          setState(() {
            selectedDay = day;
          });

          _showMessage(
            'Waktu tiba $name belum bisa dihitung. Pastikan waktu berangkat '
            'dan waktu pulang destinasi sebelumnya di Hari $day sudah diisi.',
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
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: () {
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
          'Atur Waktu Perjalanan',
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 18,
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
                          backgroundColor: AppColors.primaryBlue,
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
                color: AppColors.primaryBlue,
                size: 34,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Belum ada destinasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
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
                  backgroundColor: AppColors.primaryBlue,
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