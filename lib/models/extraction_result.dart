class LineItem {
  final String? productCode;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double? amount;
  final double confidence;
  final String? notes;

  // Editable copies shown in the review screen
  String? editedProductCode;
  String? editedDescription;
  double? editedQuantity;
  double? editedUnitPrice;
  double? editedAmount;

  LineItem({
    this.productCode,
    this.description,
    this.quantity,
    this.unitPrice,
    this.amount,
    required this.confidence,
    this.notes,
  }) {
    editedProductCode = productCode;
    editedDescription = description;
    editedQuantity = quantity;
    editedUnitPrice = unitPrice;
    editedAmount = amount;
  }

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
    productCode: j['product_code'] as String?,
    description: j['description'] as String?,
    quantity: (j['quantity'] as num?)?.toDouble(),
    unitPrice: (j['unit_price'] as num?)?.toDouble(),
    amount: (j['amount'] as num?)?.toDouble(),
    confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
    notes: j['notes'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'product_code': editedProductCode,
    'description': editedDescription,
    'quantity': editedQuantity,
    'unit_price': editedUnitPrice,
    'amount': editedAmount,
    'confidence': confidence,
    'notes': notes,
  };
}

class ExtractionTotals {
  final double? subtotal;
  final double? discount;
  final double? grandTotal;

  ExtractionTotals({this.subtotal, this.discount, this.grandTotal});

  factory ExtractionTotals.fromJson(Map<String, dynamic> j) => ExtractionTotals(
    subtotal: (j['subtotal'] as num?)?.toDouble(),
    discount: (j['discount'] as num?)?.toDouble(),
    grandTotal: (j['grand_total'] as num?)?.toDouble(),
  );
}

class ExtractionResult {
  final String extractionId;
  final bool hasWarnings;
  final String? documentType;
  final String? date;
  final String? partyName;
  final String? partyNameUrdu;
  final double overallConfidence;
  final List<LineItem> lineItems;
  final ExtractionTotals totals;
  final List<String> lowConfidenceFields;
  final String? unreadableSections;
  final String? rawTextUrdu;

  ExtractionResult({
    required this.extractionId,
    required this.hasWarnings,
    this.documentType,
    this.date,
    this.partyName,
    this.partyNameUrdu,
    required this.overallConfidence,
    required this.lineItems,
    required this.totals,
    required this.lowConfidenceFields,
    this.unreadableSections,
    this.rawTextUrdu,
  });

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;

    final items = (data['line_items'] as List<dynamic>? ?? [])
        .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return ExtractionResult(
      extractionId: json['extraction_id'] as String,
      hasWarnings: json['has_warnings'] as bool? ?? false,
      documentType: data['document_type'] as String?,
      date: data['date'] as String?,
      partyName: data['party_name'] as String?,
      partyNameUrdu: data['party_name_urdu'] as String?,
      overallConfidence: (data['overall_confidence'] as num?)?.toDouble() ?? 0.0,
      lineItems: items,
      totals: ExtractionTotals.fromJson(
        data['totals'] as Map<String, dynamic>? ?? {},
      ),
      lowConfidenceFields:
          List<String>.from(data['low_confidence_fields'] as List? ?? []),
      unreadableSections: data['unreadable_sections'] as String?,
      rawTextUrdu: data['raw_text_urdu'] as String?,
    );
  }
}
