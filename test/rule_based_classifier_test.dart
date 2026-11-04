import 'package:cardio_guard/core/constants/sensor_config.dart';
import 'package:cardio_guard/data/models/band_status.dart';
import 'package:cardio_guard/data/models/risk_assessment.dart';
import 'package:cardio_guard/data/models/vitals_packet.dart';
import 'package:cardio_guard/data/sources/ecg_synthesizer.dart';
import 'package:cardio_guard/data/sources/mock_device_source.dart';
import 'package:cardio_guard/services/classifier/risk_classifier.dart';
import 'package:cardio_guard/services/classifier/rule_based_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs the simulator for [seconds] without timers and returns the window.
VitalsWindow windowFor(SimScenario scenario, {int seconds = 10}) {
  final source = MockDeviceSource(seed: 7)..setScenario(scenario);
  final t0 = DateTime(2025, 1, 1, 12);
  // Feed ECG chunks like the real stream would.
  final packets = <VitalsPacket>[];
  for (var s = 0; s < seconds; s++) {
    source.pumpSecond();
    packets.add(source.buildPacket(now: t0.add(Duration(seconds: s))));
  }
  return VitalsWindow(packets);
}

void main() {
  const classifier = RuleBasedClassifier();

  RiskAssessment run(SimScenario s) => classifier.assess(windowFor(s));

  test('ECG samples per simulated second match the sample rate', () {
    final w = windowFor(SimScenario.normal, seconds: 3);
    expect(w.packets.last.ecgSamples.length, SensorConfig.ecgSampleRate);
  });

  test('normal is normal', () {
    expect(run(SimScenario.normal).level, RiskLevel.normal);
  });

  test('exercise (high HR + high motion) must not alarm', () {
    final a = run(SimScenario.exercise);
    expect(a.level, RiskLevel.normal);
  });

  test('tachycardia / bradycardia / low SpO2 / irregular warn', () {
    for (final s in [
      SimScenario.tachycardia,
      SimScenario.bradycardia,
      SimScenario.lowSpo2,
      SimScenario.irregular,
    ]) {
      final a = run(s);
      expect(a.level, RiskLevel.warning, reason: '$s -> ${a.reasons}');
      expect(a.reasons, isNotEmpty);
    }
  });

  test('fall with borderline vitals is a warning', () {
    final a = run(SimScenario.fallWarning);
    expect(a.level, RiskLevel.warning);
    expect(a.reasons.any((r) => r.startsWith('Fall detected')), isTrue);
  });

  test('flatline + SpO2 drop + fall is an emergency', () {
    final a = run(SimScenario.fullEmergency);
    expect(a.level, RiskLevel.emergency);
    expect(a.reasons, contains('ECG flatline pattern'));
  });

  test('fall plus abnormal vitals escalates to emergency', () {
    final w = windowFor(SimScenario.fallWarning);
    final last = w.latest.copyWith(spo2: 84);
    final escalated = classifier.assess(
      VitalsWindow([...w.packets.sublist(0, w.packets.length - 1), last]),
    );
    expect(escalated.level, RiskLevel.emergency);
  });

  test('lead-off and disconnected wrist do not alarm', () {
    final lead = run(SimScenario.chestLeadOff);
    expect(lead.level, RiskLevel.normal);
    expect(lead.reasons.join(), contains('electrode'));
    final wrist = run(SimScenario.wristDisconnected);
    expect(wrist.level, RiskLevel.normal);
  });

  test('ECG anomaly during high motion becomes motion artifact', () {
    final w = windowFor(SimScenario.irregular);
    final moving = w.packets
        .map((p) => p.copyWith(motion: p.motion.copyWith(activityLevel: 0.9)))
        .toList();
    final a = classifier.assess(VitalsWindow(moving));
    expect(a.level, RiskLevel.normal);
    expect(a.reasons, contains('Possible motion artifact'));
  });

  test('HR and ECG disagreement lowers confidence', () {
    final w = windowFor(SimScenario.normal);
    final base = classifier.assess(w);
    final bad = w.packets.map((p) => p.copyWith(heartRate: 100)).toList();
    final a = classifier.assess(VitalsWindow(bad));
    expect(a.confidence, lessThan(base.confidence));
    expect(a.reasons.join(), contains('disagree'));
  });

  test('flatline with a pulse at the wrist is not cardiac arrest', () {
    final w = windowFor(SimScenario.fullEmergency);
    final pulse = w.packets
        .map((p) => p.copyWith(
              heartRate: 70,
              spo2: 98,
              motion: p.motion.copyWith(fallDetected: false),
              wristBand: const BandStatus(),
            ))
        .toList();
    final a = classifier.assess(VitalsWindow(pulse));
    expect(a.level, isNot(RiskLevel.emergency));
  });
test('VF-like chaotic ECG is an emergency, but not during exercise', () {
    final source = MockDeviceSource(seed: 3)..setScenario(SimScenario.normal);
    final t0 = DateTime(2025, 1, 1);
    final packets = <VitalsPacket>[];
    // Normal vitals, but the ECG is switched to VF.
    source.setScenario(SimScenario.fullEmergency);
    for (var s = 0; s < 8; s++) {
      source.pumpSecond();
      packets.add(source.buildPacket(now: t0.add(Duration(seconds: s))));
    }
    // Re-use asystole packets' structure with synthesized VF samples.
    final vf = EcgSynthesizer(seed: 1)..rhythm = EcgRhythm.vf;
    final vfPackets = [
      for (final p in packets)
        p.copyWith(
          heartRate: 150,
          spo2: 97,
          ecgSamples: vf.nextChunk(250),
          motion: p.motion.copyWith(fallDetected: false),
        ),
    ];
    final a = classifier.assess(VitalsWindow(vfPackets));
    expect(a.level, RiskLevel.emergency, reason: '${a.reasons}');
    final moving = [
      for (final p in vfPackets)
        p.copyWith(motion: p.motion.copyWith(activityLevel: 0.9)),
    ];
    expect(classifier.assess(VitalsWindow(moving)).level, RiskLevel.normal);
  });
}
