import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/alert_providers.dart';
import '../../providers/location_providers.dart';
import '../../shared/widgets/connection_chip.dart';
import '../../shared/widgets/slide_to_cancel.dart';

/// Full-screen pulsing red alarm with the countdown ring. The countdown can
/// only be stopped with the slide-to-cancel control.
class EmergencyCountdownScreen extends ConsumerStatefulWidget {
  const EmergencyCountdownScreen({super.key});

  @override
  ConsumerState<EmergencyCountdownScreen> createState() => _EmergencyCountdownScreenState();
}

class _EmergencyCountdownScreenState extends ConsumerState<EmergencyCountdownScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alert = ref.watch(alertControllerProvider);
    final online = ref.watch(onlineProvider);
    final theme = Theme.of(context);
    final secs = (alert.countdownRemaining.inMilliseconds / 1000).ceil();
    final total = alert.countdownTotal.inMilliseconds;
    final progress = total == 0 ? 0.0 : alert.countdownRemaining.inMilliseconds / total;
    final vitals = alert.vitals;
    const white = Colors.white;

    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Scaffold(
          backgroundColor:
              Color.lerp(const Color(0xFF8E0000), const Color(0xFFE53935), _pulse.value),
          body: child,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Icon(Icons.emergency, size: 72, color: white),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(AppStrings.emergencyTitle,
                              style: theme.textTheme.displayMedium
                                  ?.copyWith(color: white, fontWeight: FontWeight.w900)),
                        ),
                        Text(AppStrings.sendingAlertIn,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(color: white)),
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          label: '$secs seconds until help is called',
                          child: SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 16,
                                  color: white,
                                  backgroundColor: Colors.white24,
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$secs',
                                          style: theme.textTheme.displayLarge?.copyWith(
                                              color: white,
                                              fontSize: 88,
                                              fontWeight: FontWeight.w900)),
                                      Text(AppStrings.secondsShort,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(color: white)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (alert.fall) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.personal_injury, color: white),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(AppStrings.fallShortened,
                                    style: theme.textTheme.titleSmall
                                        ?.copyWith(color: white, fontWeight: FontWeight.w800)),
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppStrings.triggeringReadings,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(color: white, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              if (vitals != null)
                                Text(
                                  '${AppStrings.heartRate} ${vitals.heartRate > 0 ? vitals.heartRate : '--'} ${AppStrings.bpm}   '
                                  '${AppStrings.spo2} ${vitals.spo2 > 0 ? '${vitals.spo2}%' : '--'}',
                                  style: theme.textTheme.titleLarge
                                      ?.copyWith(color: white, fontWeight: FontWeight.w800),
                                ),
                              const SizedBox(height: 4),
                              for (final r in alert.reasons)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.arrow_right, color: white),
                                      Expanded(
                                        child: Text(r,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(color: white)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (!online) ...[
                          const SizedBox(height: 12),
                          const OfflineChip(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SlideToCancel(
                  label: AppStrings.slideToCancel,
                  onCompleted: ref.read(alertControllerProvider.notifier).cancelCountdown,
                ),
                const SizedBox(height: 8),
                Text(AppStrings.disclaimerFooter,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
