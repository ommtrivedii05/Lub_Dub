import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/sources/device_source.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionChip extends StatelessWidget {
  const ConnectionChip({super.key, required this.state, this.demo = false});

  final DeviceConnectionState state;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case DeviceConnectionState.connected:
        return _StatusChip(
          icon: demo ? Icons.science : Icons.wifi,
          label: demo ? AppStrings.demoMode : AppStrings.connected,
          color: RiskLevel.normal.color(context),
        );
      case DeviceConnectionState.connecting:
        return _StatusChip(
          icon: Icons.sync,
          label: AppStrings.connecting,
          color: RiskLevel.warning.color(context),
        );
      case DeviceConnectionState.failed:
      case DeviceConnectionState.disconnected:
        return _StatusChip(
          icon: Icons.wifi_off,
          label: AppStrings.disconnected,
          color: RiskLevel.emergency.color(context),
        );
    }
  }
}

class GpsChip extends StatelessWidget {
  const GpsChip({super.key, required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      icon: live ? Icons.gps_fixed : Icons.gps_not_fixed,
      label: live ? AppStrings.gpsOn : AppStrings.gpsOff,
      color: live ? RiskLevel.normal.color(context) : RiskLevel.warning.color(context),
    );
  }
}

/// Shown when there is no internet; the emergency flow still works offline.
class OfflineChip extends StatelessWidget {
  const OfflineChip({super.key});

  @override
  Widget build(BuildContext context) {
    return _StatusChip(
      icon: Icons.cloud_off,
      label: AppStrings.offline,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
    );
  }
}