import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/profile_providers.dart';

/// Animated logo, then on to onboarding, profile setup or the dashboard.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go(resolveStartupRoute(ref));
        });
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeIn));
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: scale,
              child: Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.monitor_heart, size: 84, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: fade,
              child: Column(children: [
                Text(AppStrings.appName,
                    style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(AppStrings.tagline,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.onPrimary)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
