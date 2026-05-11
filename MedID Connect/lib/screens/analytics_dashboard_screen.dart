import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key, this.showBackButton = false});

  static const route = '/analytics';

  final bool showBackButton;

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  late final AnalyticsService _service = AnalyticsService(ApiClient());
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _summary = await _service.summary();
    } catch (_) {
      _summary = {
        'weekly_health_score': 82,
        'medication_adherence': 86,
        'water_average_ml': 2100,
        'sleep_average_hours': 7.1,
        'abnormal_observations': 1,
        'most_common_symptoms': ['Headache', 'Fatigue', 'Stress'],
        'progress_timeline': [
          {'label': 'Meds', 'value': 86},
          {'label': 'Water', 'value': 78},
          {'label': 'Sleep', 'value': 88},
          {'label': 'Vitals', 'value': 82},
        ],
        'trend_cards': [
          {
            'title': 'Glucose',
            'value': 103,
            'unit': 'mg/dL',
            'status': 'normal'
          },
          {'title': 'BP', 'value': 126, 'unit': 'mmHg', 'status': 'watch'},
        ],
      };
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary ?? {};
    final score = (summary['weekly_health_score'] as num?)?.toInt() ?? 82;
    final adherence = (summary['medication_adherence'] as num?)?.toInt() ?? 0;
    final water = (summary['water_average_ml'] as num?)?.toInt() ?? 0;
    final sleep = (summary['sleep_average_hours'] as num?)?.toDouble() ?? 0;
    final timeline = (summary['progress_timeline'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final trends = (summary['trend_cards'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final symptoms = (summary['most_common_symptoms'] as List? ?? const [])
        .map((item) => item.toString())
        .toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Health analytics',
            subtitle:
                'Weekly summary, adherence analytics, symptom patterns, and progress timeline.',
            icon: Icons.analytics_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                if (_loading) const LinearProgressIndicator(),
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
                              'Weekly health summary',
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
                              'Adherence $adherence% • Water ${water}ml • Sleep ${sleep.toStringAsFixed(1)}h',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      HealthScoreRing(score: score, size: 94, light: true),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Monthly trend'),
                PremiumCard(
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        minY: 40,
                        maxY: 100,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: AppPalette.primary,
                            barWidth: 4,
                            dotData: const FlDotData(show: false),
                            spots: const [
                              FlSpot(0, 68),
                              FlSpot(1, 74),
                              FlSpot(2, 72),
                              FlSpot(3, 81),
                              FlSpot(4, 84),
                              FlSpot(5, 82),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SectionHeader(title: 'Progress timeline'),
                PremiumCard(
                  child: Column(
                    children: timeline
                        .map(
                          (item) => _ProgressRow(
                            label: item['label']?.toString() ?? 'Metric',
                            value: (item['value'] as num?)?.toInt() ?? 0,
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SectionHeader(title: 'Trend cards'),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: trends
                      .map(
                        (item) => SizedBox(
                          width: 160,
                          child: PremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']?.toString() ?? 'Trend',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${item['value'] ?? '-'} ${item['unit'] ?? ''}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: AppPalette.primary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                StatusChip(
                                  label: item['status']?.toString() ?? 'normal',
                                  color: item['status'] == 'normal'
                                      ? AppPalette.success
                                      : AppPalette.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SectionHeader(title: 'Common symptoms'),
                PremiumCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: symptoms
                        .map(
                          (symptom) => StatusChip(
                            label: symptom,
                            color: AppPalette.purple,
                            icon: Icons.healing_rounded,
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: value / 100,
                backgroundColor: AppPalette.softBlue,
                color: AppPalette.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value%',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
