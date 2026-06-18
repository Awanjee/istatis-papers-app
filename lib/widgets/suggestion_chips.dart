import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/arco_components.dart';

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
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s2),
        itemBuilder: (context, index) {
          return ArcoChip(
            label: suggestions[index],
            onTap: () => onSuggestionTap(suggestions[index]),
          );
        },
      ),
    );
  }
}
