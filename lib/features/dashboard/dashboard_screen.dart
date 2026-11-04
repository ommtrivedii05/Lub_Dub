import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/thresholds.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/device_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/risk_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/vitals_providers.dart';
import '../../shared/widgets/band_status_tile.dart';
import '../../shared/widgets/connection_chip.dart';
import '../../shared/widgets/ecg_paper_chart.dart';
import '../../shared/widgets/motion_card.dart';
import '../../shared/widgets/pulsing_heart.dart';
import '../../shared/widgets/risk_status_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/spo2_gauge.dart';
import '../../shared/widgets/vital_card.dart';
import '../settings/simulator_panel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final vitals = ref.watch(vitalsProvider).latest;
    final risk = ref.watch(riskProvider);
    final device = ref.watch(deviceControllerProvider);
    final location = ref.watch(locationProvider);
    final online = ref.watch(onlineProvider);
    final thresholds = ref.watch(settingsProvider.select((s) => s.thresholds));
    final hasData = vitals != null;

    final hr = vitals?.heartRate ?? 0;
    final spo2 = vitals?.spo2 ?? 0;
    // A fast pulse while exercising is expected, so it is not flagged.
    final exerting = (vitals?.motion.activityLevel ?? 0) >= Thresholds.highMotion;
    final hrAbnormal = hasData &&
        hr > 0 &&
        (hr < thresholds.hrLow || (hr > thresholds.hrHigh && !exerting));
    final spo2Abnormal = hasData && spo2 > 0 && spo2 < thresholds.spo2Min;
    final bad = RiskLevel.warning.color(context);
    final normalColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: kDebugMode ? () => showSimulatorPanel(context) : null,
          child: const Text(AppStrings.appName),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.settings,
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ConnectionChip(state: device.connection, demo: device.demo),
              GpsChip(live: location.live),
              if (!online) const OfflineChip(),
            ],
          ),
          const SizedBox(height: 12),
          RiskStatusCard(assessment: risk, hasData: hasData),
          if (!hasData && !device.connected && !device.demo) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bluetooth_searching),
                title: const Text(AppStrings.waitingNoDevice),
                subtitle: const Text(AppStrings.connectDevice),
                trailing: const Icon(Icons.chevron_right),
                minTileHeight: 64,
                onTap: () => context.push('/connect'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ResponsivePair(
            first: VitalCard(
              label: AppStrings.heartRate,
              value: hasData && hr > 0 ? '$hr' : '--',
              unit: AppStrings.bpm,
              color: hrAbnormal ? bad : normalColor,
              leading: PulsingHeart(bpm: hr, color: hrAbnormal ? bad : AppColors.emergency),
              semanticLabel: '${AppStrings.heartRate} ${hr > 0 ? '$hr ${AppStrings.bpm}' : 'unavailable'}'
                  '${hrAbnormal ? ', outside your range' : ''}',
              child: hrAbnormal
                  ? Row(children: [
                      Icon(Icons.warning_amber_rounded, color: bad, size: 20),
                      const SizedBox(width: 4),
                      Text(hr < thresholds.hrLow ? 'Low' : 'High',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: bad, fontWeight: FontWeight.w800)),
                    ])
                  : null,
            ),
            second: VitalCard(
              label: AppStrings.spo2,
              value: hasData && spo2 > 0 ? '$spo2' : '--',
              unit: '%',
              color: spo2Abnormal ? bad : normalColor,
              leading: const Icon(Icons.bloodtype),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Spo2Gauge(
                  spo2: spo2,
                  color: spo2Abnormal ? bad : RiskLevel.normal.color(context),
                  size: 110,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          MotionCard(motion: vitals?.motion),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/ecg'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.monitor_heart),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(AppStrings.liveEcg,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                    const SizedBox(height: 8),
                    EcgPaperChart.live(
                      buffer: ref.watch(ecgBufferProvider),
                      height: 110,
                      pxPerMm: 2.2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SectionHeader('Bands'),
          ResponsivePair(
            first: BandStatusTile(
              title: AppStrings.chestBand,
              icon: Icons.monitor_heart_outlined,
              status: vitals?.chestBand,
              isChest: true,
              onTap: () => context.push('/device'),
            ),
            second: BandStatusTile(
              title: AppStrings.wristBand,
              icon: Icons.watch,
              status: vitals?.wristBand,
              isChest: false,
              onTap: () => context.push('/device'),
            ),
          ),
          if (hasData)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${AppStrings.lastUpdated} ${Formatters.time(vitals.timestamp)}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}