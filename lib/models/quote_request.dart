class QuoteRequest {
  final String customerName;
  final String company;
  final String email;
  final String productType;
  final int quantity;
  final String notes;

  QuoteRequest({
    required this.customerName,
    required this.company,
    required this.email,
    required this.productType,
    required this.quantity,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'company': company,
    'email': email,
    'product_type': productType,
    'quantity': quantity,
    'notes': notes,
  };
}

class QuoteResponse {
  final bool success;
  final String message;
  final String quoteSummary;

  QuoteResponse({
    required this.success,
    required this.message,
    required this.quoteSummary,
  });

  factory QuoteResponse.fromJson(Map<String, dynamic> json) => QuoteResponse(
    success: json['success'] as bool,
    message: json['message'] as String,
    quoteSummary: json['quote_summary'] as String,
  );
}
