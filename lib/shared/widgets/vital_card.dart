import 'package:material_ui/material_ui.dart';

/// Card with a label, a very large numeral and a unit.
class VitalCard extends StatelessWidget {
  const VitalCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.leading,
    this.color,
    this.child,
    this.semanticLabel,
  });

  final String label;
  final String value;
  final String unit;
  final Widget? leading;
  final Color? color;
  final Widget? child;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final numeral = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: color,
      height: 1.0,
    );
    return Semantics(
      label: semanticLabel ?? '$label $value $unit',
      container: true,
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, style: numeral),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(unit, style: theme.textTheme.titleMedium),
                ],
              ),
              if (child != null) ...[const SizedBox(height: 8), child!],
            ],
          ),
        ),
      ),
    );
  }
}