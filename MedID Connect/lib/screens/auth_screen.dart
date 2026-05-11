import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/health_data_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/fhir_logo.dart';
import '../widgets/premium_card.dart';
import 'home_shell_screen.dart';

enum AuthMode { login, signup }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const String route = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  bool _obscurePassword = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enterApp({bool signup = false, bool guest = false}) async {
    final auth = context.read<AuthProvider>();
    bool success = true;
    if (guest) {
      auth.continueAsGuest();
    } else if (signup) {
      success = await auth.signup(
        fullName: _nameController.text.trim().isEmpty
            ? 'Aarav Mehta'
            : _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    if (!success || !mounted) {
      return;
    }
    if (!guest) {
      await context.read<HealthDataProvider>().loadRemoteData();
    }
    if (!mounted) {
      return;
    }
    context.go(HomeShellScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSignup = _mode == AuthMode.signup;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MedIdLogo(size: 52),
                const SizedBox(height: 34),
                Text(
                  isSignup ? 'Create your health space' : 'Welcome back',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Use the mock demo account or continue as a guest to explore MedID Connect.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppPalette.muted,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                PremiumCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<AuthMode>(
                          segments: const [
                            ButtonSegment(
                              value: AuthMode.login,
                              label: Text('Login'),
                              icon: Icon(Icons.lock_open_rounded),
                            ),
                            ButtonSegment(
                              value: AuthMode.signup,
                              label: Text('Signup'),
                              icon: Icon(Icons.person_add_alt_1_rounded),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: (selection) {
                            setState(() => _mode = selection.first);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isSignup
                            ? TextField(
                                key: const ValueKey('name'),
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (isSignup) const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.password_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (auth.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPalette.danger.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppPalette.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      FilledButton.icon(
                        onPressed: auth.isSubmitting
                            ? null
                            : () => _enterApp(signup: isSignup),
                        icon: Icon(isSignup
                            ? Icons.arrow_forward_rounded
                            : Icons.login_rounded),
                        label: Text(
                          auth.isSubmitting
                              ? 'Please wait...'
                              : (isSignup ? 'Create account' : 'Login'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: auth.isSubmitting
                            ? null
                            : () => _enterApp(guest: true),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Continue as Guest'),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Forgot password flow is reserved for production email setup.',
                              ),
                            ),
                          );
                        },
                        child: const Text('Forgot password?'),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(color: Colors.blueGrey.shade100)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'or continue with',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppPalette.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(color: Colors.blueGrey.shade100)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialLoginButton(
                              label: 'Google',
                              icon: Icons.g_mobiledata_rounded,
                              onTap: () => _enterApp(guest: true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SocialLoginButton(
                              label: 'Apple',
                              icon: Icons.apple_rounded,
                              onTap: () => _enterApp(guest: true),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Demo only. No real hospital APIs or protected health data are used.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppPalette.muted,
                    fontWeight: FontWeight.w700,
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

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
      ),
    );
  }
}
