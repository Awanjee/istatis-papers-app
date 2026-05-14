class QuoteRequest {
  final String customerName;
  final String company;
  final String email;
  final String productName;
  final int quantity;
  final String notes;

  QuoteRequest({
    required this.customerName,
    required this.company,
    required this.email,
    required this.productName,
    required this.quantity,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'customer_name': customerName,
    'company': company,
    'email': email,
    'product_name': productName,
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
    success: json['success'] as bool? ?? false,
    message: json['message'] as String? ?? '',
    quoteSummary: json['quote_summary'] as String? ?? '',
  );
}
