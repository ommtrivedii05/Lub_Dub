import 'risk_assessment.dart';
import 'vitals_packet.dart';

/// Stage of the alert state machine that produced an [AlertEvent].
enum AlertStage { warning, emergency, dispatched, resolved }

enum AlertOutcome { pending, cancelledByUser, dispatched, resolved }

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => GeoPoint(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
}

class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.time,
    required this.level,
    required this.stage,
    this.reasons = const [],
    this.vitals,
    this.ecgStrip = const [],
    this.location,
    this.notified = const [],
    this.outcome = AlertOutcome.pending,
  });

  final String id;
  final DateTime time;
  final RiskLevel level;
  final AlertStage stage;
  final List<String> reasons;

  /// Vitals at the moment of the event.
  final VitalsPacket? vitals;

  /// Last ~10 s of ECG before the event.
  final List<double> ecgStrip;
  final GeoPoint? location;
  final List<String> notified;
  final AlertOutcome outcome;

  AlertEvent copyWith({
    RiskLevel? level,
    AlertStage? stage,
    List<String>? reasons,
    VitalsPacket? vitals,
    List<double>? ecgStrip,
    GeoPoint? location,
    List<String>? notified,
    AlertOutcome? outcome,
  }) {
    return AlertEvent(
      id: id,
      time: time,
      level: level ?? this.level,
      stage: stage ?? this.stage,
      reasons: reasons ?? this.reasons,
      vitals: vitals ?? this.vitals,
      ecgStrip: ecgStrip ?? this.ecgStrip,
      location: location ?? this.location,
      notified: notified ?? this.notified,
      outcome: outcome ?? this.outcome,
    );
  }

  factory AlertEvent.fromJson(Map<String, dynamic> json) {
    return AlertEvent(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      level: RiskLevel.values.byName(json['level'] as String),
      stage: AlertStage.values.byName(json['stage'] as String),
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      vitals: json['vitals'] == null
          ? null
          : VitalsPacket.fromJson(json['vitals'] as Map<String, dynamic>),
      ecgStrip: (json['ecgStrip'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      location: json['location'] == null
          ? null
          : GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      notified: (json['notified'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      outcome: AlertOutcome.values.byName(json['outcome'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'level': level.name,
        'stage': stage.name,
        'reasons': reasons,
        'vitals': vitals?.toJson(),
        'ecgStrip': ecgStrip,
        'location': location?.toJson(),
        'notified': notified,
        'outcome': outcome.name,
      };
}