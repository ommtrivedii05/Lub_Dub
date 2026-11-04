import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/device_providers.dart';
import '../../providers/vitals_providers.dart';
import '../../shared/widgets/band_status_tile.dart';
import '../../shared/widgets/connection_chip.dart';

class DeviceStatusScreen extends ConsumerWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceControllerProvider);
    final vitals = ref.watch(vitalsProvider).latest;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.deviceStatus)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            ConnectionChip(state: device.connection, demo: device.demo),
          ]),
          if (device.error != null) ...[
            const SizedBox(height: 8),
            Text(device.error!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 12),
          BandStatusTile(
            title: AppStrings.chestBand,
            icon: Icons.monitor_heart_outlined,
            status: vitals?.chestBand,
            isChest: true,
            showHelp: true,
          ),
          const SizedBox(height: 12),
          BandStatusTile(
            title: AppStrings.wristBand,
            icon: Icons.watch,
            status: vitals?.wristBand,
            isChest: false,
            showHelp: true,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => ref.read(deviceControllerProvider.notifier).reconnect(),
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.reconnect),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/connect'),
            icon: const Icon(Icons.settings_ethernet),
            label: const Text(AppStrings.connectDevice),
          ),
        ],
      ),
    );
  }
}