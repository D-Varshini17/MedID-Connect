import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class EmergencyQrScreen extends StatefulWidget {
  const EmergencyQrScreen({
    super.key,
    this.showBackButton = false,
  });

  static const String route = '/emergency-qr';

  final bool showBackButton;

  @override
  State<EmergencyQrScreen> createState() => _EmergencyQrScreenState();
}

class _EmergencyQrScreenState extends State<EmergencyQrScreen> {
  int _expiryMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final emergencyUrl = data.emergencyToken?['emergency_url']?.toString() ??
        'https://api.medidconnect.com/api/emergency/view/demo-token';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Emergency QR',
            subtitle:
                'Secure temporary-token access to critical health details for urgent situations.',
            icon: Icons.qr_code_2_rounded,
            showBackButton: widget.showBackButton,
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(
                          data: emergencyUrl,
                          version: QrVersions.auto,
                          size: 230,
                          gapless: false,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppPalette.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppPalette.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        patient.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
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
                          const StatusChip(
                            label: 'Temporary token only',
                            color: Colors.white,
                            icon: Icons.verified_user_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<int>(
                        style: const ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(Colors.white),
                        ),
                        segments: const [
                          ButtonSegment(value: 60, label: Text('1h')),
                          ButtonSegment(value: 1440, label: Text('24h')),
                          ButtonSegment(value: 10080, label: Text('7d')),
                        ],
                        selected: {_expiryMinutes},
                        onSelectionChanged: (value) {
                          setState(() => _expiryMinutes = value.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          try {
                            await context
                                .read<HealthDataProvider>()
                                .createEmergencyToken(
                                  expiresInMinutes: _expiryMinutes,
                                );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Backend unavailable. Showing demo emergency token.',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Generate secure token'),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: emergencyUrl),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Emergency URL copied'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy emergency URL'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: data.emergencyToken == null
                            ? null
                            : () async {
                                await context
                                    .read<HealthDataProvider>()
                                    .revokeEmergencyToken();
                              },
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Revoke token'),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Critical details'),
                PremiumCard(
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.bloodtype_rounded,
                        label: 'Blood group',
                        value: patient.bloodGroup,
                        color: AppPalette.danger,
                      ),
                      InfoRow(
                        icon: Icons.warning_amber_rounded,
                        label: 'Allergies',
                        value: data.allergies
                            .map((allergy) =>
                                '${allergy.code} (${allergy.criticality})')
                            .join(', '),
                        color: AppPalette.warning,
                      ),
                      InfoRow(
                        icon: Icons.medication_rounded,
                        label: 'Current medications',
                        value: data.medications
                            .map((medication) => medication.medicationName)
                            .join(', '),
                        color: AppPalette.purple,
                      ),
                      InfoRow(
                        icon: Icons.phone_in_talk_rounded,
                        label: 'Emergency contact',
                        value:
                            '${patient.emergencyContactName} - ${patient.emergencyContactPhone}',
                        color: AppPalette.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                PremiumCard(
                  color: AppPalette.softPurple,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_rounded, color: AppPalette.purple),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The QR code contains only a temporary emergency URL token. The backend decides what limited emergency details are shown, applies expiry, and logs each access.',
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
