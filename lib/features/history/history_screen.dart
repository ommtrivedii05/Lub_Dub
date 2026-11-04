import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/health_log_entry.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/settings_providers.dart';
import '../../providers/vitals_providers.dart';
import '../../shared/widgets/risk_timeline_bar.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/trend_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  bool _showLog = false;

  Future<void> _openExport() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _ExportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.history),
        actions: [
          IconButton(
            tooltip: AppStrings.exportData,
            icon: const Icon(Icons.ios_share),
            onPressed: _openExport,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                      value: false, icon: Icon(Icons.show_chart), label: Text(AppStrings.trends)),
                  ButtonSegment(
                      value: true, icon: Icon(Icons.list_alt), label: Text(AppStrings.healthLog)),
                ],
                selected: {_showLog},
                onSelectionChanged: (s) => setState(() => _showLog = s.first),
              ),
            ),
          ),
          Expanded(child: _showLog ? const _LogList() : const _Trends()),
        ],
      ),
    );
  }
}

class _Trends extends ConsumerWidget {
  const _Trends();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(historyRangeProvider);
    final view = ref.watch(historyViewProvider);
    final thresholds = ref.watch(settingsProvider.select((s) => s.thresholds));
    final theme = Theme.of(context);

    List<TrendPoint> pts(List<(DateTime, double)> l) =>
        [for (final p in l) TrendPoint(p.$1, p.$2)];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<HistoryRange>(
            showSelectedIcon: false,
            segments: [
              for (final r in HistoryRange.values) ButtonSegment(value: r, label: Text(r.label)),
            ],
            selected: {range},
            onSelectionChanged: (s) => ref.read(historyRangeProvider.notifier).state = s.first,
          ),
        ),
        const SectionHeader('${AppStrings.heartRate} (${AppStrings.bpm})'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: TrendChart(
              points: pts(view.hr),
              color: AppColors.emergency,
              unit: AppStrings.bpm,
              minY: 30,
              maxY: 180,
              dateFormat: range.axisFormat,
            ),
          ),
        ),
        const SectionHeader('${AppStrings.spo2} (%)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
            child: TrendChart(
              points: pts(view.spo2),
              color: theme.colorScheme.primary,
              unit: '%',
              minY: 80,
              maxY: 100,
              threshold: thresholds.spo2Min.toDouble(),
              dateFormat: range.axisFormat,
            ),
          ),
        ),
        const SectionHeader(AppStrings.riskTimeline),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RiskTimelineBar(segments: view.segments),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${view.warningCount} warning and ${view.emergencyCount} emergency periods in the last ${range.label}.',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _LogList extends ConsumerWidget {
  const _LogList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(healthLogProvider);
    final filter = ref.watch(logFilterProvider);
    final theme = Theme.of(context);

    // Flatten into day headers and rows so the list can build lazily.
    final rows = <Object>[];
    String? lastDay;
    for (final e in entries) {
      final day = Formatters.day(e.time);
      if (day != lastDay) {
        rows.add(day);
        lastDay = day;
      }
      rows.add(e);
    }

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text(AppStrings.all),
                  selected: filter == null,
                  onSelected: (_) => ref.read(logFilterProvider.notifier).state = null,
                ),
              ),
              for (final l in RiskLevel.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(l.icon, size: 18, color: l.color(context)),
                    label: Text(l.label),
                    selected: filter == l,
                    onSelected: (_) => ref.read(logFilterProvider.notifier).state = l,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(AppStrings.noData, style: theme.textTheme.titleMedium))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: rows.length,
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    if (row is String) return SectionHeader(row);
                    return _LogRow(entry: row as HealthLogEntry);
                  },
                ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final HealthLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = entry.level.color(context);
    return Semantics(
      label:
          '${Formatters.shortTime(entry.time)}, heart rate ${entry.heartRate}, SpO2 ${entry.spo2}, ${entry.level.label}',
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(Formatters.shortTime(entry.time),
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(
                  '${entry.heartRate} ${AppStrings.bpm}   ${entry.spo2 > 0 ? '${entry.spo2}%' : '--'}',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Icon(entry.level.icon, color: color, size: 22),
              const SizedBox(width: 6),
              Text(entry.level.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportSheet extends ConsumerWidget {
  const _ExportSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(historyRangeProvider);
    final entries = ref.watch(historyEntriesProvider(range));
    final service = ref.read(exportServiceProvider);
    final counts = service.countByLevel(entries);
    final theme = Theme.of(context);

    Future<void> csv() async {
      try {
        await service.shareCsv(entries);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the share sheet.')),
          );
        }
      }
    }

    Future<void> pdf() async {
      try {
        await service.exportPdf(entries);
      } on UnimplementedError {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text(AppStrings.pdfComingSoon)));
        }
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.exportData,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.medical_information_outlined, size: 20),
              const SizedBox(width: 6),
              Text(AppStrings.exportForClinical,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            Text(
              '${entries.length} readings, last ${range.label}: '
              '${counts[RiskLevel.normal]} normal, ${counts[RiskLevel.warning]} warning, '
              '${counts[RiskLevel.emergency]} emergency.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: entries.isEmpty ? null : csv,
              icon: const Icon(Icons.table_chart),
              label: const Text(AppStrings.exportCsv),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: pdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text(AppStrings.exportPdf),
            ),
          ],
        ),
      ),
    );
  }
}
