import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';

/// Arc gauge for SpO2 (70-100 %).
class Spo2Gauge extends StatelessWidget {
  const Spo2Gauge({super.key, required this.spo2, required this.color, this.size = 120});

  /// 0 means "no reading".
  final int spo2;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final fraction = spo2 <= 0 ? 0.0 : ((spo2 - 70) / 30).clamp(0.0, 1.0);
    return Semantics(
      label: spo2 <= 0 ? '${AppStrings.spo2} unavailable' : '${AppStrings.spo2} $spo2 percent',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size * 0.8,
        child: CustomPaint(
          painter: _GaugePainter(fraction, color, track),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  spo2 <= 0 ? '--' : '$spo2%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.fraction, this.color, this.track);

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.11;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height * 0.62),
      radius: size.width / 2 - stroke / 2,
    );
    const start = 0.75 * pi;
    const sweep = 1.5 * pi;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(rect, start, sweep, false, paint..color = track);
    if (fraction > 0) {
      canvas.drawArc(rect, start, sweep * fraction, false, paint..color = color);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}