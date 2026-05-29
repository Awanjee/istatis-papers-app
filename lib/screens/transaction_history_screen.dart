import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import 'party_balances_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final ExtractionService _service;
  late Future<List<TransactionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _service = ExtractionService(dio);
    _future = _service.getTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _future = _service.getTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF0B5E72),
            labelColor: const Color(0xFF0B5E72),
            unselectedLabelColor: Colors.grey[500],
            labelStyle: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Transactions'),
              Tab(text: 'Parties'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _TransactionsTab(future: _future, onRefresh: _refresh),
              const PartyBalancesScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions tab (extracted from original body)
// ---------------------------------------------------------------------------

class _TransactionsTab extends StatelessWidget {
  final Future<List<TransactionSummary>> future;
  final VoidCallback onRefresh;

  const _TransactionsTab({required this.future, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF0B5E72),
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<TransactionSummary>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B5E72)),
            );
          }
          if (snapshot.hasError) {
            return _buildError(context);
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return _buildEmpty(context);
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

  Widget _buildEmpty(BuildContext context) {
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

  Widget _buildError(BuildContext context) {
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
              onPressed: onRefresh,
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
