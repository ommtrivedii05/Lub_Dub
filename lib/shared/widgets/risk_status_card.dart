import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';

/// Hero card: big risk label, icon, confidence and the reasons list. The
/// colour animates smoothly between states; icon and text carry the meaning
/// too, so colour is never the only signal.
class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({super.key, required this.assessment, this.hasData = true});

  final RiskAssessment assessment;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    final level = assessment.level;
    final bg = AppColors.forLevel(level);
    final fg = AppColors.onLevel(level);
    final theme = Theme.of(context);
    final reasons = assessment.reasons;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: hasData ? bg : theme.colorScheme.surfaceContainerHighest),
      duration: const Duration(milliseconds: 500),
      builder: (context, color, child) {
        final textColor = hasData ? fg : theme.colorScheme.onSurface;
        return Semantics(
          container: true,
          liveRegion: true,
          label: hasData
              ? '${level.label}. ${AppStrings.confidence} ${(assessment.confidence * 100).round()} percent. ${reasons.join('. ')}'
              : AppStrings.waitingForData,
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (color ?? bg).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: textColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: Icon(
                          hasData ? level.icon : Icons.hourglass_empty,
                          key: ValueKey(hasData ? level : null),
                          size: 52,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                hasData ? level.label : AppStrings.waitingForData,
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (hasData)
                              Text(
                                '${AppStrings.confidence} ${(assessment.confidence * 100).round()}%',
                                style: theme.textTheme.titleMedium?.copyWith(color: textColor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hasData) ...[
                    const SizedBox(height: 14),
                    if (reasons.isEmpty)
                      Text(AppStrings.noReasons,
                          style: theme.textTheme.titleMedium?.copyWith(color: textColor))
                    else
                      for (final r in reasons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(Icons.arrow_right, color: textColor),
                              ),
                              Expanded(
                                child: Text(r,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: textColor, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}