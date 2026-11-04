import 'package:material_ui/material_ui.dart';

/// A heart icon that beats at the given heart rate.
class PulsingHeart extends StatefulWidget {
  const PulsingHeart({super.key, required this.bpm, this.size = 36, this.color});

  final int bpm;
  final double size;
  final Color? color;

  @override
  State<PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<PulsingHeart> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  Duration get _period =>
      Duration(milliseconds: (60000 / widget.bpm.clamp(30, 200)).round());

  @override
  void initState() {
    super.initState();
    _restart();
  }

  void _restart() {
    _c.stop();
    if (widget.bpm <= 0) return;
    _c.duration = _period;
    _c.repeat();
  }

  @override
  void didUpdateWidget(PulsingHeart old) {
    super.didUpdateWidget(old);
    if (old.bpm != widget.bpm) _restart();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.error;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // Quick systolic bump in the first third of each beat.
          final t = _c.value;
          final bump = t < 0.15 ? t / 0.15 : (t < 0.4 ? 1 - (t - 0.15) / 0.25 : 0.0);
          return Transform.scale(scale: 1 + 0.22 * bump, child: child);
        },
        child: Icon(Icons.favorite, color: color, size: widget.size),
      ),
    );
  }
}