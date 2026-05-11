import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/health_insight.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class AiInsightsScreen extends StatelessWidget {
  const AiInsightsScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/ai-insights';

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'AI health insights',
            subtitle:
                'Mock AI summaries generated from local sample healthcare data.',
            icon: Icons.auto_awesome_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
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
                              'Smart health snapshot',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'MedID Connect reviews trends, adherence, safety, and lab markers from the mock profile.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    height: 1.35,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      HealthScoreRing(
                          score: data.healthScore, size: 100, light: true),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Insights'),
                ...data.insights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _InsightCard(insight: insight),
                  ),
                ),
                const SectionHeader(title: 'Care reminders'),
                const PremiumCard(
                  child: Column(
                    children: [
                      _ReminderRow(
                        icon: Icons.monitor_heart_rounded,
                        color: AppPalette.primary,
                        title: 'Log blood pressure twice this week',
                        subtitle: 'Maintains the improving trend history.',
                      ),
                      _ReminderRow(
                        icon: Icons.medication_rounded,
                        color: AppPalette.purple,
                        title: 'Review medication adherence',
                        subtitle: 'One item is still pending in the tracker.',
                      ),
                      _ReminderRow(
                        icon: Icons.science_rounded,
                        color: AppPalette.cyan,
                        title: 'Schedule next wellness panel',
                        subtitle: 'Keep lab history fresh for future insights.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PremiumCard(
                  color: AppPalette.softBlue,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.health_and_safety_rounded,
                          color: AppPalette.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This is informational only and not a medical diagnosis. Consult a qualified doctor.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppPalette.ink,
                                    height: 1.35,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
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
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final HealthInsight insight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final confidence = (insight.confidence * 100).round();

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.violet.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppPalette.violet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StatusChip(
                      label: insight.category,
                      color: AppPalette.violet,
                      icon: Icons.category_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            insight.description,
            style: textTheme.bodyMedium?.copyWith(
              color: AppPalette.muted,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            insight.recommendation,
            style: textTheme.bodyMedium?.copyWith(
              color: AppPalette.ink,
              height: 1.35,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: insight.confidence,
                    minHeight: 9,
                    backgroundColor: AppPalette.softPurple,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppPalette.violet,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$confidence%',
                style: textTheme.labelLarge?.copyWith(
                  color: AppPalette.violet,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
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
