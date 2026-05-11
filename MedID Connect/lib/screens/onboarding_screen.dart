import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fhir_logo.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const String route = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.dashboard_customize_rounded,
      title: 'One view of your medical life',
      body:
          'Bring conditions, allergies, medications, reports, vitals, and immunizations into one patient-first dashboard.',
      gradient: AppPalette.cyanGradient,
    ),
    _OnboardingPage(
      icon: Icons.timeline_rounded,
      title: 'A clear medical timeline',
      body:
          'Understand what happened and when with clean interoperable history, lab reports, prescriptions, and visits.',
      gradient: AppPalette.purpleGradient,
    ),
    _OnboardingPage(
      icon: Icons.qr_code_2_rounded,
      title: 'Emergency details in seconds',
      body:
          'Share critical mock emergency information with a QR screen designed for fast access when it matters.',
      gradient: AppPalette.premiumGradient,
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'AI insights and OCR intake',
      body:
          'Use rule-based AI insights and placeholder OCR to turn reports and prescriptions into structured health data.',
      gradient: AppPalette.purpleGradient,
    ),
    _OnboardingPage(
      icon: Icons.hub_rounded,
      title: 'Hospital sandbox ready',
      body:
          'Connect HAPI FHIR demo data today, with Epic, Cerner, and ABDM/ABHA sandbox placeholders ready for approval.',
      gradient: AppPalette.cyanGradient,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      context.go(AuthScreen.route);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Column(
              children: [
                Row(
                  children: [
                    const MedIdLogo(size: 46),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go(AuthScreen.route),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 34),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 650),
                              tween: Tween(begin: 0.9, end: 1),
                              curve: Curves.easeOutBack,
                              builder: (context, value, child) {
                                return Transform.scale(
                                    scale: value, child: child);
                              },
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  gradient: page.gradient,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppPalette.primary
                                          .withValues(alpha: 0.18),
                                      blurRadius: 34,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Icon(page.icon,
                                    color: Colors.white, size: 76),
                              ),
                            ),
                            const SizedBox(height: 42),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page.body,
                              textAlign: TextAlign.center,
                              style: textTheme.bodyLarge?.copyWith(
                                color: AppPalette.muted,
                                fontWeight: FontWeight.w600,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      width: _currentPage == index ? 28 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppPalette.primary
                            : AppPalette.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _currentPage == _pages.length - 1
                        ? 'Get started'
                        : 'Continue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String body;
  final Gradient gradient;
}
