import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/extraction_result.dart';

class ExtractionService {
  final Dio _dio;

  ExtractionService(this._dio);

  /// Upload image -> GPT-4o extraction -> returns result for review screen.
  /// Takes XFile directly so it works on both web and mobile.
  Future<ExtractionResult> extractDocument(XFile imageFile) async {
    final fileName = imageFile.name;
    final bytes = await imageFile.readAsBytes();

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/extract',
      data: formData,
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
      ),
    );

    return ExtractionResult.fromJson(response.data!);
  }

  /// Confirm a reviewed extraction — creates party + transaction in DB.
  Future<Map<String, dynamic>> confirmExtraction({
    required ExtractionResult result,
    String? editedPartyName,
    String? editedDate,
    double? editedTotal,
    String? notes,
    String transactionType = 'sale',
  }) async {
    final payload = {
      'party_name': editedPartyName ?? result.partyName,
      'party_name_urdu': result.partyNameUrdu,
      'transaction_date': editedDate ?? result.date,
      'document_type': result.documentType,
      'transaction_type': transactionType,
      'total_amount': editedTotal ?? result.totals.grandTotal,
      'line_items': result.lineItems.map((i) => i.toJson()).toList(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/extract/${result.extractionId}/confirm',
      data: payload,
    );
    return response.data!;
  }

  /// Reject an extraction without saving a transaction.
  Future<void> rejectExtraction(String extractionId) async {
    await _dio.post<void>('/extract/$extractionId/reject');
  }

  /// Fetch confirmed transactions, newest first. Optional partyId filter.
  Future<List<TransactionSummary>> getTransactions({String? partyId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/extract/transactions',
      queryParameters: partyId != null ? {'party_id': partyId} : null,
    );
    return (response.data ?? [])
        .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Single transaction with all line items.
  Future<TransactionDetail> getTransactionDetail(String transactionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/extract/transactions/$transactionId',
    );
    return TransactionDetail.fromJson(response.data!);
  }

  /// Per-party running balances, sorted by outstanding amount descending.
  Future<List<PartyBalance>> getPartyBalances() async {
    final response =
        await _dio.get<List<dynamic>>('/extract/parties/balances');
    return (response.data ?? [])
        .map((e) => PartyBalance.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class TransactionLineItem {
  final String id;
  final String? productCode;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double? amount;
  final double? confidence;
  final String? notes;

  TransactionLineItem({
    required this.id,
    this.productCode,
    this.description,
    this.quantity,
    this.unitPrice,
    this.amount,
    this.confidence,
    this.notes,
  });

  factory TransactionLineItem.fromJson(Map<String, dynamic> j) =>
      TransactionLineItem(
        id: j['id'] as String,
        productCode: j['product_code'] as String?,
        description: j['description'] as String?,
        quantity: (j['quantity'] as num?)?.toDouble(),
        unitPrice: (j['unit_price'] as num?)?.toDouble(),
        amount: (j['amount'] as num?)?.toDouble(),
        confidence: (j['confidence'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
      );
}

class TransactionDetail {
  final String id;
  final String? transactionDate;
  final String? documentType;
  final String? transactionType;
  final double? totalAmount;
  final String? notes;
  final String? partyNameRoman;
  final String? partyNameUrdu;
  final List<TransactionLineItem> lineItems;

  TransactionDetail({
    required this.id,
    this.transactionDate,
    this.documentType,
    this.transactionType,
    this.totalAmount,
    this.notes,
    this.partyNameRoman,
    this.partyNameUrdu,
    required this.lineItems,
  });

  factory TransactionDetail.fromJson(Map<String, dynamic> j) {
    final party = j['parties'] as Map<String, dynamic>?;
    final items = (j['transaction_line_items'] as List<dynamic>? ?? [])
        .map((e) => TransactionLineItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return TransactionDetail(
      id: j['id'] as String,
      transactionDate: j['transaction_date'] as String?,
      documentType: j['document_type'] as String?,
      transactionType: j['transaction_type'] as String?,
      totalAmount: (j['total_amount'] as num?)?.toDouble(),
      notes: j['notes'] as String?,
      partyNameRoman: party?['name_roman'] as String?,
      partyNameUrdu: party?['name_urdu'] as String?,
      lineItems: items,
    );
  }
}

class PartyBalance {
  final String partyId;
  final String? nameRoman;
  final String? nameUrdu;
  final double balance;
  final double totalSales;
  final double totalPayments;
  final int transactionCount;
  final String? lastTransactionDate;

  PartyBalance({
    required this.partyId,
    this.nameRoman,
    this.nameUrdu,
    required this.balance,
    required this.totalSales,
    required this.totalPayments,
    required this.transactionCount,
    this.lastTransactionDate,
  });

  factory PartyBalance.fromJson(Map<String, dynamic> j) => PartyBalance(
        partyId: j['party_id'] as String,
        nameRoman: j['name_roman'] as String?,
        nameUrdu: j['name_urdu'] as String?,
        balance: (j['balance'] as num?)?.toDouble() ?? 0.0,
        totalSales: (j['total_sales'] as num?)?.toDouble() ?? 0.0,
        totalPayments: (j['total_payments'] as num?)?.toDouble() ?? 0.0,
        transactionCount: (j['transaction_count'] as num?)?.toInt() ?? 0,
        lastTransactionDate: j['last_transaction_date'] as String?,
      );
}

class TransactionSummary {
  final String id;
  final String? transactionDate;
  final String? documentType;
  final String? transactionType;
  final double? totalAmount;
  final String? notes;
  final String? partyNameRoman;
  final String? partyNameUrdu;
  final String? createdAt;

  TransactionSummary({
    required this.id,
    this.transactionDate,
    this.documentType,
    this.transactionType,
    this.totalAmount,
    this.notes,
    this.partyNameRoman,
    this.partyNameUrdu,
    this.createdAt,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> j) {
    final party = j['parties'] as Map<String, dynamic>?;
    return TransactionSummary(
      id: j['id'] as String,
      transactionDate: j['transaction_date'] as String?,
      documentType: j['document_type'] as String?,
      transactionType: j['transaction_type'] as String?,
      totalAmount: (j['total_amount'] as num?)?.toDouble(),
      notes: j['notes'] as String?,
      partyNameRoman: party?['name_roman'] as String?,
      partyNameUrdu: party?['name_urdu'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}
