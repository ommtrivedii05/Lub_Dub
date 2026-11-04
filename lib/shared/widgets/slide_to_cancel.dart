import 'package:material_ui/material_ui.dart';

/// Drag-to-confirm control used for "I'm OK". A deliberate slide avoids
/// accidental cancellation of an emergency. Screen readers can activate it
/// with a normal double-tap.
class SlideToCancel extends StatefulWidget {
  const SlideToCancel({
    super.key,
    required this.label,
    required this.onCompleted,
    this.color = Colors.white,
    this.textColor = Colors.black87,
  });

  final String label;
  final VoidCallback onCompleted;
  final Color color;
  final Color textColor;

  @override
  State<SlideToCancel> createState() => _SlideToCancelState();
}

class _SlideToCancelState extends State<SlideToCancel> {
  static const double _handle = 64;
  double _dx = 0;
  bool _dragging = false;
  bool _done = false;

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      onTap: _finish,
      excludeSemantics: true,
      child: LayoutBuilder(builder: (context, c) {
        final maxDx = (c.maxWidth - _handle - 8).clamp(1.0, double.infinity);
        final progress = (_dx / maxDx).clamp(0.0, 1.0);
        return Container(
          height: _handle + 8,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular((_handle + 8) / 2),
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: _handle),
                  child: Opacity(
                    opacity: 1 - progress,
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: _dragging ? Duration.zero : const Duration(milliseconds: 200),
                left: 4 + _dx,
                child: GestureDetector(
                  onHorizontalDragStart: (_) => setState(() => _dragging = true),
                  onHorizontalDragUpdate: (d) =>
                      setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx)),
                  onHorizontalDragEnd: (_) {
                    if (_dx / maxDx > 0.85) {
                      setState(() {
                        _dx = maxDx;
                        _dragging = false;
                      });
                      _finish();
                    } else {
                      setState(() {
                        _dx = 0;
                        _dragging = false;
                      });
                    }
                  },
                  child: Container(
                    width: _handle,
                    height: _handle,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                    child: Icon(Icons.double_arrow, size: 34, color: widget.textColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}