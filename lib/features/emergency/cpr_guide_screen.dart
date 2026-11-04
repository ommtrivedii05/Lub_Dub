import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/emergency_numbers.dart';
import '../../core/utils/formatters.dart';
import '../../providers/alert_providers.dart';

/// Hands-only CPR guide readable by a panicked bystander.
class CprGuideScreen extends ConsumerWidget {
  const CprGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cpr = ref.watch(cprControllerProvider);
    final controller = ref.read(cprControllerProvider.notifier);
    final theme = Theme.of(context);
    final pulseOn = cpr.running && cpr.beat.isOdd;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.cprTitle),
        actions: [
          IconButton(
            tooltip: cpr.muted ? AppStrings.unmute : AppStrings.mute,
            iconSize: 32,
            icon: Icon(cpr.muted ? Icons.volume_off : Icons.volume_up),
            onPressed: controller.toggleMute,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergency,
                foregroundColor: Colors.white,
              ),
              onPressed: () => ref.read(dispatcherProvider).call(EmergencyNumbers.national),
              icon: const Icon(Icons.call, size: 32),
              label: const Text(AppStrings.call112, style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Semantics(
              label: cpr.running
                  ? 'Metronome running at 110 beats per minute'
                  : 'Metronome stopped',
              child: AnimatedScale(
                scale: pulseOn ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pulseOn ? AppColors.emergency : const Color(0xFF00695C),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite, color: Colors.white, size: 54),
                      Text('110',
                          style: TextStyle(
                              color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900)),
                      Text('per minute', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.cprBeat,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('${AppStrings.elapsed} ${Formatters.mmss(cpr.elapsedSeconds)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: cpr.running ? Colors.grey.shade800 : const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              onPressed: cpr.running ? controller.stop : controller.start,
              icon: Icon(cpr.running ? Icons.stop : Icons.play_arrow, size: 40),
              label: Text(cpr.running ? AppStrings.stopCpr : AppStrings.startCpr,
                  style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < AppStrings.cprSteps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text('${i + 1}',
                            style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(AppStrings.cprSteps[i],
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600, height: 1.25)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
