import 'package:flutter/material.dart';
import 'package:istatis_app/screens/quote_screen.dart';

import '../data/products_data.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories => ['All', ...productsByCategory.keys];

  List<Product> get _filteredProducts {
    if (_selectedCategory == 'All') return catalogueProducts;
    return productsByCategory[_selectedCategory] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s2),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return ArcoChip(
                label: cat,
                selected: cat == _selectedCategory,
                onTap: () => setState(() => _selectedCategory = cat),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s3),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) =>
                _ProductCard(product: _filteredProducts[index]),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final tier = product.pricingTiers.isNotEmpty
        ? product.pricingTiers.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: ArcoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: AppRadius.rMd,
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 19,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: AppText.h3),
                      const SizedBox(height: 3),
                      Text(
                        product.description,
                        style: AppText.small.copyWith(color: AppColors.text3),
                      ),
                    ],
                  ),
                ),
                ArcoBadge(
                  label: product.category,
                  variant: ArcoBadgeVariant.accent,
                  showDot: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            const ArcoDivider(),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier != null
                      ? 'FROM PKR ${tier.pricePerUnit % 1 == 0 ? tier.pricePerUnit.toInt() : tier.pricePerUnit} / UNIT'
                      : 'MIN ${product.minOrder} UNITS',
                  style: AppText.mono.copyWith(color: AppColors.accent),
                ),
                ArcoButton(
                  label: 'Add to quote',
                  variant: ArcoButtonVariant.secondary,
                  size: ArcoButtonSize.sm,
                  onPressed: () => _openQuote(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openQuote(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.canvas,
          appBar: const ArcoTopBar(title: 'Request Quote', showBrand: false),
          body: QuoteScreen(preselectedProduct: product),
        ),
      ),
    );
  }
}
