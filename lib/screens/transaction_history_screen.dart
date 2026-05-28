import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  late final ExtractionService _service;
  late Future<List<TransactionSummary>> _future;

  @override
  void initState() {
    super.initState();
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _service = ExtractionService(dio);
    _future = _service.getTransactions();
  }

  void _refresh() {
    setState(() {
      _future = _service.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF1a472a),
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<TransactionSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a472a)),
            );
          }
          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return _buildEmpty();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) =>
                _TransactionCard(tx: transactions[i]),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Column(
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[350]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import and confirm a document\nto see it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Could not load transactions',
              style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction card
// ---------------------------------------------------------------------------

class _TransactionCard extends StatelessWidget {
  final TransactionSummary tx;

  const _TransactionCard({required this.tx});

  static const _docTypeLabels = {
    'sales_slip': 'Sales Slip',
    'price_list': 'Price List',
    'distribution_record': 'Distribution',
    'account_ledger': 'Ledger',
    'calculation_note': 'Calculation',
    'unknown': 'Unknown',
  };

  static const _docTypeColors = {
    'sales_slip': Color(0xFF1a472a),
    'price_list': Color(0xFF1565C0),
    'distribution_record': Color(0xFF6A1B9A),
    'account_ledger': Color(0xFFE65100),
    'calculation_note': Color(0xFF00695C),
    'unknown': Color(0xFF616161),
  };

  @override
  Widget build(BuildContext context) {
    final party = tx.partyNameRoman ?? tx.partyNameUrdu ?? 'Unknown party';
    final date = _formatDate(tx.transactionDate);
    final label = _docTypeLabels[tx.documentType] ?? tx.documentType ?? 'Doc';
    final chipColor =
        _docTypeColors[tx.documentType] ?? const Color(0xFF616161);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: doc type indicator
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // Middle: party + date + type chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: chipColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: chipColor,
                        ),
                      ),
                    ),
                  ],
                ),
                if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    tx.notes!,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Right: amount
          if (tx.totalAmount != null)
            Text(
              'PKR ${_formatAmount(tx.totalAmount!)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1a472a),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return 'No date';
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(0);
  }
}
