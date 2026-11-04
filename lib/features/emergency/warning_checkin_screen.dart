import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/alert_providers.dart';

/// Soft alarm + "Are you OK?" with a response timeout. If the wearer does not
/// answer in time and the condition persists, the engine escalates.
class WarningCheckinScreen extends ConsumerWidget {
  const WarningCheckinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(alertControllerProvider);
    final controller = ref.read(alertControllerProvider.notifier);
    final theme = Theme.of(context);
    const fg = Color(0xFF1A1300);
    final secs = (alert.checkInRemaining.inMilliseconds / 1000).ceil();
    final total = alert.checkInTotal.inMilliseconds;
    final progress = total == 0 ? 0.0 : alert.checkInRemaining.inMilliseconds / total;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.warning,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Icon(Icons.warning_amber_rounded, size: 88, color: fg),
                        Text(RiskLevel.warning.label,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(color: fg, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(AppStrings.areYouOk,
                              style: theme.textTheme.displayMedium
                                  ?.copyWith(color: fg, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(height: 8),
                        Text(AppStrings.checkInBody,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                        const SizedBox(height: 16),
                        for (final r in alert.reasons)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(r,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          label: '${AppStrings.respondWithin} $secs seconds',
                          child: SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 12,
                                  color: fg,
                                  backgroundColor: fg.withValues(alpha: 0.2),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$secs',
                                          style: theme.textTheme.displayMedium?.copyWith(
                                              color: fg, fontWeight: FontWeight.w900)),
                                      Text(AppStrings.secondsShort,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(color: fg)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(AppStrings.respondWithin,
                            style: theme.textTheme.titleMedium?.copyWith(color: fg)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.respondOk,
                    icon: const Icon(Icons.check_circle, size: 34),
                    label: const Text(AppStrings.imOk, style: TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emergency,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: controller.requestHelp,
                    icon: const Icon(Icons.sos, size: 28),
                    label: const Text(AppStrings.needHelp),
                  ),
                ),
                const SizedBox(height: 8),
                Text(AppStrings.checkInSoundNote,
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
