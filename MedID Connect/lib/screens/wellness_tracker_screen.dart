import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/offline_cache_service.dart';
import '../services/wellness_service.dart';
import '../theme/app_theme.dart';
import '../widgets/health_score_ring.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class WellnessTrackerScreen extends StatefulWidget {
  const WellnessTrackerScreen({super.key, this.showBackButton = false});

  static const route = '/wellness-tracker';

  final bool showBackButton;

  @override
  State<WellnessTrackerScreen> createState() => _WellnessTrackerScreenState();
}

class _WellnessTrackerScreenState extends State<WellnessTrackerScreen> {
  late final WellnessService _service = WellnessService(ApiClient());
  final _cache = OfflineCacheService();
  int _waterMl = 1600;
  double _sleepHours = 7;
  int _steps = 4200;
  int _exercise = 20;
  String _mood = 'Calm';
  Map<String, dynamic>? _score;
  List<Map<String, dynamic>> _logs = [];
  bool _saving = false;

  int get _localScore {
    final water = (_waterMl / 2500 * 25).clamp(0, 25);
    final sleep = (_sleepHours / 8 * 25).clamp(0, 25);
    final steps = (_steps / 8000 * 20).clamp(0, 20);
    final exercise = (_exercise / 30 * 15).clamp(0, 15);
    final mood = _mood == 'Happy' || _mood == 'Calm' ? 15 : 8;
    return (water + sleep + steps + exercise + mood).round().clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.score(),
        _service.logs(),
      ]);
      _score = results[0] as Map<String, dynamic>;
      _logs = (results[1] as List<Map<String, dynamic>>);
    } catch (_) {
      _logs = await _cache.readWellnessLogs();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final score = (_score?['score'] as num?)?.toInt() ?? _localScore;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Water & habits',
            subtitle:
                'Track wellness basics that improve your daily health score.',
            icon: Icons.water_drop_rounded,
            showBackButton: widget.showBackButton,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wellness score',
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
                              _suggestions().first,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      HealthScoreRing(score: score, size: 94, light: true),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Today'),
                _TrackerSlider(
                  icon: Icons.water_drop_rounded,
                  label: 'Water intake',
                  value: _waterMl.toDouble(),
                  min: 0,
                  max: 4000,
                  divisions: 16,
                  suffix: 'ml',
                  color: AppPalette.cyan,
                  onChanged: (value) =>
                      setState(() => _waterMl = value.round()),
                ),
                _TrackerSlider(
                  icon: Icons.bedtime_rounded,
                  label: 'Sleep',
                  value: _sleepHours,
                  min: 0,
                  max: 12,
                  divisions: 24,
                  suffix: 'hrs',
                  color: AppPalette.purple,
                  onChanged: (value) => setState(() =>
                      _sleepHours = double.parse(value.toStringAsFixed(1))),
                ),
                _TrackerSlider(
                  icon: Icons.directions_walk_rounded,
                  label: 'Walking steps',
                  value: _steps.toDouble(),
                  min: 0,
                  max: 15000,
                  divisions: 30,
                  suffix: 'steps',
                  color: AppPalette.success,
                  onChanged: (value) => setState(() => _steps = value.round()),
                ),
                _TrackerSlider(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercise',
                  value: _exercise.toDouble(),
                  min: 0,
                  max: 120,
                  divisions: 24,
                  suffix: 'min',
                  color: AppPalette.warning,
                  onChanged: (value) =>
                      setState(() => _exercise = value.round()),
                ),
                const SectionHeader(title: 'Mood'),
                PremiumCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Happy', 'Calm', 'Tired', 'Stressed']
                        .map(
                          (mood) => ChoiceChip(
                            label: Text(mood),
                            selected: _mood == mood,
                            onSelected: (_) => setState(() => _mood = mood),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveLog,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save wellness log'),
                ),
                const SectionHeader(title: 'Wellness summary'),
                PremiumCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      const StatusChip(
                        label: '3 day streak',
                        color: AppPalette.success,
                        icon: Icons.local_fire_department_rounded,
                      ),
                      StatusChip(
                        label: '${_logs.length} offline logs cached',
                        color: AppPalette.primary,
                        icon: Icons.cloud_done_rounded,
                      ),
                      ..._suggestions().skip(1).map(
                            (text) => StatusChip(
                              label: text,
                              color: AppPalette.cyan,
                              icon: Icons.tips_and_updates_rounded,
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

  List<String> _suggestions() {
    final remote = _score?['suggestions'];
    if (remote is List && remote.isNotEmpty) {
      return remote.map((item) => item.toString()).toList();
    }
    return [
      _waterMl < 2000
          ? 'Drink 2 more glasses of water to reach your target.'
          : 'Hydration is on track today.',
      _sleepHours < 7
          ? 'Try a 30 minute earlier bedtime tonight.'
          : 'Sleep duration looks healthy.',
      _exercise < 20
          ? 'A short evening walk can improve your score.'
          : 'Exercise target is progressing well.',
    ];
  }

  Future<void> _saveLog() async {
    setState(() => _saving = true);
    final payload = {
      'log_date': DateTime.now().toUtc().toIso8601String(),
      'water_ml': _waterMl,
      'sleep_hours': _sleepHours,
      'steps': _steps,
      'mood': _mood,
      'exercise_minutes': _exercise,
      'notes': 'Saved from MedID Connect mobile app',
    };
    try {
      await _service.createLog(payload);
      await _load();
    } catch (_) {
      await _cache.addWellnessLog(payload);
      _logs = await _cache.readWellnessLogs();
    }
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wellness log saved.')),
      );
    }
  }
}

class _TrackerSlider extends StatelessWidget {
  const _TrackerSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.suffix,
    required this.color,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String suffix;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final display =
        suffix == 'hrs' ? value.toStringAsFixed(1) : value.round().toString();
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              Text(
                '$display $suffix',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: '$display $suffix',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
