import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../data/sources/mock_device_source.dart';
import '../../providers/device_providers.dart';

/// Bottom sheet to switch the simulator scenario. Opened from Settings and by
/// long-pressing the dashboard title in debug builds.
Future<void> showSimulatorPanel(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SimulatorPanel(),
  );
}

class SimulatorPanel extends ConsumerWidget {
  const SimulatorPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceControllerProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(AppStrings.simulator,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              device.demo
                  ? AppStrings.scenario
                  : 'Start Demo Mode to use the simulator.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            if (!device.demo)
              FilledButton.icon(
                onPressed: () => ref.read(deviceControllerProvider.notifier).startDemo(),
                icon: const Icon(Icons.science),
                label: const Text(AppStrings.useDemo),
              ),
            RadioGroup<SimScenario>(
              groupValue: device.scenario,
              onChanged: (v) {
                if (v != null) ref.read(deviceControllerProvider.notifier).setScenario(v);
              },
              child: Column(
                children: [
                  for (final s in SimScenario.values)
                    RadioListTile<SimScenario>(
                      value: s,
                      title: Text(s.profile.label,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      subtitle: Text(s.profile.description),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}