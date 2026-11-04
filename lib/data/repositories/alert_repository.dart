import '../models/alert_event.dart';
import '../models/risk_assessment.dart';
import '../sources/ecg_synthesizer.dart';

abstract class AlertRepository {
  /// Newest first.
  List<AlertEvent> all();
  void add(AlertEvent event);
  AlertEvent? byId(String id);
}

class InMemoryAlertRepository implements AlertRepository {
  final List<AlertEvent> _events = [];

  @override
  List<AlertEvent> all() => List.unmodifiable(_events);

  @override
  void add(AlertEvent event) => _events.insert(0, event);

  @override
  AlertEvent? byId(String id) {
    for (final e in _events) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// A few past incidents so the Alerts screens have content in demo mode.
  void seedDemo(DateTime now) {
    List<double> strip(EcgRhythm r, int hr, int seed) {
      final s = EcgSynthesizer(seed: seed)
        ..rhythm = r
        ..heartRate = hr;
      return s.nextChunk(2500);
    }

    const home = GeoPoint(12.9716, 77.5946);
    final seeded = <AlertEvent>[
      AlertEvent(
        id: 'seed-3',
        time: now.subtract(const Duration(days: 9, hours: 2)),
        level: RiskLevel.emergency,
        stage: AlertStage.resolved,
        reasons: const ['HR 34 bpm, severe bradycardia', 'SpO2 84%, low', 'Fall detected 3 s ago'],
        ecgStrip: strip(EcgRhythm.bradycardia, 34, 3),
        location: home,
        notified: const ['Asha (daughter)', 'Dr. Rao'],
        outcome: AlertOutcome.resolved,
      ),
      AlertEvent(
        id: 'seed-2',
        time: now.subtract(const Duration(days: 9, hours: 2, minutes: 1)),
        level: RiskLevel.emergency,
        stage: AlertStage.dispatched,
        reasons: const ['HR 34 bpm, severe bradycardia', 'SpO2 84%, low', 'Fall detected 3 s ago'],
        ecgStrip: strip(EcgRhythm.bradycardia, 34, 3),
        location: home,
        notified: const ['Asha (daughter)', 'Dr. Rao'],
        outcome: AlertOutcome.dispatched,
      ),
      AlertEvent(
        id: 'seed-1',
        time: now.subtract(const Duration(days: 2, hours: 5)),
        level: RiskLevel.warning,
        stage: AlertStage.resolved,
        reasons: const ['HR 138 bpm, tachycardia'],
        ecgStrip: strip(EcgRhythm.tachycardia, 138, 1),
        location: home,
        outcome: AlertOutcome.cancelledByUser,
      ),
    ];
    _events
      ..clear()
      ..addAll(seeded);
    // Keep newest first regardless of seed order.
    _events.sort((a, b) => b.time.compareTo(a.time));
  }
}