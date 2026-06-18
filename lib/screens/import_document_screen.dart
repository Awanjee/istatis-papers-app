import '../theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import 'extraction_review_screen.dart';

class ImportDocumentScreen extends StatefulWidget {
  const ImportDocumentScreen({super.key});

  @override
  State<ImportDocumentScreen> createState() => _ImportDocumentScreenState();
}

class _ImportDocumentScreenState extends State<ImportDocumentScreen> {
  final _picker = ImagePicker();
  bool _loading = false;
  String? _errorMessage;

  late final ExtractionService _extractionService;

  @override
  void initState() {
    super.initState();
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 180),
      receiveTimeout: const Duration(seconds: 180),
    ));
    _extractionService = ExtractionService(dio);
  }

  Future<void> _pickAndExtract(ImageSource source) async {
    setState(() {
      _loading = false;
      _errorMessage = null;
    });

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (picked == null) return;

    setState(() => _loading = true);

    try {
      final result = await _extractionService.extractDocument(picked);

      if (!mounted) return;
      setState(() => _loading = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExtractionReviewScreen(
            result: result,
            extractionService: _extractionService,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = _friendlyError(e.toString());
      });
      // Print full error to console for debugging
      // ignore: avoid_print
      print('Extraction error: $e');
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('502')) return 'Could not reach the extraction service. Try again.';
    if (raw.contains('422')) return 'The image could not be parsed. Try a clearer photo.';
    if (raw.contains('connection timeout') || raw.contains('connectTimeout')) {
      return 'Request timed out — the server is taking too long. Try a smaller image.';
    }
    if (raw.contains('receive timeout') || raw.contains('receiveTimeout')) {
      return 'Server did not respond in time. Try again.';
    }
    if (raw.contains('SocketException')) {
      return 'No connection. Check your network and try again.';
    }
    if (raw.contains('CORS') || raw.contains('XMLHttpRequest')) {
      return 'CORS error — make sure the backend is running on port 8000.';
    }
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Import Document',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.text1,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Scan a receipt, khata page, or invoice',
              style: GoogleFonts.plusJakartaSans(color: AppColors.text2, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _loading ? _buildLoading() : _buildPicker(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            'Extracting document data...',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, color: AppColors.text2),
          ),
          const SizedBox(height: 8),
          Text(
            'This usually takes 5-10 seconds',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.text3),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          const Icon(
            Icons.document_scanner_outlined,
            size: 72,
            color: AppColors.accent,
          ),
          const SizedBox(height: 24),
          Text(
            'Add a document',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or choose from your gallery.\n'
            'Works with receipts, khata pages, price lists, and distribution records.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.text3,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          _PickerButton(
            icon: Icons.camera_alt_outlined,
            label: 'Take Photo',
            onTap: () => _pickAndExtract(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          _PickerButton(
            icon: Icons.photo_library_outlined,
            label: 'Choose from Gallery',
            onTap: () => _pickAndExtract(ImageSource.gallery),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.dangerSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withOpacity(0.30)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentContrast,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15),
      ),
    );
  }
}
