import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/ai_insights_screen.dart';
import '../screens/analytics_dashboard_screen.dart';
import '../screens/appointment_management_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/consent_sharing_screen.dart';
import '../screens/emergency_mode_screen.dart';
import '../screens/emergency_qr_screen.dart';
import '../screens/family_health_screen.dart';
import '../screens/fhir_viewer_screen.dart';
import '../screens/health_wallet_screen.dart';
import '../screens/home_shell_screen.dart';
import '../screens/lab_results_screen.dart';
import '../screens/legal_document_screen.dart';
import '../screens/medical_records_screen.dart';
import '../screens/medical_timeline_screen.dart';
import '../screens/medication_tracker_screen.dart';
import '../screens/medicine_reminder_screen.dart';
import '../screens/ocr_upload_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/patient_summary_screen.dart';
import '../screens/provider_sandbox_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/sos_alert_screen.dart';
import '../screens/wellness_tracker_screen.dart';
import '../widgets/app_background.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: SplashScreen.route,
    routes: [
      _route(SplashScreen.route, const SplashScreen()),
      _route(OnboardingScreen.route, const OnboardingScreen()),
      _route(AuthScreen.route, const AuthScreen()),
      _route(HomeShellScreen.route, const HomeShellScreen()),
      _route(
        MedicalRecordsScreen.route,
        const AppRouteShell(
          child: MedicalRecordsScreen(showBackButton: true),
        ),
      ),
      _route(
        PatientSummaryScreen.route,
        const AppRouteShell(
          child: PatientSummaryScreen(showBackButton: true),
        ),
      ),
      _route(
        MedicalTimelineScreen.route,
        const AppRouteShell(
          child: MedicalTimelineScreen(showBackButton: true),
        ),
      ),
      _route(
        MedicationTrackerScreen.route,
        const AppRouteShell(
          child: MedicationTrackerScreen(showBackButton: true),
        ),
      ),
      _route(
        LabResultsScreen.route,
        const AppRouteShell(
          child: LabResultsScreen(showBackButton: true),
        ),
      ),
      _route(
        EmergencyQrScreen.route,
        const AppRouteShell(
          child: EmergencyQrScreen(showBackButton: true),
        ),
      ),
      _route(
        AiInsightsScreen.route,
        const AppRouteShell(
          child: AiInsightsScreen(showBackButton: true),
        ),
      ),
      _route(
        ConsentSharingScreen.route,
        const AppRouteShell(
          child: ConsentSharingScreen(showBackButton: true),
        ),
      ),
      _route(
        FhirViewerScreen.route,
        const AppRouteShell(
          child: FhirViewerScreen(showBackButton: true),
        ),
      ),
      _route(
        ProviderSandboxScreen.route,
        const AppRouteShell(
          child: ProviderSandboxScreen(showBackButton: true),
        ),
      ),
      _route(
        OcrUploadScreen.route,
        const AppRouteShell(
          child: OcrUploadScreen(showBackButton: true),
        ),
      ),
      _route(
        HealthWalletScreen.route,
        const AppRouteShell(
          child: HealthWalletScreen(showBackButton: true),
        ),
      ),
      _route(
        EmergencyModeScreen.route,
        const AppRouteShell(child: EmergencyModeScreen()),
      ),
      _route(
        MedicineReminderScreen.route,
        const AppRouteShell(
          child: MedicineReminderScreen(showBackButton: true),
        ),
      ),
      _route(
        WellnessTrackerScreen.route,
        const AppRouteShell(
          child: WellnessTrackerScreen(showBackButton: true),
        ),
      ),
      _route(
        FamilyHealthScreen.route,
        const AppRouteShell(
          child: FamilyHealthScreen(showBackButton: true),
        ),
      ),
      _route(
        AppointmentManagementScreen.route,
        const AppRouteShell(
          child: AppointmentManagementScreen(showBackButton: true),
        ),
      ),
      _route(
        AnalyticsDashboardScreen.route,
        const AppRouteShell(
          child: AnalyticsDashboardScreen(showBackButton: true),
        ),
      ),
      _route(
        SosAlertScreen.route,
        const AppRouteShell(
          child: SosAlertScreen(showBackButton: true),
        ),
      ),
      _route(
        LegalDocumentScreen.privacyRoute,
        const AppRouteShell(child: LegalDocumentScreen.privacy),
      ),
      _route(
        LegalDocumentScreen.termsRoute,
        const AppRouteShell(child: LegalDocumentScreen.terms),
      ),
      _route(
        LegalDocumentScreen.disclaimerRoute,
        const AppRouteShell(child: LegalDocumentScreen.disclaimer),
      ),
    ],
  );

  static GoRoute _route(String path, Widget child) {
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.02),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class AppRouteShell extends StatelessWidget {
  const AppRouteShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(child: child),
      ),
    );
  }
}
