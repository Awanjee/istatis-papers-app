import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late String _transactionType;

  static const _txTypeDefaults = {
    'sales_slip': 'sale',
    'account_ledger': 'sale',
    'distribution_record': 'sale',
    'price_list': 'sale',
    'calculation_note': 'sale',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.result;
    _partyCtrl = TextEditingController(text: r.partyName ?? '');
    _dateCtrl = TextEditingController(text: r.date ?? '');
    _totalCtrl = TextEditingController(
      text: r.totals.grandTotal?.toStringAsFixed(0) ?? '',
    );
    _transactionType =
        _txTypeDefaults[r.documentType] ?? 'sale';
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
        transactionType: _transactionType,
      );
      if (!mounted) return;

      // Reset saving state so the screen renders normally before sheet appears
      setState(() => _saving = false);

      await _showWhatsAppSheet(_buildWhatsAppMessage());
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _saveError = 'Could not save. Please try again.';
      });
    }
  }

  String _buildWhatsAppMessage() {
    final party = _partyCtrl.text.trim();

    final date = _dateCtrl.text.trim().isNotEmpty
        ? _dateCtrl.text.trim()
        : 'today';
    final total = double.tryParse(_totalCtrl.text.trim());
    final totalStr = total != null
        ? 'PKR ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'
        : '';

    // Build product summary from line items (up to 3)
    final items = widget.result.lineItems;
    String productSummary = '';
    if (items.isNotEmpty) {
      final lines = items.take(3).map((i) {
        final code = i.productCode ?? '-';
        final qty = i.quantity != null ? ' x${i.quantity!.toStringAsFixed(0)}' : '';
        return '$code$qty';
      }).join(', ');
      productSummary = '\nItems: $lines${items.length > 3 ? ' ...' : ''}';
    }

    final txLabel = {
      'sale': 'Sale',
      'payment_received': 'Payment received',
      'purchase': 'Purchase',
      'expense': 'Expense',
    }[_transactionType] ?? 'Transaction';

    final buffer = StringBuffer();
    buffer.writeln('Arco Papers');
    buffer.writeln('$txLabel — $date');
    if (party.isNotEmpty) buffer.writeln('Party: $party');
    if (totalStr.isNotEmpty) buffer.writeln('Amount: $totalStr');
    if (productSummary.isNotEmpty) buffer.write(productSummary);
    return buffer.toString().trim(); // always returns a non-null string
  }

  Future<void> _showWhatsAppSheet(String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _WhatsAppSheet(initialMessage: message),
    );
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

        // Transaction type selector
        _SectionCard(
          title: 'Transaction Type',
          child: _TxTypeSelector(
            value: _transactionType,
            onChanged: (v) => setState(() => _transactionType = v),
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

class _TxTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TxTypeSelector({required this.value, required this.onChanged});

  static final _options = [
    ('sale', 'Sale', Icons.arrow_upward, const Color(0xFF1a472a)),
    ('payment_received', 'Payment In', Icons.payments_outlined, const Color(0xFF1565C0)),
    ('purchase', 'Purchase', Icons.arrow_downward, const Color(0xFF6A1B9A)),
    ('expense', 'Expense', Icons.receipt_outlined, const Color(0xFFE65100)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((opt) {
        final (key, label, icon, color) = opt;
        final selected = value == key;
        return GestureDetector(
          onTap: () => onChanged(key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.12) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? color : Colors.grey[300]!,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 14,
                    color: selected ? color : Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

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

class _WhatsAppSheet extends StatefulWidget {
  final String initialMessage;
  const _WhatsAppSheet({required this.initialMessage});

  @override
  State<_WhatsAppSheet> createState() => _WhatsAppSheetState();
}

class _WhatsAppSheetState extends State<_WhatsAppSheet> {
  late final TextEditingController _msgCtrl;

  @override
  void initState() {
    super.initState();
    _msgCtrl = TextEditingController(text: widget.initialMessage);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch() async {
    final encoded = Uri.encodeComponent(_msgCtrl.text.trim());
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.pop(context); // close sheet; review screen pops itself after
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _msgCtrl.text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_outlined,
                      color: Color(0xFF25D366), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Send on WhatsApp',
                        style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('Edit then open WhatsApp',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Editable message
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF25D366).withOpacity(0.3)),
              ),
              child: TextField(
                controller: _msgCtrl,
                maxLines: 6,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                IconButton(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_outlined),
                  color: Colors.grey[600],
                  tooltip: 'Copy',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Skip',
                        style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _launch,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: Text('Open WhatsApp',
                        style:
                            GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
