import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

class MapLocationResult {
  final LatLng location;
  final String address;

  const MapLocationResult({
    required this.location,
    required this.address,
  });
}

class MapScreen extends StatefulWidget {
  final bool focusSearch;
  final LatLng? initialLocation;

  const MapScreen({
    super.key,
    this.focusSearch = false,
    this.initialLocation,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ============================================================
  // MAP
  // ============================================================

  final MapController mapController = MapController();

  late LatLng selectedLocation;

  // ============================================================
  // SEARCH
  // ============================================================

  final TextEditingController searchController =
      TextEditingController();

  final FocusNode searchFocusNode = FocusNode();

  List<Map<String, dynamic>> searchResults = [];

  bool isSearching = false;
  bool isLoadingAddress = true;

  // ============================================================
  // ADDRESS
  // ============================================================

  String selectedAddress = 'Mencari alamat...';

  String selectedTitle = 'Lokasi yang dipilih';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    selectedLocation =
        widget.initialLocation ??
        const LatLng(
          -5.3971,
          105.2668,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddress(selectedLocation);

      if (widget.focusSearch) {
        Future.delayed(
          const Duration(milliseconds: 350),
          () {
            if (mounted) {
              searchFocusNode.requestFocus();
            }
          },
        );
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
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
        child: Stack(
          children: [

            // ====================================================
            // MAP
            // ====================================================

            Positioned.fill(
              child: FlutterMap(
                mapController: mapController,

                options: MapOptions(
                  initialCenter: selectedLocation,
                  initialZoom: 15,

                  minZoom: 5,
                  maxZoom: 19,

                  onPositionChanged: (
                    camera,
                    hasGesture,
                  ) {
                    if (hasGesture) {
                      final center = camera.center;

                      selectedLocation = center;

                      _loadAddress(
                        center,
                        showLoading: false,
                      );
                    }
                  },
                ),

                children: [

                  // =================================================
                  // OSM
                  // =================================================

                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.smarttrip.app',
                  ),

                  // =================================================
                  // CURRENT LOCATION DOT
                  // =================================================

                  if (widget.initialLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: widget.initialLocation!,
                          width: 20,
                          height: 20,

                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // =================================================
                  // ATTRIBUTION
                  // =================================================

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                      ),
                      TextSourceAttribution(
                        'CARTO',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ====================================================
            // TOP HEADER
            // ====================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,

              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  12,
                ),

                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset:
                          const Offset(0, 2),
                    ),
                  ],
                ),

                child: Column(
                  children: [

                    // =================================================
                    // APP BAR
                    // =================================================

                    Row(
                      children: [

                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },

                          child: const SizedBox(
                            width: 45,
                            height: 45,

                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.darkText,
                              size: 21,
                            ),
                          ),
                        ),

                        const Expanded(
                          child: Text(
                            'Pilih Lokasi Awal',
                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 45,
                        ),
                      ],
                    ),

                    // =================================================
                    // SEARCH BAR
                    // =================================================

                    Container(
                      height: 50,

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius:
                            BorderRadius.circular(15),

                        border: Border.all(
                          color:
                               AppColors.fieldBorder,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(0.08),
                            blurRadius: 8,
                            offset:
                                const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [

                          const SizedBox(
                            width: 15,
                          ),

                          const Icon(
                            Icons.search,
                            color: AppColors.primaryBlue,
                            size: 23,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: TextField(
                              controller:
                                  searchController,

                              focusNode:
                                  searchFocusNode,

                              textInputAction:
                                  TextInputAction.search,

                              onSubmitted: (_) {
                                _searchLocation();
                              },

                              decoration:
                                  const InputDecoration(
                                hintText:
                                    'Cari tempat atau alamat...',
                                border:
                                    InputBorder.none,
                                isDense: true,
                              ),

                              style:
                                  const TextStyle(
                                fontSize: 14,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),

                          if (searchController
                              .text
                              .isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 19,
                                color: AppColors.greyText,
                              ),

                              onPressed: () {
                                searchController.clear();

                                setState(() {
                                  searchResults = [];
                                });
                              },
                            ),

                          IconButton(
                            icon: isSearching
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward,
                                    color:
                                        AppColors.darkBlue,
                                    size: 21,
                                  ),

                            onPressed:
                                isSearching
                                    ? null
                                    : _searchLocation,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ====================================================
            // SEARCH RESULT
            // ====================================================

            if (searchResults.isNotEmpty)
              Positioned(
                top: 125,
                left: 20,
                right: 20,

                child: Container(
                  constraints:
                      const BoxConstraints(
                    maxHeight: 260,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(15),

                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(
                          0.15,
                        ),
                        blurRadius: 15,
                        offset:
                            const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: ListView.separated(
                    shrinkWrap: true,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 5,
                    ),

                    itemCount:
                        searchResults.length,

                    separatorBuilder:
                        (context, index) {
                      return const Divider(
                        height: 1,
                        indent: 55,
                      );
                    },

                    itemBuilder:
                        (context, index) {
                      final result =
                          searchResults[index];

                      final name =
                          result['display_name']
                              ?.toString() ??
                          'Lokasi';

                      return ListTile(
                        leading:
                            Container(
                          width: 38,
                          height: 38,

                          decoration:
                              const BoxDecoration(
                            color:
                                AppColors.lightBlue,
                            shape:
                                BoxShape.circle,
                          ),

                          child:
                              const Icon(
                            Icons.location_on,
                            color:
                                AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),

                        title: Text(
                          name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,

                          style:
                              const TextStyle(
                            fontSize: 14, // CHANGED - nama lokasi jadi 14
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),

                        onTap: () {
                          _selectSearchResult(
                            result,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

            // ====================================================
            // CENTER MARKER
            // ====================================================

            IgnorePointer(
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 40,
                  ),

                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,

                    children: [

                      Container(
                        width: 52,
                        height: 52,

                        decoration:
                            const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape:
                              BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      Container(
                        width: 4,
                        height: 8,

                        decoration:
                            BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ====================================================
            // CURRENT LOCATION BUTTON
            // ====================================================

            Positioned(
              right: 20,
              bottom: 300,

              child: Material(
                color: Colors.white,
                elevation: 5,
                shape:
                    const CircleBorder(),

                child: InkWell(
                  customBorder:
                      const CircleBorder(),

                  onTap:
                      _useCurrentLocation,

                  child: const SizedBox(
                    width: 52,
                    height: 52,

                    child: Icon(
                      Icons.my_location,
                      color: AppColors.darkBlue,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // BOTTOM PANEL
            // ====================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,

              child: Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  18,
                  22,
                  20,
                ),

                decoration:
                    const BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.only(
                    topLeft:
                        Radius.circular(28),
                    topRight:
                        Radius.circular(28),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Color(0x25000000),
                      blurRadius: 15,
                      offset:
                          Offset(0, -3),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // =================================================
                    // TITLE
                    // =================================================

                    const Text(
                      'Set lokasi awal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // =================================================
                    // ADDRESS CARD
                    // =================================================

                    Container(
                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEAF7FF,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          15,
                        ),
                      ),

                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                          Container(
                            width: 42,
                            height: 42,

                            decoration:
                                const BoxDecoration(
                              color:
                                  AppColors.primaryBlue,
                              shape:
                                  BoxShape.circle,
                            ),

                            child:
                                const Icon(
                              Icons.location_on,
                              color:
                                  Colors.white,
                              size: 22,
                            ),
                          ),

                          const SizedBox(
                            width: 12,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [

                                Text(
                                  selectedTitle,

                                  maxLines: 1,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    color:
                                        AppColors.darkText,
                                  ),
                                ),

                                const SizedBox(
                                  height: 5,
                                ),

                                Text(
                                  selectedAddress,

                                  maxLines: 2,

                                  overflow:
                                      TextOverflow
                                          .ellipsis,

                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    color:
                                        AppColors.greyText,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    // =================================================
                    // BUTTON
                    // =================================================

                    SizedBox(
  width: double.infinity,
  height: 48,
  child: ElevatedButton(
    onPressed: () {
      Navigator.of(context).pop(
        selectedLocation,
      );
    },

    style: ElevatedButton.styleFrom(
      backgroundColor:
          const Color(0xFF0D47A1),

      foregroundColor:
          Colors.white,

      elevation: 0,

      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(25),
      ),
    ),

    child: const Text(
      'Gunakan Lokasi Ini',

      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
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
  // SEARCH LOCATION
  // ============================================================

  Future<void> _searchLocation() async {
    final query =
        searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q':
              '$query, Lampung, Indonesia',
          'format': 'jsonv2',
          'limit': '5',
          'countrycodes': 'id',
          'addressdetails': '1',
        },
      );

      final response =
          await http.get(
        uri,
        headers: {
          'User-Agent':
              'SmartTrip/1.0 (smarttrip.app)',
          'Accept-Language':
              'id-ID,id;q=0.9',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Gagal mencari lokasi',
        );
      }

      final data =
          jsonDecode(response.body);

      if (!mounted) return;

      setState(() {
        searchResults =
            List<Map<String, dynamic>>.from(
          data,
        );
      });

      if (searchResults.isEmpty) {
        _showMessage(
          'Lokasi tidak ditemukan.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Tidak dapat mencari lokasi. Periksa koneksi internet.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  // ============================================================
  // SELECT SEARCH RESULT
  // ============================================================

  void _selectSearchResult(
    Map<String, dynamic> result,
  ) {
    final lat =
        double.tryParse(
      result['lat'].toString(),
    );

    final lon =
        double.tryParse(
      result['lon'].toString(),
    );

    if (lat == null || lon == null) {
      return;
    }

    final location =
        LatLng(lat, lon);

    setState(() {
      selectedLocation =
          location;

      searchResults = [];

      selectedTitle =
          result['name']?.toString() ??
          'Lokasi yang dipilih';

      selectedAddress =
          result['display_name']?.toString() ??
          'Alamat tidak tersedia';

      isLoadingAddress = false;
    });

    mapController.move(
      location,
      17,
    );
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Aktifkan GPS terlebih dahulu.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _showMessage(
          'Izin lokasi diperlukan untuk menggunakan posisi saat ini.',
        );
        return;
      }

      final position =
          await Geolocator
              .getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
        ),
      );

      final location =
          LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        selectedLocation =
            location;

        isLoadingAddress = true;
      });

      mapController.move(
        location,
        17,
      );

      await _loadAddress(
        location,
      );
    } catch (e) {
      _showMessage(
        'Tidak dapat mengambil lokasi perangkat.',
      );
    }
  }

  // ============================================================
  // REVERSE GEOCODING
  // ============================================================

  Future<void> _loadAddress(
    LatLng location, {
    bool showLoading = true,
  }) async {
    if (showLoading) {
      setState(() {
        isLoadingAddress = true;
      });
    }

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat':
              location.latitude.toString(),
          'lon':
              location.longitude.toString(),
          'format': 'jsonv2',
          'addressdetails': '1',
        },
      );

      final response =
          await http.get(
        uri,
        headers: {
          'User-Agent':
              'SmartTrip/1.0 (smarttrip.app)',
          'Accept-Language':
              'id-ID,id;q=0.9',
        },
      );

      if (response.statusCode != 200) {
        throw Exception();
      }

      final data =
          jsonDecode(response.body);

      if (!mounted) return;

      final address =
          data['address']
              as Map<String, dynamic>?;

      final displayName =
          data['display_name']
              ?.toString();

      String title =
          address?['road']
                  ?.toString() ??
              address?['amenity']
                  ?.toString() ??
              address?['village']
                  ?.toString() ??
              address?['town']
                  ?.toString() ??
              address?['city']
                  ?.toString() ??
              'Lokasi yang dipilih';

      String detail =
          displayName ??
          '${location.latitude.toStringAsFixed(6)}, '
              '${location.longitude.toStringAsFixed(6)}';

      setState(() {
        selectedTitle =
            title;

        selectedAddress =
            detail;

        isLoadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        selectedTitle =
            'Lokasi yang dipilih';

        selectedAddress =
            '${location.latitude.toStringAsFixed(6)}, '
            '${location.longitude.toStringAsFixed(6)}';

        isLoadingAddress = false;
      });
    }
  }

  // ============================================================
  // USE SELECTED LOCATION
  // ============================================================

  void _useSelectedLocation() {
    Navigator.pop(
      context,

      MapLocationResult(
        location: selectedLocation,
        address:
            selectedAddress,
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}