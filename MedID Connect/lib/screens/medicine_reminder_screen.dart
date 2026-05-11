import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../services/api_client.dart';
import '../services/medication_engine_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class MedicineReminderScreen extends StatefulWidget {
  const MedicineReminderScreen({super.key, this.showBackButton = false});

  static const route = '/medicine-reminders';

  final bool showBackButton;

  @override
  State<MedicineReminderScreen> createState() => _MedicineReminderScreenState();
}

class _MedicineReminderScreenState extends State<MedicineReminderScreen> {
  late final MedicationEngineService _service =
      MedicationEngineService(ApiClient());
  final Set<String> _taken = {};
  final Set<String> _missed = {};
  Map<String, dynamic>? _checklist;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    try {
      _checklist = await _service.checklist();
      final items = (_checklist?['items'] as List? ?? const []);
      for (final item in items) {
        if (item is Map && item['status'] == 'taken') {
          _taken.add(item['medication_id'].toString());
        }
      }
    } catch (_) {
      _checklist = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final meds =
        data.medications.where((item) => item.status == 'active').toList();
    final total = meds.length;
    final adherence = total == 0 ? 0 : ((_taken.length / total) * 100).round();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Medicine reminders',
            subtitle:
                'Daily checklist, taken confirmation, missed tracking, and local notification demo.',
            icon: Icons.alarm_rounded,
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
                  gradient: AppPalette.purpleGradient,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$adherence%',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0,
                                  ),
                            ),
                            Text(
                              'weekly adherence',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await NotificationService.showDemoReminder();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reminder notification sent.'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.notifications_active_rounded),
                        label: const Text('Test'),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Today schedule'),
                _ScheduleColumn(
                  title: 'Morning',
                  icon: Icons.wb_sunny_rounded,
                  color: AppPalette.warning,
                  meds: meds,
                  taken: _taken,
                  missed: _missed,
                  slot: 'morning',
                  onStatus: _mark,
                ),
                _ScheduleColumn(
                  title: 'Afternoon',
                  icon: Icons.light_mode_rounded,
                  color: AppPalette.cyan,
                  meds: meds,
                  taken: _taken,
                  missed: _missed,
                  slot: 'afternoon',
                  onStatus: _mark,
                ),
                _ScheduleColumn(
                  title: 'Night',
                  icon: Icons.nights_stay_rounded,
                  color: AppPalette.purple,
                  meds: meds,
                  taken: _taken,
                  missed: _missed,
                  slot: 'night',
                  onStatus: _mark,
                ),
                const SectionHeader(title: 'Weekly adherence'),
                PremiumCard(
                  child: SizedBox(
                    height: 170,
                    child: BarChart(
                      BarChartData(
                        maxY: 100,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                  'S'
                                ];
                                return Text(days[value.toInt() % days.length]);
                              },
                            ),
                          ),
                        ),
                        barGroups: [72, 84, 92, adherence, 0, 0, 0]
                            .asMap()
                            .entries
                            .map(
                              (entry) => BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.toDouble(),
                                    width: 16,
                                    color: AppPalette.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ),
                const SectionHeader(title: 'Safety'),
                PremiumCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: '${_missed.length} missed today',
                        color: _missed.isEmpty
                            ? AppPalette.success
                            : AppPalette.warning,
                        icon: Icons.event_busy_rounded,
                      ),
                      ...data.medicationSafetyWarnings.take(2).map(
                            (warning) => StatusChip(
                              label: warning['message']?.toString() ??
                                  'Safety warning',
                              color: AppPalette.danger,
                              icon: Icons.warning_rounded,
                            ),
                          ),
                      if (data.medicationSafetyWarnings.isEmpty)
                        const StatusChip(
                          label: 'No allergy conflicts detected',
                          color: AppPalette.success,
                          icon: Icons.verified_rounded,
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

  Future<void> _mark(String medicationId, String status) async {
    setState(() {
      if (status == 'taken') {
        _taken.add(medicationId);
        _missed.remove(medicationId);
      } else {
        _missed.add(medicationId);
        _taken.remove(medicationId);
      }
    });
    final id = int.tryParse(medicationId);
    if (id != null) {
      try {
        await _service.createLog(medicationId: id, status: status);
      } catch (_) {}
    }
  }
}

class _ScheduleColumn extends StatelessWidget {
  const _ScheduleColumn({
    required this.title,
    required this.icon,
    required this.color,
    required this.meds,
    required this.taken,
    required this.missed,
    required this.slot,
    required this.onStatus,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<dynamic> meds;
  final Set<String> taken;
  final Set<String> missed;
  final String slot;
  final Future<void> Function(String medicationId, String status) onStatus;

  @override
  Widget build(BuildContext context) {
    final filtered = meds.where((med) {
      final frequency = med.frequency.toString().toLowerCase();
      if (frequency.contains(slot)) return true;
      if (slot == 'morning' && frequency.contains('daily')) return true;
      if (slot == 'night' && frequency.contains('night')) return true;
      return frequency.contains('twice') || frequency.contains('daily');
    }).toList();

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('No medicine scheduled in this slot.'),
            )
          else
            ...filtered.map(
              (med) {
                final isTaken = taken.contains(med.id);
                final isMissed = missed.contains(med.id);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    med.medicationName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text('${med.dosageInstruction} - ${med.frequency}'),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Taken',
                        onPressed: () => onStatus(med.id, 'taken'),
                        icon: Icon(
                          Icons.check_rounded,
                          color: isTaken ? AppPalette.success : null,
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Missed',
                        onPressed: () => onStatus(med.id, 'missed'),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isMissed ? AppPalette.danger : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
