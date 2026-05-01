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
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1a472a),
              ),
            ),
            backgroundColor: const Color(0xFFf0f7f4),
            side: const BorderSide(color: Color(0xFF1a472a)),
            onPressed: () => onSuggestionTap(suggestions[index]),
          );
        },
      ),
    );
  }
}
