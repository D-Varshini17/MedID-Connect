import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/premium_card.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.showBackButton = true,
  });

  static const String privacyRoute = '/privacy-policy';
  static const String termsRoute = '/terms';
  static const String disclaimerRoute = '/medical-disclaimer';

  final String title;
  final String subtitle;
  final String body;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: PageHeader(
            title: title,
            subtitle: subtitle,
            icon: Icons.policy_rounded,
            showBackButton: showBackButton,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverToBoxAdapter(
            child: PremiumCard(
              color: AppPalette.softBlue,
              child: Text(
                body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const privacy = LegalDocumentScreen(
    title: 'Privacy policy',
    subtitle: 'Placeholder privacy policy for Play Store preparation.',
    body:
        'MedID Connect stores personal health information only for the user account. Production release requires a hosted privacy policy URL, clear consent language, retention periods, data export, and deletion workflow. Do not use this MVP for real patient data until legal, security, and compliance review is complete.',
  );

  static const terms = LegalDocumentScreen(
    title: 'Terms of service',
    subtitle: 'Placeholder terms for MVP testing.',
    body:
        'This MVP is provided for demonstration and development. Users must not rely on the app as a replacement for professional medical care. Hospital, FHIR, ABDM, OCR, and AI integrations are sandbox or placeholder flows until approved production integrations are completed.',
  );

  static const disclaimer = LegalDocumentScreen(
    title: 'Medical disclaimer',
    subtitle: 'Required AI and healthcare safety notice.',
    body:
        'This is informational only and not a medical diagnosis. Consult a qualified doctor for diagnosis, treatment, medication changes, emergencies, and interpretation of lab results. AI and OCR outputs require human verification.',
  );
}
