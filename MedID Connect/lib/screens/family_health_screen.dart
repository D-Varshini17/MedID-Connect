import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/health_data_provider.dart';
import '../services/api_client.dart';
import '../services/family_service.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';

class FamilyHealthScreen extends StatefulWidget {
  const FamilyHealthScreen({super.key, this.showBackButton = false});

  static const route = '/family-health';

  final bool showBackButton;

  @override
  State<FamilyHealthScreen> createState() => _FamilyHealthScreenState();
}

class _FamilyHealthScreenState extends State<FamilyHealthScreen> {
  late final FamilyService _service = FamilyService(ApiClient());
  List<Map<String, dynamic>> _members = [];
  int _selectedIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _members = await _service.members();
    } catch (_) {
      _members = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final fallback = [
      {
        'full_name': data.patient.name,
        'relationship': 'Self',
        'age': data.patient.age,
        'gender': data.patient.gender,
        'blood_group': data.patient.bloodGroup,
        'emergency_enabled': true,
      },
      {
        'full_name': 'Lakshmi R',
        'relationship': 'Mother',
        'age': 58,
        'gender': 'Female',
        'blood_group': 'O+',
        'emergency_enabled': true,
      },
    ];
    final members = _members.isEmpty ? fallback : _members;
    final selected =
        members[_selectedIndex.clamp(0, members.length - 1).toInt()];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: 'Family health',
            subtitle:
                'Manage parent, child, spouse, and caregiver profiles from one account.',
            icon: Icons.family_restroom_rounded,
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
                              selected['full_name']?.toString() ??
                                  'Family member',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${selected['relationship']} mode • Blood ${selected['blood_group'] ?? 'not set'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Add family member',
                        onPressed: () => _showAddMember(context),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Switch profile'),
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final selected = _selectedIndex == index;
                      return SizedBox(
                        width: 190,
                        child: PremiumCard(
                          onTap: () => setState(() => _selectedIndex = index),
                          border: selected
                              ? Border.all(color: AppPalette.primary, width: 2)
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member['full_name']?.toString() ?? 'Member',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${member['relationship']} • ${member['age'] ?? '-'} yrs',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppPalette.muted,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              StatusChip(
                                label: member['emergency_enabled'] == false
                                    ? 'Private'
                                    : 'Emergency sharing',
                                color: member['emergency_enabled'] == false
                                    ? AppPalette.warning
                                    : AppPalette.success,
                                icon: Icons.health_and_safety_rounded,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SectionHeader(title: 'Shared care'),
                const PremiumCard(
                  child: Column(
                    children: [
                      _FamilyFeatureRow(
                        icon: Icons.qr_code_2_rounded,
                        color: AppPalette.danger,
                        title: 'Shared emergency access',
                        subtitle:
                            'Emergency card can include selected family profiles.',
                      ),
                      _FamilyFeatureRow(
                        icon: Icons.alarm_rounded,
                        color: AppPalette.purple,
                        title: 'Shared reminders',
                        subtitle:
                            'Caregiver can help track parent or child medicines.',
                      ),
                      _FamilyFeatureRow(
                        icon: Icons.admin_panel_settings_rounded,
                        color: AppPalette.primary,
                        title: 'Role-based permissions',
                        subtitle:
                            'Owner, caregiver, child mode, and view-only roles are backend-ready.',
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

  Future<void> _showAddMember(BuildContext context) async {
    final name = TextEditingController();
    final relation = TextEditingController(text: 'Parent');
    final age = TextEditingController();
    final gender = TextEditingController();
    final blood = TextEditingController();

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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add family member',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relation,
                decoration: const InputDecoration(labelText: 'Relationship'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gender,
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: blood,
                decoration: const InputDecoration(labelText: 'Blood group'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final payload = {
                    'full_name': name.text.trim(),
                    'relationship': relation.text.trim(),
                    'age': int.tryParse(age.text.trim()),
                    'gender': gender.text.trim(),
                    'blood_group': blood.text.trim(),
                    'emergency_enabled': true,
                    'profile_payload': <String, dynamic>{},
                  };
                  try {
                    await _service.createMember(payload);
                    await _load();
                  } catch (_) {
                    setState(() => _members.insert(0, payload));
                  }
                  if (context.mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save member'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyFeatureRow extends StatelessWidget {
  const _FamilyFeatureRow({
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
