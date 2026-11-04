import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/sensor_config.dart';
import '../../data/repositories/vitals_repository.dart';

/// Read access to samples, oldest first.
abstract class _Samples {
  int get length;
  double at(int i);
}

class _BufferSamples implements _Samples {
  _BufferSamples(this.buffer);
  final EcgRingBuffer buffer;
  @override
  int get length => buffer.length;
  @override
  double at(int i) => buffer.at(i);
}

class _ListSamples implements _Samples {
  _ListSamples(this.list);
  final List<double> list;
  @override
  int get length => list.length;
  @override
  double at(int i) => list[i];
}

/// ECG on millimetre paper: [speed] mm/s horizontally, [gain] mm/mV
/// vertically. Painting is driven by the ring buffer's change notifications
/// (about 25 per second), not by widget rebuilds.
class EcgPaperChart extends StatelessWidget {
  /// Live trace from [buffer]. Pass [frozen] to show a paused snapshot.
  const EcgPaperChart.live({
    super.key,
    required EcgRingBuffer this.buffer,
    this.frozen,
    this.speed = 25,
    this.gain = 10,
    this.height = 220,
    this.pxPerMm = 3.0,
    this.showGrid = true,
  })  : samples = null;

  /// Static strip (alert detail, responder view).
  const EcgPaperChart.strip({
    super.key,
    required List<double> this.samples,
    this.speed = 25,
    this.gain = 10,
    this.height = 140,
    this.pxPerMm = 3.0,
    this.showGrid = true,
  })  : buffer = null,
        frozen = null;

  final EcgRingBuffer? buffer;
  final List<double>? frozen;
  final List<double>? samples;
  final double speed;
  final double gain;
  final double height;
  final double pxPerMm;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final _Samples src = samples != null
        ? _ListSamples(samples!)
        : (frozen != null ? _ListSamples(frozen!) : _BufferSamples(buffer!));
    final live = samples == null && frozen == null;
    return Semantics(
      label: 'ECG trace',
      image: true,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _EcgPainter(
                source: src,
                repaint: live ? buffer : null,
                speed: speed,
                gain: gain,
                pxPerMm: pxPerMm,
                showGrid: showGrid,
                dark: dark,
                alignRight: live || frozen != null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  _EcgPainter({
    required this.source,
    required super.repaint,
    required this.speed,
    required this.gain,
    required this.pxPerMm,
    required this.showGrid,
    required this.dark,
    required this.alignRight,
  });

  final _Samples source;
  final double speed;
  final double gain;
  final double pxPerMm;
  final bool showGrid;
  final bool dark;
  final bool alignRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paper = dark ? const Color(0xFF14201F) : AppColors.ecgPaperLight;
    canvas.drawRect(Offset.zero & size, Paint()..color = paper);

    if (showGrid) {
      final minor = Paint()
        ..color = (dark ? const Color(0xFF2B4442) : AppColors.ecgGridMinor)
        ..strokeWidth = 0.5;
      final major = Paint()
        ..color = (dark ? const Color(0xFF3E6360) : AppColors.ecgGridMajor)
        ..strokeWidth = 1.0;
      var i = 0;
      for (var x = 0.0; x <= size.width; x += pxPerMm, i++) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), i % 5 == 0 ? major : minor);
      }
      i = 0;
      for (var y = 0.0; y <= size.height; y += pxPerMm, i++) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), i % 5 == 0 ? major : minor);
      }
    }

    final n = source.length;
    if (n < 2) return;
    final pxPerSample = speed * pxPerMm / SensorConfig.ecgSampleRate;
    final visible = (size.width / pxPerSample).floor();
    final count = n < visible ? n : visible;
    final first = n - count;
    final mid = size.height / 2;
    final pxPerMv = gain * pxPerMm;
    final xStart = alignRight ? size.width - count * pxPerSample : 0.0;
    // Skip samples when more than one sample falls on a pixel.
    final stride = pxPerSample < 1 ? (1 / pxPerSample).floor() : 1;

    final path = Path();
    var started = false;
    for (var k = 0; k < count; k += stride) {
      final x = xStart + k * pxPerSample;
      final y = (mid - source.at(first + k) * pxPerMv).clamp(0.0, size.height);
      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = dark ? const Color(0xFF7CF3C9) : const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) => true;
}
