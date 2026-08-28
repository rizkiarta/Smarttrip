import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';
import '../services/saved_itinerary_service.dart';
import 'map_screen.dart';
import 'destination_selection_screen.dart';
import 'ai_itinerary_screen.dart';

class TravelInformationScreen extends StatefulWidget {
  const TravelInformationScreen({super.key});

  @override
  State<TravelInformationScreen> createState() =>
      _TravelInformationScreenState();
}

class _TravelInformationScreenState extends State<TravelInformationScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController tripNameController = TextEditingController();

  final TextEditingController startLocationController = TextEditingController();

  // ============================================================
  // VARIABLES
  // ============================================================

  DateTime? startDate;

  // Jumlah hari perjalanan
  int travelDuration = 1;

  int participants = 2;

  // ============================================================
  // SELECTED LOCATION FROM MAP
  // ============================================================

  LatLng? selectedStartLocation;

  // ============================================================
  // REVERSE GEOCODING (KOORDINAT -> NAMA ALAMAT)
  // ============================================================
  //
  // Supaya lokasi yang tampil ke pengguna berupa nama alamat/tempat
  // yang mudah dibaca, bukan angka latitude/longitude.
  //
  // ============================================================

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      final Uri uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&zoom=16'
        '&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {
          // Nominatim mewajibkan User-Agent yang jelas.
          'User-Agent': 'SmartTripApp/1.0 (Flutter)',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        final String? displayName = data['display_name'] as String?;

        if (displayName != null && displayName.trim().isNotEmpty) {
          return displayName;
        }
      }
    } catch (_) {
      // Diamkan, fallback ke teks default di bawah.
    }

    return 'Lokasi terpilih';
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    try {
      // ========================================================
      // 1. CEK APAKAH GPS / LOCATION SERVICE AKTIF
      // ========================================================

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        _showMessage(
          'GPS belum aktif. Silakan aktifkan lokasi pada perangkat.',
        );

        return;
      }

      // ========================================================
      // 2. CEK IZIN LOKASI
      // ========================================================

      LocationPermission permission = await Geolocator.checkPermission();

      // ========================================================
      // 3. KALAU BELUM ADA IZIN → MINTA IZIN
      // ========================================================

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // ========================================================
      // 4. USER MENOLAK IZIN
      // ========================================================

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        _showMessage(
          'Izin lokasi diperlukan untuk menggunakan lokasi saat ini.',
        );

        return;
      }

      // ========================================================
      // 5. IZIN DITOLAK PERMANEN
      // ========================================================

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        _showMessage(
          'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui pengaturan aplikasi.',
        );

        return;
      }

      // ========================================================
      // 6. AMBIL POSISI GPS
      // ========================================================

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // ========================================================
      // 7. SIMPAN KOORDINAT
      // ========================================================

      if (!mounted) return;

      setState(() {
        selectedStartLocation = LatLng(position.latitude, position.longitude);

        startLocationController.text = 'Mencari nama lokasi...';
      });

      // ========================================================
      // 7b. UBAH KOORDINAT MENJADI NAMA ALAMAT
      // ========================================================

      final String address = await _getAddressFromLatLng(
        selectedStartLocation!,
      );

      if (!mounted) return;

      setState(() {
        startLocationController.text = address;
      });

      // ========================================================
      // 8. TAMPILKAN PESAN BERHASIL
      // ========================================================

      _showMessage('Lokasi saat ini berhasil digunakan.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal mendapatkan lokasi saat ini.');
    }
  }

  // ============================================================
  // SELECTED DESTINATION / KOTA
  // ============================================================

  String? selectedDestination;

  final List<String> lampungDestinations = [
    'Kabupaten Lampung Barat',
    'Kabupaten Lampung Selatan',
    'Kabupaten Lampung Tengah',
    'Kabupaten Lampung Timur',
    'Kabupaten Lampung Utara',
    'Kabupaten Mesuji',
    'Kabupaten Pesawaran',
    'Kabupaten Pesisir Barat',
    'Kabupaten Pringsewu',
    'Kabupaten Tanggamus',
    'Kabupaten Tulang Bawang',
    'Kabupaten Tulang Bawang Barat',
    'Kabupaten Way Kanan',
    'Kota Bandar Lampung',
    'Kota Metro',
  ];

  // ============================================================
  // SELECTED VEHICLE
  // ============================================================

  String? selectedVehicle;

  final List<String> vehicleOptions = ['Mobil', 'Motor', 'Bus'];

  // ============================================================
  // CATEGORIES
  // ============================================================

  final List<String> categories = ['Alam', 'Budaya', 'Kuliner', 'Buatan'];

  final Set<String> selectedCategories = {'Alam', 'Kuliner'};

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    tripNameController.dispose();
    startLocationController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(context),

            // ==================================================
            // FORM
            // ==================================================
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==========================================
                    // NAMA PERJALANAN
                    // ==========================================

                    _buildFieldLabel('Nama Perjalanan'),

                    const SizedBox(height: 9),

                    _buildTextField(
                      controller: tripNameController,
                      hintText: 'Contoh: Liburan ke Lampung Barat',
                    ),

                    const SizedBox(height: 29),

                    // ==========================================
                    // LOKASI AWAL
                    // ==========================================
                    _buildFieldLabel('Lokasi Awal'),

                    const SizedBox(height: 9),

                    _buildLocationField(),

                    const SizedBox(height: 29),

                    // ==========================================
                    // KOTA TUJUAN
                    // ==========================================
                    _buildFieldLabel('Kota Tujuan'),

                    const SizedBox(height: 9),

                    _buildDestinationDropdown(),

                    const SizedBox(height: 29),

                    // ==========================================
                    // DURASI PERJALANAN
                    // ==========================================
                    _buildFieldLabel('Durasi Perjalanan'),

                    const SizedBox(height: 9),

                    _buildDurationDropdown(),

                    const SizedBox(height: 29),

                    // ==========================================
                    // TANGGAL PERJALANAN
                    // ==========================================
                    _buildFieldLabel('Tanggal Perjalanan'),

                    const SizedBox(height: 9),

                    _buildStartDateBox(),

                    // ==========================================
                    // INFO TANGGAL SELESAI
                    // ==========================================
                    if (startDate != null) ...[
                      const SizedBox(height: 9),

                      _buildDateSummary(),
                    ],

                    const SizedBox(height: 29),

                    // ==========================================
                    // JUMLAH PESERTA
                    // ==========================================
                    _buildFieldLabel('Jumlah Peserta'),

                    const SizedBox(height: 9),

                    _buildParticipantCounter(),

                    const SizedBox(height: 29),

                    // ==========================================
                    // TRANSPORTASI
                    // ==========================================
                    _buildFieldLabel('Transportasi'),

                    const SizedBox(height: 9),

                    _buildVehicleDropdown(),

                    const SizedBox(height: 29),

                    // ==========================================
                    // KATEGORI DESTINASI
                    // ==========================================
                    _buildFieldLabel('Kategori Destinasi'),

                    const SizedBox(height: 10),

                    _buildCategorySelector(),

                    const SizedBox(height: 34),

                    // ==========================================
                    // PILIH DESTINASI
                    // ==========================================
                    _buildOutlineButton(
                      text: 'Pilih Destinasi',
                      onPressed: () {
                        _handleChooseDestination();
                      },
                    ),

                    const SizedBox(height: 12),

                    // ==========================================
                    // REKOMENDASI AI
                    // ==========================================
                    _buildPrimaryButton(
                      text: 'Rekomendasi AI',
                      onPressed: () {
                        _handleAIRecommendation();
                      },
                    ),
                  ],
                ),
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
    return SizedBox(
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ====================================================
          // BACK BUTTON
          // ====================================================
          Positioned(
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.greyText,
                  size: 19,
                ),
              ),
            ),
          ),

          // ====================================================
          // TITLE
          // ====================================================
          const Center(
            child: Text(
              'Informasi Perjalanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD LABEL
  // ============================================================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,

      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: TextField(
        controller: controller,

        keyboardType: keyboardType,

        style: const TextStyle(fontSize: 13, color: AppColors.darkText),

        decoration: InputDecoration(
          hintText: hintText,

          hintStyle: const TextStyle(fontSize: 13, color: AppColors.greyText),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DESTINATION DROPDOWN
  // ============================================================

  Widget _buildDestinationDropdown() {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.symmetric(horizontal: 17),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedDestination,

          isExpanded: true,

          dropdownColor: Colors.white,

          borderRadius: BorderRadius.circular(10),

          elevation: 4,

          menuMaxHeight: 300,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.greyText,
            size: 22,
          ),

          hint: const Text(
            'Pilih kota/kabupaten tujuan',

            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),

          style: const TextStyle(
            fontSize: 13,
            color: AppColors.darkText,
            fontWeight: FontWeight.w500,
          ),

          selectedItemBuilder: (context) {
            return lampungDestinations.map((destination) {
              return Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  destination,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },

          items: lampungDestinations.map((String destination) {
            final bool isSelected = selectedDestination == destination;

            return DropdownMenuItem<String>(
              value: destination,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEAF7FF)
                      : Colors.transparent,

                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: [
                    Icon(
                      Icons.location_city_outlined,

                      size: 19,

                      color: isSelected ? AppColors.primaryBlue : AppColors.greyText,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        destination,

                        maxLines: 1,

                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 13,

                          color: isSelected ? AppColors.darkBlue : AppColors.darkText,

                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),

                    if (isSelected)
                      const Icon(Icons.check, size: 18, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            );
          }).toList(),

          onChanged: (String? value) {
            if (value == null) return;

            setState(() {
              selectedDestination = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // DURATION DROPDOWN
  // ============================================================

  Widget _buildDurationDropdown() {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.symmetric(horizontal: 17),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: travelDuration,

          isExpanded: true,

          dropdownColor: Colors.white,

          borderRadius: BorderRadius.circular(10),

          elevation: 4,

          menuMaxHeight: 300,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.greyText,
            size: 22,
          ),

          style: const TextStyle(
            fontSize: 13,
            color: AppColors.darkText,
            fontWeight: FontWeight.w500,
          ),

          items: List.generate(14, (index) {
            final int days = index + 1;

            return DropdownMenuItem<int>(
              value: days,

              child: Text(
                '$days ${days == 1 ? 'Hari' : 'Hari'}',

                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }),

          onChanged: (int? value) {
            if (value == null) return;

            setState(() {
              travelDuration = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE DROPDOWN
  // ============================================================

  Widget _buildVehicleDropdown() {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      padding: const EdgeInsets.symmetric(horizontal: 17),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVehicle,

          isExpanded: true,

          dropdownColor: Colors.white,

          borderRadius: BorderRadius.circular(10),

          elevation: 4,

          menuMaxHeight: 220,

          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.greyText,
            size: 22,
          ),

          hint: const Text(
            'Pilih kendaraan',

            style: TextStyle(fontSize: 13, color: AppColors.greyText),
          ),

          style: const TextStyle(
            fontSize: 13,
            color: AppColors.darkText,
            fontWeight: FontWeight.w500,
          ),

          selectedItemBuilder: (context) {
            return vehicleOptions.map((vehicle) {
              return Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  vehicle,

                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList();
          },

          items: vehicleOptions.map((String vehicle) {
            final bool isSelected = selectedVehicle == vehicle;

            IconData vehicleIcon;

            switch (vehicle) {
              case 'Mobil':
                vehicleIcon = Icons.directions_car_outlined;
                break;

              case 'Motor':
                vehicleIcon = Icons.two_wheeler_outlined;
                break;

              case 'Bus':
                vehicleIcon = Icons.directions_bus_outlined;
                break;

              default:
                vehicleIcon = Icons.directions_car_outlined;
            }

            return DropdownMenuItem<String>(
              value: vehicle,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),

                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEAF7FF)
                      : Colors.transparent,

                  borderRadius: BorderRadius.circular(8),
                ),

                child: Row(
                  children: [
                    Icon(
                      vehicleIcon,

                      size: 20,

                      color: isSelected ? AppColors.primaryBlue : AppColors.greyText,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        vehicle,

                        style: TextStyle(
                          fontSize: 13,

                          color: isSelected ? AppColors.darkBlue : AppColors.darkText,

                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),

                    if (isSelected)
                      const Icon(Icons.check, size: 18, color: AppColors.primaryBlue),
                  ],
                ),
              ),
            );
          }).toList(),

          onChanged: (String? value) {
            if (value == null) return;

            setState(() {
              selectedVehicle = value;
            });
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION FIELD
  // ============================================================

  Widget _buildLocationField() {
    return GestureDetector(
      onTap: () {
        _showLocationOptions();
      },

      child: Container(
        height: 58,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(color: AppColors.borderColor),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            const SizedBox(width: 10),

            Container(
              width: 38,
              height: 38,

              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),

              child: const Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 22,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    selectedStartLocation == null
                        ? 'Pilih lokasi awal'
                        : 'Lokasi dipilih',

                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    selectedStartLocation == null
                        ? 'Cari atau tentukan lokasi melalui peta'
                        : startLocationController.text,

                    maxLines: 1,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(fontSize: 11, color: AppColors.greyText),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(right: 12),

              child: Icon(Icons.chevron_right, color: AppColors.greyText, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION OPTIONS
  // ============================================================

  void _showLocationOptions() {
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
              // TITLE
              // ==================================================
              const Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  'Pilih Lokasi Awal',

                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ==================================================
              // CURRENT LOCATION
              // ==================================================
              _buildLocationOption(
                icon: Icons.my_location,

                title: 'Gunakan lokasi saat ini',

                subtitle: 'Gunakan posisi perangkat',

                onTap: () async {
                  Navigator.pop(context);

                  await _getCurrentLocation();
                },
              ),

              // ==================================================
              // MAP
              // ==================================================
              _buildLocationOption(
                icon: Icons.map_outlined,

                title: 'Tentukan di peta',

                subtitle: 'Pilih titik lokasi melalui OpenStreetMap',

                onTap: () async {
                  Navigator.pop(context);

                  final LatLng? result = await Navigator.push<LatLng>(
                    context,

                    MaterialPageRoute(
                      builder: (context) {
                        return const MapScreen();
                      },
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      selectedStartLocation = result;

                      startLocationController.text = 'Mencari nama lokasi...';
                    });

                    // ==================================================
                    // UBAH KOORDINAT DARI PETA MENJADI NAMA ALAMAT
                    // ==================================================

                    final String address = await _getAddressFromLatLng(
                      result,
                    );

                    if (!mounted) return;

                    setState(() {
                      startLocationController.text = address;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LOCATION OPTION
  // ============================================================

  Widget _buildLocationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        margin: const EdgeInsets.only(bottom: 10),

        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(12),

          border: Border.all(color: AppColors.borderColor),
        ),

        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,

              decoration: const BoxDecoration(
                color: Color(0xFFEAF7FF),
                shape: BoxShape.circle,
              ),

              child: Icon(icon, color: AppColors.primaryBlue, size: 21),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,

                    style: const TextStyle(fontSize: 10, color: AppColors.greyText),
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.greyText, size: 21),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // START DATE
  // ============================================================

  Widget _buildStartDateBox() {
    return GestureDetector(
      onTap: () {
        _selectStartDate();
      },

      child: Container(
        height: 48,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(10),

          border: Border.all(color: AppColors.borderColor),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        padding: const EdgeInsets.symmetric(horizontal: 17),

        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryBlue,
              size: 19,
            ),

            const SizedBox(width: 11),

            Expanded(
              child: Text(
                startDate == null
                    ? 'Pilih tanggal mulai'
                    : _formatDate(startDate!),

                style: TextStyle(
                  fontSize: 13,

                  color: startDate == null ? AppColors.greyText : AppColors.darkText,

                  fontWeight: startDate == null
                      ? FontWeight.w400
                      : FontWeight.w500,
                ),
              ),
            ),

            const Icon(Icons.keyboard_arrow_down, color: AppColors.greyText, size: 22),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DATE SUMMARY
  // ============================================================

  Widget _buildDateSummary() {
    final DateTime endDate = _calculateEndDate();

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),

      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFF),

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: const Color(0xFFDDEFFF)),
      ),

      child: Row(
        children: [
          const Icon(Icons.event_outlined, color: AppColors.primaryBlue, size: 20),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              travelDuration == 1
                  ? 'Perjalanan 1 hari · ${_formatDate(startDate!)}'
                  : 'Perjalanan $travelDuration hari · '
                        '${_formatDate(startDate!)} s/d ${_formatDate(endDate)}',

              style: const TextStyle(
                fontSize: 12,
                color: AppColors.darkText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALCULATE END DATE
  // ============================================================

  DateTime _calculateEndDate() {
    if (startDate == null) {
      return DateTime.now();
    }

    return startDate!.add(Duration(days: travelDuration - 1));
  }

  // ============================================================
  // PARTICIPANT COUNTER
  // ============================================================

  Widget _buildParticipantCounter() {
    return Container(
      height: 48,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: AppColors.borderColor),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          // ==================================================
          // MINUS
          // ==================================================

          GestureDetector(
            onTap: () {
              if (participants > 1) {
                setState(() {
                  participants--;
                });
              }
            },

            child: Container(
              width: 50,
              height: 48,

              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppColors.borderColor)),
              ),

              child: const Icon(Icons.remove, color: AppColors.greyText, size: 24),
            ),
          ),

          // ==================================================
          // VALUE
          // ==================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),

              child: Text(
                '$participants Orang',

                style: const TextStyle(fontSize: 13, color: AppColors.darkText),
              ),
            ),
          ),

          // ==================================================
          // PLUS
          // ==================================================
          GestureDetector(
            onTap: () {
              setState(() {
                participants++;
              });
            },

            child: Container(
              width: 50,
              height: 48,

              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.borderColor)),
              ),

              child: const Icon(Icons.add, color: AppColors.greyText, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CATEGORY SELECTOR
  // ============================================================

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 38,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        physics: const BouncingScrollPhysics(),

        itemCount: categories.length,

        separatorBuilder: (context, index) {
          return const SizedBox(width: 7);
        },

        itemBuilder: (context, index) {
          final category = categories[index];

          final isSelected = selectedCategories.contains(category);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedCategories.remove(category);
                } else {
                  selectedCategories.add(category);
                }
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),

              padding: const EdgeInsets.symmetric(horizontal: 25),

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : const Color(0xFFF1F1F1),

                borderRadius: BorderRadius.circular(20),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
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
  // OUTLINE BUTTON
  // ============================================================

  Widget _buildOutlineButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,

      child: OutlinedButton(
        onPressed: onPressed,

        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,

          foregroundColor: AppColors.darkBlue,

          side: const BorderSide(color: AppColors.darkBlue, width: 1),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),

        child: Text(
          text,

          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,

      child: ElevatedButton(
        onPressed: onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,

          foregroundColor: AppColors.darkBlue,

          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),

        child: Text(
          text,

          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ============================================================
  // SELECT START DATE
  // ============================================================

  Future<void> _selectStartDate() async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,

      initialDate: startDate ?? today,

      firstDate: today,

      lastDate: DateTime(2035),

      helpText: 'Pilih tanggal mulai perjalanan',

      cancelText: 'Batal',

      confirmText: 'Pilih',

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      startDate = picked;
    });
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(DateTime date) {
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

    return '${date.day} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  Future<void> _checkDateOverlapAndProceed(
    BuildContext context,
    VoidCallback onProceed,
  ) async {
    if (startDate == null) {
      onProceed();
      return;
    }

    final DateTime endDate = _calculateEndDate();
    final DateTime newStart = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final DateTime newEnd = DateTime(endDate.year, endDate.month, endDate.day);

    Map<String, dynamic>? overlappingTrip;
    final allItineraries = SavedItineraryService.instance.itineraries.value;

    for (final itin in allItineraries) {
      if (itin.isEmpty) continue;
      final DateTime? s = _parseDate(itin.first['startDate']);
      final DateTime? e = _parseDate(itin.first['endDate']);
      if (s != null && e != null) {
        final DateTime existingStart = DateTime(s.year, s.month, s.day);
        final DateTime existingEnd = DateTime(e.year, e.month, e.day);

        if (!newStart.isAfter(existingEnd) && !newEnd.isBefore(existingStart)) {
          overlappingTrip = itin.first;
          break;
        }
      }
    }

    if (overlappingTrip == null) {
      onProceed();
      return;
    }

    final String tripTitle = overlappingTrip['tripName'] ?? 'Perjalanan';

    final bool? choice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF4E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFE65100),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ada Perjalanan Bentrok!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamu sudah memiliki rencana "$tripTitle" di rentang tanggal ini. Tetap ingin membuat perjalanan baru?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.greyText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Tetap Buat Perjalanan Baru',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text(
                      'Kembali & Ubah Tanggal',
                      style: TextStyle(fontSize: 13, color: AppColors.greyText),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == true) {
      onProceed();
    }
  }

  // ============================================================
  // HANDLE CHOOSE DESTINATION
  // ============================================================

  Future<void> _handleChooseDestination() async {
    FocusScope.of(context).unfocus();

    if (tripNameController.text.trim().isEmpty) {
      _showMessage('Silakan isi nama perjalanan terlebih dahulu.');
      return;
    }

    if (selectedStartLocation == null) {
      _showMessage('Silakan pilih lokasi awal perjalanan terlebih dahulu.');
      return;
    }

    if (selectedDestination == null) {
      _showMessage('Silakan pilih kota/kabupaten tujuan terlebih dahulu.');
      return;
    }

    if (startDate == null) {
      _showMessage('Silakan pilih tanggal mulai perjalanan terlebih dahulu.');
      return;
    }

    if (selectedVehicle == null) {
      _showMessage('Silakan pilih kendaraan terlebih dahulu.');
      return;
    }

    if (selectedCategories.isEmpty) {
      _showMessage('Silakan pilih minimal satu kategori destinasi.');
      return;
    }

    _checkDateOverlapAndProceed(context, () async {
      final DateTime endDate = _calculateEndDate();

      final Map<String, dynamic> travelData = {
        'tripName': tripNameController.text.trim(),
        'startLatLng': selectedStartLocation,
        'destination': selectedDestination,
        'duration': travelDuration,
        'startDate': startDate,
        'endDate': endDate,
        'participants': '$participants Orang',
        'vehicle': selectedVehicle,
        'categories': selectedCategories.toList(),
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          settings: RouteSettings(arguments: travelData),
          builder: (context) {
            return DestinationSelectionScreen(
              selectedCategories: selectedCategories.toSet(),
              travelDuration: travelDuration,
              startLocation: selectedStartLocation,
              startLocationName: startLocationController.text,
              destinationCity: selectedDestination,
              travelData: travelData,
            );
          },
        ),
      );

      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  // ============================================================
  // AI RECOMMENDATION
  // ============================================================

  Future<void> _handleAIRecommendation() async {
    FocusScope.of(context).unfocus();

    if (tripNameController.text.trim().isEmpty) {
      _showMessage('Silakan isi nama perjalanan terlebih dahulu.');
      return;
    }

    if (selectedStartLocation == null) {
      _showMessage('Silakan pilih lokasi awal perjalanan terlebih dahulu.');
      return;
    }

    if (selectedDestination == null) {
      _showMessage('Silakan pilih kota/kabupaten tujuan terlebih dahulu.');
      return;
    }

    if (startDate == null) {
      _showMessage('Silakan pilih tanggal mulai perjalanan terlebih dahulu.');
      return;
    }

    if (selectedVehicle == null) {
      _showMessage('Silakan pilih kendaraan terlebih dahulu.');
      return;
    }

    if (selectedCategories.isEmpty) {
      _showMessage('Silakan pilih minimal satu kategori destinasi.');
      return;
    }

    _checkDateOverlapAndProceed(context, () async {
      final DateTime endDate = _calculateEndDate();

      final Map<String, dynamic> travelData = {
        'tripName': tripNameController.text.trim(),
        'startLocation': selectedStartLocation,
        'destination': selectedDestination,
        'duration': travelDuration,
        'startDate': startDate,
        'endDate': endDate,
        'participants': participants,
        'vehicle': selectedVehicle,
        'categories': selectedCategories.toList(),
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return AIItineraryScreen(
              travelData: travelData,
              startCoordinate: selectedStartLocation,
              startLocationName: startLocationController.text,
            );
          },
        ),
      );

      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    });
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),

        behavior: SnackBarBehavior.floating,

        margin: const EdgeInsets.all(16),

        duration: const Duration(seconds: 2),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}