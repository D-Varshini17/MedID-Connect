import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/date_format_service.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class PatientSummaryScreen extends StatelessWidget {
  const PatientSummaryScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/patient-summary';

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Patient summary',
            subtitle:
                'A unified FHIR-style overview of demographics and key clinical resources.',
            icon: Icons.assignment_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                PremiumCard(
                  gradient: AppPalette.cyanGradient,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          patient.initials,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patient.id,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusChip(
                                  label: '${patient.age} years',
                                  color: Colors.white,
                                  icon: Icons.cake_rounded,
                                ),
                                StatusChip(
                                  label: patient.bloodGroup,
                                  color: Colors.white,
                                  icon: Icons.bloodtype_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Demographics'),
                PremiumCard(
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.person_rounded,
                        label: 'Gender',
                        value: patient.gender,
                      ),
                      InfoRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Birth date',
                        value: DateFormatService.shortDate(patient.birthDate),
                        color: AppPalette.purple,
                      ),
                      InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Phone',
                        value: patient.phone,
                        color: AppPalette.cyan,
                      ),
                      InfoRow(
                        icon: Icons.home_rounded,
                        label: 'Address',
                        value: patient.address,
                        color: AppPalette.warning,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'AllergyIntolerance'),
                PremiumCard(
                  child: Column(
                    children: data.allergies
                        .map(
                          (allergy) => _ResourceRow(
                            icon: Icons.warning_amber_rounded,
                            color: allergy.criticality == 'high'
                                ? AppPalette.danger
                                : AppPalette.warning,
                            title: allergy.code,
                            subtitle:
                                '${allergy.reaction} - recorded ${DateFormatService.shortDate(allergy.recordedDate)}',
                            meta: allergy.criticality,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SectionHeader(title: 'Condition'),
                PremiumCard(
                  child: Column(
                    children: data.conditions
                        .map(
                          (condition) => _ResourceRow(
                            icon: Icons.monitor_heart_rounded,
                            color: AppPalette.primary,
                            title: condition.name,
                            subtitle:
                                '${condition.notes} Onset ${DateFormatService.shortDate(condition.onsetDate)}.',
                            meta: condition.clinicalStatus,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SectionHeader(title: 'Observation'),
                PremiumCard(
                  child: Column(
                    children: data.observations.take(5).map((observation) {
                      return _ResourceRow(
                        icon: observation.isInRange
                            ? Icons.check_circle_rounded
                            : Icons.info_rounded,
                        color: observation.isInRange
                            ? AppPalette.success
                            : AppPalette.warning,
                        title: observation.display,
                        subtitle:
                            '${observation.value.g} ${observation.unit} on ${DateFormatService.shortDate(observation.effectiveDate)}',
                        meta: observation.isInRange ? 'in range' : 'review',
                      );
                    }).toList(),
                  ),
                ),
                const SectionHeader(title: 'Immunization'),
                PremiumCard(
                  child: Column(
                    children: data.immunizations
                        .map(
                          (immunization) => _ResourceRow(
                            icon: Icons.vaccines_rounded,
                            color: AppPalette.purple,
                            title: immunization.vaccineCode,
                            subtitle:
                                '${immunization.performer} - ${DateFormatService.shortDate(immunization.occurrenceDate)}',
                            meta: immunization.status,
                          ),
                        )
                        .toList(),
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

extension _CompactNumber on num {
  String get g {
    if (this == roundToDouble()) {
      return round().toString();
    }
    return toStringAsFixed(1);
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String meta;

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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusChip(label: meta, color: color),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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
