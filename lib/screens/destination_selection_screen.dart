import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'detail_destination_screen.dart';
import 'manual_schedule_screen.dart';
import 'ai_itinerary_screen.dart';
import '../data/destinations_data.dart';
import '../theme/app_colors.dart';
import '../services/destination_service.dart';
import '../widgets/smart_image.dart';



class DestinationSelectionScreen extends StatefulWidget {
  final Set<String> selectedCategories;
  final LatLng? startLocation;

  // ============================================================
  // NAMA ALAMAT LOKASI AWAL (HASIL REVERSE GEOCODING)
  // ============================================================
  //
  // Dikirim dari TravelInformationScreen supaya layar-layar
  // berikutnya (termasuk ManualScheduleScreen) tidak perlu
  // menampilkan koordinat mentah lagi.
  //
  // ============================================================

  final String? startLocationName;

  // ============================================================
  // JUMLAH HARI PERJALANAN
  // ============================================================

  final int travelDuration;

  // ============================================================
  // KOTA/KABUPATEN TUJUAN (DARI TRAVEL INFORMATION SCREEN)
  // ============================================================
  //
  // Dipakai untuk menyaring daftar destinasi supaya yang tampil
  // relevan dengan kota/kabupaten yang sudah dipilih pengguna,
  // selain filter kategori yang sudah ada.
  //
  // ============================================================

  final String? destinationCity;

  // ============================================================
  // DATA PERJALANAN LENGKAP (DARI TRAVEL INFORMATION SCREEN)
  // ============================================================
  //
  // Berisi tripName, startDate, endDate, participants, vehicle,
  // destination, dst. Diteruskan apa adanya ke ManualScheduleScreen
  // supaya jadwal akhir yang tersimpan tetap membawa informasi ini
  // sampai ke PlanScreen & ItineraryDetailScreen.
  //
  // ============================================================

  final Map<String, dynamic>? travelData;

  const DestinationSelectionScreen({
    super.key,
    required this.selectedCategories,
    required this.travelDuration,
    this.startLocation,
    this.startLocationName,
    this.destinationCity,
    this.travelData,
  });

  @override
  State<DestinationSelectionScreen> createState() =>
      _DestinationSelectionScreenState();
}

class _DestinationSelectionScreenState
    extends State<DestinationSelectionScreen> {
  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchController = TextEditingController();

  // ============================================================
  // CATEGORY
  // ============================================================

  final List<String> categories = [
    'Semua',
    'Alam',
    'Budaya',
    'Kuliner',
    'Buatan',
  ];

  String selectedCategory = 'Semua';

  // ============================================================
  // HARI YANG SEDANG DIPILIH
  // ============================================================

  int selectedDay = 1;

  // ============================================================
  // DESTINASI YANG DIPILIH BERDASARKAN HARI
  //
  // Contoh:
  //
  // Hari 1:
  // - Pantai Mutun
  // - Pantai Klara
  //
  // Hari 2:
  // - Museum Lampung
  // - Puncak Mas
  //
  // ============================================================

  late Map<int, Set<String>> selectedDestinationsByDay;

  // ============================================================
  // DESTINATION DATA (DARI DATABASE LARAVEL BACKEND)
  // ============================================================

  List<Map<String, String>> get destinations {
    final liveModels = DestinationService.instance.destinations.value;
    return liveModels.map((d) => {
      'id': d.id,
      'latitude': d.latitude.toString(),
      'longitude': d.longitude.toString(),
      'name': d.name,
      'location': d.location,
      'category': d.category,
      'rating': d.rating.toStringAsFixed(1),
      'reviews': '${d.reviewsCount} ulasan',
      'image': d.mainImage ?? 'assets/images/pulau_wayang.jpg',
      'description': d.description,
    }).toList();
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  final Set<String> favoriteDestinations = {};

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    if (DestinationService.instance.destinations.value.isEmpty) {
      DestinationService.instance.fetchDashboardData();
    }

    selectedDestinationsByDay = {};

    for (int day = 1; day <= widget.travelDuration; day++) {
      selectedDestinationsByDay[day] = {};
    }
  }


  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // FILTERED DESTINATIONS
  // ============================================================

  List<Map<String, String>> get filteredDestinations {
    final String keyword = searchController.text.trim().toLowerCase();

    return destinations.where((destination) {
      final String name = (destination['name'] ?? '').toLowerCase();

      final String location = (destination['location'] ?? '').toLowerCase();

      final String category = destination['category'] ?? 'Alam';


      // ========================================================
      // FILTER KATEGORI DARI INFORMASI PERJALANAN
      // ========================================================

      final bool matchTravelCategory =
          widget.selectedCategories.isEmpty ||
          widget.selectedCategories.contains('Semua') ||
          widget.selectedCategories.contains(category);

      // ========================================================
      // FILTER KOTA/KABUPATEN TUJUAN DARI INFORMASI PERJALANAN
      // ========================================================

      final bool matchTravelDestination = destinationMatchesCity(
        location,
        widget.destinationCity,
      );

      // ========================================================
      // FILTER SEARCH
      // ========================================================

      final bool matchSearch =
          keyword.isEmpty ||
          name.contains(keyword) ||
          location.contains(keyword);

      // ========================================================
      // FILTER KATEGORI DI HALAMAN
      // ========================================================

      final bool matchCategory =
          selectedCategory == 'Semua' || category == selectedCategory;

      return matchTravelCategory &&
          matchTravelDestination &&
          matchSearch &&
          matchCategory;
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(context),

            // ==================================================
            // KONTEKS KOTA/KABUPATEN TUJUAN
            // ==================================================

            if (widget.destinationCity != null &&
                widget.destinationCity!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Menampilkan destinasi untuk ${widget.destinationCity}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ==================================================
            // SEARCH BAR
            // ==================================================
            _buildSearchBar(),

            const SizedBox(height: 17),

            // ==================================================
            // CATEGORY
            // ==================================================
            _buildCategoryFilter(),

            const SizedBox(height: 14),

            // ==================================================
            // DAY SELECTOR
            // ==================================================
            _buildDaySelector(),

            const SizedBox(height: 10),

            // ==================================================
            // DESTINATION LIST
            // ==================================================
            Expanded(child: _buildDestinationList()),
          ],
        ),
      ),

      // ========================================================
      // BOTTOM BUTTONS
      // ========================================================
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Stack(
        children: [
          // ----------------------------------------------------
          // BACK BUTTON
          // ----------------------------------------------------

          Positioned(
            left: 20,
            top: 17,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },

              child: Container(
                width: 40,
                height: 40,

                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,

                  border: Border.all(color:  AppColors.borderColor),
                ),

                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.greyText,
                ),
              ),
            ),
          ),

          // ----------------------------------------------------
          // TITLE
          // ----------------------------------------------------
          const Positioned(
            left: 0,
            right: 0,
            top: 23,

            child: Center(
              child: Text(
                'Pilih Destinasi',

                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Container(
        height: 40,

        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color:  AppColors.borderColor),
        ),

        child: TextField(
          controller: searchController,

          onChanged: (value) {
            setState(() {});
          },

          style: const TextStyle(fontSize: 12, color: AppColors.darkText),

          decoration: const InputDecoration(
            border: InputBorder.none,

            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.greyText),

            hintText: 'Cari',

            hintStyle: TextStyle(fontSize: 12, color: AppColors.greyText),

            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CATEGORY FILTER
  // ============================================================

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 34,

      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),

        scrollDirection: Axis.horizontal,

        physics: const BouncingScrollPhysics(),

        itemCount: categories.length,

        separatorBuilder: (context, index) {
          return const SizedBox(width: 7);
        },

        itemBuilder: (context, index) {
          final String category = categories[index];

          final bool isSelected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),

              padding: const EdgeInsets.symmetric(horizontal: 22),

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : AppColors.lightGrey,

                borderRadius: BorderRadius.circular(18),
              ),

              child: Text(
                category,

                style: TextStyle(
                  fontSize: 12,

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
  // DAY SELECTOR
  // ============================================================

  Widget _buildDaySelector() {
    return SizedBox(
      height: 40,

      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),

        scrollDirection: Axis.horizontal,

        physics: const BouncingScrollPhysics(),

        itemCount: widget.travelDuration,

        separatorBuilder: (context, index) {
          return const SizedBox(width: 8);
        },

        itemBuilder: (context, index) {
          final int day = index + 1;

          final bool isSelected = selectedDay == day;

          final int count = selectedDestinationsByDay[day]?.length ?? 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDay = day;
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),

              padding: const EdgeInsets.symmetric(horizontal: 17),

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,

                borderRadius: BorderRadius.circular(20),

                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : AppColors.borderColor,
                ),
              ),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    'Hari $day',

                    style: TextStyle(
                      fontSize: 12,

                      fontWeight: FontWeight.w600,

                      color: isSelected ? Colors.white : AppColors.darkText,
                    ),
                  ),

                  if (count > 0) ...[
                    const SizedBox(width: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3, // CHANGED - padding menyesuaikan font yang lebih besar
                      ),

                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFEAF6FF),

                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Text(
                        '$count',

                        style: TextStyle(
                          fontSize: 12, // CHANGED - font terkecil jadi 12

                          fontWeight: FontWeight.bold,

                          color: isSelected ? AppColors.darkBlue : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DESTINATION LIST
  // ============================================================

  Widget _buildDestinationList() {
    return ValueListenableBuilder<List<DestinationModel>>(
      valueListenable: DestinationService.instance.destinations,
      builder: (context, liveModels, child) {
        final List<Map<String, String>> data = filteredDestinations;

        if (data.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
          itemCount: data.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildDestinationCard(data[index]),
            );
          },
        );
      },
    );
  }


  // ============================================================
  // DESTINATION CARD
  // ============================================================

  Widget _buildDestinationCard(Map<String, String> destination) {
    final String name = destination['name'] ?? 'Destinasi';

    final String image = destination['image'] ?? 'assets/images/pulau_wayang.jpg';

    final String reviews = destination['reviews'] ?? '0 ulasan';


    // ==========================================================
    // CEK DESTINASI UNTUK HARI YANG SEDANG AKTIF
    // ==========================================================

    final bool isSelected =
        selectedDestinationsByDay[selectedDay]?.contains(name) ?? false;

    final bool isFavorite = favoriteDestinations.contains(name);

    return GestureDetector(
      // ========================================================
      // OPEN DETAIL
      // ========================================================

      onTap: () {
        _openDetail(destination);
      },

      child: Container(
        width: double.infinity,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(22),

          border: Border.all(color: AppColors.borderColor),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),

              blurRadius: 5,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        clipBehavior: Clip.antiAlias,

        child: Column(
          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 145,
                  child: SmartImage(
                    imagePathOrUrl: image,
                    fit: BoxFit.cover,
                  ),
                ),


                // ----------------------------------------------
                // FAVORITE BUTTON
                // ----------------------------------------------
                Positioned(
                  top: 10,
                  right: 10,

                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isFavorite) {
                          favoriteDestinations.remove(name);
                        } else {
                          favoriteDestinations.add(name);
                        }
                      });
                    },

                    child: Container(
                      width: 36,
                      height: 36,

                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,

                        color: isFavorite ? Colors.red : AppColors.darkBlue,

                        size: 21,
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
              padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),

              child: Row(
                children: [
                  // --------------------------------------------
                  // NAME + RATING
                  // --------------------------------------------

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          name,

                          maxLines: 1,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Row(
                          children: [
                            _buildRatingStars(),

                            const SizedBox(width: 8),

                            Text(
                              reviews,

                              style: const TextStyle(
                                fontSize: 12, // CHANGED - font terkecil jadi 12
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // --------------------------------------------
                  // TAMBAH BUTTON
                  // --------------------------------------------
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        final Set<String> dayDestinations =
                            selectedDestinationsByDay[selectedDay]!;

                        if (isSelected) {
                          dayDestinations.remove(name);
                        } else {
                          dayDestinations.add(name);
                        }
                      });
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),

                      width: 120,
                      height: 38,

                      alignment: Alignment.center,

                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEAF6FF) : AppColors.darkBlue,

                        borderRadius: BorderRadius.circular(22),

                        border: isSelected
                            ? Border.all(color: AppColors.primaryBlue)
                            : null,
                      ),

                      child: Text(
                        isSelected ? 'Ditambahkan' : 'Tambah',

                        style: TextStyle(
                          fontSize: 14,

                          fontWeight: FontWeight.bold,

                          color: isSelected ? AppColors.darkBlue : Colors.white,
                        ),
                      ),
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

  // ============================================================
  // OPEN DETAIL
  // ============================================================

  void _openDetail(Map<String, String> destination) {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {
          return DetailDestinationScreen(
            name: destination['name']!,
            location: destination['location']!,
            rating: destination['rating']!,
            reviews: destination['reviews']!,
            mainImage: destination['image']!,
            description: destination['description']!,
          );
        },
      ),
    );
  }

  // ============================================================
  // RATING
  // ============================================================

  Widget _buildRatingStars() {
    return const Row(
      mainAxisSize: MainAxisSize.min,

      children: [
        Icon(Icons.star, size: 16, color: AppColors.darkBlue),

        Icon(Icons.star, size: 16, color: AppColors.darkBlue),

        Icon(Icons.star, size: 16, color: AppColors.darkBlue),

        Icon(Icons.star, size: 16, color: AppColors.darkBlue),

        Icon(Icons.star_half, size: 16, color: AppColors.darkBlue),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
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

            child: const Icon(Icons.search_off, color: AppColors.primaryBlue, size: 35),
          ),

          const SizedBox(height: 15),

          const Text(
            'Destinasi tidak ditemukan',

            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Coba gunakan kata kunci lainnya.',

            style: TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTONS
  // ============================================================

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),

      decoration: const BoxDecoration(color: Colors.white),

      child: SafeArea(
        top: false,

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // ATUR MANUAL
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 42,

              child: OutlinedButton(
                onPressed: _handleManual,

                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,

                  foregroundColor: AppColors.darkBlue,

                  side: const BorderSide(color: AppColors.darkBlue, width: 1),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),

                child: const Text(
                  'Atur Manual',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 9),

            // ==================================================
            // ATUR DENGAN AI
            // ==================================================
            SizedBox(
              width: double.infinity,
              height: 42,

              child: ElevatedButton(
                onPressed: _handleAI,

                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,

                  foregroundColor: AppColors.darkBlue,

                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),

                child: const Text(
                  'Atur dengan AI',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MANUAL
  // ============================================================

  Future<void> _handleManual() async {
    // ==========================================================
    // CEK APAKAH ADA DESTINASI YANG DIPILIH
    // ==========================================================

    bool hasAnyDestination = false;

    for (int day = 1; day <= widget.travelDuration; day++) {
      final Set<String> dayDestinations = selectedDestinationsByDay[day] ?? {};

      if (dayDestinations.isNotEmpty) {
        hasAnyDestination = true;
        break;
      }
    }

    // ==========================================================
    // BELUM ADA DESTINASI
    // ==========================================================

    if (!hasAnyDestination) {
      _showMessage('Pilih minimal satu destinasi terlebih dahulu.');

      return;
    }

    // ==========================================================
    // BUAT DATA DESTINASI BERDASARKAN HARI
    // ==========================================================

    final Map<int, List<Map<String, dynamic>>> destinationsByDay = {};

    for (int day = 1; day <= widget.travelDuration; day++) {
      final Set<String> selectedNames = selectedDestinationsByDay[day] ?? {};

      final List<Map<String, dynamic>> selectedData = destinations
          .where((destination) {
            return selectedNames.contains(destination['name']);
          })
          .map((destination) => Map<String, dynamic>.from(destination))
          .toList();

      destinationsByDay[day] = selectedData;
    }

    // ==========================================================
    // MASUK KE MANUAL SCHEDULE
    // ==========================================================
    //
    // 'source': 'manual' ditandai di sini supaya nanti kalau user
    // menekan "Edit Itinerary" dari PlanScreen, aplikasi tahu harus
    // membuka lagi ManualScheduleScreen (bukan AIItineraryScreen).
    // Field ini otomatis ikut ke setiap hari di dailySchedules lewat
    // spread ...tripInfo di ManualScheduleScreen._handlePreview.
    // ==========================================================

    final Map<String, dynamic> travelDataWithSource = {
      ...?widget.travelData,
      'source': 'manual',
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ManualScheduleScreen(
            startLocation:
                (widget.startLocationName != null &&
                        widget.startLocationName!.trim().isNotEmpty)
                ? widget.startLocationName!
                : 'Lokasi awal belum ditentukan',
            // Koordinat asli lokasi awal (dari peta/GPS di
            // TravelInformationScreen) diteruskan juga di sini,
            // supaya ManualScheduleScreen bisa menyimpannya sebagai
            // titik keberangkatan di peta rute -- sebelumnya cuma
            // nama teksnya yang diteruskan, koordinatnya dibuang di
            // sini sehingga peta rute tidak pernah tahu titik
            // berangkatnya di mana.
            startCoordinate: widget.startLocation,
            destinationsByDay: destinationsByDay,
            travelData: travelDataWithSource,
          );
        },
      ),
    );

    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  // ============================================================
  // AI
  // ============================================================
  //
  // Sama seperti _handleManual: destinasi yang sudah dicentang user
  // (per hari) dikumpulkan dulu, lalu diteruskan ke AIItineraryScreen
  // supaya AI HANYA menyusun urutan & jadwal dari destinasi pilihan
  // user itu -- bukan asal ambil dari pool kategori+kota. AI di sini
  // baru mengurutkan berdasarkan prediksi kepadatan (dummy, di sisi
  // Flutter); nanti kalau backend scoring AI sudah siap, tinggal
  // AIItineraryScreen yang disambungkan ke API, alur & data yang
  // dikirim dari sini tidak perlu berubah.
  // ============================================================

  Future<void> _handleAI() async {
    bool hasAnyDestination = false;

    for (int day = 1; day <= widget.travelDuration; day++) {
      final Set<String> dayDestinations = selectedDestinationsByDay[day] ?? {};

      if (dayDestinations.isNotEmpty) {
        hasAnyDestination = true;
        break;
      }
    }

    if (!hasAnyDestination) {
      _showMessage('Pilih minimal satu destinasi terlebih dahulu.');

      return;
    }

    // ==========================================================
    // BUAT DATA DESTINASI BERDASARKAN HARI (SAMA SEPERTI MANUAL)
    // ==========================================================

    final Map<int, List<Map<String, dynamic>>> destinationsByDay = {};

    for (int day = 1; day <= widget.travelDuration; day++) {
      final Set<String> selectedNames = selectedDestinationsByDay[day] ?? {};

      final List<Map<String, dynamic>> selectedData = destinations
          .where((destination) {
            return selectedNames.contains(destination['name']);
          })
          .map((destination) => Map<String, dynamic>.from(destination))
          .toList();

      destinationsByDay[day] = selectedData;
    }

    // ==========================================================
    // MASUK KE AI ITINERARY SCREEN
    // ==========================================================
    //
    // 'source': 'ai' ditandai di sini dengan alasan yang sama seperti
    // di _handleManual (lihat komentar di sana).
    // ==========================================================

    final Map<String, dynamic> travelDataWithSource = {
      ...?widget.travelData,
      'source': 'ai',
    };

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AIItineraryScreen(
            travelData: travelDataWithSource,
            destinationsByDay: destinationsByDay,
            startCoordinate: widget.startLocation,
            startLocationName: widget.startLocationName,
          );
        },
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  // ============================================================
  // SNACKBAR
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
}