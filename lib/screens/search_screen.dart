import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/destinations_data.dart';
import '../services/destination_service.dart';
import '../services/search_history_service.dart';
import '../widgets/smart_image.dart';
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

  // FocusNode search field -- dipakai supaya keyboard bisa auto-fokus
  // begitu halaman ini dibuka dalam keadaan kosong (dari home).
  final FocusNode _searchFocusNode = FocusNode();

  late String _keyword = widget.keyword;

  // ============================================================
  // URUTKAN (SORT)
  // ============================================================

  _SortOption _sortOption = _SortOption.relevansi;

  @override
  void initState() {
    super.initState();
    if (DestinationService.instance.destinations.value.isEmpty) {
      DestinationService.instance.fetchDashboardData().then((_) {
        if (mounted) setState(() {});
      });
    }

    // STATE KOSONG -- riwayat pencarian & pencarian populer, sumbernya
    // dari layanan masing-masing (SharedPreferences & backend).
    SearchHistoryService.instance.loadHistory();
    if (DestinationService.instance.popularSearches.value.isEmpty) {
      DestinationService.instance.fetchPopularSearches();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // TRIGGER PENCARIAN DARI RIWAYAT / KATEGORI / POPULER
  // ============================================================
  //
  // Dipakai bareng oleh 3 section di state kosong: isi search field
  // dengan value yang dipilih, lalu langsung tampilkan hasilnya
  // (state berpindah ke "ada teks" secara alami).
  // ============================================================

  void _applySearch(String value, {bool saveToHistory = true}) {
    _searchController.text = value;
    _searchController.selection = TextSelection.collapsed(offset: value.length);

    setState(() {
      _keyword = value;
    });

    _searchFocusNode.unfocus();

    if (saveToHistory) {
      SearchHistoryService.instance.addSearch(value);
    }
  }

  // ============================================================
  // DATA DESTINASI (FROM LARAVEL BACKEND DB)
  // ============================================================

  List<Map<String, String>> get destinations {
    final query = _keyword.toLowerCase().trim();
    final serverList = DestinationService.instance.destinations.value;

    final List<Map<String, String>> source =
        serverList.map((d) => d.toDisplayMap()).toList();

    final filtered = source.where((destination) {
      final name = (destination['name'] ?? '').toLowerCase();
      final location = (destination['location'] ?? '').toLowerCase();
      final category = (destination['category'] ?? '').toLowerCase();

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
          fontSize: 14,
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
    // STATE KOSONG (belum ada teks) vs STATE ADA TEKS (nampilin hasil,
    // perilakunya tetap sama seperti sebelumnya).
    final bool isEmptyKeyword = _keyword.trim().isEmpty;
    final results = isEmptyKeyword ? const <Map<String, String>>[] : destinations;

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
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColorLight),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF555555),
                        size: 27,
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
                              focusNode: _searchFocusNode,
                              autofocus: widget.keyword.isEmpty,
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

                                if (value.trim().isNotEmpty) {
                                  SearchHistoryService.instance.addSearch(value.trim());
                                }

                                FocusScope.of(context).unfocus();
                              },
                              maxLines: 1,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Cari destinasi...',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppColors.darkText,
                                fontSize: 14,
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

            if (isEmptyKeyword)
              // ==================================================
              // STATE KOSONG -- riwayat, kategori, & pencarian populer
              // ==================================================
              Expanded(child: _buildDiscoverState(context))
            else ...[
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
                          fontSize: 14,
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
                                fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATE KOSONG -- RIWAYAT + KATEGORI + PENCARIAN POPULER
  // ============================================================

  Widget _buildDiscoverState(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      // SizedBox(width: double.infinity) di sini PENTING -- tanpa ini,
      // pas kontennya cuma dikit (misal cuma "Kategori Pencarian" doang,
      // riwayat & populer lagi kosong), Column bakal nyusut selebar
      // konten terlebarnya doang. Karena Column paling luar (di
      // SafeArea) defaultnya CrossAxisAlignment.center, blok yang
      // nyusut itu jadi ke-tengah-in ke layar, bukan nempel ke padding
      // kiri 25 -- makanya kelihatan geser ke kanan waktu section lain
      // kosong. Maksa full width di sini bikin crossAxisAlignment.start
      // di bawah selalu efektif, apapun isinya.
      child: SizedBox(
        width: double.infinity,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchHistorySection(),

          // Gap ini cuma muncul kalau riwayat pencarian ADA isinya --
          // supaya waktu riwayat kosong, jarak ke "Kategori Pencarian"
          // tetap sama persis kayak jarak dari header ke section
          // pertama pada umumnya (gak ada gap 24 yang "nyangkut").
          ValueListenableBuilder<List<String>>(
            valueListenable: SearchHistoryService.instance.history,
            builder: (context, history, _) {
              return history.isEmpty
                  ? const SizedBox.shrink()
                  : const SizedBox(height: 24);
            },
          ),

          _buildCategorySection(),
          const SizedBox(height: 24),
          _buildPopularSearchSection(),
        ],
        ),
      ),
    );
  }

  // ==================================================
  // RIWAYAT PENCARIAN
  // ==================================================

  Widget _buildSearchHistorySection() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: SearchHistoryService.instance.history,
      builder: (context, history, _) {
        if (history.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat Pencarian',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => SearchHistoryService.instance.clearAll(),
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...history.map((keyword) => _buildHistoryTile(keyword)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTile(String keyword) {
    return GestureDetector(
      onTap: () => _applySearch(keyword, saveToHistory: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.history, color: Colors.grey, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                keyword,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 13,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => SearchHistoryService.instance.removeSearch(keyword),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.close, color: Colors.grey, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // KATEGORI PENCARIAN
  // ==================================================

  Widget _buildCategorySection() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: DestinationService.instance.categories,
      builder: (context, categories, _) {
        final list = categories.where((c) => c != 'Semua').toList();
        if (list.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kategori Pencarian',
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: list.map((category) {
                return _buildCategoryChip(category);
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    return GestureDetector(
      // CATATAN - kategori difilter lewat search field yang sudah ada
      // (getter `destinations` sudah cek kecocokan nama/lokasi/kategori),
      // jadi tap kategori otomatis pindah ke state "ada teks" dengan
      // hasil yang sudah terfilter, tanpa perlu jalur filter terpisah.
      onTap: () => _applySearch(category, saveToHistory: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE2F3FF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForCategory(category), color: AppColors.primaryBlue, size: 16),
            const SizedBox(width: 6),
            Text(
              category,
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Alam':
        return Icons.landscape_outlined;
      case 'Kuliner':
        return Icons.restaurant_outlined;
      case 'Budaya':
        return Icons.temple_buddhist_outlined;
      case 'Buatan':
        return Icons.apartment_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  // ==================================================
  // PENCARIAN POPULER
  // ==================================================

  Widget _buildPopularSearchSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: DestinationService.instance.isLoadingPopular,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<String?>(
          valueListenable: DestinationService.instance.errorPopular,
          builder: (context, popularError, _) {
            return ValueListenableBuilder<List<String>>(
              valueListenable: DestinationService.instance.popularSearches,
              builder: (context, popularSearches, _) {
                // Kosong/gagal fetch -- sembunyikan section-nya saja,
                // jangan sampai bikin layar error/crash.
                if (!isLoading && (popularError != null || popularSearches.isEmpty)) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pencarian Populer',
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: popularSearches.map((keyword) {
                          return _buildPopularChip(keyword);
                        }).toList(),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPopularChip(String keyword) {
    return GestureDetector(
      onTap: () => _applySearch(keyword, saveToHistory: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E3E3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, color: AppColors.primaryBlue, size: 15),
            const SizedBox(width: 6),
            Text(
              keyword,
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
        height: 172, // CHANGED - card diperbesar tingginya supaya konten tidak overflow setelah font membesar

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
            height: 158, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar

            child: Stack(
              children: [
                SmartImage(
                  imagePathOrUrl: destination['image'] ?? 'assets/images/pulau_wayang.jpg',
                  width: 135,
                  height: 158, // CHANGED - disesuaikan agar tetap pas dengan font yang lebih besar
                  borderRadius: BorderRadius.circular(12),
                  fit: BoxFit.cover,
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
                          fontSize: 12, // CHANGED - font terkecil jadi 12
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
                    fontSize: 12, // CHANGED - font terkecil jadi 12
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
                        fontSize: 12, // CHANGED - font terkecil jadi 12
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      destination['reviews']!,

                      style: const TextStyle(
                        color: AppColors.greyText,
                        fontSize: 12, // CHANGED - font terkecil jadi 12
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
                    vertical: 4, // CHANGED - padding menyesuaikan font yang lebih besar
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
                      fontSize: 12, // CHANGED - font terkecil jadi 12
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
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}