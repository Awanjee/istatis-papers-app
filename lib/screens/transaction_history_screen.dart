import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';
import 'party_balances_screen.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _tabIndex = 0;
  late final ExtractionService _service;
  late Future<List<TransactionSummary>> _future;

  @override
  void initState() {
    super.initState();
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
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
    return Column(
      children: [
        ArcoSegTabs(
          labels: const ['Transactions', 'Parties'],
          selectedIndex: _tabIndex,
          onSelected: (i) => setState(() => _tabIndex = i),
        ),
        Expanded(
          child: _tabIndex == 0
              ? _TransactionsTab(
                  future: _future,
                  onRefresh: _refresh,
                  service: _service,
                )
              : const PartyBalancesScreen(),
        ),
      ],
    );
  }
}

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
      onRefresh: () async => onRefresh(),
      child: FutureBuilder<List<TransactionSummary>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildError(context);
          }
          final transactions = snapshot.data ?? [];
          if (transactions.isEmpty) {
            return _buildEmpty(context);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s4),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (context, i) =>
                _TransactionCard(tx: transactions[i], service: service),
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
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.text3,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'No transactions yet',
              style: AppText.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Import and confirm a document\nto see it here.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: AppColors.text3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: AppSpacing.s3),
            Text(
              'Could not load transactions',
              style: AppText.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

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
    final chipColor = _docTypeColors[tx.documentType] ?? AppColors.text3;

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
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: AppRadius.rXs,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.text3,
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      Text(date, style: AppText.caption),
                      const SizedBox(width: AppSpacing.s3),
                      _TypeChip(label: label, color: chipColor),
                    ],
                  ),
                  if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text(
                      tx.notes!,
                      style: AppText.caption.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (tx.totalAmount != null)
              Text(
                'PKR ${_formatAmount(tx.totalAmount!)}',
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
          ],
        ),
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
      return amount
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return amount.toStringAsFixed(0);
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.rPill,
      ),
      child: Text(label, style: AppText.chip.copyWith(color: color)),
    );
  }
}
