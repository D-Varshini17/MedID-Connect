import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/status_chip.dart';
import 'sos_alert_screen.dart';

class EmergencyModeScreen extends StatefulWidget {
  const EmergencyModeScreen({super.key});

  static const route = '/emergency-mode';

  @override
  State<EmergencyModeScreen> createState() => _EmergencyModeScreenState();
}

class _EmergencyModeScreenState extends State<EmergencyModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  bool _flashlight = false;
  bool _siren = true;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final qrPayload = data.emergencyQrPayload();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF07111F), Color(0xFF111827), Color(0xFF250A1B)],
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Back',
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      StatusChip(
                        label: _siren ? 'SOS armed' : 'Quiet mode',
                        color: _siren ? AppPalette.danger : AppPalette.cyan,
                        icon: _siren
                            ? Icons.sos_rounded
                            : Icons.notifications_off_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) {
                      final scale = 1 + (_pulse.value * 0.06);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppPalette.danger.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppPalette.danger.withValues(
                                    alpha: 0.28 + _pulse.value * 0.2),
                                blurRadius: 45,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emergency_share_rounded,
                            size: 58,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Emergency mode',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap NFC / Scan QR simulation',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BigInfo(label: 'Patient', value: patient.name),
                              const SizedBox(height: 16),
                              _BigInfo(
                                label: 'Blood group',
                                value: patient.bloodGroup,
                                color: AppPalette.danger,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(data: qrPayload, size: 108),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EmergencyPanel(
                    title: 'Allergies',
                    icon: Icons.warning_rounded,
                    color: AppPalette.warning,
                    items: data.allergies
                        .map((item) => '${item.code} - ${item.reaction}')
                        .toList(),
                  ),
                  _EmergencyPanel(
                    title: 'Current medications',
                    icon: Icons.medication_rounded,
                    color: AppPalette.purple,
                    items: data.medications
                        .where((item) => item.status == 'active')
                        .map((item) =>
                            '${item.medicationName} ${item.dosageInstruction}')
                        .toList(),
                  ),
                  _EmergencyPanel(
                    title: 'Chronic diseases',
                    icon: Icons.monitor_heart_rounded,
                    color: AppPalette.cyan,
                    items: data.conditions
                        .where((item) => item.clinicalStatus == 'active')
                        .map((item) => item.name)
                        .toList(),
                  ),
                  _EmergencyPanel(
                    title: 'Emergency contact',
                    icon: Icons.phone_in_talk_rounded,
                    color: AppPalette.success,
                    items: [
                      '${patient.emergencyContactName} - ${patient.emergencyContactPhone}',
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push(SosAlertScreen.route),
                          icon: const Icon(Icons.sos_rounded),
                          label: const Text('Start SOS'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        tooltip: 'Flashlight simulation',
                        onPressed: () =>
                            setState(() => _flashlight = !_flashlight),
                        icon: Icon(_flashlight
                            ? Icons.flashlight_on_rounded
                            : Icons.flashlight_off_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Siren simulation',
                        onPressed: () => setState(() => _siren = !_siren),
                        icon: Icon(_siren
                            ? Icons.campaign_rounded
                            : Icons.volume_off_rounded),
                      ),
                    ],
                  ),
                  if (_flashlight) ...[
                    const SizedBox(height: 14),
                    Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.16),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: -math.pi / 8,
                        child: const Icon(
                          Icons.flashlight_on_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BigInfo extends StatelessWidget {
  const _BigInfo({
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white60,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _EmergencyPanel extends StatelessWidget {
  const _EmergencyPanel({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  items.isEmpty ? 'No critical item saved.' : items.join('\n'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
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
