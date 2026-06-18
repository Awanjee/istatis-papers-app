import '../theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import 'party_balances_screen.dart';
import 'transaction_detail_screen.dart';

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
          color: AppColors.text1,
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.text3,
            labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle:
                GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
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
              _TransactionsTab(future: _future, onRefresh: _refresh, service: _service),
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
  final ExtractionService service;

  const _TransactionsTab({
    required this.future,
    required this.onRefresh,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<TransactionSummary>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
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
            itemBuilder: (context, i) => _TransactionCard(
              tx: transactions[i],
              service: service,
            ),
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
                size: 64, color: AppColors.text3),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Import and confirm a document\nto see it here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.text3),
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
              style: GoogleFonts.plusJakartaSans(
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
  final ExtractionService service;

  const _TransactionCard({required this.tx, required this.service});

  static const _docTypeLabels = {
    'sales_slip': 'Sales Slip',
    'price_list': 'Price List',
    'distribution_record': 'Distribution',
    'account_ledger': 'Ledger',
    'calculation_note': 'Calculation',
    'unknown': 'Unknown',
  };

  static const _docTypeColors = {
    'sales_slip': AppColors.accent,
    'price_list': AppColors.accent,
    'distribution_record': AppColors.accent,
    'account_ledger': AppColors.warning,
    'calculation_note': AppColors.success,
    'unknown': AppColors.text3,
  };

  @override
  Widget build(BuildContext context) {
    final party = tx.partyNameRoman ?? tx.partyNameUrdu ?? 'Unknown party';
    final date = _formatDate(tx.transactionDate);
    final label = _docTypeLabels[tx.documentType] ?? tx.documentType ?? 'Doc';
    final chipColor =
        _docTypeColors[tx.documentType] ?? AppColors.text3;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            transactionId: tx.id,
            service: service,
            initialPartyName: party,
          ),
        ),
      ),
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.text1,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: AppColors.text3),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: AppColors.text3),
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
                        style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.text3,
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    ));  // closes GestureDetector child + GestureDetector
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
