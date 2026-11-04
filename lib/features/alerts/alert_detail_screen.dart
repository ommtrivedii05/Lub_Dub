import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert_event.dart';
import '../../data/models/motion_data.dart';
import '../../providers/alert_providers.dart';
import '../../shared/widgets/alert_tile.dart';
import '../../shared/widgets/ecg_paper_chart.dart';
import '../../shared/widgets/location_map_card.dart';
import '../../shared/widgets/section_header.dart';

class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(alertHistoryProvider);
    final event = events.where((e) => e.id == id).firstOrNull;
    final theme = Theme.of(context);

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text(AppStrings.alertDetail)),
        body: Center(child: Text(AppStrings.noAlerts, style: theme.textTheme.titleMedium)),
      );
    }

    final color = event.level.color(context);
    final v = event.vitals;
    final m = v?.motion;

    String posture(Posture p) => switch (p) {
          Posture.upright => AppStrings.upright,
          Posture.lying => AppStrings.lying,
          Posture.unknown => AppStrings.unknown,
        };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.alertDetail)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2),
            ),
            child: Row(children: [
              Icon(event.level.icon, color: color, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${event.level.label} - ${event.stageLabel}',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                    Text(Formatters.dateTime(event.time), style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ]),
          ),
          const SectionHeader(AppStrings.triggeringReadings),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.reasons.isEmpty)
                    Text(AppStrings.noReasons, style: theme.textTheme.titleMedium)
                  else
                    for (final r in event.reasons)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.arrow_right),
                            Expanded(child: Text(r, style: theme.textTheme.titleMedium)),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (event.ecgStrip.isNotEmpty) ...[
            const SectionHeader('ECG (last 10 s)'),
            EcgPaperChart.strip(samples: event.ecgStrip, height: 150, pxPerMm: 1.2),
          ],
          if (v != null) ...[
            const SectionHeader(AppStrings.lastVitals),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(AppStrings.heartRate,
                        v.heartRate > 0 ? '${v.heartRate} ${AppStrings.bpm}' : '--'),
                    _Line(AppStrings.spo2, v.spo2 > 0 ? '${v.spo2}%' : '--'),
                    if (m != null) ...[
                      _Line(AppStrings.activity, '${(m.activityLevel * 100).round()}%'),
                      _Line(AppStrings.posture, posture(m.posture)),
                      _Line(AppStrings.fall,
                          m.fallDetected ? AppStrings.fallDetected : AppStrings.fallNone),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SectionHeader(AppStrings.liveLocation),
          if (event.location == null)
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_off),
                title: Text(AppStrings.gpsOff),
              ),
            )
          else
            LocationMapCard(location: event.location, height: 200),
          const SectionHeader(AppStrings.notified),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: event.notified.isEmpty
                  ? Text(AppStrings.none, style: theme.textTheme.titleMedium)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final n in event.notified)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              const Icon(Icons.check_circle, color: AppColors.normal, size: 22),
                              const SizedBox(width: 8),
                              Expanded(child: Text(n, style: theme.textTheme.titleMedium)),
                            ]),
                          ),
                      ],
                    ),
            ),
          ),
          const SectionHeader(AppStrings.outcome),
          Card(
            child: ListTile(
              minTileHeight: 64,
              leading: Icon(event.outcome == AlertOutcome.pending
                  ? Icons.hourglass_empty
                  : Icons.flag_circle),
              title: Text(event.outcomeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
