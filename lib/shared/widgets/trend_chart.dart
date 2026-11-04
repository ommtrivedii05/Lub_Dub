import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';

class TrendPoint {
  const TrendPoint(this.time, this.value);
  final DateTime time;
  final double value;
}

/// Line chart for HR / SpO2 trends. Data should already be downsampled.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.unit,
    required this.minY,
    required this.maxY,
    this.dateFormat = 'HH:mm',
    this.threshold,
    this.height = 180,
    this.semanticLabel,
  });

  final List<TrendPoint> points;
  final Color color;
  final String unit;
  final double minY;
  final double maxY;
  final String dateFormat;

  /// Horizontal reference line (e.g. minimum SpO2).
  final double? threshold;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(child: Text(AppStrings.noData, style: theme.textTheme.titleMedium)),
      );
    }
    final t0 = points.first.time.millisecondsSinceEpoch.toDouble();
    final span = (points.last.time.millisecondsSinceEpoch - t0).clamp(1, double.infinity);
    final spots = [
      for (final p in points) FlSpot(p.time.millisecondsSinceEpoch - t0, p.value),
    ];
    final grid = theme.colorScheme.onSurface.withValues(alpha: 0.1);
    final labelStyle = theme.textTheme.bodySmall;
    final fmt = DateFormat(dateFormat);

    return Semantics(
      label: semanticLabel ??
          'Trend chart, ${points.length} points, from ${points.first.value.round()} to ${points.last.value.round()} $unit',
      child: SizedBox(
        height: height,
        child: ExcludeSemantics(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: 0,
              maxX: span.toDouble(),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => [
                    for (final s in spots)
                      LineTooltipItem(
                        '${s.y.round()} $unit\n${fmt.format(DateTime.fromMillisecondsSinceEpoch((t0 + s.x).round()))}',
                        TextStyle(color: color, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: threshold == null
                  ? null
                  : ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: threshold!,
                        color: theme.colorScheme.error.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                    ]),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, meta) => Text(v.round().toString(), style: labelStyle),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: span / 4,
                    getTitlesWidget: (v, meta) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        fmt.format(DateTime.fromMillisecondsSinceEpoch((t0 + v).round())),
                        style: labelStyle,
                      ),
                    ),
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.15,
                  preventCurveOverShooting: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}