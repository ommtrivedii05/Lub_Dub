import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/device_providers.dart';
import '../../providers/settings_providers.dart';
import '../../shared/widgets/section_header.dart';
import 'simulator_panel.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final device = ref.watch(deviceControllerProvider);
    final theme = Theme.of(context);
    final t = s.thresholds;

    Widget slider({
      required String title,
      required String valueText,
      required double value,
      required double min,
      required double max,
      required int divisions,
      required ValueChanged<double> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Text(valueText,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: valueText,
              semanticFormatterCallback: (_) => '$title $valueText',
              onChanged: onChanged,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const SectionHeader(AppStrings.thresholds),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                slider(
                  title: AppStrings.hrLow,
                  valueText: '${t.hrLow} ${AppStrings.bpm}',
                  value: t.hrLow.toDouble(),
                  min: 35,
                  max: 70,
                  divisions: 35,
                  onChanged: (v) => notifier.setThresholds(t.copyWith(hrLow: v.round())),
                ),
                slider(
                  title: AppStrings.hrHigh,
                  valueText: '${t.hrHigh} ${AppStrings.bpm}',
                  value: t.hrHigh.toDouble(),
                  min: 90,
                  max: 180,
                  divisions: 90,
                  onChanged: (v) => notifier.setThresholds(t.copyWith(hrHigh: v.round())),
                ),
                slider(
                  title: AppStrings.spo2Min,
                  valueText: '${t.spo2Min}%',
                  value: t.spo2Min.toDouble(),
                  min: 85,
                  max: 97,
                  divisions: 12,
                  onChanged: (v) => notifier.setThresholds(t.copyWith(spo2Min: v.round())),
                ),
                slider(
                  title: AppStrings.fallSensitivity,
                  valueText: '${(t.fallSensitivity * 100).round()}%',
                  value: t.fallSensitivity,
                  min: 0,
                  max: 1,
                  divisions: 10,
                  onChanged: (v) => notifier.setThresholds(t.copyWith(fallSensitivity: v)),
                ),
              ]),
            ),
          ),
          const SectionHeader('Emergency'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                slider(
                  title: AppStrings.countdownLength,
                  valueText: '${s.countdownSeconds} s',
                  value: s.countdownSeconds.toDouble(),
                  min: 10,
                  max: 60,
                  divisions: 10,
                  onChanged: (v) => notifier.setCountdown(v.round()),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.alarmSound),
                  value: s.alarmSound,
                  onChanged: (v) => notifier.update((x) => x.copyWith(alarmSound: v)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.alarmVibration),
                  value: s.alarmVibration,
                  onChanged: (v) => notifier.update((x) => x.copyWith(alarmVibration: v)),
                ),
              ]),
            ),
          ),
          const SectionHeader(AppStrings.classifierSource),
          Card(
            child: RadioGroup<ClassifierSource>(
              groupValue: s.classifier,
              onChanged: (v) {
                if (v != null) notifier.setClassifier(v);
              },
              child: const Column(children: [
                RadioListTile<ClassifierSource>(
                  value: ClassifierSource.rules,
                  title: Text(AppStrings.classifierRules),
                ),
                RadioListTile<ClassifierSource>(
                  value: ClassifierSource.device,
                  title: Text(AppStrings.classifierDevice),
                ),
                RadioListTile<ClassifierSource>(
                  value: ClassifierSource.tflite,
                  title: Text(AppStrings.classifierTflite),
                ),
              ]),
            ),
          ),
          const SectionHeader('Device'),
          Card(
            child: Column(children: [
              ListTile(
                minTileHeight: 64,
                leading: const Icon(Icons.settings_ethernet),
                title: const Text(AppStrings.esp32Connection),
                subtitle: Text('${s.host}:${s.port}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/connect'),
              ),
              SwitchListTile(
                title: const Text(AppStrings.demoMode),
                subtitle: const Text('Simulated bands and ECG'),
                value: device.demo,
                onChanged: (v) {
                  final ctl = ref.read(deviceControllerProvider.notifier);
                  notifier.update((x) => x.copyWith(demoMode: v));
                  if (v) {
                    ctl.startDemo();
                  } else {
                    ctl.disconnect();
                  }
                },
              ),
              ListTile(
                minTileHeight: 64,
                leading: const Icon(Icons.science),
                title: const Text(AppStrings.simulator),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showSimulatorPanel(context),
              ),
            ]),
          ),
          const SectionHeader('Display and data'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.theme,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text(AppStrings.themeSystem)),
                        ButtonSegment(value: ThemeMode.light, label: Text(AppStrings.themeLight)),
                        ButtonSegment(value: ThemeMode.dark, label: Text(AppStrings.themeDark)),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (v) => notifier.setThemeMode(v.first),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: s.retentionDays,
                    decoration: const InputDecoration(labelText: AppStrings.dataRetention),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                      DropdownMenuItem(value: 30, child: Text('30 days')),
                      DropdownMenuItem(value: 90, child: Text('90 days')),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.update((x) => x.copyWith(retentionDays: v));
                    },
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.language),
                    title: Text(AppStrings.language),
                    subtitle: Text(AppStrings.languagePlaceholder),
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}
