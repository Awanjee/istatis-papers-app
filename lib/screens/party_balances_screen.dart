import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
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
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _service = ExtractionService(dio);
    _future = _service.getPartyBalances();
  }

  void _refresh() => setState(() => _future = _service.getPartyBalances());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF0B5E72),
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<PartyBalance>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B5E72)),
            );
          }
          if (snap.hasError) {
            return _buildError();
          }
          final parties = snap.data ?? [];
          if (parties.isEmpty) return _buildEmpty();

          // Summary totals at the top
          final totalOwed =
              parties.fold(0.0, (s, p) => s + (p.balance > 0 ? p.balance : 0));
          final totalOwing =
              parties.fold(0.0, (s, p) => s + (p.balance < 0 ? p.balance.abs() : 0));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _SummaryRow(totalOwed: totalOwed, totalOwing: totalOwing),
              const SizedBox(height: 16),
              ...parties.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PartyCard(
                      party: p,
                      onTap: () => _openPartyTransactions(p),
                    ),
                  )),
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
            Icon(Icons.people_outline, size: 64, color: Colors.grey[350]),
            const SizedBox(height: 16),
            Text(
              'No parties yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confirm a transaction to see\nparty balances here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
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
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 12),
          Text(
            'Could not load balances',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _refresh, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary row at top
// ---------------------------------------------------------------------------

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
            color: const Color(0xFF0B5E72),
            icon: Icons.arrow_circle_up_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'iStatis Owes',
            amount: totalOwing,
            color: const Color(0xFFE65100),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PKR ${_fmt(amount)}',
            style: GoogleFonts.inter(
              fontSize: 16,
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
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ---------------------------------------------------------------------------
// Party card
// ---------------------------------------------------------------------------

class _PartyCard extends StatelessWidget {
  final PartyBalance party;
  final VoidCallback onTap;

  const _PartyCard({required this.party, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = party.nameRoman ?? party.nameUrdu ?? 'Unknown';
    final balance = party.balance;
    final isOwed = balance >= 0; // party owes iStatis
    final balanceColor =
        isOwed ? const Color(0xFF0B5E72) : const Color(0xFFE65100);
    final lastDate = _formatDate(party.lastTransactionDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            // Left accent
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: balanceColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${party.transactionCount} transactions',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                      if (lastDate != null) ...[
                        Text('  ·  ',
                            style: GoogleFonts.inter(color: Colors.grey[400])),
                        Text(
                          'Last: $lastDate',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Right: balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${_fmtAbs(balance)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOwed ? 'owes iStatis' : 'iStatis owes',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: balanceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
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
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

// ---------------------------------------------------------------------------
// Party-filtered transaction history screen (pushed on tap)
// ---------------------------------------------------------------------------

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
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _service = ExtractionService(dio);
    _future = _service.getTransactions(partyId: widget.party.partyId);
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.party.nameRoman ?? widget.party.nameUrdu ?? 'Unknown';
    final balance = widget.party.balance;
    final isOwed = balance >= 0;
    final balanceColor =
        isOwed ? const Color(0xFF0B5E72) : const Color(0xFFE65100);

    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B5E72),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${isOwed ? "Owes" : "Owed"} PKR ${_fmtAbs(balance)}',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              child: Text('Could not load.',
                  style: GoogleFonts.inter(color: Colors.grey[600])));
          }
          final txs = snap.data ?? [];
          if (txs.isEmpty) {
            return Center(
              child: Text('No transactions found.',
                  style: GoogleFonts.inter(color: Colors.grey[500])));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _PartyTxRow(tx: txs[i], service: _service),
          );
        },
      ),
    );
  }

  String _fmtAbs(double v) => v
      .abs()
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

class _PartyTxRow extends StatelessWidget {
  final TransactionSummary tx;
  final ExtractionService service;
  const _PartyTxRow({required this.tx, required this.service});

  static const _txTypeColors = {
    'sale': Color(0xFF0B5E72),
    'payment_received': Color(0xFF1565C0),
    'purchase': Color(0xFF6A1B9A),
    'expense': Color(0xFFE65100),
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
    final color = _txTypeColors[txType] ?? const Color(0xFF616161);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(tx.transactionDate),
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[500]),
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
          if (tx.totalAmount != null)
            Text(
              '${isCredit ? "-" : "+"}PKR ${_fmt(tx.totalAmount!)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCredit ? const Color(0xFF1565C0) : const Color(0xFF0B5E72),
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

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
