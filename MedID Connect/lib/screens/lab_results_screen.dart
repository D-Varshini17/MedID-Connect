import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnostic_report.dart';
import '../models/observation.dart';
import '../services/date_format_service.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/lab-results';

  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final pressureTrend = data.observationsByCode('8480-6');
    final cholesterolTrend = data.observationsByCode('2093-3');
    final glucoseTrend = data.observationsByCode('2339-0');
    final heartRateTrend = data.observationsByCode('8867-4');

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Lab results',
            subtitle:
                'Mock DiagnosticReport resources with Observation values and trends.',
            icon: Icons.show_chart_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                FilledButton.icon(
                  onPressed: () => _showObservationForm(context),
                  icon: const Icon(Icons.add_chart_rounded),
                  label: const Text('Add lab value'),
                ),
                const SizedBox(height: 14),
                _TrendCard(
                  title: 'Blood pressure',
                  subtitle: 'Systolic readings',
                  icon: Icons.monitor_heart_rounded,
                  color: AppPalette.primary,
                  observations: pressureTrend,
                ),
                const SizedBox(height: 12),
                _TrendCard(
                  title: 'Cholesterol',
                  subtitle: 'Total cholesterol',
                  icon: Icons.water_drop_rounded,
                  color: AppPalette.purple,
                  observations: cholesterolTrend,
                ),
                const SizedBox(height: 12),
                _TrendCard(
                  title: 'Glucose',
                  subtitle: 'Fasting glucose',
                  icon: Icons.bubble_chart_rounded,
                  color: AppPalette.cyan,
                  observations: glucoseTrend,
                ),
                const SizedBox(height: 12),
                _TrendCard(
                  title: 'Heart rate',
                  subtitle: 'Resting bpm trend',
                  icon: Icons.favorite_rounded,
                  color: AppPalette.danger,
                  observations: heartRateTrend,
                ),
                const SectionHeader(title: 'DiagnosticReport'),
                ...data.diagnosticReports.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReportCard(
                      report: report,
                      observations: data.observationsForReport(report),
                    ),
                  ),
                ),
                const SectionHeader(title: 'Key observations'),
                PremiumCard(
                  child: Column(
                    children: data.observations
                        .where((observation) => observation.code != '8480-6')
                        .map((observation) =>
                            _ObservationRow(observation: observation))
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

  Future<void> _showObservationForm(BuildContext context) async {
    String type = 'glucose';
    final value = TextEditingController();
    final unit = TextEditingController(text: 'mg/dL');
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add lab value',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'blood_pressure',
                      child: Text('Blood pressure'),
                    ),
                    DropdownMenuItem(
                        value: 'cholesterol', child: Text('Cholesterol')),
                    DropdownMenuItem(value: 'glucose', child: Text('Glucose')),
                    DropdownMenuItem(
                        value: 'heart_rate', child: Text('Heart rate')),
                  ],
                  onChanged: (next) => setSheetState(() {
                    type = next ?? type;
                    unit.text = type == 'heart_rate'
                        ? 'bpm'
                        : type == 'blood_pressure'
                            ? 'mmHg'
                            : 'mg/dL';
                  }),
                  decoration:
                      const InputDecoration(labelText: 'Observation type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Value'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () async {
                    final parsed = double.tryParse(value.text.trim()) ?? 0;
                    final normalMax = switch (type) {
                      'blood_pressure' => 120.0,
                      'cholesterol' => 200.0,
                      'glucose' => 99.0,
                      'heart_rate' => 100.0,
                      _ => null,
                    };
                    final normalMin = switch (type) {
                      'blood_pressure' => 90.0,
                      'cholesterol' => 120.0,
                      'glucose' => 70.0,
                      'heart_rate' => 60.0,
                      _ => null,
                    };
                    try {
                      await context.read<HealthDataProvider>().addObservation({
                        'observation_type': type,
                        'value': parsed,
                        'unit': unit.text.trim(),
                        'normal_min': normalMin,
                        'normal_max': normalMax,
                        'status': normalMax != null && parsed > normalMax
                            ? 'high'
                            : 'normal',
                        'observed_at': DateTime.now().toUtc().toIso8601String(),
                        'fhir_payload': <String, dynamic>{},
                      });
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Backend unavailable. Lab entry is ready for connected mode.',
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
                  label: const Text('Save lab value'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.observations,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Observation> observations;

  @override
  Widget build(BuildContext context) {
    final latest = observations.isEmpty ? null : observations.last;
    return PremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppPalette.muted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              if (latest != null)
                Text(
                  _formatValue(latest),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 210,
            child: _TrendChart(observations: observations, color: color),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.observations,
    required this.color,
  });

  final List<Observation> observations;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    final minValue =
        observations.map((item) => item.value).reduce((a, b) => a < b ? a : b);
    final maxValue =
        observations.map((item) => item.value).reduce((a, b) => a > b ? a : b);
    final minY = (minValue - 6).clamp(0, double.infinity).toDouble();
    final maxY = maxValue + 6;
    final interval = ((maxY - minY) / 3).clamp(1, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.blueGrey.withValues(alpha: 0.12),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.round().toString(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 ||
                    index >= observations.length ||
                    value != index) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormatService.monthDay(
                        observations[index].effectiveDate),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppPalette.muted,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              observations.length,
              (index) => FlSpot(index.toDouble(), observations[index].value),
            ),
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 4,
            color: color,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.observations,
  });

  final DiagnosticReport report;
  final List<Observation> observations;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.cyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.biotech_rounded, color: AppPalette.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${report.performer} - ${DateFormatService.shortDate(report.issuedDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(label: report.status, color: AppPalette.success),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.summary,
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
            children: observations
                .map(
                  (observation) => StatusChip(
                    label:
                        '${observation.display}: ${_formatValue(observation)}',
                    color: observation.isInRange
                        ? AppPalette.success
                        : AppPalette.warning,
                    icon: observation.isInRange
                        ? Icons.check_rounded
                        : Icons.priority_high_rounded,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ObservationRow extends StatelessWidget {
  const _ObservationRow({required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color =
        observation.isInRange ? AppPalette.success : AppPalette.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              observation.isInRange
                  ? Icons.check_circle_rounded
                  : Icons.info_rounded,
              color: color,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  observation.display,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormatService.shortDate(observation.effectiveDate),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatValue(observation),
            style: textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatValue(Observation observation) {
  final value = observation.value == observation.value.roundToDouble()
      ? observation.value.round().toString()
      : observation.value.toStringAsFixed(1);
  return '$value ${observation.unit}';
}
