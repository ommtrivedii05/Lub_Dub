import 'risk_assessment.dart';

/// One row of the long-term health log (a downsampled vitals reading).
class HealthLogEntry {
  const HealthLogEntry({
    required this.time,
    required this.heartRate,
    required this.spo2,
    required this.level,
    this.activityLevel = 0,
    this.note = '',
  });

  final DateTime time;
  final int heartRate;
  final int spo2;
  final RiskLevel level;
  final double activityLevel;
  final String note;

  HealthLogEntry copyWith({
    DateTime? time,
    int? heartRate,
    int? spo2,
    RiskLevel? level,
    double? activityLevel,
    String? note,
  }) {
    return HealthLogEntry(
      time: time ?? this.time,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      level: level ?? this.level,
      activityLevel: activityLevel ?? this.activityLevel,
      note: note ?? this.note,
    );
  }

  factory HealthLogEntry.fromJson(Map<String, dynamic> json) {
    return HealthLogEntry(
      time: DateTime.parse(json['time'] as String),
      heartRate: (json['heartRate'] as num).toInt(),
      spo2: (json['spo2'] as num).toInt(),
      level: RiskLevel.values.byName(json['level'] as String),
      activityLevel: (json['activityLevel'] as num?)?.toDouble() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'heartRate': heartRate,
        'spo2': spo2,
        'level': level.name,
        'activityLevel': activityLevel,
        'note': note,
      };
}