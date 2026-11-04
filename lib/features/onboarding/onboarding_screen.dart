import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/location_providers.dart';
import '../../providers/profile_providers.dart';

/// Four slides: purpose, hardware, permissions, medical disclaimer.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _permissionsAsked = false;
  bool _asking = false;

  static const _icons = [
    Icons.favorite,
    Icons.watch,
    Icons.shield_outlined,
    Icons.medical_information_outlined,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _askPermissions() async {
    setState(() => _asking = true);
    await ref.read(locationServiceProvider).requestAppPermissions();
    if (!mounted) return;
    setState(() {
      _asking = false;
      _permissionsAsked = true;
    });
  }

  void _next() {
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _finish() {
    ref.read(onboardingCompleteProvider.notifier).state = true;
    context.go(resolveStartupRoute(ref));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == AppStrings.onboardingTitles.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: last ? null : () => _controller.jumpToPage(3),
                child: const Text(AppStrings.skip),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: AppStrings.onboardingTitles.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icons[i], size: 76, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 28),
                      Semantics(
                        header: true,
                        child: Text(AppStrings.onboardingTitles[i],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 14),
                      Text(AppStrings.onboardingBodies[i],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(height: 1.4)),
                      if (i == 2) ...[
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _asking ? null : _askPermissions,
                          icon: Icon(_permissionsAsked ? Icons.check : Icons.lock_open),
                          label: Text(_permissionsAsked
                              ? 'Permissions requested'
                              : AppStrings.grantPermissions),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < AppStrings.onboardingTitles.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                        child: const Text(AppStrings.back),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: last ? _finish : _next,
                      child: Text(last ? AppStrings.iUnderstand : AppStrings.next),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
