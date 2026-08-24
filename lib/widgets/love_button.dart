import 'package:flutter/material.dart';

import '../services/saved_destinations_service.dart';

// ================================================================
// LOVE BUTTON (SAVE DESTINATION)
// ================================================================
//
// Tombol hati bulat yang dipasang di atas gambar kartu destinasi.
// Statusnya diambil dari SavedDestinationsService yang dipakai
// bersama oleh semua layar, jadi kalau di-tap di satu kartu, kartu
// lain untuk destinasi yang sama otomatis ikut berubah.
//
// ================================================================

class LoveButton extends StatelessWidget {
  final String destinationId;
  final double size;

  const LoveButton({
    super.key,
    required this.destinationId,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: SavedDestinationsService.instance.savedIds,
      builder: (context, savedIds, _) {
        final bool isSaved = savedIds.contains(destinationId);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SavedDestinationsService.instance.toggle(destinationId);
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isSaved ? Icons.favorite : Icons.favorite_border,
              color: isSaved ? Colors.redAccent : const Color(0xFF9A9A9A),
              size: size * 0.55,
            ),
          ),
        );
      },
    );
  }
}
