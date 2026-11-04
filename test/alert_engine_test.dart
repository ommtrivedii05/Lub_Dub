import 'package:cardio_guard/data/models/alert_event.dart';
import 'package:cardio_guard/data/models/motion_data.dart';
import 'package:cardio_guard/data/models/risk_assessment.dart';
import 'package:cardio_guard/data/models/vitals_packet.dart';
import 'package:cardio_guard/services/alert_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final t0 = DateTime(2025, 1, 1, 12);

class Harness {
  Harness({AlertEngineConfig? config})
      : engine = AlertEngine(
          config: config ?? const AlertEngineConfig(),
          notifiedNames: () => const ['Asha (daughter)'],
        );

  final AlertEngine engine;
  final List<AlertEvent> events = [];
  DateTime now = t0;

  VitalsPacket packet({bool fall = false}) => VitalsPacket(
        timestamp: now,
        heartRate: 70,
        spo2: 97,
        motion: MotionData(fallDetected: fall, fallAgeSeconds: fall ? 2 : null),
      );

  /// One second passes with the classifier reporting [level].
  void step(RiskLevel level, {bool fall = false}) {
    now = now.add(const Duration(seconds: 1));
    events.addAll(engine.ingest(
      assessment: RiskAssessment(level: level, reasons: ['r']),
      vitals: packet(fall: fall),
      ecgStrip: const [0.0, 1.0],
      now: now,
    ));
  }

  void steps(RiskLevel level, int n, {bool fall = false}) {
    for (var i = 0; i < n; i++) {
      step(level, fall: fall);
    }
  }

  void idle(int seconds) {
    now = now.add(Duration(seconds: seconds));
    events.addAll(engine.tick(now));
  }
}

void main() {
  test('a single warning sample is debounced', () {
    final h = Harness();
    h.step(RiskLevel.warning);
    h.step(RiskLevel.normal);
    expect(h.engine.state, AlertState.monitoring);
    expect(h.events, isEmpty);
  });

  test('flapping between normal and warning never alarms', () {
    final h = Harness();
    for (var i = 0; i < 20; i++) {
      h.step(i.isEven ? RiskLevel.warning : RiskLevel.normal);
    }
    expect(h.engine.state, AlertState.monitoring);
    expect(h.events, isEmpty);
  });

  test('sustained warning enters the warning state and writes an event', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    expect(h.engine.state, AlertState.warning);
    expect(h.events.single.stage, AlertStage.warning);
    expect(h.events.single.reasons, ['r']);
    expect(h.events.single.ecgStrip, isNotEmpty);
  });

  test('warning escalates when unanswered and the condition persists', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    h.steps(RiskLevel.warning, 10);
    expect(h.engine.state, AlertState.warning);
    h.steps(RiskLevel.warning, 12);
    expect(h.engine.state, AlertState.emergency);
    expect(h.events.last.stage, AlertStage.emergency);
  });

  test('warning that clears before the timeout returns to monitoring', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    h.steps(RiskLevel.normal, 5);
    expect(h.engine.state, AlertState.monitoring);
    expect(h.events.last.outcome, AlertOutcome.resolved);
  });

  test('"I\'m OK" at the check-in cancels and snoozes the same condition', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    h.events.addAll(h.engine.respondOk(h.now));
    expect(h.engine.state, AlertState.monitoring);
    expect(h.events.last.outcome, AlertOutcome.cancelledByUser);
    h.steps(RiskLevel.warning, 20);
    expect(h.engine.state, AlertState.monitoring, reason: 'snoozed');
  });

  test('emergency runs a countdown then auto-dispatches', () {
    final h = Harness();
    h.steps(RiskLevel.emergency, 3);
    expect(h.engine.state, AlertState.emergency);
    expect(h.engine.countdownTotal, const Duration(seconds: 30));
    h.idle(29);
    expect(h.engine.state, AlertState.emergency);
    h.idle(1);
    expect(h.engine.state, AlertState.dispatched);
    expect(h.events.last.stage, AlertStage.dispatched);
    expect(h.events.last.notified, ['Asha (daughter)']);
  });

  test('a detected fall shortens the countdown', () {
    final h = Harness();
    h.steps(RiskLevel.emergency, 3, fall: true);
    expect(h.engine.countdownTotal, const Duration(seconds: 15));
    expect(h.engine.fallTriggered, isTrue);
    h.idle(15);
    expect(h.engine.state, AlertState.dispatched);
  });

  test('countdown is configurable and never below 10 s with a fall', () {
    const cfg = AlertEngineConfig(countdown: Duration(seconds: 10));
    expect(cfg.countdownFor(fall: true), const Duration(seconds: 10));
    expect(cfg.countdownFor(fall: false), const Duration(seconds: 10));
  });

  test('cancelling the countdown prevents dispatch', () {
    final h = Harness();
    h.steps(RiskLevel.emergency, 3);
    h.idle(10);
    h.events.addAll(h.engine.cancelCountdown(h.now));
    expect(h.engine.state, AlertState.monitoring);
    h.idle(60);
    expect(h.events.where((e) => e.stage == AlertStage.dispatched), isEmpty);
    expect(h.events.last.outcome, AlertOutcome.cancelledByUser);
  });

  test('a recovering classifier does not cancel the countdown', () {
    final h = Harness();
    h.steps(RiskLevel.emergency, 3);
    h.steps(RiskLevel.normal, 10);
    expect(h.engine.state, AlertState.emergency);
  });

  test('resolve after dispatch ends the incident', () {
    final h = Harness();
    h.steps(RiskLevel.emergency, 3);
    h.idle(30);
    h.events.addAll(h.engine.resolve(h.now));
    expect(h.engine.state, AlertState.resolved);
    expect(h.events.last.outcome, AlertOutcome.resolved);
    h.idle(61);
    expect(h.engine.state, AlertState.monitoring);
  });

  test('"I need help" dispatches immediately', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    h.events.addAll(h.engine.requestHelp(h.now));
    expect(h.engine.state, AlertState.dispatched);
  });

  test('every transition writes exactly one event', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3); // -> warning
    h.steps(RiskLevel.emergency, 3); // -> emergency
    h.idle(30); // -> dispatched
    h.events.addAll(h.engine.resolve(h.now)); // -> resolved
    expect(h.events.map((e) => e.stage).toList(), [
      AlertStage.warning,
      AlertStage.emergency,
      AlertStage.dispatched,
      AlertStage.resolved,
    ]);
    expect(h.events.map((e) => e.id).toSet().length, 4);
  });

  test('recovery needs sustained normal readings (hysteresis)', () {
    final h = Harness();
    h.steps(RiskLevel.warning, 3);
    h.steps(RiskLevel.normal, 4);
    expect(h.engine.state, AlertState.warning);
    h.step(RiskLevel.normal);
    expect(h.engine.state, AlertState.monitoring);
  });
}