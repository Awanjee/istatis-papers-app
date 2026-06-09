import '../models/product.dart';

// Replace these with real prices when you have them
final List<Product> catalogueProducts = [
  // ── ENVELOPES ───────────────────────────────────────────
  Product(
    id: 'env_c4',
    name: 'C4 Envelope',
    category: 'Envelopes',
    description:
        '229x324mm. Fits A4 documents without folding. '
        'Popular with hospitals and law firms.',
    unit: 'per envelope',
    minOrder: 1000,
    pricingTiers: [
      PricingTier(minQuantity: 10000, pricePerUnit: 6.0, label: '10,000+'),
      PricingTier(minQuantity: 5000, pricePerUnit: 7.0, label: '5,000+'),
      PricingTier(minQuantity: 1000, pricePerUnit: 10.0, label: '1,000+'),
    ],
  ),
  Product(
    id: 'env_c5',
    name: 'C5 Envelope',
    category: 'Envelopes',
    description:
        '162x229mm. Fits A4 documents folded once. '
        'Popular with banks and universities.',
    unit: 'per envelope',
    minOrder: 1000,
    pricingTiers: [
      PricingTier(minQuantity: 5000, pricePerUnit: 4.5, label: '5,000+'),
      PricingTier(minQuantity: 1000, pricePerUnit: 6.5, label: '1,000+'),
    ],
  ),
  Product(
    id: 'env_dl',
    name: 'DL Envelope',
    category: 'Envelopes',
    description:
        '110x220mm. Standard letter envelope, folded twice. '
        'Most common corporate envelope.',
    unit: 'per envelope',
    minOrder: 2000,
    pricingTiers: [
      PricingTier(minQuantity: 10000, pricePerUnit: 3.5, label: '10,000+'),
      PricingTier(minQuantity: 2000, pricePerUnit: 5.0, label: '2,000+'),
    ],
  ),

  // ── PAPER ───────────────────────────────────────────────
  Product(
    id: 'paper_a4_70',
    name: 'A4 Paper 70gsm',
    category: 'Paper',
    description:
        '500 sheets per ream. Standard quality for '
        'everyday printing and photocopying.',
    unit: 'per ream',
    minOrder: 10,
    pricingTiers: [
      PricingTier(minQuantity: 500, pricePerUnit: 700, label: '500+'),
      PricingTier(minQuantity: 100, pricePerUnit: 750, label: '100+'),
      PricingTier(minQuantity: 10, pricePerUnit: 850, label: '10+'),
    ],
  ),
  Product(
    id: 'paper_a4_80',
    name: 'A4 Paper 80gsm',
    category: 'Paper',
    description:
        '500 sheets per ream. Premium quality, recommended '
        'for laser printers and official documents.',
    unit: 'per ream',
    minOrder: 10,
    pricingTiers: [
      PricingTier(minQuantity: 500, pricePerUnit: 800, label: '500+'),
      PricingTier(minQuantity: 100, pricePerUnit: 850, label: '100+'),
      PricingTier(minQuantity: 10, pricePerUnit: 1000, label: '10+'),
    ],
  ),

  // ── FILE CARRIERS ────────────────────────────────────────
  Product(
    id: 'fc_standard',
    name: 'A4 File Carrier Standard',
    category: 'File Carriers',
    description:
        'Standard A4 file carrier. Suitable for offices, '
        'schools and general document storage.',
    unit: 'per unit',
    minOrder: 100,
    pricingTiers: [
      PricingTier(minQuantity: 1000, pricePerUnit: 30, label: '1,000+'),
      PricingTier(minQuantity: 500, pricePerUnit: 35, label: '500+'),
      PricingTier(minQuantity: 100, pricePerUnit: 45, label: '100+'),
    ],
  ),
  Product(
    id: 'fc_heavy',
    name: 'A4 File Carrier Heavy Duty',
    category: 'File Carriers',
    description:
        'Heavy duty A4 file carrier. Popular with government '
        'departments and hospitals for patient records.',
    unit: 'per unit',
    minOrder: 100,
    pricingTiers: [
      PricingTier(minQuantity: 500, pricePerUnit: 55, label: '500+'),
      PricingTier(minQuantity: 100, pricePerUnit: 70, label: '100+'),
    ],
  ),
];

// Group products by category
Map<String, List<Product>> get productsByCategory {
  final Map<String, List<Product>> grouped = {};
  for (final product in catalogueProducts) {
    grouped.putIfAbsent(product.category, () => []);
    grouped[product.category]!.add(product);
  }
  return grouped;
}
