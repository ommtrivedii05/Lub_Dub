import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/sensor_config.dart';
import '../data/models/health_log_entry.dart';
import '../data/models/risk_assessment.dart';
import '../data/models/vitals_packet.dart';
import '../data/repositories/vitals_repository.dart';
import '../services/classifier/ecg_analysis.dart';
import '../services/export_service.dart';
import '../services/classifier/risk_classifier.dart';
import 'risk_providers.dart';
import 'settings_providers.dart';

final vitalsRepositoryProvider = Provider<InMemoryVitalsRepository>((ref) {
  final repo = InMemoryVitalsRepository()..seedDemoHistory(DateTime.now());
  return repo;
});

/// The ring buffer the live ECG painters listen to.
final ecgBufferProvider =
    Provider<EcgRingBuffer>((ref) => ref.watch(vitalsRepositoryProvider).ecgBuffer);

class VitalsState {
  const VitalsState({this.latest, this.window = const []});

  final VitalsPacket? latest;
  final List<VitalsPacket> window;
}

class VitalsNotifier extends Notifier<VitalsState> {
  int _packetsSinceLog = 0;

  @override
  VitalsState build() => const VitalsState();

  /// Called by the device controller for every 1 Hz packet.
  void onPacket(VitalsPacket packet) {
    final repo = ref.read(vitalsRepositoryProvider);
    repo.addPacket(packet);
    final window = repo.window(SensorConfig.classifierWindowSeconds);
    state = VitalsState(latest: packet, window: window);

    final assessment =
        ref.read(riskProvider.notifier).update(VitalsWindow(window));

    // One health-log row per minute.
    _packetsSinceLog++;
    if (_packetsSinceLog >= 60) {
      _packetsSinceLog = 0;
      repo.addLog(HealthLogEntry(
        time: packet.timestamp,
        heartRate: packet.heartRate,
        spo2: packet.spo2,
        level: assessment.level,
        activityLevel: packet.motion.activityLevel,
      ));
      final days = ref.read(settingsProvider).retentionDays;
      repo.prune(DateTime.now().subtract(Duration(days: days)));
    }
  }

  void onEcgChunk(List<double> chunk) =>
      ref.read(vitalsRepositoryProvider).ecgBuffer.write(chunk);
}

final vitalsProvider =
    NotifierProvider<VitalsNotifier, VitalsState>(VitalsNotifier.new);
/// Derived ECG numbers for the live ECG screen, refreshed at the 1 Hz packet
/// rate (never at the sample rate).
class EcgMetrics {
  const EcgMetrics({this.heartRate, this.rrMs, this.motionArtifact = false, this.leadOff = false});

  final int? heartRate;
  final int? rrMs;
  final bool motionArtifact;
  final bool leadOff;
}

final ecgMetricsProvider = Provider<EcgMetrics>((ref) {
  final vitals = ref.watch(vitalsProvider);
  final latest = vitals.latest;
  if (latest == null) return const EcgMetrics();
  final analysis = EcgAnalysis.analyze(
    ref.read(ecgBufferProvider).last(SensorConfig.ecgSampleRate * 6),
  );
  final rr = analysis.rrSeconds;
  return EcgMetrics(
    heartRate: analysis.heartRate?.round(),
    rrMs: rr.isEmpty ? null : (rr.last * 1000).round(),
    motionArtifact: latest.motion.activityLevel >= 0.6,
    leadOff: latest.chestBand.leadOff || !latest.chestBand.connected,
  );
});

enum HistoryRange { hour, day, week, month }

extension HistoryRangeX on HistoryRange {
  String get label => const ['1h', '24h', '7d', '30d'][index];
  Duration get span => const [
        Duration(hours: 1),
        Duration(hours: 24),
        Duration(days: 7),
        Duration(days: 30),
      ][index];
  String get axisFormat => this == HistoryRange.hour || this == HistoryRange.day ? 'HH:mm' : 'd MMM';
}

/// Log entries inside [range], oldest first. Recomputes when the log grows.
final historyEntriesProvider =
    Provider.family<List<HealthLogEntry>, HistoryRange>((ref, range) {
  ref.watch(vitalsProvider.select((v) => v.latest?.timestamp.minute));
  final cutoff = DateTime.now().subtract(range.span);
  return ref
      .read(vitalsRepositoryProvider)
      .log
      .where((e) => !e.time.isBefore(cutoff))
      .toList();
});

/// Chart-ready aggregation of the health log for one [HistoryRange].
class HistoryView {
  const HistoryView({
    this.hr = const [],
    this.spo2 = const [],
    this.segments = const [],
    this.warningCount = 0,
    this.emergencyCount = 0,
  });

  final List<(DateTime, double)> hr;
  final List<(DateTime, double)> spo2;

  /// Worst risk level per time bucket (null = no data).
  final List<RiskLevel?> segments;
  final int warningCount;
  final int emergencyCount;
}

HistoryView buildHistoryView(
  List<HealthLogEntry> entries,
  HistoryRange range,
  DateTime now, {
  int buckets = 96,
}) {
  final start = now.subtract(range.span);
  final width = range.span.inMilliseconds / buckets;
  final hrSum = List<double>.filled(buckets, 0);
  final hrN = List<int>.filled(buckets, 0);
  final spSum = List<double>.filled(buckets, 0);
  final spN = List<int>.filled(buckets, 0);
  final worst = List<RiskLevel?>.filled(buckets, null);
  var warnings = 0;
  var emergencies = 0;
  for (final e in entries) {
    final i = ((e.time.difference(start).inMilliseconds) / width).floor();
    if (i < 0 || i >= buckets) continue;
    if (e.heartRate > 0) {
      hrSum[i] += e.heartRate;
      hrN[i]++;
    }
    if (e.spo2 > 0) {
      spSum[i] += e.spo2;
      spN[i]++;
    }
    final w = worst[i];
    if (w == null || e.level.index > w.index) worst[i] = e.level;
  }
  for (final w in worst) {
    if (w == RiskLevel.warning) warnings++;
    if (w == RiskLevel.emergency) emergencies++;
  }
  DateTime mid(int i) =>
      start.add(Duration(milliseconds: ((i + 0.5) * width).round()));
  return HistoryView(
    hr: [for (var i = 0; i < buckets; i++) if (hrN[i] > 0) (mid(i), hrSum[i] / hrN[i])],
    spo2: [for (var i = 0; i < buckets; i++) if (spN[i] > 0) (mid(i), spSum[i] / spN[i])],
    segments: worst,
    warningCount: warnings,
    emergencyCount: emergencies,
  );
}

final historyRangeProvider = StateProvider<HistoryRange>((ref) => HistoryRange.day);

final historyViewProvider = Provider<HistoryView>((ref) {
  final range = ref.watch(historyRangeProvider);
  final entries = ref.watch(historyEntriesProvider(range));
  return buildHistoryView(entries, range, DateTime.now());
});

/// Risk filter of the health log list (null = all).
final logFilterProvider = StateProvider<RiskLevel?>((ref) => null);

/// Every stored log entry, newest first, honouring [logFilterProvider].
final healthLogProvider = Provider<List<HealthLogEntry>>((ref) {
  ref.watch(vitalsProvider.select((v) => v.latest?.timestamp.minute));
  final filter = ref.watch(logFilterProvider);
  final all = ref.read(vitalsRepositoryProvider).log;
  final list = filter == null ? all : all.where((e) => e.level == filter).toList();
  return list.reversed.toList();
});

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());