import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';

/// One slice of the timeline, already reduced to its worst level (null = no data).
typedef TimelineSegments = List<RiskLevel?>;

/// Horizontal bar coloured by risk level over time, with a legend that uses
/// icons and text as well as colour.
class RiskTimelineBar extends StatelessWidget {
  const RiskTimelineBar({super.key, required this.segments, this.start, this.end});

  final TimelineSegments segments;
  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final empty = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _summary(),
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 26,
              width: double.infinity,
              child: CustomPaint(
                painter: _TimelinePainter(segments, dark, empty),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final l in RiskLevel.values)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(l.icon, size: 18, color: l.color(context)),
                const SizedBox(width: 4),
                Text(l.label, style: theme.textTheme.bodyMedium),
              ]),
          ],
        ),
      ],
    );
  }

  String _summary() {
    final counts = {for (final l in RiskLevel.values) l: 0};
    for (final s in segments) {
      if (s != null) counts[s] = counts[s]! + 1;
    }
    return '${AppStrings.riskTimeline}: ${counts[RiskLevel.warning]} warning and ${counts[RiskLevel.emergency]} emergency periods';
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter(this.segments, this.dark, this.empty);

  final TimelineSegments segments;
  final bool dark;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) {
      canvas.drawRect(Offset.zero & size, Paint()..color = empty);
      return;
    }
    final w = size.width / segments.length;
    for (var i = 0; i < segments.length; i++) {
      final level = segments[i];
      final paint = Paint()
        ..color = level == null ? empty : AppColors.forLevel(level, dark: dark);
      // Slight overlap avoids hairline gaps between slices.
      canvas.drawRect(Rect.fromLTWH(i * w, 0, w + 0.6, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.segments != segments || old.dark != dark || old.empty != empty;
}