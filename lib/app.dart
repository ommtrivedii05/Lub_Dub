import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/alert_providers.dart';
import 'providers/device_providers.dart';
import 'providers/settings_providers.dart';
import 'services/alert_engine.dart';

class LubDubApp extends ConsumerStatefulWidget {
  const LubDubApp({super.key});

  @override
  ConsumerState<LubDubApp> createState() => _LubDubAppState();
}

class _LubDubAppState extends ConsumerState<LubDubApp> {
  @override
  void initState() {
    super.initState();
    // Demo mode is the default until a real device is connected.
    Future.microtask(() {
      if (ref.read(settingsProvider).demoMode) {
        ref.read(deviceControllerProvider.notifier).startDemo();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _AlertRouteListener(child: child ?? const SizedBox()),
    );
  }
}

/// Opens the alarm screens when the alert engine changes state, wherever the
/// user currently is. Reading the controller here also keeps it alive.
///
/// go_router does not reflect imperative pushes in its route information, so
/// this widget remembers which alarm screen it opened itself.
class _AlertRouteListener extends ConsumerStatefulWidget {
  const _AlertRouteListener({required this.child});

  final Widget child;

  @override
  ConsumerState<_AlertRouteListener> createState() => _AlertRouteListenerState();
}

class _AlertRouteListenerState extends ConsumerState<_AlertRouteListener> {
  String? _top;

  void _navigate(AlertState next) {
    switch (next) {
      case AlertState.warning:
        if (_top != '/warning') appRouter.push('/warning');
        _top = '/warning';
        break;
      case AlertState.emergency:
        if (_top == '/warning') {
          appRouter.pushReplacement('/countdown');
        } else if (_top != '/countdown') {
          appRouter.push('/countdown');
        }
        _top = '/countdown';
        break;
      case AlertState.dispatched:
        if (_top == '/countdown' || _top == '/warning') {
          appRouter.pushReplacement('/emergency');
        } else if (_top != '/emergency') {
          appRouter.push('/emergency');
        }
        _top = '/emergency';
        break;
      case AlertState.resolved:
      case AlertState.monitoring:
        if (_top != null) appRouter.go('/dashboard');
        _top = null;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AlertState>(
      alertControllerProvider.select((s) => s.engineState),
      (prev, next) => _navigate(next),
    );
    return widget.child;
  }
}