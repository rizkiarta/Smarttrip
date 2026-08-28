import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../services/my_reviews_service.dart';
import '../services/profile_service.dart';
import '../widgets/smart_image.dart';
import '../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final String destinationName;
  final double overallRating;
  final int totalReviews;

  final String? destinationId;

  const ReviewScreen({
    super.key,
    required this.destinationName,
    this.overallRating = 4.8,
    this.totalReviews = 235,
    this.destinationId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // ============================================================
  // RATING DISTRIBUTION (persentase per bintang, dari 5 ke 1)
  // ============================================================

  static const Map<int, double> _ratingBreakdown = {
    5: 0.64,
    4: 0.22,
    3: 0.08,
    2: 0.04,
    1: 0.02,
  };

  List<Map<String, dynamic>> _serverReviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _fetchDestinationReviews();
  }

  Future<void> _fetchDestinationReviews() async {
    if (widget.destinationId == null || widget.destinationId!.isEmpty) return;
    if (mounted) setState(() => _isLoadingReviews = true);
    try {
      final safeId = Uri.encodeComponent(widget.destinationId!);
      final res = await ApiService.instance.get('destinations/$safeId/reviews');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List).map((r) => _mapReview(r)).toList();
        if (mounted) setState(() => _serverReviews = list);
      }
    } on ApiException catch (e) {
      debugPrint('Fetch reviews ApiException: ${e.message}');
    } catch (e) {
      debugPrint('Fetch reviews error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Map<String, dynamic> _mapReview(dynamic r) => {
    'id': r['id'],
    'avatar': r['user_avatar'],
    'name': r['user_name'] ?? 'Pengguna SmartTrip',
    'rating': (r['rating'] as num?)?.toDouble() ?? 5.0,
    'time': r['created_at'] ?? 'Baru saja',
    'text': r['review_text'] ?? '',
    'likes': (r['likes_count'] ?? 0).toString(),
    'photos': r['photos'] != null ? List<String>.from(r['photos']) : <String>[],
    'liked': r['liked'] == true,
  };

  final List<Map<String, dynamic>> _reviews = [];


  // ============================================================
  // FILTER STATE (null = Semua)
  // ============================================================

  int? _selectedStarFilter;

  // ============================================================
  // RENDER FOTO ULASAN
  // ============================================================
  //
  // Foto bawaan (mock data) disimpan sebagai path assets/...,
  // sedangkan foto yang dipilih pengguna dari kamera/galeri
  // disimpan sebagai path file asli di perangkat. Widget ini
  // otomatis menentukan cara menampilkan keduanya.
  // ============================================================

  Widget _buildPhotoImage(String path) {
    return SmartImage(
      imagePathOrUrl: path,
      fit: BoxFit.cover,
    );
  }


  List<Map<String, dynamic>> get _allReviews =>
      _serverReviews.isNotEmpty ? _serverReviews : _reviews;

  List<Map<String, dynamic>> get _filteredReviews {
    final list = _allReviews;
    if (_selectedStarFilter == null) return list;

    return list.where((review) {
      final double rating = (review['rating'] as num).toDouble();
      return rating.round() == _selectedStarFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
                    children: [
                      _buildRatingSummary(),

                      const SizedBox(height: 22),

                      _buildFilterChips(),

                      const SizedBox(height: 18),

                      if (_isLoadingReviews)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_filteredReviews.isEmpty)
                        _buildEmptyState()
                      else
                        ..._filteredReviews.map((review) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildReviewCard(review),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),

            // ====================================================
            // FLOATING "BERI RATING" BUTTON
            // ====================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomButton(context),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:  AppColors.borderColorLight,
                    ),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),

            const Text(
              'Ulasan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RATING SUMMARY (angka besar + bar distribusi)
  // ============================================================

  Widget _buildRatingSummary() {
    final int fullStars = widget.overallRating.floor();
    final bool hasHalfStar = (widget.overallRating - fullStars) >= 0.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ==================================================
        // ANGKA + BINTANG BESAR
        // ==================================================

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.overallRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: List.generate(5, (index) {
                  IconData icon;

                  if (index < fullStars) {
                    icon = Icons.star;
                  } else if (index == fullStars && hasHalfStar) {
                    icon = Icons.star_half;
                  } else {
                    icon = Icons.star_border;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(icon, color: AppColors.primaryBlue, size: 18),
                  );
                }),
              ),

              const SizedBox(height: 6),

              Text(
                '(${widget.totalReviews} ulasan)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // ==================================================
        // BAR DISTRIBUSI
        // ==================================================

        Expanded(
          child: Column(
            children: _ratingBreakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${entry.key}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greyText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value,
                          minHeight: 6,
                          backgroundColor:  AppColors.borderColor,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FILTER CHIPS
  // ============================================================

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildFilterChip(
            label: 'Semua',
            active: _selectedStarFilter == null,
            onTap: () {
              setState(() {
                _selectedStarFilter = null;
              });
            },
          ),

          const SizedBox(width: 8),

          for (int star in const [5, 4, 3, 2, 1]) ...[
            _buildFilterChip(
              label: '$star',
              icon: Icons.star,
              active: _selectedStarFilter == star,
              onTap: () {
                setState(() {
                  _selectedStarFilter = star;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryBlue : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: active ? Colors.white : AppColors.primaryBlue,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.darkText,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: Color(0xFFCCCCCC),
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada ulasan dengan rating ini.',
            style: TextStyle(fontSize: 12, color: AppColors.greyText),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  // ============================================================
  // TOGGLE LIKE
  // ============================================================

  Future<void> _toggleLike(Map<String, dynamic> review) async {
    final dynamic rawId = review['id'];
    final int? reviewId = (rawId is int) ? rawId : int.tryParse(rawId?.toString() ?? '');
    final bool currentlyLiked = review['liked'] as bool? ?? false;
    final int currentLikes = int.tryParse(review['likes']?.toString() ?? '0') ?? 0;

    setState(() {
      if (currentlyLiked) {
        review['liked'] = false;
        review['likes'] = (currentLikes - 1).clamp(0, 999999).toString();
      } else {
        review['liked'] = true;
        review['likes'] = (currentLikes + 1).toString();
      }
    });

    if (reviewId != null) {
      try {
        final res = await ApiService.instance.post('reviews/$reviewId/like');
        if (res['likes_count'] != null && mounted) {
          setState(() {
            review['liked'] = res['liked'] == true;
            review['likes'] = res['likes_count'].toString();
          });
        }
      } catch (e) {
        debugPrint('Toggle review like API error: $e');
      }
    }
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final double rating = review['rating'] as double;
    final int fullStars = rating.floor();
    final bool hasHalfStar = (rating - fullStars) >= 0.5;
    final List<String> photos = review['photos'] as List<String>;
    final bool liked = review['liked'] as bool? ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ==================================================
          // USER
          // ==================================================

          Row(
            children: [
              buildAvatarImage(review['avatar'] as String?, size: 42),


              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Row(
                      children: List.generate(5, (index) {
                        if (index < fullStars) {
                          return const Icon(
                            Icons.star,
                            color: AppColors.darkBlue,
                            size: 15,
                          );
                        }

                        if (index == fullStars && hasHalfStar) {
                          return const Icon(
                            Icons.star_half,
                            color: AppColors.darkBlue,
                            size: 15,
                          );
                        }

                        return const Icon(
                          Icons.star_border,
                          color: AppColors.darkBlue,
                          size: 15,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Text(
                review['time'] as String,
                style: const TextStyle(fontSize: 10, color: AppColors.greyText),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ==================================================
          // TEXT
          // ==================================================

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              review['text'] as String,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Color(0xFF444444),
              ),
            ),
          ),

          // ==================================================
          // PHOTOS (opsional)
          // ==================================================

          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: List.generate(photos.length, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == photos.length - 1 ? 0 : 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.3,
                        child: _buildPhotoImage(photos[index]),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 12),

          // ==================================================
          // LIKE
          // ==================================================

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => _toggleLike(review),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: liked
                            ? AppColors.primaryBlue.withValues(alpha: 0.12)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: liked
                              ? AppColors.primaryBlue
                              :  AppColors.borderColor,
                        ),
                      ),
                      child: Icon(
                        liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: liked ? AppColors.primaryBlue : AppColors.darkBlue,
                        size: 16,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      review['likes'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            liked ? FontWeight.w700 : FontWeight.normal,
                        color: liked ? AppColors.primaryBlue : AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white,
            Colors.white,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            _showAddReviewSheet(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.darkBlue,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text(
                'Beri rating dan ulasan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADD REVIEW BOTTOM SHEET
  // ============================================================

  static const int _maxReviewPhotos = 5;

  Future<void> _pickImagesFromGallery(
    List<XFile> targetList,
    void Function(void Function()) setSheetState,
  ) async {
    final ImagePicker picker = ImagePicker();

    try {
      final List<XFile> picked = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (picked.isEmpty) return;

      setSheetState(() {
        final int remainingSlots = _maxReviewPhotos - targetList.length;

        if (remainingSlots <= 0) return;

        targetList.addAll(
          picked.take(remainingSlots),
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka galeri.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera(
    List<XFile> targetList,
    void Function(void Function()) setSheetState,
  ) async {
    if (targetList.length >= _maxReviewPhotos) return;

    final ImagePicker picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) return;

      setSheetState(() {
        targetList.add(photo);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka kamera.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoSourceSheet(
    BuildContext context,
    List<XFile> targetList,
    void Function(void Function()) setSheetState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primaryBlue),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera(targetList, setSheetState);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImagesFromGallery(targetList, setSheetState);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BARIS PRATINJAU FOTO YANG DIPILIH (di dalam form ulasan)
  // ============================================================

  Widget _buildSelectedPhotosRow(
    List<XFile> selectedPhotos,
    void Function(void Function()) setSheetState,
  ) {
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...selectedPhotos.map((file) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedPhotos.remove(file);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          if (selectedPhotos.length < _maxReviewPhotos)
            GestureDetector(
              onTap: () => _showPhotoSourceSheet(
                context,
                selectedPhotos,
                setSheetState,
              ),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: AppColors.greyText,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddReviewSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    int selectedRating = 5;
    final TextEditingController textController = TextEditingController();
    final List<XFile> selectedPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Beri rating untuk ${widget.destinationName}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final int starValue = index + 1;

                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              selectedRating = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            child: Icon(
                              starValue <= selectedRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppColors.primaryBlue,
                              size: 34,
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: textController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ceritakan pengalamanmu di sini...',
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'Tambahkan foto (opsional)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildSelectedPhotosRow(
                      selectedPhotos,
                      setSheetState,
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          final String reviewText = textController.text.trim();

                          if (reviewText.isEmpty && selectedPhotos.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Isi ulasan atau tambahkan foto terlebih dahulu.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final ProfileData myProfile = ProfileService.instance.profile.value;
                          final List<File> imageFiles = selectedPhotos.map((f) => File(f.path)).toList();
                          final List<String> photoPaths = selectedPhotos.map((f) => f.path).toList();
                          final String targetDestId = (widget.destinationId != null && widget.destinationId!.isNotEmpty)
                              ? widget.destinationId!
                              : widget.destinationName;

                          Navigator.pop(context);

                          // Optimistic: tampilkan ulasan sementara
                          if (mounted) {
                            setState(() {
                              _serverReviews.insert(0, {
                                'id': null,
                                'avatar': ProfileService.instance.currentAvatarForReview,
                                'name': myProfile.name,
                                'rating': selectedRating.toDouble(),
                                'time': 'Baru saja',
                                'text': reviewText,
                                'likes': '0',
                                'photos': photoPaths,
                                'liked': false,
                              });
                            });
                          }

                          try {
                            await MyReviewsService.instance.addReview(
                              MyReviewEntry(
                                destinationId: targetDestId,
                                destinationName: widget.destinationName,
                                avatar: ProfileService.instance.currentAvatarForReview,
                                name: myProfile.name,
                                rating: selectedRating.toDouble(),
                                time: 'Baru saja',
                                text: reviewText,
                                photos: photoPaths,
                              ),
                              localImageFiles: imageFiles,
                            );
                            // Refresh dari server setelah berhasil
                            await _fetchDestinationReviews();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('✅ Ulasan berhasil ditambahkan'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.green,
                              ),
                            );
                          } on ApiException catch (e) {
                            // Rollback optimistic update
                            if (mounted) setState(() => _serverReviews.removeWhere((r) => r['id'] == null));
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('❌ Gagal: ${e.message}'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          } catch (e) {
                            if (mounted) setState(() => _serverReviews.removeWhere((r) => r['id'] == null));
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('❌ Gagal menyimpan ulasan. Coba lagi.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: AppColors.darkBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Kirim Ulasan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}