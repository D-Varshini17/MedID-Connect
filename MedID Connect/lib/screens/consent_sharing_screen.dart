import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_client.dart';
import '../services/consent_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class ConsentSharingScreen extends StatefulWidget {
  const ConsentSharingScreen({super.key, this.showBackButton = false});

  static const String route = '/consent-sharing';

  final bool showBackButton;

  @override
  State<ConsentSharingScreen> createState() => _ConsentSharingScreenState();
}

class _ConsentSharingScreenState extends State<ConsentSharingScreen> {
  late final ConsentService _service = ConsentService(ApiClient());
  late Future<List<Map<String, dynamic>>> _future = _load();
  String? _latestShareUrl;
  bool _busy = false;

  Future<List<Map<String, dynamic>>> _load() async {
    try {
      return await _service.list();
    } catch (_) {
      return [];
    }
  }

  Future<void> _createConsent() async {
    setState(() => _busy = true);
    try {
      final expiresAt = DateTime.now().add(const Duration(days: 1));
      final result = await _service.create({
        'grantee_name': 'Demo Doctor',
        'grantee_type': 'doctor',
        'hospital_name': 'HAPI FHIR Sandbox Hospital',
        'doctor_name': 'Dr. Demo',
        'purpose': 'Review latest medical records',
        'allowed_resources': [
          'Patient',
          'AllergyIntolerance',
          'MedicationRequest',
          'Condition',
          'Observation',
          'DiagnosticReport',
        ],
        'expires_at': expiresAt.toUtc().toIso8601String(),
      });
      _latestShareUrl = result['share_url']?.toString();
      _future = _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consent share link generated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient().readableError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Consent & sharing',
            subtitle:
                'Create temporary doctor or hospital access links with FHIR-ready resources and access logs.',
            icon: Icons.verified_user_rounded,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share only what you choose',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The QR/link contains only a temporary token. Medical data stays on the backend and every access is logged.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : _createConsent,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.link_rounded),
                        label: const Text('Generate demo share link'),
                      ),
                    ],
                  ),
                ),
                if (_latestShareUrl != null) ...[
                  const SizedBox(height: 14),
                  PremiumCard(
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded,
                            color: AppPalette.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _latestShareUrl!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          onPressed: () => Clipboard.setData(
                              ClipboardData(text: _latestShareUrl!)),
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
                const SectionHeader(title: 'Allowed FHIR resources'),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                        label: 'Patient',
                        color: AppPalette.primary,
                        icon: Icons.person_rounded),
                    StatusChip(
                        label: 'Allergies',
                        color: AppPalette.warning,
                        icon: Icons.warning_rounded),
                    StatusChip(
                        label: 'Meds',
                        color: AppPalette.purple,
                        icon: Icons.medication_rounded),
                    StatusChip(
                        label: 'Labs',
                        color: AppPalette.cyan,
                        icon: Icons.science_rounded),
                    StatusChip(
                        label: 'Reports',
                        color: AppPalette.success,
                        icon: Icons.description_rounded),
                  ],
                ),
                const SectionHeader(title: 'Active consents'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const PremiumCard(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (items.isEmpty) {
                      return const PremiumCard(
                        child: Text(
                            'No backend consents yet. Generate a demo share link to start.'),
                      );
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: PremiumCard(
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.local_hospital_rounded),
                                  ),
                                  title: Text(
                                      item['grantee_name']?.toString() ??
                                          'Consent'),
                                  subtitle:
                                      Text('Expires ${item['expires_at']}'),
                                  trailing: TextButton(
                                    onPressed: () async {
                                      await _service.revoke(item['id'] as int);
                                      setState(() => _future = _load());
                                    },
                                    child: const Text('Revoke'),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
