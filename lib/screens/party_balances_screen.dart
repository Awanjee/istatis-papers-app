import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';
import 'transaction_detail_screen.dart';

class PartyBalancesScreen extends StatefulWidget {
  const PartyBalancesScreen({super.key});

  @override
  State<PartyBalancesScreen> createState() => _PartyBalancesScreenState();
}

class _PartyBalancesScreenState extends State<PartyBalancesScreen> {
  late final ExtractionService _service;
  late Future<List<PartyBalance>> _future;

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
    _future = _service.getPartyBalances();
  }

  void _refresh() => setState(() => _future = _service.getPartyBalances());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<PartyBalance>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return _buildError();
          final parties = snap.data ?? [];
          if (parties.isEmpty) return _buildEmpty();

          final totalOwed = parties.fold(
            0.0,
            (s, p) => s + (p.balance > 0 ? p.balance : 0),
          );
          final totalOwing = parties.fold(
            0.0,
            (s, p) => s + (p.balance < 0 ? p.balance.abs() : 0),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s6,
            ),
            children: [
              _SummaryRow(totalOwed: totalOwed, totalOwing: totalOwing),
              const SizedBox(height: AppSpacing.s4),
              ...parties.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: _PartyCard(
                    party: p,
                    onTap: () => _openPartyTransactions(p),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openPartyTransactions(PartyBalance party) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyTransactionHistoryScreen(party: party),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Column(
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppColors.text3),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'No parties yet',
              style: AppText.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.text3,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'Confirm a transaction to see\nparty balances here.',
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(color: AppColors.text3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
          const SizedBox(height: AppSpacing.s3),
          Text(
            'Could not load balances',
            style: AppText.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.s2),
          TextButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double totalOwed;
  final double totalOwing;

  const _SummaryRow({required this.totalOwed, required this.totalOwing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Owed to iStatis',
            amount: totalOwed,
            color: AppColors.accent,
            icon: Icons.arrow_circle_up_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.s3),
        Expanded(
          child: _SummaryCard(
            label: 'iStatis Owes',
            amount: totalOwing,
            color: AppColors.warning,
            icon: Icons.arrow_circle_down_outlined,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: AppDecorations.semanticTint(color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppSpacing.s2),
              Text(label, style: AppText.chip.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'PKR ${_fmt(amount)}',
            style: AppText.bodyLg.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _PartyCard extends StatelessWidget {
  final PartyBalance party;
  final VoidCallback onTap;

  const _PartyCard({required this.party, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = party.nameRoman ?? party.nameUrdu ?? 'Unknown';
    final balance = party.balance;
    final isOwed = balance >= 0;
    final balanceColor = isOwed ? AppColors.accent : AppColors.warning;
    final lastDate = _formatDate(party.lastTransactionDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: balanceColor,
                borderRadius: AppRadius.rXs,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Row(
                    children: [
                      Text(
                        '${party.transactionCount} transactions',
                        style: AppText.caption,
                      ),
                      if (lastDate != null) ...[
                        Text('  ·  ', style: AppText.caption),
                        Text('Last: $lastDate', style: AppText.caption),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${_fmtAbs(balance)}',
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w800,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOwed ? 'owes iStatis' : 'iStatis owes',
                  style: AppText.caption.copyWith(
                    color: balanceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.s2),
            const Icon(Icons.chevron_right, color: AppColors.text3, size: 20),
          ],
        ),
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtAbs(double v) => v
      .abs()
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class PartyTransactionHistoryScreen extends StatefulWidget {
  final PartyBalance party;

  const PartyTransactionHistoryScreen({super.key, required this.party});

  @override
  State<PartyTransactionHistoryScreen> createState() =>
      _PartyTransactionHistoryScreenState();
}

class _PartyTransactionHistoryScreenState
    extends State<PartyTransactionHistoryScreen> {
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
    _future = _service.getTransactions(partyId: widget.party.partyId);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.party.nameRoman ?? widget.party.nameUrdu ?? 'Unknown';
    final balance = widget.party.balance;
    final isOwed = balance >= 0;
    final balanceColor = isOwed ? AppColors.accent : AppColors.warning;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: ArcoTopBar(
        title: name,
        subtitle: '${isOwed ? "Owes" : "Owed"} PKR ${_fmtAbs(balance)}',
        showBrand: false,
      ),
      body: FutureBuilder<List<TransactionSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: balanceColor),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Could not load.',
                style: AppText.small.copyWith(color: AppColors.text3),
              ),
            );
          }
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return Center(
              child: Text(
                'No transactions found.',
                style: AppText.small.copyWith(color: AppColors.text3),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s4),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s3),
            itemBuilder: (_, i) => _PartyTxRow(tx: txs[i], service: _service),
          );
        },
      ),
    );
  }

  String _fmtAbs(double v) => v
      .abs()
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

class _PartyTxRow extends StatelessWidget {
  final TransactionSummary tx;
  final ExtractionService service;
  const _PartyTxRow({required this.tx, required this.service});

  static const _txTypeColors = {
    'sale': AppColors.accent,
    'payment_received': AppColors.success,
    'purchase': AppColors.warning,
    'expense': AppColors.warning,
  };

  static const _txTypeLabels = {
    'sale': 'Sale',
    'payment_received': 'Payment',
    'purchase': 'Purchase',
    'expense': 'Expense',
  };

  @override
  Widget build(BuildContext context) {
    final txType = tx.transactionType ?? 'sale';
    final color = _txTypeColors[txType] ?? AppColors.text3;
    final label = _txTypeLabels[txType] ?? txType;
    final isCredit = txType == 'payment_received';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            transactionId: tx.id,
            service: service,
            initialPartyName: tx.partyNameRoman ?? tx.partyNameUrdu,
          ),
        ),
      ),
      child: Container(
        decoration: AppDecorations.card(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s4,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.rXs,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TypeChip(label: label, color: color),
                      const SizedBox(width: AppSpacing.s2),
                      Text(
                        _formatDate(tx.transactionDate),
                        style: AppText.caption,
                      ),
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
                '${isCredit ? "-" : "+"}PKR ${_fmt(tx.totalAmount!)}',
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCredit ? AppColors.success : AppColors.accent,
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

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
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
