import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/fhir_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';

class FhirViewerScreen extends StatefulWidget {
  const FhirViewerScreen({super.key, this.showBackButton = false});

  static const String route = '/fhir-viewer';

  final bool showBackButton;

  @override
  State<FhirViewerScreen> createState() => _FhirViewerScreenState();
}

class _FhirViewerScreenState extends State<FhirViewerScreen> {
  final _resources = const [
    'Patient',
    'Observation',
    'Condition',
    'MedicationRequest',
    'AllergyIntolerance',
    'DiagnosticReport',
    'Immunization',
    'Appointment',
  ];
  late final FhirService _service = FhirService(ApiClient());
  String _selected = 'Patient';
  Future<Map<String, dynamic>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final auth = context.read<AuthProvider>();
    final id = auth.currentUser?['id'];
    final patientId = id is int ? id : int.tryParse(id?.toString() ?? '') ?? 1;
    try {
      if (_selected == 'Patient') return await _service.patient(patientId);
      return await _service.bundle(_selected, patientId);
    } catch (_) {
      return {
        'resourceType': _selected == 'Patient' ? 'Patient' : 'Bundle',
        'status': 'offline-demo',
        'message': 'Run the backend and sign in to view live FHIR JSON.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'FHIR viewer',
            subtitle:
                'Developer-friendly FHIR R4 JSON export for patient-controlled sharing.',
            icon: Icons.data_object_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    segments: _resources
                        .map((resource) => ButtonSegment(
                            value: resource, label: Text(resource)))
                        .toList(),
                    selected: {_selected},
                    onSelectionChanged: (value) {
                      setState(() {
                        _selected = value.first;
                        _future = _load();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),
                FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final json = const JsonEncoder.withIndent('  ')
                        .convert(snapshot.data ?? {'loading': true});
                    return PremiumCard(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppPalette.darkCard
                          : const Color(0xFFF8FBFF),
                      child: SelectableText(
                        json,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
