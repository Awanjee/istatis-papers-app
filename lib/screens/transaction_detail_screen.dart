import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/extraction_service.dart';

// ---------------------------------------------------------------------------
// Product code helpers
// ---------------------------------------------------------------------------

const _sizeExpansions = {
  'a/4': 'A4',
  'a4': 'A4',
  'f/s': 'Foolscap',
  'f15': 'Foolscap',
  'a/3': 'A3',
  '9x4': '9×4"',
  '11x5': '11×5"',
  '8x10': '8×10"',
  '9x6': '9×6"',
  '7x5': '7×5"',
  '7.5x5': '7.5×5"',
};

const _typeExpansions = {
  'prt': 'Print',
  'print': 'Print',
  'dcp': 'Digital Copy',
  'g-2': 'Grade 2',
  'g2': 'Grade 2',
  'usa': 'USA Import',
  'windo': 'Window',
  'window': 'Window',
  'callon': 'Carbon Copy',
  'callory': 'Carbon Copy',
  'open': 'Offset',
};

String expandProductCode(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Unknown';
  final parts = raw.trim().split(RegExp(r'[-/\s]+'));
  final expanded = parts
      .map((p) {
        final lower = p.toLowerCase();
        return _sizeExpansions[lower] ??
            _typeExpansions[lower] ??
            p.toUpperCase();
      })
      .join(' ');
  return expanded;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final ExtractionService service;
  final String? initialPartyName; // shown while loading

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    required this.service,
    this.initialPartyName,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  late Future<TransactionDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.getTransactionDetail(widget.transactionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0B5E72),
        elevation: 0,
        title: Text(
          widget.initialPartyName ?? 'Transaction',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0B5E72),
          ),
        ),
      ),
      body: FutureBuilder<TransactionDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0B5E72)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load transaction details',
                      style: GoogleFonts.inter(fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          }

          final tx = snapshot.data!;
          return _TransactionDetailBody(tx: tx);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _TransactionDetailBody extends StatelessWidget {
  final TransactionDetail tx;

  const _TransactionDetailBody({required this.tx});

  static const _txTypeLabels = {
    'sale': 'Sale',
    'payment_received': 'Payment',
    'purchase': 'Purchase',
    'expense': 'Expense',
  };

  static const _txTypeColors = {
    'sale': Color(0xFF1a472a),
    'payment_received': Color(0xFF0B5E72),
    'purchase': Color(0xFF6A1B9A),
    'expense': Color(0xFFE65100),
  };

  static const _docTypeLabels = {
    'sales_slip': 'Sales Slip',
    'price_list': 'Price List',
    'distribution_record': 'Distribution',
    'account_ledger': 'Ledger',
    'calculation_note': 'Calculation',
    'unknown': 'Unknown',
  };

  @override
  Widget build(BuildContext context) {
    final txType = tx.transactionType ?? 'sale';
    final txColor = _txTypeColors[txType] ?? const Color(0xFF616161);
    final txLabel = _txTypeLabels[txType] ?? txType;
    final docLabel =
        _docTypeLabels[tx.documentType] ?? tx.documentType ?? 'Doc';
    final party = tx.partyNameRoman ?? tx.partyNameUrdu ?? 'Unknown party';
    final date = _formatDate(tx.transactionDate);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header card
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      party,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _Chip(label: txLabel, color: txColor),
                ],
              ),
              // Urdu name if present and different
              if (tx.partyNameUrdu != null &&
                  tx.partyNameUrdu != tx.partyNameRoman) ...[
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    tx.partyNameUrdu!,
                    style: GoogleFonts.notoNastaliqUrdu(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _MetaRow(icon: Icons.calendar_today_outlined, label: date),
              const SizedBox(height: 6),
              _MetaRow(icon: Icons.description_outlined, label: docLabel),
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.notes_outlined,
                  label: tx.notes!,
                  italic: true,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    tx.totalAmount != null
                        ? 'PKR ${_formatAmount(tx.totalAmount!)}'
                        : 'N/A',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: txColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Line items
        if (tx.lineItems.isEmpty)
          _Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No line items recorded',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Line Items (${tx.lineItems.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
          ),
          _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // Column headers
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'PRODUCT',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'QTY × PRICE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'AMOUNT',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...tx.lineItems.asMap().entries.map((entry) {
                  final isLast = entry.key == tx.lineItems.length - 1;
                  return _LineItemRow(
                    item: entry.value,
                    isLast: isLast,
                    txColor: txColor,
                  );
                }),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
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

// ---------------------------------------------------------------------------
// Line item row
// ---------------------------------------------------------------------------

class _LineItemRow extends StatelessWidget {
  final TransactionLineItem item;
  final bool isLast;
  final Color txColor;

  const _LineItemRow({
    required this.item,
    required this.isLast,
    required this.txColor,
  });

  @override
  Widget build(BuildContext context) {
    final code = expandProductCode(item.productCode);
    final desc = item.description?.trim();
    final lowConfidence = item.confidence != null && item.confidence! < 0.6;

    final qtyStr = item.quantity?.toStringAsFixed(
      item.quantity! == item.quantity!.truncateToDouble() ? 0 : 1,
    );
    final priceStr = item.unitPrice != null ? _fmt(item.unitPrice!) : null;
    final qtyPrice = (qtyStr != null && priceStr != null)
        ? '$qtyStr × $priceStr'
        : null;
    final amountStr = item.amount != null ? _fmt(item.amount!) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (lowConfidence)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.warning_amber_rounded,
                              size: 13,
                              color: Colors.orange[400],
                            ),
                          ),
                        Expanded(
                          child: Text(
                            code,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.productCode != null)
                      Text(
                        item.productCode!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    if (desc != null && desc.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          desc,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.orange[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Qty × Price
              Expanded(
                flex: 3,
                child: Text(
                  qtyPrice ?? (qtyStr ?? ''),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black54),
                ),
              ),
              // Amount
              Expanded(
                flex: 2,
                child: Text(
                  amountStr ?? '',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: txColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) {
      return v
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
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
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool italic;

  const _MetaRow({
    required this.icon,
    required this.label,
    this.italic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
