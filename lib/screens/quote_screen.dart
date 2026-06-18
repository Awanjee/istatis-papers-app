import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quote_request.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';

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
  late final ApiService _apiService;

  bool _isLoading = false;
  bool _submitted = false;
  String _resultMessage = '';
  String _quoteSummary = '';
  String? _selectedProductName;

  static const _productOptions = [
    ('C4 Envelope', 'C4 Envelope (229x324mm)'),
    ('C5 Envelope', 'C5 Envelope (162x229mm)'),
    ('DL Envelope', 'DL Envelope (110x220mm)'),
    ('A4 Paper 70gsm', 'A4 Paper 70gsm'),
    ('A4 Paper 80gsm', 'A4 Paper 80gsm'),
    ('A4 File Carrier Standard', 'A4 File Carrier Standard'),
    ('A4 File Carrier Heavy Duty', 'A4 File Carrier Heavy Duty'),
  ];

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _apiService = ApiService(accessTokenProvider: () => auth.accessToken);
    final email = auth.userEmail;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    if (widget.preselectedProduct != null) {
      _selectedProductName = widget.preselectedProduct!.id;
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
    if (_selectedProductName == null) {
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
      productName: _selectedProductName!,
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
      padding: const EdgeInsets.all(AppSpacing.s5),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ArcoSectionHead(
              eyebrow: 'Quote',
              title: 'Get a quote',
              subtitle:
                  'Fill in your details and we\'ll email you a personalised quote.',
            ),
            const SizedBox(height: AppSpacing.s6),
            ArcoPanel(
              child: Column(
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Your name',
                    hint: 'Muhammad Ali',
                    validator: (v) => v!.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _buildField(
                    controller: _companyController,
                    label: 'Company / organisation',
                    hint: 'Islamabad Diagnostic Center',
                    validator: (v) => v!.isEmpty ? 'Company is required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _buildField(
                    controller: _emailController,
                    label: 'Email address',
                    hint: 'you@company.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: ArcoFieldLabel(label: 'Product type'),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProductName,
                    decoration: const InputDecoration(
                      hintText: 'Select a product',
                    ),
                    items: _productOptions
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.$1,
                            child: Text(p.$2, style: AppText.small),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedProductName = val),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _buildField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hint: '5000',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Quantity is required';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  _buildField(
                    controller: _notesController,
                    label: 'Additional notes (optional)',
                    hint: 'Delivery to Lahore, custom printing...',
                    maxLines: 3,
                    validator: (_) => null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            ArcoButton(
              label: 'Request quote',
              expand: true,
              loading: _isLoading,
              onPressed: _submitQuote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ArcoAlert(
              variant: ArcoAlertVariant.success,
              message: 'Quote sent successfully.',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: AppSpacing.s5),
            Text(
              _resultMessage,
              textAlign: TextAlign.center,
              style: AppText.body,
            ),
            if (_quoteSummary.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s4),
              ArcoPanel(
                child: Text(
                  _quoteSummary,
                  style: AppText.mono.copyWith(color: AppColors.accent),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s6),
            ArcoButton(
              label: 'Request another quote',
              variant: ArcoButtonVariant.secondary,
              expand: true,
              onPressed: () => setState(() {
                _submitted = false;
                _nameController.clear();
                _companyController.clear();
                _emailController.clear();
                _quantityController.clear();
                _notesController.clear();
                _selectedProductName = null;
              }),
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
        ArcoFieldLabel(label: label),
        const SizedBox(height: AppSpacing.s2),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: AppText.small,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
