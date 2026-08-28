import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'ai_itinerary_screen.dart';
import 'itinerary_detail_screen.dart';
import '../services/saved_itinerary_service.dart';
import '../widgets/smart_image.dart';
import '../data/destinations_data.dart';
import 'manual_schedule_screen.dart';
import 'travel_information_screen.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/auth_guard.dart';


// ===================================================================
// HISTORY SCREEN (TAB "RIWAYAT")
// ===================================================================
//
// Menampilkan SEMUA itinerary yang tersimpan di SavedItineraryService,
// sama persis sumber datanya dengan PlanScreen (jadi selalu sinkron --
// tambah/edit/hapus itinerary di satu tempat otomatis kelihatan juga
// di tab satunya), cuma beda tata letak kartu: di sini kartu memanjang
// horizontal (thumbnail kecil di kiri, teks di kanan) sesuai desain,
// bukan kartu vertikal dengan gambar besar di atas seperti PlanScreen.
//
// Aksi "Edit"/"Hapus" & navigasi ke detail memakai logika yang sama
// dengan PlanScreen supaya perilakunya konsisten di seluruh app.
// ===================================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ================================================================
  // FILTER: HANYA ITINERARY YANG SUDAH SELESAI
  // ================================================================
  //
  // Riwayat nampilin itinerary yang endDate-nya sudah LEWAT hari ini,
  // ATAU yang minimal SATU harinya sudah ditandai selesai manual
  // (lihat SavedItineraryService.hasAnyCompletedDay) -- BUKAN semua
  // itinerary yang tersimpan. Itinerary yang belum mulai tetap di
  // PlanScreen.
  //
  // CATATAN: berbeda dengan dulu, itinerary MULTI-HARI yang baru
  // sebagian harinya selesai (mis. hari 1 sudah ditandai selesai,
  // hari 2-3 belum) sengaja tampil di SINI *dan* tetap tampil aktif
  // di TripScreen (lihat TripScreen._findActiveTrip) -- karena hari
  // 2/3-nya belum dijalani, trip itu masih relevan di tab Trip, tapi
  // karena hari 1 sudah selesai, dia juga relevan buat dilihat di
  // Riwayat. Baru benar-benar hilang dari TripScreen begitu tanggal
  // sistem sudah lewat endDate-nya.
  //
  // Pengecekan tanggal (_dateOnly) sengaja disamakan persis dengan
  // TripScreen supaya "hari ini" didefinisikan sama di kedua layar.
  //
  // ================================================================

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isFinished(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) return false;

    if (SavedItineraryService.instance.hasAnyCompletedDay(itinerary)) {
      return true;
    }

    final dynamic end = itinerary.first['endDate'];
    DateTime? endDay;

    if (end is DateTime) {
      endDay = _dateOnly(end);
    } else if (end is String) {
      final parsed = DateTime.tryParse(end);
      if (parsed != null) {
        endDay = _dateOnly(parsed);
      }
    }

    if (endDay == null) return false;

    final DateTime today = _dateOnly(DateTime.now());
    return endDay.isBefore(today);
  }

  List<List<Map<String, dynamic>>> _finishedItinerariesOf(
    List<List<Map<String, dynamic>>> savedItineraries,
  ) {
    return savedItineraries.where(_isFinished).toList();
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    if (!ApiService.instance.isAuthenticated) {
      return _buildGuestState(context);
    }
    return ValueListenableBuilder<List<List<Map<String, dynamic>>>>(
      valueListenable: SavedItineraryService.instance.itineraries,
      builder: (context, savedItineraries, _) {
        final List<List<Map<String, dynamic>>> finishedItineraries =
            _finishedItinerariesOf(savedItineraries);

        final bool hasItinerary = finishedItineraries.isNotEmpty;

        // Kondisi kosong sekarang pakai shell sendiri (_buildEmptyState),
        // disamakan PERSIS dengan TripScreen._buildEmptyState (header foto
        // biru tinggi 285 + konten putih rounded 42 + layout Spacer),
        // bukan lagi shell header-200 yang dipakai kondisi terisi.
        if (!hasItinerary) {
          return _buildEmptyState(context);
        }

        return _buildScaffold(context, finishedItineraries);
      },
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(height: 285, width: double.infinity, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/background_header.png'), fit: BoxFit.cover))),
          SafeArea(
            child: Column(
              children: [
                Container(width: double.infinity, padding: const EdgeInsets.fromLTRB(25, 30, 25, 0), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Riwayat', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold)), SizedBox(height: 5), Text('Lihat semua itinerary yang pernah kamu buat', style: TextStyle(color: Colors.white, fontSize: 12))])),
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
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.lock_outline, color: AppColors.primaryBlue, size: 36)),
                          const SizedBox(height: 18),
                          const Text('Masuk untuk melihat riwayat', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                          const SizedBox(height: 8),
                          const Text('Riwayat perjalananmu akan tersimpan di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.greyText, height: 1.4)),
                          const SizedBox(height: 20),
                          SizedBox(width: 180, height: 44, child: ElevatedButton(onPressed: () => showLoginRequiredSheet(context, action: 'melihat riwayat perjalanan'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.w600)))),
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
    List<List<Map<String, dynamic>>> savedItineraries,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // ==========================================================
          // BLUE HEADER
          // ==========================================================
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

          // ==========================================================
          // MAIN CONTENT
          // ==========================================================
          SafeArea(
            child: Column(
              children: [
                // ======================================================
                // HEADER TEXT
                // ======================================================
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Riwayat',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Lihat semua itinerary yang pernah kamu buat',

                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ======================================================
                // WHITE CONTENT (ROUNDED TOP)
                // ======================================================
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

                    child: RefreshIndicator(
                      onRefresh: () async {
                        await SavedItineraryService.instance.fetchItineraries();
                      },
                      color: AppColors.primaryBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),

                        padding: const EdgeInsets.fromLTRB(20, 32, 20, 110),

                        child: Column(
                          children: [
                            for (final savedItinerary in savedItineraries)
                              _buildHistoryCard(context, savedItinerary),
                          ],
                        ),
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

  // ================================================================
  // EMPTY STATE -- DISAMAKAN PERSIS DENGAN TripScreen._buildEmptyState
  // ================================================================
  //
  // Shell (header foto biru tinggi 285 + konten putih rounded 42) dan
  // layout isinya (Spacer flex 5/7, icon 100x100 berisi image 55x55,
  // spacing 26/8/26, ukuran teks & tombol) disalin PERSIS dari
  // TripScreen._buildEmptyState sesuai permintaan. Yang beda cuma teks
  // (judul/deskripsi) & fallback icon, disesuaikan konteks Riwayat.
  // ================================================================

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ======================================================
          // BLUE HEADER (sama persis dengan TripScreen/PlanScreen)
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

          SafeArea(
            child: Column(
              children: [
                // ==================================================
                // HEADER TEXT
                // ==================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Lihat semua itinerary yang pernah kamu buat',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // ==================================================
                // WHITE CONTENT (rounded 42, sama dengan TripScreen)
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Column(
                        children: [
                          const Spacer(flex: 5),

                          // Ukuran disamakan PERSIS dengan
                          // TripScreen/PlanScreen: SizedBox 100x100
                          // berisi Image.asset 55x55.
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              'assets/images/smarttrip_logo_icon.png',
                              width: 55,
                              height: 55,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.history_rounded,
                                  size: 60,
                                  color: AppColors.primaryBlue.withValues(alpha: 0.85),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Belum ada riwayat perjalanan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText,
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Yuk buat rencana perjalananmu dan temukan destinasi wisata terbaik di Lampung',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.greyText,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 26),

                          SizedBox(
                            width: 180,
                            height: 45,
                            child: ElevatedButton(
                              onPressed: () {
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
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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

  // ================================================================
  // SATU KARTU RIWAYAT (HORIZONTAL)
  // ================================================================

  Widget _buildHistoryCard(
    BuildContext context,
    List<Map<String, dynamic>> savedItinerary,
  ) {
    final itinerary = savedItinerary;

    final String dateRangeText = _formatDateRange(
      itinerary.isNotEmpty ? itinerary.first['startDate'] : null,
      itinerary.isNotEmpty ? itinerary.first['endDate'] : null,
    );

    // "X Hari" = jumlah hari dalam itinerary ini (setiap elemen list
    // = satu hari, lihat catatan di SavedItineraryService).
    final int totalDays = itinerary.length;

    int totalDestinations = 0;

    for (final day in itinerary) {
      final destinations = day['destinations'];

      if (destinations is List) {
        totalDestinations += destinations.length;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),

      child: GestureDetector(
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

          padding: const EdgeInsets.all(12),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius: BorderRadius.circular(18),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // ======================================================
              // THUMBNAIL
              // ======================================================
              SmartImage(
                imagePathOrUrl: _cardImagePath(itinerary),
                width: 78,
                height: 78,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(14),
              ),

              const SizedBox(width: 14),

              // ======================================================
              // TEXT INFO
              // ======================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _tripTitle(itinerary),

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.greyText,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          dateRangeText,

                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.greyText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '$totalDays Hari  •  $totalDestinations Destinasi',

                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),

              // ======================================================
              // THREE DOT MENU
              // ======================================================
              GestureDetector(
                onTap: () {
                  _showItineraryMenu(context, savedItinerary);
                },

                child: const Padding(
                  padding: EdgeInsets.only(left: 4),

                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.greyText,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // GAMBAR CARD -- IKUT DESTINASI PERTAMA (SAMA POLANYA DENGAN
  // PlanScreen._cardImagePath)
  // ================================================================

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

  // ================================================================
  // ID ITINERARY
  // ================================================================

  String? _itineraryId(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) {
      return null;
    }

    return itinerary.first['itineraryId']?.toString();
  }

  // ================================================================
  // JUDUL TRIP (SAMA POLANYA DENGAN PlanScreen._tripTitle)
  // ================================================================

  String _tripTitle(List<Map<String, dynamic>> itinerary) {
    if (itinerary.isEmpty) {
      return 'Explore Lampung Barat';
    }

    final String tripName = itinerary.first['tripName']?.toString().trim() ?? '';

    return tripName.isNotEmpty ? tripName : 'Explore Lampung Barat';
  }

  // ================================================================
  // FORMAT RENTANG TANGGAL
  // ================================================================

  String _formatDateRange(dynamic startDate, dynamic endDate) {
    DateTime? startDt;
    DateTime? endDt;

    if (startDate is DateTime) {
      startDt = startDate;
    } else if (startDate is String) {
      startDt = DateTime.tryParse(startDate);
    }

    if (endDate is DateTime) {
      endDt = endDate;
    } else if (endDate is String) {
      endDt = DateTime.tryParse(endDate);
    }

    if (startDt == null || endDt == null) {
      return '20–21 Juli 2026';
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

    final String start = '${startDt.day} ${months[startDt.month - 1]}';
    final String end = '${endDt.day} ${months[endDt.month - 1]} ${endDt.year}';

    return '$start – $end';
  }

  // ================================================================
  // OPEN TRAVEL INFORMATION (SAAT "BUAT ITINERARY" DITEKAN)
  // ================================================================

  Future<void> _openTravelInformation(BuildContext context) async {
    await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {
          return const TravelInformationScreen();
        },
      ),
    );
  }

  // ================================================================
  // MENU EDIT / HAPUS (SAMA POLANYA DENGAN PlanScreen)
  // ================================================================

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
              Container(
                width: 40,
                height: 4,

                margin: const EdgeInsets.only(bottom: 18),

                decoration: BoxDecoration(
                  color: const Color(0xFFD8D8D8),

                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.darkBlue),

                title: const Text('Edit Itinerary'),

                onTap: () {
                  Navigator.pop(context);

                  _editItinerary(context, savedItinerary);
                },
              ),

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

  // ================================================================
  // HAPUS ITINERARY
  // ================================================================

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
                  'Itinerary ini akan dihapus dari daftar riwayat perjalananmu.',
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

  // ================================================================
  // EDIT ITINERARY -- BALIK KE ATUR MANUAL / HASIL GENERATE (SAMA
  // POLANYA DENGAN PlanScreen._editItinerary)
  // ================================================================

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

    // ------------------------------------------------------------
    // RAKIT ULANG destinationsByDay + WAKTU DARI DATA TERSIMPAN
    // (persis sama logikanya dengan PlanScreen._editItinerary, biar
    // perilaku "Edit Itinerary" konsisten mau dibuka dari tab Rencana
    // atau tab Riwayat)
    // ------------------------------------------------------------

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
        // yang ditambahkan ManualScheduleScreen/AIItineraryScreen saat
        // preview dibuat -- BUKAN field asli destinasi. Dibuang lagi
        // supaya destinasi yang dikirim balik bersih seperti aslinya.
        destination.remove('arrivalTime');
        destination.remove('departureTime');

        destinations.add(destination);
      }

      destinationsByDay[day] = destinations;

      departureTimesByDay[day] = _parseTime(daySchedule['departureTime']);

      arrivalTimesByDay[day] = arrivals;

      returnTimesByDay[day] = returns;
    }

    // ------------------------------------------------------------
    // DATA PERJALANAN (tripName, startDate, dst) TANPA FIELD
    // SPESIFIK-HARI
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // BUKA LAYAR YANG SESUAI
    // ------------------------------------------------------------

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
}