import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert_event.dart';

extension AlertEventUi on AlertEvent {
  String get stageLabel {
    switch (stage) {
      case AlertStage.warning:
        return AppStrings.stageWarning;
      case AlertStage.emergency:
        return AppStrings.stageEmergency;
      case AlertStage.dispatched:
        return AppStrings.stageDispatched;
      case AlertStage.resolved:
        return AppStrings.stageResolved;
    }
  }

  String get outcomeLabel {
    switch (outcome) {
      case AlertOutcome.pending:
        return AppStrings.outcomePending;
      case AlertOutcome.cancelledByUser:
        return AppStrings.outcomeCancelled;
      case AlertOutcome.dispatched:
        return AppStrings.outcomeDispatched;
      case AlertOutcome.resolved:
        return AppStrings.outcomeResolved;
    }
  }
}

class AlertTile extends StatelessWidget {
  const AlertTile({super.key, required this.event, this.onTap});

  final AlertEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = event.level.color(context);
    final reason = event.reasons.isEmpty ? event.stageLabel : event.reasons.first;
    return Semantics(
      button: true,
      label:
          '${event.level.label} ${event.stageLabel}, ${Formatters.dateTime(event.time)}. $reason. ${event.outcomeLabel}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(event.level.icon, color: color, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${event.level.label} - ${event.stageLabel}',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(Formatters.dateTime(event.time), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      Text(reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 2),
                      Text(event.outcomeLabel,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700, color: color)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}