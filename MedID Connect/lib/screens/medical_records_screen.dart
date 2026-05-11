import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/status_chip.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/records';

  final bool showBackButton;

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  String _filter = 'All';
  String _search = '';
  final Map<String, ({bool favorite, bool pinned})> _flags = {};

  static const List<String> _filters = [
    'All',
    'Lab Report',
    'Prescription',
    'Diagnosis',
    'Vaccination',
    'Visit Summary',
    'Insurance',
  ];

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final records = _records(data)
        .where(
      (record) => _filter == 'All' || record['record_type'] == _filter,
    )
        .where((record) {
      if (_search.trim().isEmpty) return true;
      final query = _search.trim().toLowerCase();
      return [
        record['title'],
        record['description'],
        record['provider_name'],
        record['doctor_name'],
        record['record_type'],
      ].any((value) => value.toString().toLowerCase().contains(query));
    }).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Medical records',
            subtitle: 'Add, edit, delete, filter, and view health records.',
            icon: Icons.folder_shared_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                FilledButton.icon(
                  onPressed: () => _showRecordForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add medical record'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'PDF/image upload placeholder is ready for file storage integration.',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Upload PDF / image placeholder'),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search documents',
                    hintText: 'Search lab, diagnosis, doctor, hospital',
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters
                        .map(
                          (filter) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  const PremiumCard(
                    child: _EmptyRecords(),
                  )
                else
                  ...records.map(
                    (record) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RecordCard(
                        record: record,
                        favorite: _flagFor(record).favorite,
                        pinned: _flagFor(record).pinned,
                        onView: () => _showRecordDetails(context, record),
                        onEdit: () => _showRecordForm(context, record: record),
                        onFavorite: () => _toggleFavorite(record),
                        onPin: () => _togglePinned(record),
                        onDelete: data.usingBackend && record['id'] is int
                            ? () async =>
                                data.deleteMedicalRecord(record['id'] as int)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ({bool favorite, bool pinned}) _flagFor(Map<String, dynamic> record) {
    return _flags[record['id'].toString()] ?? (favorite: false, pinned: false);
  }

  void _toggleFavorite(Map<String, dynamic> record) {
    final id = record['id'].toString();
    final current = _flagFor(record);
    setState(() {
      _flags[id] = (favorite: !current.favorite, pinned: current.pinned);
    });
  }

  void _togglePinned(Map<String, dynamic> record) {
    final id = record['id'].toString();
    final current = _flagFor(record);
    setState(() {
      _flags[id] = (favorite: current.favorite, pinned: !current.pinned);
    });
  }

  List<Map<String, dynamic>> _records(HealthDataProvider data) {
    if (data.medicalRecords.isNotEmpty) {
      return data.medicalRecords;
    }
    return [
      for (final report in data.diagnosticReports)
        {
          'id': report.id,
          'record_type': 'Lab Report',
          'title': report.title,
          'description': report.summary,
          'provider_name': report.performer,
          'doctor_name': 'Care team',
          'record_date': report.issuedDate.toIso8601String(),
        },
      for (final vaccine in data.immunizations)
        {
          'id': vaccine.id,
          'record_type': 'Vaccination',
          'title': vaccine.vaccineCode,
          'description': 'Lot ${vaccine.lotNumber}',
          'provider_name': vaccine.performer,
          'doctor_name': 'Immunization team',
          'record_date': vaccine.occurrenceDate.toIso8601String(),
        },
    ];
  }

  Future<void> _showRecordForm(
    BuildContext context, {
    Map<String, dynamic>? record,
  }) async {
    final title = TextEditingController(text: record?['title']?.toString());
    final description =
        TextEditingController(text: record?['description']?.toString());
    final provider =
        TextEditingController(text: record?['provider_name']?.toString());
    final doctor =
        TextEditingController(text: record?['doctor_name']?.toString());
    String recordType = record?['record_type']?.toString() ?? 'Lab Report';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record == null ? 'Add record' : 'Edit record',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: recordType,
                      items: _filters
                          .where((filter) => filter != 'All')
                          .map(
                            (filter) => DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => recordType = value ?? recordType),
                      decoration:
                          const InputDecoration(labelText: 'Record type'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: provider,
                      decoration: const InputDecoration(labelText: 'Provider'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: doctor,
                      decoration: const InputDecoration(
                          labelText: 'Doctor / clinician'),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        final payload = {
                          'record_type': recordType,
                          'title': title.text.trim(),
                          'description': description.text.trim(),
                          'provider_name': provider.text.trim(),
                          'doctor_name': doctor.text.trim(),
                          'record_date':
                              DateTime.now().toUtc().toIso8601String(),
                          'fhir_resource_type': recordType,
                          'fhir_payload': <String, dynamic>{},
                        };
                        try {
                          await context
                              .read<HealthDataProvider>()
                              .addMedicalRecord(payload);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Backend unavailable. Record form is ready for connected mode.',
                                ),
                              ),
                            );
                          }
                        }
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save record'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showRecordDetails(BuildContext context, Map<String, dynamic> record) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(
              label: record['record_type']?.toString() ?? 'Record',
              color: AppPalette.primary,
              icon: Icons.folder_rounded,
            ),
            const SizedBox(height: 12),
            Text(
              record['title']?.toString() ?? 'Medical record',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(record['description']?.toString() ?? 'No description.'),
            const SizedBox(height: 14),
            Text('Provider: ${record['provider_name'] ?? 'Unknown'}'),
            Text('Clinician: ${record['doctor_name'] ?? 'Unknown'}'),
          ],
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.favorite,
    required this.pinned,
    required this.onView,
    required this.onEdit,
    required this.onFavorite,
    required this.onPin,
    required this.onDelete,
  });

  final Map<String, dynamic> record;
  final bool favorite;
  final bool pinned;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;
  final VoidCallback onPin;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final date = DateTime.tryParse(record['record_date']?.toString() ?? '');
    return PremiumCard(
      onTap: onView,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppPalette.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['title']?.toString() ?? 'Record',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${record['provider_name'] ?? 'Provider'} - ${date == null ? 'No date' : DateFormatService.shortDate(date)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: record['record_type']?.toString() ?? 'Record',
                      color: AppPalette.cyan,
                    ),
                    if (pinned)
                      const StatusChip(
                        label: 'Pinned critical',
                        color: AppPalette.danger,
                        icon: Icons.push_pin_rounded,
                      ),
                    if (favorite)
                      const StatusChip(
                        label: 'Favorite',
                        color: AppPalette.warning,
                        icon: Icons.star_rounded,
                      ),
                    IconButton.filledTonal(
                      tooltip: favorite ? 'Unfavorite' : 'Favorite',
                      onPressed: onFavorite,
                      icon: Icon(favorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded),
                    ),
                    IconButton.filledTonal(
                      tooltip: pinned ? 'Unpin' : 'Pin critical report',
                      onPressed: onPin,
                      icon: Icon(pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                    ),
                    if (onDelete != null)
                      IconButton.filledTonal(
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.folder_open_rounded,
            size: 42, color: AppPalette.primary),
        const SizedBox(height: 10),
        Text(
          'No records yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
            'Add a medical record to start building your health timeline.'),
      ],
    );
  }
}
