import '../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestionChips extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const SuggestionChips({super.key, required this.onSuggestionTap});

  static const suggestions = [
    'C4 envelope pricing',
    'Bulk paper order',
    'File carriers for hospital',
    'Compare envelope sizes',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              suggestions[index],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.accent,
              ),
            ),
            backgroundColor: AppColors.surface1,
            side: const BorderSide(color: AppColors.accent),
            onPressed: () => onSuggestionTap(suggestions[index]),
          );
        },
      ),
    );
  }
}
