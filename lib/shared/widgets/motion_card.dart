import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/motion_data.dart';
import '../../data/models/risk_assessment.dart';

class MotionCard extends StatelessWidget {
  const MotionCard({super.key, required this.motion});

  final MotionData? motion;

  String get _posture {
    switch (motion?.posture) {
      case Posture.upright:
        return AppStrings.upright;
      case Posture.lying:
        return AppStrings.lying;
      default:
        return AppStrings.unknown;
    }
  }

  IconData get _postureIcon {
    switch (motion?.posture) {
      case Posture.upright:
        return Icons.accessibility_new;
      case Posture.lying:
        return Icons.hotel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = motion;
    final fall = m?.fallDetected ?? false;
    final red = RiskLevel.emergency.color(context);
    final activity = m?.activityLevel ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.directions_walk),
              const SizedBox(width: 8),
              Text(AppStrings.motion,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Text('${AppStrings.activity}: ${(activity * 100).round()}%',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: activity, minHeight: 10),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(_postureIcon),
              const SizedBox(width: 8),
              Expanded(
                child: Text('${AppStrings.posture}: $_posture', style: theme.textTheme.titleMedium),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(fall ? Icons.error : Icons.check_circle_outline,
                  color: fall ? red : null),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fall
                      ? '${AppStrings.fallDetected}${m?.fallAgeSeconds != null ? ' (${m!.fallAgeSeconds} s ago)' : ''}'
                      : AppStrings.fallNone,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: fall ? FontWeight.w800 : FontWeight.w400,
                    color: fall ? red : null,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}