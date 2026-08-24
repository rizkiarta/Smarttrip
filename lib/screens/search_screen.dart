import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/destinations_data.dart';
import 'detail_destination_screen.dart';
import '../widgets/love_button.dart';

// ================================================================
// PILIHAN URUTKAN
// ================================================================

enum _SortOption { relevansi, ratingTertinggi, namaAZ }

class SearchScreen extends StatefulWidget {
  final String keyword;

  const SearchScreen({
    super.key,
    required this.keyword,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // ============================================================
  // KEYWORD (BISA DIKETIK ULANG LANGSUNG DI HALAMAN INI)
  // ============================================================
  //
  // Sebelumnya keyword cuma ditampilkan sebagai Text statis, jadi
  // untuk cari kata kunci baru harus balik dulu ke home. Sekarang
  // field-nya beneran bisa diketik (controller diisi keyword awal
  // dari home), dan hasil pencarian langsung update tiap ketikan
  // lewat setState -- tidak perlu tekan Enter atau pindah halaman.
  // ============================================================

  late final TextEditingController _searchController = TextEditingController(
    text: widget.keyword,
  );

  late String _keyword = widget.keyword;

  // ============================================================
  // URUTKAN (SORT)
  // ============================================================

  _SortOption _sortOption = _SortOption.relevansi;

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATA DESTINASI
  // ============================================================

  // Sumber datanya sekarang kDestinationsData (sama seperti home,
  // rekomendasi, dan prediksi kepadatan), bukan daftar lokal terpisah
  // seperti sebelumnya. Ini penting supaya setiap destinasi punya 'id'
  // yang konsisten di seluruh layar — dibutuhkan supaya status
  // "love"/simpan pada sebuah destinasi tetap sama walau dilihat dari
  // hasil pencarian, home, atau layar lain.
  List<Map<String, String>> get destinations {
    final query = _keyword.toLowerCase().trim();

    final filtered = kDestinationsData.where((destination) {
      final name = destination['name']!.toLowerCase();
      final location = destination['location']!.toLowerCase();
      final category = destination['category']!.toLowerCase();

      return name.contains(query) ||
          location.contains(query) ||
          category.contains(query);
    }).toList();

    switch (_sortOption) {
      case _SortOption.ratingTertinggi:
        filtered.sort((a, b) {
          final ratingA = double.tryParse(a['rating'] ?? '') ?? 0;
          final ratingB = double.tryParse(b['rating'] ?? '') ?? 0;

          return ratingB.compareTo(ratingA);
        });
        break;

      case _SortOption.namaAZ:
        filtered.sort((a, b) {
          return (a['name'] ?? '')
              .toLowerCase()
              .compareTo((b['name'] ?? '').toLowerCase());
        });
        break;

      case _SortOption.relevansi:
        // Urutan hasil filter apa adanya (sesuai urutan di
        // kDestinationsData), tidak diurutkan ulang.
        break;
    }

    return filtered;
  }

  // ============================================================
  // LABEL TOMBOL URUTKAN (IKUT PILIHAN AKTIF)
  // ============================================================

  String get _sortLabel {
    switch (_sortOption) {
      case _SortOption.ratingTertinggi:
        return 'Rating';
      case _SortOption.namaAZ:
        return 'A-Z';
      case _SortOption.relevansi:
        return 'Urutkan';
    }
  }

  // ============================================================
  // BOTTOM SHEET PILIHAN URUTKAN
  // ============================================================

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Urutkan Berdasarkan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                _buildSortTile(
                  label: 'Relevansi',
                  option: _SortOption.relevansi,
                ),

                _buildSortTile(
                  label: 'Rating Tertinggi',
                  option: _SortOption.ratingTertinggi,
                ),

                _buildSortTile(
                  label: 'Nama (A-Z)',
                  option: _SortOption.namaAZ,
                ),

                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile({
    required String label,
    required _SortOption option,
  }) {
    final bool selected = _sortOption == option;

    return ListTile(
      onTap: () {
        setState(() {
          _sortOption = option;
        });

        Navigator.pop(context);
      },
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? AppColors.primaryBlue : AppColors.darkText,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.primaryBlue, size: 18)
          : null,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final results = destinations;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [

            // ==================================================
            // HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                25,
                15,
                25,
                0,
              ),
              child: Row(
                children: [

                  // ==================================================
                  // BACK BUTTON
                  // ==================================================

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.darkText,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ==================================================
                  // SEARCH KEYWORD
                  // ==================================================

                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius:
                            BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE7E7E7),
                        ),
                      ),
                      child: Row(
                        children: [

                          const Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: 20,
                          ),

                          const SizedBox(width: 10),

                          // ==================================================
                          // INPUT KEYWORD (BISA DIKETIK LANGSUNG DI SINI)
                          // ==================================================

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: (value) {
                                // Live filter -- hasil update tiap
                                // ketikan, tidak perlu tekan Enter.
                                setState(() {
                                  _keyword = value;
                                });
                              },
                              onSubmitted: (value) {
                                setState(() {
                                  _keyword = value;
                                });

                                FocusScope.of(context).unfocus();
                              },
                              maxLines: 1,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Cari destinasi...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          // ==================================================
                          // CLEAR KEYWORD (BUKAN BALIK HALAMAN)
                          // ==================================================
                          //
                          // Cuma muncul kalau ada teksnya, dan cuma
                          // membersihkan input -- pengguna tetap di
                          // halaman ini, sama seperti aplikasi pada
                          // umumnya.
                          // ==================================================

                          ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, _) {
                              if (value.text.isEmpty) {
                                return const SizedBox();
                              }

                              return GestureDetector(
                                onTap: () {
                                  _searchController.clear();

                                  setState(() {
                                    _keyword = '';
                                  });
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // RESULT HEADER
            // ==================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
              ),
              child: Row(
                children: [

                  // JUMLAH HASIL
                  Expanded(
                    child: Text(
                      '${results.length} destinasi ditemukan',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // ==================================================
                  // SORT BUTTON
                  // ==================================================

                  GestureDetector(
                    onTap: _showSortOptions,
                    child: Container(
                      height: 32,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE3E3E3),
                        ),
                      ),
                      child: Row(
                        children: [

                          const Icon(
                            Icons.tune,
                            color: AppColors.primaryBlue,
                            size: 16,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            _sortLabel,
                            style: const TextStyle(
                              color: AppColors.darkText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // HASIL PENCARIAN
            // ==================================================

            Expanded(
              child: results.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics:
                          const BouncingScrollPhysics(),

                      padding: const EdgeInsets.fromLTRB(
                        25,
                        0,
                        25,
                        30,
                      ),

                      itemCount: results.length,

                      separatorBuilder: (
                        context,
                        index,
                      ) {
                        return const SizedBox(
                          height: 12,
                        );
                      },

                      itemBuilder: (
                        context,
                        index,
                      ) {
                        return _buildDestinationCard(
                          context,
                          results[index],
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
  // DESTINATION CARD
  // ============================================================

  Widget _buildDestinationCard(
    BuildContext context,
    Map<String, String> destination,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DetailDestinationScreen(
                destinationId: destination['id'],
                name: destination['name']!,
                location: destination['location']!,
                rating: destination['rating']!,
                reviews: destination['reviews']!,
                mainImage: destination['image']!,
                galleryImages: kDestinationGalleryImages[destination['id']],
                description: destination['description']!,
              );
            },
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 155,

      padding: const EdgeInsets.all(7),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: const Color(0xFFE6E6E6),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==================================================
          // IMAGE + LOVE BUTTON
          // ==================================================

          SizedBox(
            width: 135,
            height: 141,

            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: SizedBox(
                    width: 135,
                    height: 141,

                    child: Image.asset(
                      destination['image']!,

                      fit: BoxFit.cover,

                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color: const Color(0xFFE8F4FA),

                          child: const Icon(
                            Icons.image_outlined,
                            color: AppColors.primaryBlue,
                            size: 35,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                Positioned(
                  top: 6,
                  right: 6,
                  child: LoveButton(
                    destinationId: destination['id']!,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================
          // INFORMATION
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                // ==================================================
                // NAME
                // ==================================================

                Text(
                  destination['name']!,

                  maxLines: 1,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // ==================================================
                // LOCATION
                // ==================================================

                Row(
                  children: [

                    const Icon(
                      Icons.location_on,
                      color: AppColors.primaryBlue,
                      size: 15,
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        destination['location']!,

                        maxLines: 1,

                        overflow:
                            TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: AppColors.greyText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                // ==================================================
                // DESCRIPTION
                // ==================================================

                Text(
                  destination['description']!,

                  maxLines: 3,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: AppColors.greyText,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),

                const Spacer(),

                // ==================================================
                // RATING
                // ==================================================

                Row(
                  children: [

                    const Icon(
                      Icons.star,
                      color: Color(0xFF164B9B),
                      size: 15,
                    ),

                    const SizedBox(width: 4),

                    Text(
                      destination['rating']!,

                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      destination['reviews']!,

                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // ==================================================
                // CATEGORY
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFE2F3FF),

                    borderRadius:
                        BorderRadius.circular(10),
                  ),

                  child: Text(
                    destination['category']!,

                    style: const TextStyle(
                      color: Color(0xFF1689D5),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
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
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [

          Container(
            width: 65,
            height: 65,

            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FA),

              borderRadius:
                  BorderRadius.circular(20),
            ),

            child: const Icon(
              Icons.search_off,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Destinasi tidak ditemukan',

            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'Tidak ada hasil untuk "$_keyword"',

            style: const TextStyle(
              color: AppColors.greyText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}