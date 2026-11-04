import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/alert_providers.dart';
import '../../shared/widgets/alert_tile.dart';

class AlertsHistoryScreen extends ConsumerStatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  ConsumerState<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends ConsumerState<AlertsHistoryScreen> {
  RiskLevel? _filter;

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(alertHistoryProvider);
    final events = _filter == null ? all : all.where((e) => e.level == _filter).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.alerts)),
      body: Column(
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
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                ),
                for (final l in const [RiskLevel.warning, RiskLevel.emergency])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(l.icon, size: 18, color: l.color(context)),
                      label: Text(l.label),
                      selected: _filter == l,
                      onSelected: (_) => setState(() => _filter = l),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(child: Text(AppStrings.noAlerts, style: theme.textTheme.titleMedium))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => AlertTile(
                      event: events[i],
                      onTap: () => context.push('/alert/${events[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
