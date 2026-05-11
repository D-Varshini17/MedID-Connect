import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../services/date_format_service.dart';
import '../theme/app_theme.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/metric_card.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import 'ai_insights_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'appointment_management_screen.dart';
import 'consent_sharing_screen.dart';
import 'emergency_mode_screen.dart';
import 'emergency_qr_screen.dart';
import 'family_health_screen.dart';
import 'fhir_viewer_screen.dart';
import 'health_wallet_screen.dart';
import 'lab_results_screen.dart';
import 'medicine_reminder_screen.dart';
import 'medication_tracker_screen.dart';
import 'ocr_upload_screen.dart';
import 'provider_sandbox_screen.dart';
import 'sos_alert_screen.dart';
import 'wellness_tracker_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenTab,
  });

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppPalette.premiumGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        patient.initials,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppPalette.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            patient.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'AI insights',
                      onPressed: () => context.push(AiInsightsScreen.route),
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                PremiumCard(
                  gradient: AppPalette.premiumGradient,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health score',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your mock record looks stable with controlled blood pressure and in-range labs.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.push(EmergencyQrScreen.route),
                              icon: const Icon(Icons.emergency_share_rounded),
                              label: const Text('Emergency access'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      HealthScoreRing(
                        score: data.healthScore,
                        size: 96,
                        light: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                PremiumCard(
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppPalette.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.hub_rounded,
                            color: AppPalette.success),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hospital sandbox ready: HAPI FHIR, Epic, Cerner, and ABDM placeholders.',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  children: [
                    MetricCard(
                      label: 'Age',
                      value: '${patient.age}',
                      icon: Icons.cake_rounded,
                      color: AppPalette.primary,
                      subtitle: patient.gender,
                    ),
                    MetricCard(
                      label: 'Blood group',
                      value: patient.bloodGroup,
                      icon: Icons.bloodtype_rounded,
                      color: AppPalette.danger,
                      subtitle: 'Emergency ready',
                    ),
                    MetricCard(
                      label: 'Active meds',
                      value: '${data.activeMedicationCount}',
                      icon: Icons.medication_rounded,
                      color: AppPalette.purple,
                      subtitle: '${data.medicationsTakenToday} taken today',
                      onTap: () => context.push(MedicationTrackerScreen.route),
                    ),
                    MetricCard(
                      label: 'Lab reports',
                      value: '${data.diagnosticReports.length}',
                      icon: Icons.science_rounded,
                      color: AppPalette.cyan,
                      subtitle: 'Latest final',
                      onTap: () => onOpenTab(3),
                    ),
                  ],
                ),
                const SectionHeader(title: 'Quick actions'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                  children: [
                    _QuickAction(
                      icon: Icons.assignment_rounded,
                      label: 'Records',
                      color: AppPalette.primary,
                      onTap: () => onOpenTab(1),
                    ),
                    _QuickAction(
                      icon: Icons.medication_liquid_rounded,
                      label: 'Meds',
                      color: AppPalette.purple,
                      onTap: () => context.push(MedicationTrackerScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.show_chart_rounded,
                      label: 'Labs',
                      color: AppPalette.cyan,
                      onTap: () => onOpenTab(3),
                    ),
                    _QuickAction(
                      icon: Icons.timeline_rounded,
                      label: 'Timeline',
                      color: AppPalette.warning,
                      onTap: () => onOpenTab(2),
                    ),
                    _QuickAction(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Emergency',
                      color: AppPalette.danger,
                      onTap: () => context.push(EmergencyQrScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI',
                      color: AppPalette.violet,
                      onTap: () => context.push(AiInsightsScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.verified_user_rounded,
                      label: 'Share',
                      color: AppPalette.success,
                      onTap: () => context.push(ConsentSharingScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.data_object_rounded,
                      label: 'FHIR',
                      color: AppPalette.primary,
                      onTap: () => context.push(FhirViewerScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.document_scanner_rounded,
                      label: 'OCR',
                      color: AppPalette.cyan,
                      onTap: () => context.push(OcrUploadScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.hub_rounded,
                      label: 'Sandbox',
                      color: AppPalette.purple,
                      onTap: () => context.push(ProviderSandboxScreen.route),
                    ),
                  ],
                ),
                const SectionHeader(title: 'Smart daily tools'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.92,
                  children: [
                    _QuickAction(
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Wallet',
                      color: AppPalette.primary,
                      onTap: () => context.push(HealthWalletScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.lock_rounded,
                      label: 'Emergency',
                      color: AppPalette.danger,
                      onTap: () => context.push(EmergencyModeScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.sos_rounded,
                      label: 'SOS',
                      color: AppPalette.danger,
                      onTap: () => context.push(SosAlertScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.alarm_rounded,
                      label: 'Reminder',
                      color: AppPalette.purple,
                      onTap: () => context.push(MedicineReminderScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.water_drop_rounded,
                      label: 'Habits',
                      color: AppPalette.cyan,
                      onTap: () => context.push(WellnessTrackerScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.family_restroom_rounded,
                      label: 'Family',
                      color: AppPalette.success,
                      onTap: () => context.push(FamilyHealthScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.event_available_rounded,
                      label: 'Visits',
                      color: AppPalette.violet,
                      onTap: () =>
                          context.push(AppointmentManagementScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.analytics_rounded,
                      label: 'Analytics',
                      color: AppPalette.warning,
                      onTap: () => context.push(AnalyticsDashboardScreen.route),
                    ),
                    _QuickAction(
                      icon: Icons.cloud_done_rounded,
                      label: 'Offline',
                      color: AppPalette.primary,
                      onTap: () => context.push(HealthWalletScreen.route),
                    ),
                  ],
                ),
                const SectionHeader(title: 'Allergies'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.allergies
                      .map(
                        (allergy) => StatusChip(
                          label: '${allergy.code} - ${allergy.criticality}',
                          color: allergy.criticality == 'high'
                              ? AppPalette.danger
                              : AppPalette.warning,
                          icon: Icons.warning_amber_rounded,
                        ),
                      )
                      .toList(),
                ),
                const SectionHeader(title: 'Active conditions'),
                PremiumCard(
                  child: Column(
                    children: data.conditions
                        .map(
                          (condition) => _DashboardListRow(
                            icon: Icons.monitor_heart_rounded,
                            color: AppPalette.primary,
                            title: condition.name,
                            subtitle:
                                '${condition.severity} severity, ${condition.clinicalStatus}',
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SectionHeader(title: 'Current medications'),
                PremiumCard(
                  child: Column(
                    children: data.medications
                        .map(
                          (medication) => _DashboardListRow(
                            icon: Icons.medication_rounded,
                            color: medication.takenToday
                                ? AppPalette.success
                                : AppPalette.purple,
                            title: medication.medicationName,
                            subtitle:
                                '${medication.frequency} - ${medication.dosageInstruction}',
                          ),
                        )
                        .toList(),
                  ),
                ),
                SectionHeader(
                  title: 'Recent lab reports',
                  actionLabel: 'View all',
                  onAction: () => context.push(LabResultsScreen.route),
                ),
                PremiumCard(
                  child: Column(
                    children: data.diagnosticReports
                        .map(
                          (report) => _DashboardListRow(
                            icon: Icons.biotech_rounded,
                            color: AppPalette.cyan,
                            title: report.title,
                            subtitle: '${report.performer} - ${report.status}',
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SectionHeader(title: 'Upcoming appointments'),
                PremiumCard(
                  child: Column(
                    children: data.appointments
                        .map(
                          (appointment) => _DashboardListRow(
                            icon: Icons.event_available_rounded,
                            color: AppPalette.violet,
                            title: appointment.title,
                            subtitle:
                                '${appointment.practitioner} - ${DateFormatService.shortDate(appointment.dateTime)} at ${appointment.location}',
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardListRow extends StatelessWidget {
  const _DashboardListRow({
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
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
