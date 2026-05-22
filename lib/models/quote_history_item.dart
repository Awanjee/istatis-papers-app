class QuoteHistoryItem {
  final String id;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? quoteText;
  final String? productName;
  final String? productUnit;

  QuoteHistoryItem({
    required this.id,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.createdAt,
    this.quoteText,
    this.productName,
    this.productUnit,
  });

  factory QuoteHistoryItem.fromJson(Map<String, dynamic> json) {
    return QuoteHistoryItem(
      id: json['id'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      quoteText: json['quote_text'] as String?,
      productName: json['product_name'] as String?,
      productUnit: json['product_unit'] as String?,
    );
  }
}

class OrderResult {
  final String id;
  final String status;
  final double totalAmount;
  final String quoteId;
  final String? productName;
  final String message;

  OrderResult({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.quoteId,
    this.productName,
    required this.message,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      id: json['id'] as String,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      quoteId: json['quote_id'] as String,
      productName: json['product_name'] as String?,
      message: json['message'] as String? ?? 'Order created successfully',
    );
  }
}
