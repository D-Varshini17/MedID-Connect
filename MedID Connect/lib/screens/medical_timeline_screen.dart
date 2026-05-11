import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/medical_event.dart';
import '../services/date_format_service.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/status_chip.dart';

class MedicalTimelineScreen extends StatelessWidget {
  const MedicalTimelineScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/timeline';

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final events = [...data.timeline]..sort((a, b) => b.date.compareTo(a.date));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Medical timeline',
            subtitle:
                'Visits, reports, prescriptions, conditions, and vaccines in date order.',
            icon: Icons.timeline_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _TimelineItem(
                event: events[index],
                isLast: index == events.length - 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
  });

  final MedicalEvent event;
  final bool isLast;

  Color get color {
    switch (event.type) {
      case MedicalEventType.lab:
        return AppPalette.cyan;
      case MedicalEventType.medication:
        return AppPalette.purple;
      case MedicalEventType.vaccine:
        return AppPalette.success;
      case MedicalEventType.condition:
        return AppPalette.warning;
      case MedicalEventType.visit:
        return AppPalette.primary;
    }
  }

  IconData get icon {
    switch (event.type) {
      case MedicalEventType.lab:
        return Icons.biotech_rounded;
      case MedicalEventType.medication:
        return Icons.medication_rounded;
      case MedicalEventType.vaccine:
        return Icons.vaccines_rounded;
      case MedicalEventType.condition:
        return Icons.monitor_heart_rounded;
      case MedicalEventType.visit:
        return Icons.local_hospital_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: color.withValues(alpha: 0.16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: event.status, color: color),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      event.subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppPalette.muted,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded,
                            size: 17, color: color),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatService.shortDate(event.date),
                          style: textTheme.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
