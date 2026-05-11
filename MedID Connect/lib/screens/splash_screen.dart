import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/fhir_logo.dart';
import 'home_shell_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String route = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _fade = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _routeAfterStartup();
  }

  Future<void> _routeAfterStartup() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 2200)),
      context.read<AuthProvider>().bootstrap(),
    ]);
    if (!mounted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated && !auth.isDemoMode) {
      await context.read<HealthDataProvider>().loadRemoteData();
      if (!mounted) {
        return;
      }
      context.go(HomeShellScreen.route);
    } else {
      context.go(OnboardingScreen.route);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.lerp(
                      Alignment.topLeft,
                      Alignment.topRight,
                      _controller.value,
                    ) ??
                    Alignment.topLeft,
                end: Alignment.lerp(
                      Alignment.bottomRight,
                      Alignment.bottomLeft,
                      _controller.value,
                    ) ??
                    Alignment.bottomRight,
                colors: const [
                  Color(0xFFE9F7FF),
                  Color(0xFFF7FCFF),
                  Color(0xFFF0E7FF),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const MedIdLogo(size: 96, showText: false),
                    const SizedBox(height: 26),
                    Text(
                      'MedID Connect',
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your medical identity, securely connected',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 34),
                    const SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
