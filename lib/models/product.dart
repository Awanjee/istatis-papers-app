import 'package:flutter/widgets.dart';

class PricingTier {
  final int minQuantity;
  final double pricePerUnit;
  final String label;

  const PricingTier({
    required this.minQuantity,
    required this.pricePerUnit,
    required this.label,
  });
}

class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final String unit;
  final int minOrder;
  final List<PricingTier> pricingTiers;
  final IconData? icon;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.unit,
    required this.minOrder,
    required this.pricingTiers,
    this.icon,
  });
}