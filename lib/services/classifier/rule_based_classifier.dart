import '../../core/constants/thresholds.dart';
import '../../data/models/motion_data.dart';
import '../../data/models/risk_assessment.dart';
import 'ecg_analysis.dart';
import 'risk_classifier.dart';

/// Multi-sensor fusion rules:
///  * ECG anomalies during high motion are downgraded to "possible motion
///    artifact" (so exercise never alarms);
///  * a fall plus abnormal vitals escalates to emergency;
///  * wrist HR and ECG HR disagreeing lowers confidence;
///  * ECG flatline with a pulse at the wrist is an electrode problem, not
///    cardiac arrest.
class RuleBasedClassifier implements RiskClassifier {
  const RuleBasedClassifier([this.thresholds = const Thresholds()]);

  final Thresholds thresholds;

  @override
  String get id => 'rules';

  @override
  RiskAssessment assess(VitalsWindow window) {
    if (window.isEmpty) return const RiskAssessment.normal();
    final p = window.latest;
    final t = thresholds;

    final reasons = <String>[];
    final notes = <String>[];
    var confidence = 0.92;

    final ecgUsable = p.chestBand.usable && p.chestBand.signalQuality >= 0.3;
    final wristUsable = p.wristBand.usable;
    final hrUsable = wristUsable && p.heartRate > 0;
    final spo2Usable = wristUsable && p.spo2 > 0;

    if (!p.chestBand.connected) {
      notes.add('Chest band offline - ECG and motion not monitored');
    } else if (p.chestBand.leadOff) {
      notes.add('Chest electrode off - ECG not monitored');
    }
    if (!p.wristBand.connected) {
      notes.add('Wrist band offline - HR and SpO2 from ECG only');
    } else if (p.wristBand.fingerOff) {
      notes.add('Wrist sensor off skin - HR and SpO2 unavailable');
    }

    final highMotion = window.recentActivity() >= Thresholds.highMotion;
    var abnormal = 0;
    var critical = false;
    var artifact = false;
    var flatline = false;
    var fibrillation = false;
    final hr = p.heartRate;

    // Heart rate (wrist). High HR during exertion is expected.
    if (hrUsable) {
      if (hr < Thresholds.hrCriticalLow) {
        reasons.add('HR $hr bpm, severe bradycardia');
        abnormal++;
        critical = true;
      } else if (hr < t.hrLow) {
        reasons.add('HR $hr bpm, bradycardia');
        abnormal++;
      } else if (!highMotion && hr > Thresholds.hrCriticalHigh) {
        reasons.add('HR $hr bpm, severe tachycardia');
        abnormal++;
        critical = true;
      } else if (!highMotion && hr > t.hrHigh) {
        reasons.add('HR $hr bpm, tachycardia');
        abnormal++;
      }
    }

    if (spo2Usable && p.spo2 < t.spo2Min) {
      if (p.spo2 < Thresholds.spo2Critical) {
        reasons.add('SpO2 ${p.spo2}%, critically low');
        critical = true;
      } else {
        reasons.add('SpO2 ${p.spo2}%, low');
      }
      abnormal++;
    }

    // ECG shape / rhythm.
    if (ecgUsable) {
      final ecg = EcgAnalysis.analyze(window.ecg);
      if (ecg.flatline) {
        if (hrUsable && hr >= Thresholds.hrCriticalLow) {
          reasons.add('ECG flatline but pulse detected - check electrodes');
          abnormal++;
          confidence *= 0.6;
        } else {
          flatline = true;
          reasons.add('ECG flatline pattern');
          abnormal++;
          critical = true;
        }
      } else if (ecg.chaotic) {
        if (highMotion) {
          artifact = true;
        } else {
          fibrillation = true;
          reasons.add('Chaotic ECG, possible fibrillation');
          abnormal++;
          critical = true;
        }
      } else if (ecg.irregular) {
        if (highMotion) {
          artifact = true;
        } else {
          reasons.add(
              'Irregular rhythm, R-R variation ${(ecg.rrVariation * 100).round()}%');
          abnormal++;
        }
      }

      final ecgHr = ecg.heartRate;
      if (hrUsable &&
          ecgHr != null &&
          !flatline &&
          !fibrillation &&
          !artifact &&
          (ecgHr - hr).abs() > Thresholds.hrDisagreement) {
        confidence *= 0.65;
        notes.add('HR sensors disagree (wrist $hr, ECG ${ecgHr.round()} bpm)');
      }
    }

    if (artifact) {
      confidence *= 0.7;
      notes.add('Possible motion artifact');
    }

    // Fall (motion sensor) fused with the vitals.
    var fall = false;
    final m = p.motion;
    final fallAge = m.fallAgeSeconds ?? 0;
    if (t.fallSensitivity >= 0.1 &&
        m.fallDetected &&
        fallAge <= Thresholds.fallRelevantSeconds) {
      fall = true;
      reasons.add('Fall detected $fallAge s ago');
    }

    final fallEscalates = fall &&
        (abnormal > 0 ||
            (t.fallSensitivity >= 0.8 && m.posture == Posture.lying));

    final emergency = flatline ||
        fibrillation ||
        fallEscalates ||
        (critical && abnormal >= 2) ||
        abnormal >= 3;
    final warning = abnormal > 0 || fall;

    final level = emergency
        ? RiskLevel.emergency
        : (warning ? RiskLevel.warning : RiskLevel.normal);

    // Weak signals make every judgement less certain.
    final qualities = <double>[
      if (ecgUsable) p.chestBand.signalQuality,
      if (wristUsable) p.wristBand.signalQuality,
    ];
    if (qualities.isEmpty) {
      confidence *= 0.4;
    } else {
      final q = qualities.reduce((a, b) => a < b ? a : b);
      confidence *= 0.6 + 0.4 * q;
    }
    if (!ecgUsable || !wristUsable) confidence *= 0.75;

    return RiskAssessment(
      level: level,
      confidence: confidence.clamp(0.05, 0.99),
      reasons: [...reasons, ...notes],
    );
  }
}