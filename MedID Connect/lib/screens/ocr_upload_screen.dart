import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/ocr_upload_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';

class OcrUploadScreen extends StatefulWidget {
  const OcrUploadScreen({super.key, this.showBackButton = false});

  static const String route = '/ocr-upload';

  final bool showBackButton;

  @override
  State<OcrUploadScreen> createState() => _OcrUploadScreenState();
}

class _OcrUploadScreenState extends State<OcrUploadScreen> {
  late final OcrUploadService _service = OcrUploadService(ApiClient());
  bool _busy = false;
  Map<String, dynamic>? _result;

  Future<void> _pickAndUpload(bool labReport) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final result = labReport
          ? await _service.uploadLabReport(path)
          : await _service.uploadPrescription(path);
      setState(() => _result = result);
    } catch (error) {
      setState(() {
        _result = {
          'status': 'offline-demo',
          'message': ApiClient().readableError(error),
          'placeholder': labReport
              ? 'Glucose 146 mg/dL detected and ready to save as Observation.'
              : 'Metformin 500mg detected and ready to save as Medication.',
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'OCR upload',
            subtitle:
                'Upload prescription or lab PDFs/images. The MVP uses safe placeholder extraction with confirm-before-save flow.',
            icon: Icons.document_scanner_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                PremiumCard(
                  gradient: AppPalette.cyanGradient,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI document intake',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Future engines: Tesseract, Google Vision, AWS Textract, medical NLP, and clinician review.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : () => _pickAndUpload(false),
                        icon: const Icon(Icons.medication_rounded),
                        label: const Text('Prescription'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _busy ? null : () => _pickAndUpload(true),
                        icon: const Icon(Icons.science_rounded),
                        label: const Text('Lab report'),
                      ),
                    ),
                  ],
                ),
                if (_busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                const SectionHeader(title: 'Extraction result'),
                PremiumCard(
                  child: _result == null
                      ? const Text(
                          'Upload a file to see extracted medicines or lab values.')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _result!.entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                const SizedBox(height: 12),
                const PremiumCard(
                  color: AppPalette.softBlue,
                  child: Text(
                    'This OCR output is informational only and must be confirmed by the user before clinical use.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
