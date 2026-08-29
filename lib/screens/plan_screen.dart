import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'travel_information_screen.dart';
import 'itinerary_detail_screen.dart';
import '../services/saved_itinerary_service.dart';
import '../data/destinations_data.dart';
import 'manual_schedule_screen.dart';
import 'ai_itinerary_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/smart_image.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';



class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {

  @override
  void initState() {
    super.initState();
    if (ApiService.instance.isAuthenticated) {
      SavedItineraryService.instance.fetchItineraries();
    }
  }


  // ============================================================
  // BUILD
  // ============================================================


  @override
  Widget build(BuildContext context) {
    if (!ApiService.instance.isAuthenticated) {
      return _buildGuestScaffold(context);
    }
    return ValueListenableBuilder<List<List<Map<String, dynamic>>>>(
      valueListenable: SavedItineraryService.instance.itineraries,
      builder: (context, savedItineraries, _) {
        final bool hasItinerary = savedItineraries.isNotEmpty;

        return _buildScaffold(context, hasItinerary, savedItineraries);
      },
    );
  }

  Widget _buildGuestScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 285,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/background_header.png'), fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rencana', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text('Kelola semua itinerary perjalananmu di Lampung', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(42), topRight: Radius.circular(42))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 36),
                          ),
                          const SizedBox(height: 18),
                          const Text('Masuk untuk melihat rencana', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          const SizedBox(height: 8),
                          const Text('Simpan dan kelola itinerary perjalananmu. Masuk untuk mulai membuat rencana.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4)),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 180, height: 44,
                            child: ElevatedButton(
                              onPressed: () => showLoginRequiredSheet(context, action: 'membuat dan melihat rencana perjalanan'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const Spacer(flex: 7),
                        ],
                      ),
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

  Widget _buildScaffold(
    BuildContext context,
    bool hasItinerary,
    List<List<Map<String, dynamic>>> savedItineraries,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================================================
      // BODY
      // ==========================================================
      body: Stack(
        children: [
          // ======================================================
          // BLUE HEADER
          // ======================================================

          Container(
            height: 285,
            width: double.infinity,

            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background_header.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ======================================================
          // MAIN CONTENT
          // ======================================================
          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Rencana',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Kelola semua itinerary perjalananmu di Lampung',

                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // WHITE CONTENT
                // ==================================================
                Expanded(
                  child: Container(
                    width: double.infinity,

                    decoration: const BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(42),
                        topRight: Radius.circular(42),
                      ),
                    ),

                    // ==================================================
                    // CONDITION
                    // ==================================================
                    //
                    // Kalau belum ada itinerary, konten dibangun langsung
                    // sebagai Expanded (bukan SingleChildScrollView) supaya
                    // bisa pakai Spacer buat naruh isi di tengah -- persis
                    // seperti TripScreen._buildEmptyState. Kalau sudah ada
                    // isinya, tetap pakai SingleChildScrollView seperti
                    // sebelumnya karena daftar itinerary bisa panjang dan
                    // perlu bisa di-scroll.
                    //
                    // ==================================================
                    child: !hasItinerary
                        ? _buildEmptyState(context)
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),

                            padding: const EdgeInsets.fromLTRB(20, 32, 20, 110),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                _buildItineraryList(context, savedItineraries),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // FLOATING ADD BUTTON
          // ======================================================
          if (hasItinerary)
            Positioned(
              right: 22,
              bottom: 88,

              child: GestureDetector(
                onTap: () {
                  if (!requireAuth(context, action: 'membuat itinerary baru')) return;
                  _openTravelInformation(context);
                },

                child: Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: AppColors.darkBlue,

                    shape: BoxShape.circle,

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),

                        blurRadius: 8,

                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: const Icon(Icons.add, color: Colors.white, size: 32),
                ),
              ),
            ),
        ],
      ),

      // ==========================================================
      // BOTTOM NAVIGATION
      // ==========================================================
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(BuildContext context) {
    // Layout disamakan PERSIS dengan TripScreen._buildEmptyState:
    // Padding horizontal 36 membungkus seluruh Column, lalu isinya
    // diposisikan pakai Spacer(flex: 5) di atas dan Spacer(flex: 7)
    // di bawah -- bukan SizedBox tinggi tetap + mainAxisAlignment
    // center seperti sebelumnya. Ini butuh parent yang bounded
    // (Expanded), bukan SingleChildScrollView, sama seperti di
    // TripScreen.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),

      child: Column(
        children: [
          const Spacer(flex: 5),

          // ======================================================
          // LOGO ICON
          // ======================================================

          SizedBox(
            width: 100,
            height: 100,

            child: Image.asset(
              'assets/images/smarttrip_logo_icon.png',

              width: 55,
              height: 55,

              fit: BoxFit.contain,

              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.map_outlined,
                  size: 60,
                  color: AppColors.primaryBlue,
                );
              },
            ),
          ),

          const SizedBox(height: 26),

          // ======================================================
          // TITLE
          // ======================================================
          const Text(
            'Belum ada itinerary',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),

          const SizedBox(height: 8),

          // ======================================================
          // DESCRIPTION
          // ======================================================

          const Text(
            'Yuk buat rencana perjalananmu dan temukan destinasi wisata terbaik di Lampung.',

            textAlign: TextAlign.center,

            style: TextStyle(fontSize: 14, color: AppColors.greyText, height: 1.4),
          ),

          const SizedBox(height: 26),

          // ======================================================
          // BUTTON BUAT ITINERARY
          // ======================================================
          SizedBox(
            width: 180,
            height: 45,

            child: ElevatedButton(
              onPressed: () {
                if (!requireAuth(context, action: 'membuat itinerary')) return;
                _openTravelInformation(context);
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,

                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text(
                'Buat Itinerary',

                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const Spacer(flex: 7),
        ],
      ),
    );
  }

  // ============================================================
  // DAFTAR ITINERARY (BISA LEBIH DARI SATU)
  // ============================================================

  Widget _buildItineraryList(
    BuildContext context,
    List<List<Map<String, dynamic>>> savedItineraries,
  ) {
    return Column(
      children: [
        for (final savedItinerary in savedItineraries)
          _buildItineraryCard(context, savedItinerary),
      ],
    );
  }

  // ============================================================
  // GAMBAR CARD -- IKUT DESTINASI PERTAMA YANG DIKUNJUNGI
  // ============================================================
  //
  // Sebelumnya selalu 'assets/images/danau_ranau.jpg' (hardcode,
  // tidak sesuai destinasi aslinya). Sekarang diambil dari
  // destinasi pertama Hari 1 (itinerary.first['destinations'] sudah
  // dalam urutan kunjungan yang sebenarnya, lihat _swapDestination/
  // _reorderStop). Kalau tidak ada gambarnya (mis. itinerary kosong
  // atau field 'image' tidak diisi), tetap fallback ke gambar lama
  // supaya card tidak pernah kosong.
  //
  // ============================================================

  String _cardImagePath(List<Map<String, dynamic>> itinerary) {
    const String fallback = 'assets/images/danau_ranau.jpg';

    if (itinerary.isEmpty) {
      return fallback;
    }

    for (final day in itinerary) {
      final dynamic destinations = day['destinations'];
      if (destinations is List) {
        for (final dest in destinations) {
          if (dest is Map) {
            for (final key in ['image', 'main_image', 'mainImage', 'photo', 'cover_image', 'image_url']) {
              final val = dest[key]?.toString().trim();
              if (val != null && val.isNotEmpty && val != 'null') {
                return val;
              }
            }
            final String destId = dest['id']?.toString() ?? '';
            final String destName = dest['name']?.toString() ?? '';
            final liveDest = findDestinationById(destId) ?? findDestinationByName(destName);
            if (liveDest != null && liveDest['image'] != null && liveDest['image']!.isNotEmpty) {
              return liveDest['image']!;
            }
          }
        }
      }
    }

    return fallback;
  }

  // ============================================================
  // ID ITINERARY (DIPAKAI UNTUK HAPUS YANG TEPAT)
  // ============================================================

  String? _itineraryId(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) {
      return null;
    }

    return itinerary.first['itineraryId']?.toString();
  }

  // ============================================================
  // SATU KARTU ITINERARY
  // ============================================================

  Widget _buildItineraryCard(
    BuildContext context,
    List<Map<String, dynamic>> savedItinerary,
  ) {
    // ======================================================
    // DATA ITINERARY INI
    // ======================================================

    final itinerary = savedItinerary;

    // ======================================================
    // RENTANG TANGGAL (DARI startDate & endDate)
    // ======================================================
    //
    // 'dateRange' tidak pernah diisi di mana pun sepanjang alur
    // (Travel Information -> ... -> Manual Schedule), jadi dihitung
    // di sini dari startDate/endDate yang sekarang memang ikut
    // terbawa ke setiap hari di itinerary. Konsisten dengan cara
    // ItineraryDetailScreen menampilkan tanggal.
    //
    // ======================================================

    final String dateRangeText = _formatDateRange(
      itinerary.isNotEmpty ? itinerary.first['startDate'] : null,
      itinerary.isNotEmpty ? itinerary.first['endDate'] : null,
    );

    // Hitung total destinasi
    int totalDestinations = 0;

    for (final day in itinerary) {
      final destinations = day['destinations'];

      if (destinations is List) {
        totalDestinations += destinations.length;
      }
    }

    return Column(
      children: [
        // ======================================================
        // ITINERARY CARD
        // ======================================================

        GestureDetector(
          onTap: () {
            if (savedItinerary.isEmpty) {
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ItineraryDetailScreen(itinerary: savedItinerary);
                },
              ),
            );
          },

          child: Container(
            width: double.infinity,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color:  AppColors.borderColor),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ==================================================
                // IMAGE
                // ==================================================

                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),

                      child: SizedBox(
                        width: double.infinity,

                        height: 145,

                        child: SmartImage(
                          imagePathOrUrl: _cardImagePath(itinerary),
                          fit: BoxFit.cover,
                        ),

                      ),
                    ),

                    // =================================================
                    // THREE DOT BUTTON
                    // =================================================
                    Positioned(
                      right: 10,
                      top: 10,

                      child: GestureDetector(
                        onTap: () {
                          _showItineraryMenu(context, savedItinerary);
                        },

                        child: Container(
                          width: 34,
                          height: 34,

                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),

                            shape: BoxShape.circle,
                          ),

                          child: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ==================================================
                // CARD INFORMATION
                // ==================================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 15),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // =============================================
                      // TITLE
                      // =============================================

                      Text(
                        _tripTitle(itinerary),

                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // =============================================
                      // DATE + DESTINATION + PEOPLE
                      // =============================================
                      Row(
                        children: [
                          Text(
                            dateRangeText,

                            style: const TextStyle(
                              fontSize: 12, // CHANGED - font terkecil jadi 12
                              color: AppColors.greyText,
                            ),
                          ),

                          _buildDot(),

                          Text(
                            '$totalDestinations Destinasi',

                            style: const TextStyle(
                              fontSize: 12, // CHANGED - font terkecil jadi 12
                              color: AppColors.greyText,
                            ),
                          ),

                          _buildDot(),

                          Text(
                            _formatParticipants(itinerary),

                            style: const TextStyle(
                              fontSize: 12, // CHANGED - font terkecil jadi 12
                              color: AppColors.greyText,
                            ),
                          ),
                        ],
                      ),

                      // =============================================
                      // BUDGET
                      // =============================================
                      //
                      // Field 'budget' sebenarnya TIDAK PERNAH diisi di
                      // manapun sepanjang alur (TravelInformationScreen
                      // -> ManualScheduleScreen/AIItineraryScreen), dan
                      // destinations_data.dart juga tidak punya data
                      // harga apa pun untuk dihitung. Sebelumnya box ini
                      // selalu menampilkan angka hardcode 'Rp. 5.100.000'
                      // yang sama sekali tidak sesuai itinerary yang
                      // sebenarnya -- jadi sekarang box ini disembunyikan
                      // kalau memang belum ada data budget beneran,
                      // daripada menampilkan angka yang salah/palsu.
                      if (itinerary.isNotEmpty &&
                          itinerary.first['budget'] != null &&
                          itinerary.first['budget'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6, // CHANGED - padding menyesuaikan font yang lebih besar
                          ),

                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F4FF),

                            borderRadius: BorderRadius.circular(5),
                          ),

                          child: Text(
                            'Estimasi Budget:  ${itinerary.first['budget']}',

                            style: const TextStyle(
                              fontSize: 12, // CHANGED - font terkecil jadi 12
                              color: AppColors.darkBlue,
                              fontWeight: FontWeight.w500,
                            ),
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

        const SizedBox(height: 20),
      ],
    );
  }

  // ============================================================
  // JUDUL TRIP (DENGAN FALLBACK YANG BENAR)
  // ============================================================
  //
  // Sebelumnya cuma cek `!= null`. Padahal tripName hasil
  // `.trim()` di TravelInformationScreen bisa jadi String kosong
  // ('') kalau user memang tidak mengisi -- itu BUKAN null, jadi
  // lolos cek lama dan menampilkan judul kosong di card. Sekarang
  // dicek `.isNotEmpty` juga, sama seperti pola yang sudah dipakai
  // ItineraryDetailScreen._buildTripInformation.
  // ============================================================

  String _tripTitle(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) {
      return 'Explore Lampung Barat';
    }

    final String tripName = itinerary.first['tripName']?.toString().trim() ?? '';

    return tripName.isNotEmpty ? tripName : 'Explore Lampung Barat';
  }

  // ============================================================
  // FORMAT JUMLAH PESERTA
  // ============================================================
  //
  // 'participants' formatnya beda tergantung jalur yang dipakai
  // user: jalur manual (TravelInformationScreen._handleChooseDestination)
  // menyimpannya sebagai String "2 Orang", tapi jalur AI
  // (AIItineraryScreen._handleNext meneruskan travelData['participants']
  // apa adanya) bisa berupa angka mentah. Fungsi ini menormalkan
  // keduanya supaya card selalu menampilkan format yang sama.
  // ============================================================

  String _formatParticipants(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) {
      return '2 Orang';
    }

    final dynamic raw = itinerary.first['participants'];

    if (raw == null) {
      return '2 Orang';
    }

    final String text = raw.toString().trim();

    if (text.isEmpty) {
      return '2 Orang';
    }

    return text.toLowerCase().contains('orang') ? text : '$text Orang';
  }

  // ============================================================
  // FORMAT RENTANG TANGGAL
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatDateRange(dynamic rawStart, dynamic rawEnd) {
    final DateTime? startDate = _parseDate(rawStart);
    final DateTime? endDate = _parseDate(rawEnd);

    if (startDate == null || endDate == null) {
      return 'Perjalanan Lampung';
    }

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final String start = '${startDate.day} ${months[startDate.month - 1]}';

    final String end =
        '${endDate.day} ${months[endDate.month - 1]} ${endDate.year}';

    return '$start – $end';
  }


  // ============================================================
  // SMALL DOT
  // ============================================================

  Widget _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),

      child: Text('•', style: TextStyle(fontSize: 12, color: AppColors.greyText)), // CHANGED - font terkecil jadi 12
    );
  }

  // ============================================================
  // OPEN TRAVEL INFORMATION
  // ============================================================

  Future<void> _openTravelInformation(BuildContext context) async {
    // ==========================================================
    // TIDAK PERLU LAGI MENAMPUNG HASIL SECARA MANUAL
    // ==========================================================
    //
    // Itinerary yang berhasil dibuat sudah disimpan langsung ke
    // SavedItineraryService di ItineraryPreviewScreen (saat tombol
    // "Simpan Jadwal" ditekan). Widget ini (PlanScreen) sudah
    // mendengarkan service tersebut lewat ValueListenableBuilder di
    // build(), jadi begitu data berubah, kartu itinerary otomatis
    // ter-update -- apa pun jalur navigasi yang dipakai user untuk
    // kembali ke sini.
    //
    // ==========================================================

    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {
          return const TravelInformationScreen();
        },
      ),
    );
  }

  // ============================================================
  // EDIT ITINERARY -- BALIK KE ATUR MANUAL / HASIL GENERATE
  // (SEBELUM PREVIEW), BUKAN KE TRAVELINFORMATIONSCREEN DARI NOL
  // ============================================================
  //
  // Sebelumnya "Edit Itinerary" cuma memanggil _openTravelInformation,
  // yaitu membuka ulang TravelInformationScreen kosong -- padahal
  // maksudnya edit, bukan bikin itinerary baru dari awal. Sekarang:
  //
  // 1. Dilihat dulu field 'source' (ditandai di
  //    DestinationSelectionScreen saat pertama kali dibuat, lihat
  //    komentar 'source' di sana) untuk tahu itinerary ini hasil
  //    "Atur Manual" atau "Atur dengan AI".
  // 2. Destinasi & waktu yang sudah tersimpan (SavedItineraryService)
  //    dirakit ulang jadi bentuk yang dipahami
  //    ManualScheduleScreen/AIItineraryScreen, lalu langsung dibuka
  //    lagi layar yang sesuai -- persis "sebelum preview" seperti
  //    yang diminta.
  //
  // ============================================================

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) {
      return null;
    }

    final List<String> parts = value.toString().split(':');

    if (parts.length != 2) {
      return null;
    }

    final int? hour = int.tryParse(parts[0]);
    final int? minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _editItinerary(
    BuildContext context,
    List<Map<String, dynamic>>? savedItinerary,
  ) {
    if (savedItinerary == null || savedItinerary.isEmpty) {
      return;
    }

    final Map<String, dynamic> firstDay = savedItinerary.first;

    final String source = firstDay['source']?.toString() ?? 'manual';

    // ----------------------------------------------------------
    // RAKIT ULANG destinationsByDay + WAKTU DARI DATA TERSIMPAN
    // ----------------------------------------------------------

    final Map<int, List<Map<String, dynamic>>> destinationsByDay = {};

    final Map<int, TimeOfDay?> departureTimesByDay = {};

    final Map<int, List<TimeOfDay?>> arrivalTimesByDay = {};

    final Map<int, List<TimeOfDay?>> returnTimesByDay = {};

    for (final daySchedule in savedItinerary) {
      final int day = daySchedule['day'] is int
          ? daySchedule['day'] as int
          : (int.tryParse(daySchedule['day']?.toString() ?? '') ?? 1);

      final List<dynamic> rawDestinations =
          daySchedule['destinations'] is List
              ? daySchedule['destinations'] as List
              : const [];

      final List<Map<String, dynamic>> destinations = [];

      final List<TimeOfDay?> arrivals = [];

      final List<TimeOfDay?> returns = [];

      for (final rawDestination in rawDestinations) {
        final Map<String, dynamic> destination = Map<String, dynamic>.from(
          rawDestination as Map,
        );

        arrivals.add(_parseTime(destination['arrivalTime']));

        returns.add(_parseTime(destination['departureTime']));

        // 'arrivalTime'/'departureTime' di sini adalah waktu KUNJUNGAN
        // (ditambahkan ManualScheduleScreen/AIItineraryScreen saat
        // preview dibuat) -- BUKAN field asli destinasi dari
        // destinations_data.dart. Dibuang lagi supaya destinasi yang
        // dikirim balik ke ManualScheduleScreen/AIItineraryScreen
        // bersih seperti data aslinya.
        destination.remove('arrivalTime');
        destination.remove('departureTime');

        destinations.add(destination);
      }

      destinationsByDay[day] = destinations;

      departureTimesByDay[day] = _parseTime(daySchedule['departureTime']);

      arrivalTimesByDay[day] = arrivals;

      returnTimesByDay[day] = returns;
    }

    // ----------------------------------------------------------
    // DATA PERJALANAN (tripName, startDate, dst) TANPA FIELD
    // SPESIFIK-HARI
    // ----------------------------------------------------------

    final Map<String, dynamic> travelData = Map<String, dynamic>.from(
      firstDay,
    )
      ..remove('day')
      ..remove('destinations')
      ..remove('departureTime')
      ..remove('startLocation')
      ..remove('startLatitude')
      ..remove('startLongitude');

    final String startLocation =
        firstDay['startLocation']?.toString() ?? 'Lokasi awal belum ditentukan';

    final double? startLatitude = double.tryParse(
      firstDay['startLatitude']?.toString() ?? '',
    );

    final double? startLongitude = double.tryParse(
      firstDay['startLongitude']?.toString() ?? '',
    );

    final LatLng? startCoordinate =
        (startLatitude != null && startLongitude != null)
            ? LatLng(startLatitude, startLongitude)
            : null;

    // ----------------------------------------------------------
    // BUKA LAYAR YANG SESUAI
    // ----------------------------------------------------------

    if (source == 'ai') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AIItineraryScreen(
              travelData: travelData,
              destinationsByDay: destinationsByDay,
              startCoordinate: startCoordinate,
              startLocationName: startLocation,
            );
          },
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return ManualScheduleScreen(
              startLocation: startLocation,
              startCoordinate: startCoordinate,
              destinationsByDay: destinationsByDay,
              travelData: travelData,
              initialDepartureTimesByDay: departureTimesByDay,
              initialArrivalTimesByDay: arrivalTimesByDay,
              initialReturnTimesByDay: returnTimesByDay,
            );
          },
        ),
      );
    }
  }

  // ============================================================
  // ITINERARY MENU
  // ============================================================

  void _showItineraryMenu(
    BuildContext context,
    List<Map<String, dynamic>>? savedItinerary,
  ) {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),

          decoration: const BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Container(
                width: 40,
                height: 4,

                margin: const EdgeInsets.only(bottom: 18),

                decoration: BoxDecoration(
                  color: const Color(0xFFD8D8D8),

                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // ==================================================
              // EDIT
              // ==================================================
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.darkBlue),

                title: const Text('Edit Itinerary'),

                onTap: () {
                  Navigator.pop(context);

                  _editItinerary(context, savedItinerary);
                },
              ),

              // ==================================================
              // DELETE
              // ==================================================
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),

                title: const Text('Hapus Itinerary'),

                onTap: () {
                  Navigator.pop(context);

                  _deleteItinerary(context, _itineraryId(savedItinerary ?? []));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DELETE ITINERARY
  // ============================================================

  void _deleteItinerary(BuildContext context, String? itineraryId) {
    // ==============================================================
    // BENTUK POPUP DISAMAKAN dengan popup "Itinerary berhasil
    // dibuat!" di ItineraryPreviewScreen: Dialog putih sudut 22,
    // ikon lingkaran di atas, judul tebal, tombol utama penuh
    // (rounded 25), tombol teks di bawahnya.
    // ==============================================================

    showDialog(
      context: context,
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
                // IKON
                // ----------------------------------------------
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 18),

                // ----------------------------------------------
                // JUDUL
                // ----------------------------------------------
                const Text(
                  'Hapus Itinerary?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // DESKRIPSI
                // ----------------------------------------------
                const Text(
                  'Itinerary ini akan dihapus dari daftar rencana perjalananmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.greyText,
                  ),
                ),

                const SizedBox(height: 22),

                // ----------------------------------------------
                // HAPUS
                // ----------------------------------------------
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // Hapus itinerary ini SAJA (berdasarkan id-nya),
                      // bukan SavedItineraryService.instance.clear() yang
                      // dulu menghapus SEMUA itinerary tersimpan -- sekarang
                      // kan bisa ada lebih dari satu card sekaligus.
                      if (itineraryId != null) {
                        SavedItineraryService.instance.remove(itineraryId);
                      }

                      Navigator.pop(dialogContext);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // BATAL
                // ----------------------------------------------
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Batal',
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
}