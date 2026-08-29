import 'package:flutter/material.dart';

// ================================================================
// CATEGORY BADGE
// ================================================================
//
// Chip kecil untuk menampilkan kategori destinasi (Alam, Kuliner,
// Budaya, Buatan, dst -- sesuai field 'category' di kDestinationsData).
// Dipakai di semua kartu destinasi supaya tampilannya konsisten.
//
// ================================================================

class CategoryBadge extends StatelessWidget {
  final String category;
  final bool compact;

  const CategoryBadge({
    super.key,
    required this.category,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10, // CHANGED - padding menyesuaikan font yang lebih besar
        vertical: compact ? 3.5 : 5, // CHANGED - padding menyesuaikan font yang lebih besar
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE2F3FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12, // CHANGED - font terkecil jadi 12 (sebelumnya 9/10)
          color: const Color(0xFF2486C5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}