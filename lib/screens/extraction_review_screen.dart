import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/extraction_result.dart';
import '../services/extraction_service.dart';

class ExtractionReviewScreen extends StatefulWidget {
  final ExtractionResult result;
  final ExtractionService extractionService;

  const ExtractionReviewScreen({
    super.key,
    required this.result,
    required this.extractionService,
  });

  @override
  State<ExtractionReviewScreen> createState() => _ExtractionReviewScreenState();
}

class _ExtractionReviewScreenState extends State<ExtractionReviewScreen> {
  late final TextEditingController _partyCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _totalCtrl;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _partyCtrl = TextEditingController(text: r.partyName ?? '');
    _dateCtrl = TextEditingController(text: r.date ?? '');
    _totalCtrl = TextEditingController(
      text: r.totals.grandTotal?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _partyCtrl.dispose();
    _dateCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.extractionService.confirmExtraction(
        result: widget.result,
        editedPartyName:
            _partyCtrl.text.trim().isEmpty ? null : _partyCtrl.text.trim(),
        editedDate:
            _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim(),
        editedTotal: double.tryParse(_totalCtrl.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction saved.'),
          backgroundColor: Color(0xFF1a472a),
        ),
      );
      Navigator.pop(context); // back to import screen
    } catch (e) {
      setState(() {
        _saving = false;
        _saveError = 'Could not save. Please try again.';
      });
    }
  }

  // ------------------------------------------------------------------
  // Confidence colour helpers
  // ------------------------------------------------------------------

  Color _confColor(double conf) {
    if (conf >= 0.8) return Colors.green[700]!;
    if (conf >= 0.6) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Color _confBg(double conf) {
    if (conf >= 0.8) return Colors.green[50]!;
    if (conf >= 0.6) return Colors.orange[50]!;
    return Colors.red[50]!;
  }

  String _docTypeLabel(String? dt) {
    const labels = {
      'calculation_note': 'Calculation Note',
      'sales_slip': 'Sales Slip',
      'price_list': 'Price List',
      'distribution_record': 'Distribution Record',
      'account_ledger': 'Account Ledger',
      'unknown': 'Unknown',
    };
    return labels[dt] ?? (dt ?? 'Unknown');
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a472a),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Extraction',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _docTypeLabel(r.documentType),
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _ConfidenceBadge(confidence: r.overallConfidence),
          ),
        ],
      ),
      body: _saving
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1a472a)),
            )
          : _buildBody(r),
      bottomNavigationBar: _saving ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody(ExtractionResult r) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Warning banner
        if (r.hasWarnings) _buildWarningBanner(r),

        // Header fields
        _SectionCard(
          title: 'Document Details',
          child: Column(
            children: [
              _EditField(
                label: 'Party / Name',
                controller: _partyCtrl,
                urduHint: r.partyNameUrdu,
              ),
              const SizedBox(height: 12),
              _EditField(
                label: 'Date',
                controller: _dateCtrl,
                hint: 'DD/MM/YY',
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 12),
              _EditField(
                label: 'Total Amount (PKR)',
                controller: _totalCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Line items
        if (r.lineItems.isNotEmpty)
          _SectionCard(
            title: 'Line Items (${r.lineItems.length})',
            child: Column(
              children: r.lineItems
                  .map((item) => _LineItemTile(
                        item: item,
                        confColor: _confColor(item.confidence),
                        confBg: _confBg(item.confidence),
                      ))
                  .toList(),
            ),
          ),

        // Unreadable sections note
        if (r.unreadableSections != null && r.unreadableSections!.isNotEmpty)
          _InfoTile(
            icon: Icons.visibility_off_outlined,
            color: Colors.grey[700]!,
            bg: Colors.grey[100]!,
            text: 'Could not read: ${r.unreadableSections}',
          ),

        // Urdu raw text
        if (r.rawTextUrdu != null && r.rawTextUrdu!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _SectionCard(
              title: 'Urdu Text (verbatim)',
              child: Text(
                r.rawTextUrdu!,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.8,
                ),
              ),
            ),
          ),

        if (_saveError != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _InfoTile(
              icon: Icons.error_outline,
              color: Colors.red[700]!,
              bg: Colors.red[50]!,
              text: _saveError!,
            ),
          ),

        const SizedBox(height: 100), // space above bottom bar
      ],
    );
  }

  Widget _buildWarningBanner(ExtractionResult r) {
    final fields = r.lowConfidenceFields;
    final hasUnread = r.unreadableSections != null && r.unreadableSections!.isNotEmpty;

    String message = 'Some fields may need review';
    if (fields.isNotEmpty) {
      message = 'Low confidence: ${fields.take(3).join(", ")}';
      if (fields.length > 3) message += ' +${fields.length - 3} more';
    } else if (hasUnread) {
      message = 'Some sections could not be read';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.amber[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Discard',
                  style: GoogleFonts.inter(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a472a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Confirm & Save',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// Sub-widgets
// ------------------------------------------------------------------

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    Color bg;
    if (confidence >= 0.8) {
      bg = Colors.green[700]!;
    } else if (confidence >= 0.6) {
      bg = Colors.orange[700]!;
    } else {
      bg = Colors.red[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct%',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? urduHint;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    this.hint,
    this.urduHint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1a472a), width: 1.5),
            ),
            suffix: urduHint != null
                ? Text(
                    urduHint!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textDirection: TextDirection.rtl,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _LineItemTile extends StatelessWidget {
  final LineItem item;
  final Color confColor;
  final Color confBg;

  const _LineItemTile({
    required this.item,
    required this.confColor,
    required this.confBg,
  });

  @override
  Widget build(BuildContext context) {
    final code = item.editedProductCode ?? item.productCode ?? '-';
    final desc = item.editedDescription;
    final qty = item.editedQuantity;
    final price = item.editedUnitPrice;
    final amt = item.editedAmount;
    final pct = (item.confidence * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: confColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  children: [
                    if (qty != null)
                      _MiniStat(label: 'qty', value: qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 2)),
                    if (price != null)
                      _MiniStat(label: 'unit', value: price.toStringAsFixed(0)),
                    if (amt != null)
                      _MiniStat(label: 'total', value: amt.toStringAsFixed(0)),
                  ],
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.notes!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: confColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: confColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String text;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
