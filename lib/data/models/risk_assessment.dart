enum RiskLevel { normal, warning, emergency }

extension RiskLevelX on RiskLevel {
  int get severity => index;
  bool operator >(RiskLevel other) => index > other.index;
  bool operator <(RiskLevel other) => index < other.index;
}

/// Output of a classifier: a risk level, how sure it is, and why.
class RiskAssessment {
  const RiskAssessment({
    required this.level,
    this.confidence = 1.0,
    this.reasons = const [],
  });

  const RiskAssessment.normal()
      : level = RiskLevel.normal,
        confidence = 1.0,
        reasons = const [];

  final RiskLevel level;

  /// 0..1.
  final double confidence;
  final List<String> reasons;

  RiskAssessment copyWith({
    RiskLevel? level,
    double? confidence,
    List<String>? reasons,
  }) {
    return RiskAssessment(
      level: level ?? this.level,
      confidence: confidence ?? this.confidence,
      reasons: reasons ?? this.reasons,
    );
  }

  factory RiskAssessment.fromJson(Map<String, dynamic> json) {
    return RiskAssessment(
      level: RiskLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => RiskLevel.normal,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'confidence': confidence,
        'reasons': reasons,
      };
}