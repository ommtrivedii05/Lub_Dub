import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/settings_providers.dart';
import '../../providers/vitals_providers.dart';
import '../../shared/widgets/ecg_paper_chart.dart';
import '../../shared/widgets/pulsing_heart.dart';

class LiveEcgScreen extends ConsumerStatefulWidget {
  const LiveEcgScreen({super.key});

  @override
  ConsumerState<LiveEcgScreen> createState() => _LiveEcgScreenState();
}

class _LiveEcgScreenState extends ConsumerState<LiveEcgScreen> {
  List<double>? _frozen;

  void _togglePause() {
    setState(() {
      if (_frozen == null) {
        final buffer = ref.read(ecgBufferProvider);
        _frozen = buffer.last(buffer.length);
      } else {
        _frozen = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final speed = ref.watch(ecgSpeedProvider);
    final gain = ref.watch(ecgGainProvider);
    final metrics = ref.watch(ecgMetricsProvider);
    final latest = ref.watch(vitalsProvider).latest;
    final hr = latest?.heartRate ?? metrics.heartRate ?? 0;
    final paused = _frozen != null;
    final warn = RiskLevel.warning.color(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.liveEcg)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (metrics.leadOff)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: warn.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: warn, width: 2),
              ),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, color: warn, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(AppStrings.leadOffBanner,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: AppStrings.heartRate,
                  value: hr > 0 ? '$hr' : '--',
                  unit: AppStrings.bpm,
                  leading: PulsingHeart(bpm: hr, color: AppColors.emergency, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Metric(
                  label: AppStrings.rrInterval,
                  value: metrics.rrMs?.toString() ?? '--',
                  unit: 'ms',
                  leading: const Icon(Icons.timer_outlined, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              EcgPaperChart.live(
                buffer: ref.watch(ecgBufferProvider),
                frozen: _frozen,
                speed: speed,
                gain: gain,
                height: 260,
              ),
              if (metrics.motionArtifact)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: warn.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: warn,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.vibration, size: 18, color: Color(0xFF1A1300)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(AppStrings.motionArtifact,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF1A1300), fontWeight: FontWeight.w800)),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
              if (paused)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Chip(
                    avatar: const Icon(Icons.pause, size: 18),
                    label: const Text(AppStrings.pause),
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${speed.toStringAsFixed(speed % 1 == 0 ? 0 : 1)} mm/s  -  ${gain.round()} mm/mV',
              textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              onPressed: _togglePause,
              icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 30),
              label: Text(paused ? AppStrings.resume : AppStrings.pause),
            ),
          ),
          const SizedBox(height: 20),
          Text(AppStrings.speed,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<double>(
            showSelectedIcon: true,
            segments: const [
              ButtonSegment(value: 12.5, label: Text('12.5')),
              ButtonSegment(value: 25, label: Text('25')),
              ButtonSegment(value: 50, label: Text('50')),
            ],
            selected: {speed},
            onSelectionChanged: (s) => ref.read(ecgSpeedProvider.notifier).state = s.first,
          ),
          const SizedBox(height: 16),
          Text(AppStrings.gain,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SegmentedButton<double>(
            showSelectedIcon: true,
            segments: const [
              ButtonSegment(value: 5, label: Text('5')),
              ButtonSegment(value: 10, label: Text('10')),
              ButtonSegment(value: 20, label: Text('20')),
            ],
            selected: {gain},
            onSelectionChanged: (s) => ref.read(ecgGainProvider.notifier).state = s.first,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.unit, required this.leading});

  final String label;
  final String value;
  final String unit;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value $unit',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                leading,
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Text(unit, style: theme.textTheme.titleMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}