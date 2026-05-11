import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HealthScoreRing extends StatelessWidget {
  const HealthScoreRing({
    super.key,
    required this.score,
    this.size = 112,
    this.light = false,
  });

  final int score;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.white : AppPalette.primary;
    final background =
        light ? Colors.white.withValues(alpha: 0.22) : AppPalette.softBlue;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 950),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: score / 100),
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: background,
                  valueColor: AlwaysStoppedAnimation<Color>(foreground),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                  ),
                  Text(
                    'score',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
