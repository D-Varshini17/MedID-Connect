import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/sos_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class SosAlertScreen extends StatefulWidget {
  const SosAlertScreen({super.key, this.showBackButton = false});

  static const route = '/sos-alert';

  final bool showBackButton;

  @override
  State<SosAlertScreen> createState() => _SosAlertScreenState();
}

class _SosAlertScreenState extends State<SosAlertScreen> {
  late final SosService _service = SosService(ApiClient());
  Timer? _timer;
  int _seconds = 0;
  bool _sending = false;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    try {
      _alerts = await _service.alerts();
    } catch (_) {
      _alerts = [];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'SOS alert',
            subtitle:
                'Mock emergency message, GPS placeholder, call placeholder, and countdown flow.',
            icon: Icons.sos_rounded,
            showBackButton: widget.showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
                PremiumCard(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppPalette.danger, AppPalette.purple],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _seconds > 0 ? 124 : 106,
                        height: _seconds > 0 ? 124 : 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _seconds > 0 ? '$_seconds' : 'SOS',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _seconds > 0
                            ? 'Emergency alert sending soon'
                            : 'Press and start emergency countdown',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.tonalIcon(
                        onPressed: _sending
                            ? null
                            : (_seconds > 0
                                ? _cancelCountdown
                                : _startCountdown),
                        icon: Icon(
                          _seconds > 0
                              ? Icons.close_rounded
                              : Icons.emergency_share_rounded,
                        ),
                        label: Text(_seconds > 0 ? 'Cancel' : 'Start SOS'),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Emergency actions'),
                PremiumCard(
                  child: Column(
                    children: [
                      const _ActionRow(
                        icon: Icons.location_on_rounded,
                        color: AppPalette.primary,
                        title: 'GPS placeholder',
                        subtitle:
                            'Chennai, Tamil Nadu approx. location simulation',
                      ),
                      const _ActionRow(
                        icon: Icons.phone_in_talk_rounded,
                        color: AppPalette.success,
                        title: 'Call emergency contact',
                        subtitle:
                            'Call intent placeholder for Android release build.',
                      ),
                      _ActionRow(
                        icon: Icons.sms_rounded,
                        color: AppPalette.warning,
                        title: 'Mock emergency message',
                        subtitle: _sending
                            ? 'Sending...'
                            : 'Backend stores a mock alert log when available.',
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Recent SOS logs'),
                if (_alerts.isEmpty)
                  const PremiumCard(
                    child: Text('No SOS logs yet. Try the mock alert flow.'),
                  )
                else
                  ..._alerts.map(
                    (alert) => PremiumCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.history_rounded,
                              color: AppPalette.danger),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alert['message']?.toString() ??
                                  'Emergency alert sent',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusChip(
                            label: alert['status']?.toString() ?? 'mock_sent',
                            color: AppPalette.success,
                          ),
                        ],
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

  void _startCountdown() {
    setState(() => _seconds = 5);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_seconds <= 1) {
        timer.cancel();
        await _sendAlert();
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    setState(() => _seconds = 0);
  }

  Future<void> _sendAlert() async {
    setState(() {
      _seconds = 0;
      _sending = true;
    });
    try {
      await _service.sendMockAlert(latitude: 13.0827, longitude: 80.2707);
      await _loadAlerts();
    } catch (_) {
      _alerts.insert(0, {
        'message': 'Emergency help needed. Offline mock alert saved locally.',
        'status': 'offline_mock',
      });
    }
    if (mounted) {
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock SOS alert completed.')),
      );
    }
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(subtitle),
    );
  }
}
