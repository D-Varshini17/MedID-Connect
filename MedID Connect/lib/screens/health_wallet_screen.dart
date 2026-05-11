import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../providers/health_data_provider.dart';
import '../services/api_client.dart';
import '../services/offline_cache_service.dart';
import '../services/wallet_service.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class HealthWalletScreen extends StatefulWidget {
  const HealthWalletScreen({super.key, this.showBackButton = false});

  static const route = '/health-wallet';

  final bool showBackButton;

  @override
  State<HealthWalletScreen> createState() => _HealthWalletScreenState();
}

class _HealthWalletScreenState extends State<HealthWalletScreen> {
  late final WalletService _walletService = WalletService(ApiClient());
  final _cache = OfflineCacheService();
  Map<String, dynamic>? _wallet;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wallet = await _walletService.summary();
      await _cache.saveWallet(wallet);
      _wallet = wallet;
    } catch (_) {
      _wallet = await _cache.readWallet();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final emergencyCard = _wallet?['emergency_card'] as Map? ??
        {
          'name': patient.name,
          'blood_group': patient.bloodGroup,
          'allergies': data.allergies.map((e) => e.code).toList(),
          'medications': data.medications.map((e) => e.medicationName).toList(),
          'contacts': [patient.emergencyContactPhone],
        };
    final qrData = jsonEncode(emergencyCard);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Smart health wallet',
            subtitle:
                'Offline-friendly emergency card, medical identity, and share-ready summary.',
            icon: Icons.account_balance_wallet_rounded,
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
                              patient.name,
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
                              'Blood group ${patient.bloodGroup} • ${patient.age} years',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                await Clipboard.setData(
                                    ClipboardData(text: qrData));
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Emergency card copied')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text('Quick share'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: QrImageView(data: qrData, size: 100),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Emergency details'),
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
                        icon: Icons.medication_rounded,
                        label: 'Current medicines',
                        value: data.medications
                            .map((m) => m.medicationName)
                            .join(', '),
                        color: AppPalette.purple,
                      ),
                      InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Emergency contact',
                        value:
                            '${patient.emergencyContactName} - ${patient.emergencyContactPhone}',
                        color: AppPalette.primary,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Allergies & conditions'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...data.allergies.map(
                      (item) => StatusChip(
                        label: '${item.code} (${item.criticality})',
                        color: item.criticality == 'high'
                            ? AppPalette.danger
                            : AppPalette.warning,
                        icon: Icons.warning_rounded,
                      ),
                    ),
                    ...data.conditions.map(
                      (item) => StatusChip(
                        label: item.name,
                        color: AppPalette.primary,
                        icon: Icons.monitor_heart_rounded,
                      ),
                    ),
                  ],
                ),
                const SectionHeader(title: 'Vaccination & insurance'),
                PremiumCard(
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.vaccines_rounded,
                        label: 'Vaccination summary',
                        value: data.immunizations
                            .map((e) => e.vaccineCode)
                            .join(', '),
                        color: AppPalette.success,
                      ),
                      const InfoRow(
                        icon: Icons.health_and_safety_rounded,
                        label: 'Insurance ID',
                        value: 'INS-MEDID-0000',
                        color: AppPalette.cyan,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'QR download placeholder ready for mobile storage.')),
                  ),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Download QR / emergency card'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
