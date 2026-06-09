import 'package:istatis_app/screens/quote_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/products_data.dart';
import '../models/product.dart';

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
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) =>
                _ProductCard(product: _filteredProducts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = cat == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF1a472a),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                selectedColor: const Color(0xFF1a472a),
                backgroundColor: const Color(0xFFf0f7f4),
                checkmarkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF1a472a)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf0f7f4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.category,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF1a472a),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Min: ${product.minOrder.toString()} units',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Product name
            Text(
              product.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),

            // Description
            Text(
              product.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Pricing tiers
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              'Bulk Pricing (PKR)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.pricingTiers
                  .map((tier) => _PricingChip(tier: tier))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Quote button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showQuoteDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1a472a),
                  side: const BorderSide(color: Color(0xFF1a472a)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Request Quote',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuoteDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF1a472a),
            title: Text(
              'Request Quote',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: QuoteScreen(preselectedProduct: product),
        ),
      ),
    );
  }
}

class _PricingChip extends StatelessWidget {
  final PricingTier tier;

  const _PricingChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFf0f7f4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFc8e6c9)),
      ),
      child: Column(
        children: [
          Text(
            tier.label,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
          ),
          Text(
            'PKR ${tier.pricePerUnit % 1 == 0 ? tier.pricePerUnit.toInt() : tier.pricePerUnit}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1a472a),
            ),
          ),
        ],
      ),
    );
  }
}
