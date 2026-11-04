enum Posture { upright, lying, unknown }

/// Chest-band accelerometer / gyroscope summary for one packet.
class MotionData {
  const MotionData({
    this.accelX = 0,
    this.accelY = 0,
    this.accelZ = 1,
    this.gyroX = 0,
    this.gyroY = 0,
    this.gyroZ = 0,
    this.activityLevel = 0.1,
    this.posture = Posture.upright,
    this.fallDetected = false,
    this.fallAgeSeconds,
  });

  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  /// 0 (still) .. 1 (vigorous movement).
  final double activityLevel;
  final Posture posture;
  final bool fallDetected;

  /// Seconds since the fall was detected, when [fallDetected] is true.
  final int? fallAgeSeconds;

  MotionData copyWith({
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    double? activityLevel,
    Posture? posture,
    bool? fallDetected,
    int? fallAgeSeconds,
  }) {
    return MotionData(
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      activityLevel: activityLevel ?? this.activityLevel,
      posture: posture ?? this.posture,
      fallDetected: fallDetected ?? this.fallDetected,
      fallAgeSeconds: fallAgeSeconds ?? this.fallAgeSeconds,
    );
  }

  factory MotionData.fromJson(Map<String, dynamic> json) {
    double d(String k, double def) => (json[k] as num?)?.toDouble() ?? def;
    return MotionData(
      accelX: d('accelX', 0),
      accelY: d('accelY', 0),
      accelZ: d('accelZ', 1),
      gyroX: d('gyroX', 0),
      gyroY: d('gyroY', 0),
      gyroZ: d('gyroZ', 0),
      activityLevel: d('activityLevel', 0),
      posture: Posture.values.firstWhere(
        (p) => p.name == json['posture'],
        orElse: () => Posture.unknown,
      ),
      fallDetected: json['fallDetected'] as bool? ?? false,
      fallAgeSeconds: (json['fallAgeSeconds'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'accelX': accelX,
        'accelY': accelY,
        'accelZ': accelZ,
        'gyroX': gyroX,
        'gyroY': gyroY,
        'gyroZ': gyroZ,
        'activityLevel': activityLevel,
        'posture': posture.name,
        'fallDetected': fallDetected,
        'fallAgeSeconds': fallAgeSeconds,
      };
}