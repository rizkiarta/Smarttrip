import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/saved_itinerary_service.dart';

// ================================================================
// UBAH INFO DASAR -- bottom sheet RINGAN untuk ganti nama perjalanan
// & tanggal mulai SAJA, tanpa masuk ke ManualScheduleScreen/
// AIItineraryScreen sama sekali.
//
// Dipakai dari menu "Kelola Itinerary" di PlanScreen, sebagai
// alternatif yang lebih cepat dibanding "Ubah Destinasi & Jadwal"
// untuk kasus yang paling sering: user cuma mau ganti tanggal atau
// nama trip, destinasi & jam kunjungan per hari tetap sama persis.
// ================================================================

Future<void> showEditBasicInfoSheet(
  BuildContext context,
  List<Map<String, dynamic>> savedItinerary,
) {
  if (savedItinerary.isEmpty) {
    return Future.value();
  }

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _EditBasicInfoSheet(savedItinerary: savedItinerary),
  );
}

class _EditBasicInfoSheet extends StatefulWidget {
  const _EditBasicInfoSheet({required this.savedItinerary});

  final List<Map<String, dynamic>> savedItinerary;

  @override
  State<_EditBasicInfoSheet> createState() => _EditBasicInfoSheetState();
}

class _EditBasicInfoSheetState extends State<_EditBasicInfoSheet> {
  late final TextEditingController _nameController;
  DateTime? _startDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic> firstDay = widget.savedItinerary.first;

    _nameController = TextEditingController(
      text: firstDay['tripName']?.toString() ?? '',
    );

    _startDate = _parseDate(firstDay['startDate']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS -- sengaja disamakan gayanya dengan TravelInformationScreen
  // (_parseDate / _formatDate) supaya perilakunya konsisten.
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickStartDate() async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(2035),
      locale: const Locale('id', 'ID'),
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

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  // ============================================================
  // CEK BENTROK TANGGAL DENGAN ITINERARY LAIN -- pola sama seperti
  // _checkDateOverlapAndProceed di TravelInformationScreen, tapi
  // itinerary yang sedang diedit sendiri dikecualikan (kalau tidak,
  // tanggal lama pasti selalu "bentrok" dengan dirinya sendiri).
  // ============================================================

  Map<String, dynamic>? _findOverlappingTrip(
    String selfId,
    DateTime newStart,
    DateTime newEndInclusive,
  ) {
    final allItineraries = SavedItineraryService.instance.itineraries.value;

    for (final itin in allItineraries) {
      if (itin.isEmpty) continue;

      final String? id = itin.first['itineraryId']?.toString();
      if (id == selfId) continue;

      final DateTime? s = _parseDate(itin.first['startDate']);
      final DateTime? e = _parseDate(itin.first['endDate']);
      if (s == null || e == null) continue;

      final DateTime existingStart = DateTime(s.year, s.month, s.day);
      final DateTime existingEnd = DateTime(e.year, e.month, e.day);

      if (!newStart.isAfter(existingEnd) && !newEndInclusive.isBefore(existingStart)) {
        return itin.first;
      }
    }

    return null;
  }

  Future<void> _handleSave() async {
    final String? itineraryId =
        widget.savedItinerary.first['itineraryId']?.toString();

    if (itineraryId == null) {
      Navigator.pop(context);
      return;
    }

    final String newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama perjalanan tidak boleh kosong')),
      );
      return;
    }

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal mulai belum dipilih')),
      );
      return;
    }

    final int dayCount = widget.savedItinerary.length;

    final DateTime newStart = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
    );

    final DateTime newEnd = newStart.add(Duration(days: dayCount - 1));

    final Map<String, dynamic>? overlap = _findOverlappingTrip(
      itineraryId, newStart, newEnd,
    );

    if (overlap != null) {
      final String tripTitle = overlap['tripName']?.toString() ?? 'Perjalanan';

      final bool? proceed = await showDialog<bool>(
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
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kamu sudah punya rencana "$tripTitle" di rentang tanggal ini. Tetap ganti tanggal?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, color: AppColors.greyText, height: 1.4,
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Tetap Ganti Tanggal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Batal', style: TextStyle(fontSize: 14, color: AppColors.greyText)),
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (proceed != true) return;
    }

    setState(() => _saving = true);

    try {
      await SavedItineraryService.instance.updateBasicInfo(
        itineraryId,
        tripName: newName,
        startDate: newStart,
      );

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const Text(
                'Ubah Info Dasar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Destinasi & jadwal per hari tidak ikut berubah.',
                style: TextStyle(fontSize: 11.5, color: AppColors.greyText),
              ),
              const SizedBox(height: 20),

              // ======================================================
              // NAMA PERJALANAN
              // ======================================================
              const Text('Nama Perjalanan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              const SizedBox(height: 8),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 14, color: AppColors.darkText),
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Liburan ke Lampung Barat',
                    hintStyle: TextStyle(fontSize: 14, color: AppColors.greyText),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ======================================================
              // TANGGAL MULAI
              // ======================================================
              const Text('Tanggal Mulai', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkText)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickStartDate,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.primaryBlue, size: 19),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          _startDate == null ? 'Pilih tanggal mulai' : _formatDate(_startDate!),
                          style: TextStyle(
                            fontSize: 14,
                            color: _startDate == null ? AppColors.greyText : AppColors.darkText,
                            fontWeight: _startDate == null ? FontWeight.w400 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.greyText, size: 22),
                    ],
                  ),
                ),
              ),

              if (_startDate != null && widget.savedItinerary.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  'Perjalanan ${widget.savedItinerary.length} hari, s/d '
                  '${_formatDate(_startDate!.add(Duration(days: widget.savedItinerary.length - 1)))}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.greyText),
                ),
              ],

              const SizedBox(height: 22),

              // ======================================================
              // SIMPAN
              // ======================================================
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F6F8),
                    foregroundColor: AppColors.darkText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Batal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}