import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/health_data_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/info_row.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import 'auth_screen.dart';
import 'legal_document_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _medicationReminders = true;
  bool _labAlerts = true;
  bool _emergencyAccess = true;
  bool _biometricUnlock = false;
  bool _pinLock = false;
  bool _shareAnalytics = false;
  bool _consentVault = true;

  @override
  Widget build(BuildContext context) {
    final data = context.watch<HealthDataProvider>();
    final patient = data.patient;
    final textTheme = Theme.of(context).textTheme;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: 'Profile',
            subtitle: 'Patient profile, preferences, and demo app settings.',
            icon: Icons.person_rounded,
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
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          patient.initials,
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              patient.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _showProfileForm(context),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit profile'),
                ),
                const SectionHeader(title: 'Contact'),
                PremiumCard(
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Mobile',
                        value: patient.phone,
                        color: AppPalette.primary,
                      ),
                      InfoRow(
                        icon: Icons.mail_rounded,
                        label: 'Email',
                        value: patient.email,
                        color: AppPalette.cyan,
                      ),
                      InfoRow(
                        icon: Icons.contact_emergency_rounded,
                        label: 'Emergency contact',
                        value:
                            '${patient.emergencyContactName} - ${patient.emergencyContactPhone}',
                        color: AppPalette.danger,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Settings'),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _SettingSwitch(
                            icon: Icons.dark_mode_rounded,
                            color: AppPalette.violet,
                            title: 'Dark mode',
                            subtitle: 'Switch to a futuristic night interface',
                            value: themeProvider.isDarkMode,
                            onChanged: themeProvider.toggleDarkMode,
                          );
                        },
                      ),
                      _SettingSwitch(
                        icon: Icons.alarm_rounded,
                        color: AppPalette.purple,
                        title: 'Medication reminders',
                        subtitle: 'Daily mock adherence nudges',
                        value: _medicationReminders,
                        onChanged: (value) =>
                            setState(() => _medicationReminders = value),
                      ),
                      _SettingSwitch(
                        icon: Icons.science_rounded,
                        color: AppPalette.cyan,
                        title: 'Lab alerts',
                        subtitle: 'Notify when a new report is available',
                        value: _labAlerts,
                        onChanged: (value) =>
                            setState(() => _labAlerts = value),
                      ),
                      _SettingSwitch(
                        icon: Icons.qr_code_2_rounded,
                        color: AppPalette.danger,
                        title: 'Emergency QR access',
                        subtitle: 'Allow quick access to critical mock info',
                        value: _emergencyAccess,
                        onChanged: (value) =>
                            setState(() => _emergencyAccess = value),
                      ),
                      _SettingSwitch(
                        icon: Icons.fingerprint_rounded,
                        color: AppPalette.primary,
                        title: 'Biometric unlock',
                        subtitle: 'Placeholder setting for future secure login',
                        value: _biometricUnlock,
                        onChanged: (value) =>
                            setState(() => _biometricUnlock = value),
                      ),
                      _SettingSwitch(
                        icon: Icons.pin_rounded,
                        color: AppPalette.success,
                        title: 'PIN lock',
                        subtitle:
                            'Local PIN placeholder for offline emergency data',
                        value: _pinLock,
                        onChanged: (value) => setState(() => _pinLock = value),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Connected hospitals'),
                const PremiumCard(
                  child: Column(
                    children: [
                      _HospitalTile(
                        name: 'Apollo Health Network',
                        status: 'Connected',
                        specialty: 'Cardiology and diagnostics',
                        color: AppPalette.primary,
                      ),
                      _HospitalTile(
                        name: 'City Care Clinic',
                        status: 'FHIR ready',
                        specialty: 'Primary care and immunizations',
                        color: AppPalette.cyan,
                      ),
                      _HospitalTile(
                        name: 'MedID Virtual Care',
                        status: 'Demo sandbox',
                        specialty: 'Telehealth appointments',
                        color: AppPalette.purple,
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Privacy & security'),
                PremiumCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingSwitch(
                        icon: Icons.privacy_tip_rounded,
                        color: AppPalette.purple,
                        title: 'Consent vault',
                        subtitle: 'Require consent before sharing records',
                        value: _consentVault,
                        onChanged: (value) =>
                            setState(() => _consentVault = value),
                      ),
                      _SettingSwitch(
                        icon: Icons.analytics_outlined,
                        color: AppPalette.warning,
                        title: 'Anonymous product analytics',
                        subtitle: 'Off by default for privacy-first demos',
                        value: _shareAnalytics,
                        onChanged: (value) =>
                            setState(() => _shareAnalytics = value),
                      ),
                      _SettingLink(
                        icon: Icons.devices_rounded,
                        color: AppPalette.cyan,
                        title: 'Session management',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Session and device tracking UI placeholder is ready.',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'MedID Connect'),
                PremiumCard(
                  child: Column(
                    children: [
                      const InfoRow(
                        icon: Icons.dataset_rounded,
                        label: 'Data source',
                        value: 'Local mock FHIR resources only',
                        color: AppPalette.purple,
                      ),
                      const InfoRow(
                        icon: Icons.android_rounded,
                        label: 'Platform',
                        value: 'Android APK + Flutter web ready',
                        color: AppPalette.success,
                      ),
                      _SettingLink(
                        icon: Icons.privacy_tip_rounded,
                        color: AppPalette.primary,
                        title: 'Privacy policy',
                        onTap: () =>
                            context.push(LegalDocumentScreen.privacyRoute),
                      ),
                      _SettingLink(
                        icon: Icons.gavel_rounded,
                        color: AppPalette.purple,
                        title: 'Terms of service',
                        onTap: () =>
                            context.push(LegalDocumentScreen.termsRoute),
                      ),
                      _SettingLink(
                        icon: Icons.medical_information_rounded,
                        color: AppPalette.warning,
                        title: 'Medical disclaimer',
                        onTap: () =>
                            context.push(LegalDocumentScreen.disclaimerRoute),
                      ),
                      _SettingLink(
                        icon: Icons.download_rounded,
                        color: AppPalette.cyan,
                        title: 'Data export placeholder',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Data export workflow placeholder is ready.')),
                        ),
                      ),
                      _SettingLink(
                        icon: Icons.delete_outline_rounded,
                        color: AppPalette.danger,
                        title: 'Delete account placeholder',
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Account deletion placeholder requires production confirmation flow.')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            context.go(AuthScreen.route);
                          }
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Sign out of demo'),
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

  Future<void> _showProfileForm(BuildContext context) async {
    final data = context.read<HealthDataProvider>();
    final patient = data.patient;
    final name = TextEditingController(text: patient.name);
    final age = TextEditingController(text: patient.age.toString());
    final gender = TextEditingController(text: patient.gender);
    final bloodGroup = TextEditingController(text: patient.bloodGroup);
    final phone = TextEditingController(text: patient.phone);
    final contactName =
        TextEditingController(text: patient.emergencyContactName);
    final contactPhone =
        TextEditingController(text: patient.emergencyContactPhone);

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
                'Edit profile',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(
                  controller: age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age')),
              const SizedBox(height: 12),
              TextField(
                  controller: gender,
                  decoration: const InputDecoration(labelText: 'Gender')),
              const SizedBox(height: 12),
              TextField(
                  controller: bloodGroup,
                  decoration: const InputDecoration(labelText: 'Blood group')),
              const SizedBox(height: 12),
              TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              TextField(
                  controller: contactName,
                  decoration: const InputDecoration(
                      labelText: 'Emergency contact name')),
              const SizedBox(height: 12),
              TextField(
                  controller: contactPhone,
                  decoration: const InputDecoration(
                      labelText: 'Emergency contact phone')),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  try {
                    await context.read<HealthDataProvider>().updateProfile({
                      'full_name': name.text.trim(),
                      'age': int.tryParse(age.text.trim()),
                      'gender': gender.text.trim(),
                      'blood_group': bloodGroup.text.trim(),
                      'phone': phone.text.trim(),
                      'emergency_contact': {
                        'name': contactName.text.trim(),
                        'relationship': 'Emergency contact',
                        'phone': contactPhone.text.trim(),
                      },
                    });
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Backend unavailable. Profile editing is ready for connected mode.',
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
                label: const Text('Save profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HospitalTile extends StatelessWidget {
  const _HospitalTile({
    required this.name,
    required this.status,
    required this.specialty,
    required this.color,
  });

  final String name;
  final String status;
  final String specialty;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.local_hospital_rounded, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  specialty,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPalette.muted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingLink extends StatelessWidget {
  const _SettingLink({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
