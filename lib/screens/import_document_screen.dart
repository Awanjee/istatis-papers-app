import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/supabase_config.dart';
import '../services/extraction_service.dart';
import '../theme/app_theme.dart';
import '../theme/arco_components.dart';
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
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 180),
        receiveTimeout: const Duration(seconds: 180),
      ),
    );
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
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('502')) {
      return 'Could not reach the extraction service. Try again.';
    }
    if (raw.contains('422')) {
      return 'The image could not be parsed. Try a clearer photo.';
    }
    if (raw.contains('connection timeout') || raw.contains('connectTimeout')) {
      return 'Request timed out. Try a smaller image.';
    }
    if (raw.contains('receive timeout') || raw.contains('receiveTimeout')) {
      return 'Server did not respond in time. Try again.';
    }
    if (raw.contains('SocketException')) {
      return 'No connection. Check your network and try again.';
    }
    if (raw.contains('CORS') || raw.contains('XMLHttpRequest')) {
      return 'CORS error. Make sure the backend is running on port 8000.';
    }
    return 'Error: $raw';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoading();
    return _buildPicker();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.s6),
          Text('Extracting document data...', style: AppText.body),
          const SizedBox(height: AppSpacing.s2),
          Text('This usually takes 5-10 seconds', style: AppText.caption),
        ],
      ),
    );
  }

  Widget _buildPicker() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const ArcoSectionHead(
            eyebrow: 'Import',
            title: 'Add a document',
            subtitle:
                'Take a photo or choose from your gallery. Works with receipts, khata pages, price lists, and distribution records.',
          ),
          const SizedBox(height: AppSpacing.s8),
          ArcoButton(
            label: 'Take photo',
            icon: Icons.camera_alt_outlined,
            expand: true,
            onPressed: () => _pickAndExtract(ImageSource.camera),
          ),
          const SizedBox(height: AppSpacing.s3),
          ArcoButton(
            label: 'Choose from gallery',
            icon: Icons.photo_library_outlined,
            variant: ArcoButtonVariant.secondary,
            expand: true,
            onPressed: () => _pickAndExtract(ImageSource.gallery),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.s6),
            ArcoAlert(
              variant: ArcoAlertVariant.danger,
              message: _errorMessage!,
            ),
          ],
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
