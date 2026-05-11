import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medication_request.dart';
import '../services/date_format_service.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class MedicationTrackerScreen extends StatelessWidget {
  const MedicationTrackerScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/medications';

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final adherencePercent = (data.medicationAdherence * 100).round();
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Medication tracker',
            subtitle:
                'Track active mock MedicationRequest resources and today\'s adherence.',
            icon: Icons.medication_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                PremiumCard(
                  gradient: AppPalette.purpleGradient,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Today\'s adherence',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '$adherencePercent%',
                            style: textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: data.medicationAdherence,
                          minHeight: 12,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${data.medicationsTakenToday} of ${data.medications.length} marked as taken today.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _showMedicationForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add medication'),
                ),
                const SectionHeader(title: 'Active medications'),
                ...data.medications.map(
                  (medication) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MedicationTile(
                      medication: medication,
                      onEdit: () => _showMedicationForm(
                        context,
                        medication: medication,
                      ),
                    ),
                  ),
                ),
                const SectionHeader(title: 'Schedule'),
                const PremiumCard(
                  child: Column(
                    children: [
                      _ScheduleRow(
                        time: '08:00 AM',
                        label: 'Amlodipine 5 mg',
                        icon: Icons.wb_sunny_rounded,
                        color: AppPalette.primary,
                      ),
                      _ScheduleRow(
                        time: '01:00 PM',
                        label: 'Vitamin D3 1000 IU',
                        icon: Icons.restaurant_rounded,
                        color: AppPalette.warning,
                      ),
                      _ScheduleRow(
                        time: '09:30 PM',
                        label: 'Cetirizine 10 mg if symptoms appear',
                        icon: Icons.nightlight_round,
                        color: AppPalette.purple,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Interaction watch'),
                const PremiumCard(
                  color: AppPalette.softPurple,
                  child: Column(
                    children: [
                      _WarningRow(
                        icon: Icons.warning_amber_rounded,
                        color: AppPalette.warning,
                        title: 'Cetirizine + sedatives',
                        subtitle:
                            'May increase drowsiness. Avoid alcohol and confirm with your clinician.',
                      ),
                      _WarningRow(
                        icon: Icons.verified_user_rounded,
                        color: AppPalette.success,
                        title: 'Amlodipine schedule looks consistent',
                        subtitle:
                            'Morning dosing pattern is aligned with the current mock care plan.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showMedicationForm(
    BuildContext context, {
    MedicationRequest? medication,
  }) async {
    final name = TextEditingController(text: medication?.medicationName);
    final dosage = TextEditingController(text: medication?.dosageInstruction);
    final frequency = TextEditingController(text: medication?.frequency);
    final doctor = TextEditingController(text: medication?.prescriber);
    bool active = medication?.status != 'inactive';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
                    medication == null ? 'Add medication' : 'Edit medication',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    decoration:
                        const InputDecoration(labelText: 'Medicine name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dosage,
                    decoration: const InputDecoration(labelText: 'Dosage'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: frequency,
                    decoration: const InputDecoration(
                      labelText: 'Schedule time / frequency',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: doctor,
                    decoration:
                        const InputDecoration(labelText: 'Prescribing doctor'),
                  ),
                  SwitchListTile(
                    value: active,
                    onChanged: (value) => setSheetState(() => active = value),
                    title: const Text('Active medication'),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () async {
                      final payload = {
                        'medicine_name': name.text.trim(),
                        'dosage': dosage.text.trim(),
                        'frequency': frequency.text.trim(),
                        'prescribing_doctor': doctor.text.trim(),
                        'active': active,
                        'start_date': DateTime.now().toUtc().toIso8601String(),
                      };
                      try {
                        final provider = context.read<HealthDataProvider>();
                        final id = int.tryParse(medication?.id ?? '');
                        if (id != null) {
                          await provider.updateMedication(id, payload);
                        } else {
                          await provider.addMedication(payload);
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Backend unavailable. Medication form is ready for connected mode.',
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
                    label: const Text('Save medication'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WarningRow extends StatelessWidget {
  const _WarningRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationTile extends StatelessWidget {
  const _MedicationTile({
    required this.medication,
    required this.onEdit,
  });

  final MedicationRequest medication;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final data = context.read<HealthDataProvider>();
    final textTheme = Theme.of(context).textTheme;
    final statusColor =
        medication.takenToday ? AppPalette.success : AppPalette.purple;

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.medication_liquid_rounded, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medication.medicationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: medication.takenToday,
                      onChanged: (_) => data.toggleMedication(medication.id),
                    ),
                  ],
                ),
                Text(
                  medication.dosageInstruction,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppPalette.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: medication.frequency,
                      color: AppPalette.primary,
                      icon: Icons.repeat_rounded,
                    ),
                    StatusChip(
                      label: medication.status,
                      color: AppPalette.success,
                      icon: Icons.check_rounded,
                    ),
                    StatusChip(
                      label: DateFormatService.shortDate(medication.startDate),
                      color: AppPalette.cyan,
                      icon: Icons.calendar_month_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Prescriber: ${medication.prescriber}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final id = int.tryParse(medication.id);
                        if (id == null) {
                          return;
                        }
                        await context
                            .read<HealthDataProvider>()
                            .deleteMedication(id);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Delete'),
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

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.time,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String time;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: Text(
              time,
              style: textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
