/// Clinical-ish thresholds used by the rule-based classifier. User adjustable
/// in Settings (HR low/high, SpO2 minimum, fall sensitivity).
class Thresholds {
  const Thresholds({
    this.hrLow = 50,
    this.hrHigh = 120,
    this.spo2Min = 92,
    this.fallSensitivity = 0.5,
  });

  /// Below this is bradycardia (warning).
  final int hrLow;

  /// Above this at rest is tachycardia (warning).
  final int hrHigh;
  final int spo2Min;

  /// 0 (ignore minor falls) .. 1 (very sensitive).
  final double fallSensitivity;

  // Fixed limits.
  static const int hrCriticalLow = 40;
  static const int hrCriticalHigh = 150;
  static const int spo2Critical = 88;

  /// Above this activity level ECG anomalies are suspected motion artifact.
  static const double highMotion = 0.6;

  /// Seconds a fall stays relevant for escalation.
  static const int fallRelevantSeconds = 60;

  /// Spread (bpm) between HR sensors/ECG that counts as a disagreement.
  static const int hrDisagreement = 25;

  Thresholds copyWith({
    int? hrLow,
    int? hrHigh,
    int? spo2Min,
    double? fallSensitivity,
  }) {
    return Thresholds(
      hrLow: hrLow ?? this.hrLow,
      hrHigh: hrHigh ?? this.hrHigh,
      spo2Min: spo2Min ?? this.spo2Min,
      fallSensitivity: fallSensitivity ?? this.fallSensitivity,
    );
  }
}