import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_request.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class QuoteScreen extends StatefulWidget {
  final Product? preselectedProduct;

  const QuoteScreen({super.key, this.preselectedProduct});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _submitted = false;
  String _resultMessage = '';
  String _quoteSummary = '';

  // Product type dropdown
  String? _selectedProductType;

  static const _productOptions = [
    ('envelope_c4', 'C4 Envelope (229x324mm)'),
    ('envelope_c5', 'C5 Envelope (162x229mm)'),
    ('envelope_dl', 'DL Envelope (110x220mm)'),
    ('paper_a4_70gsm', 'A4 Paper 70gsm'),
    ('paper_a4_80gsm', 'A4 Paper 80gsm'),
    ('file_carrier_standard', 'A4 File Carrier Standard'),
    ('file_carrier_heavy', 'A4 File Carrier Heavy Duty'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedProduct != null) {
      _selectedProductType = widget.preselectedProduct!.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _emailController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a product')));
      return;
    }

    setState(() => _isLoading = true);

    final request = QuoteRequest(
      customerName: _nameController.text.trim(),
      company: _companyController.text.trim(),
      email: _emailController.text.trim(),
      productType: _selectedProductType!,
      quantity: int.parse(_quantityController.text.trim()),
      notes: _notesController.text.trim(),
    );

    final response = await _apiService.requestQuote(request);

    setState(() {
      _isLoading = false;
      _submitted = response.success;
      _resultMessage = response.message;
      _quoteSummary = response.quoteSummary;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildSuccess();
    return _buildForm();
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get a Quote',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1a472a),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fill in your details and we\'ll email '
              'you a personalised quote.',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Name
            _buildField(
              controller: _nameController,
              label: 'Your Name',
              hint: 'Muhammad Ali',
              validator: (v) => v!.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),

            // Company
            _buildField(
              controller: _companyController,
              label: 'Company / Organisation',
              hint: 'Islamabad Diagnostic Center',
              validator: (v) => v!.isEmpty ? 'Company is required' : null,
            ),
            const SizedBox(height: 14),

            // Email
            _buildField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'you@company.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v!.isEmpty) {
                  return 'Email is required';
                }
                if (!v.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Product dropdown
            Text(
              'Product',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedProductType,
              decoration: _inputDecoration(''),
              hint: Text(
                'Select a product',
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
              items: _productOptions
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.$1,
                      child: Text(p.$2, style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedProductType = val),
            ),
            const SizedBox(height: 14),

            // Quantity
            _buildField(
              controller: _quantityController,
              label: 'Quantity',
              hint: '5000',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v!.isEmpty) {
                  return 'Quantity is required';
                }
                final n = int.tryParse(v);
                if (n == null || n <= 0) {
                  return 'Enter a valid quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Notes
            _buildField(
              controller: _notesController,
              label: 'Additional Notes (optional)',
              hint:
                  'Delivery to Lahore, custom '
                  'printing required...',
              maxLines: 3,
              validator: (_) => null,
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a472a),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Request Quote',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
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

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFf0f7f4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Color(0xFF1a472a),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Quote Sent!',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1a472a),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _resultMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
            ),
            if (_quoteSummary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFf0f7f4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _quoteSummary,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1a472a),
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => setState(() {
                _submitted = false;
                _nameController.clear();
                _companyController.clear();
                _emailController.clear();
                _quantityController.clear();
                _notesController.clear();
                _selectedProductType = null;
              }),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1a472a),
                side: const BorderSide(color: Color(0xFF1a472a)),
              ),
              child: Text('Request Another Quote', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: _inputDecoration(hint),
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1a472a)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
