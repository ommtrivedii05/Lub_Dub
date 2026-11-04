import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/band_status.dart';
import '../../data/models/risk_assessment.dart';

class BandStatusTile extends StatelessWidget {
  const BandStatusTile({
    super.key,
    required this.title,
    required this.icon,
    required this.status,
    required this.isChest,
    this.showHelp = false,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final BandStatus? status;
  final bool isChest;

  /// Show the full lead-off / finger-off explanation (Device Status screen).
  final bool showHelp;
  final VoidCallback? onTap;

  String? get _problem {
    final s = status;
    if (s == null) return null;
    if (!s.connected) return AppStrings.bandDisconnectedHelp;
    if (isChest && s.leadOff) return AppStrings.leadOffHelp;
    if (!isChest && s.fingerOff) return AppStrings.fingerOffHelp;
    return null;
  }

  String? get _problemTitle {
    final s = status;
    if (s == null) return null;
    if (!s.connected) return AppStrings.disconnected;
    if (isChest && s.leadOff) return AppStrings.leadOff;
    if (!isChest && s.fingerOff) return AppStrings.fingerOff;
    return null;
  }

  IconData _batteryIcon(int pct) {
    if (pct >= 90) return Icons.battery_full;
    if (pct >= 60) return Icons.battery_5_bar;
    if (pct >= 30) return Icons.battery_3_bar;
    if (pct >= 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = status;
    final warn = RiskLevel.warning.color(context);
    final ok = RiskLevel.normal.color(context);
    final problem = _problemTitle;
    final connected = s?.connected ?? false;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                  problem != null
                      ? Icons.warning_amber_rounded
                      : (connected ? Icons.check_circle : Icons.cancel_outlined),
                  color: problem != null ? warn : (connected ? ok : null),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    problem ?? (connected ? AppStrings.connected : AppStrings.disconnected),
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Icon(_batteryIcon(s?.batteryPercent ?? 0), size: 20),
                const SizedBox(width: 6),
                Text('${AppStrings.battery} ${s?.batteryPercent ?? 0}%',
                    style: theme.textTheme.bodyLarge),
              ]),
              const SizedBox(height: 8),
              Text('${AppStrings.signal} ${((s?.signalQuality ?? 0) * 100).round()}%',
                  style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: s?.signalQuality ?? 0, minHeight: 8),
              ),
              if (showHelp && _problem != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: warn.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: warn),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_problem!, style: theme.textTheme.bodyLarge)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}