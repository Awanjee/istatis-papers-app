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
  }) async {
    final payload = {
      'party_name': editedPartyName ?? result.partyName,
      'party_name_urdu': result.partyNameUrdu,
      'transaction_date': editedDate ?? result.date,
      'document_type': result.documentType,
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

  /// Fetch confirmed transactions, newest first.
  Future<List<TransactionSummary>> getTransactions() async {
    final response = await _dio.get<List<dynamic>>('/extract/transactions');
    return (response.data ?? [])
        .map((e) => TransactionSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class TransactionSummary {
  final String id;
  final String? transactionDate;
  final String? documentType;
  final double? totalAmount;
  final String? notes;
  final String? partyNameRoman;
  final String? partyNameUrdu;
  final String? createdAt;

  TransactionSummary({
    required this.id,
    this.transactionDate,
    this.documentType,
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
      totalAmount: (j['total_amount'] as num?)?.toDouble(),
      notes: j['notes'] as String?,
      partyNameRoman: party?['name_roman'] as String?,
      partyNameUrdu: party?['name_urdu'] as String?,
      createdAt: j['created_at'] as String?,
    );
  }
}
