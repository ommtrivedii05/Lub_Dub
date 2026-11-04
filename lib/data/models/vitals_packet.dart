import 'band_status.dart';
import 'motion_data.dart';
import 'risk_assessment.dart';

/// One fused reading from the ESP32. Vitals arrive about once a second; the
/// ECG samples in a packet are a chunk (about 250 Hz) and may be empty.
class VitalsPacket {
  const VitalsPacket({
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    this.ecgSamples = const [],
    this.motion = const MotionData(),
    this.chestBand = const BandStatus(),
    this.wristBand = const BandStatus(),
    this.deviceRisk,
  });

  final DateTime timestamp;
  final int heartRate;
  final int spo2;
  final List<double> ecgSamples;
  final MotionData motion;
  final BandStatus chestBand;
  final BandStatus wristBand;

  /// Label produced by the classifier running on the ESP32, if any.
  final RiskAssessment? deviceRisk;

  VitalsPacket copyWith({
    DateTime? timestamp,
    int? heartRate,
    int? spo2,
    List<double>? ecgSamples,
    MotionData? motion,
    BandStatus? chestBand,
    BandStatus? wristBand,
    RiskAssessment? deviceRisk,
  }) {
    return VitalsPacket(
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      spo2: spo2 ?? this.spo2,
      ecgSamples: ecgSamples ?? this.ecgSamples,
      motion: motion ?? this.motion,
      chestBand: chestBand ?? this.chestBand,
      wristBand: wristBand ?? this.wristBand,
      deviceRisk: deviceRisk ?? this.deviceRisk,
    );
  }

  factory VitalsPacket.fromJson(Map<String, dynamic> json) {
    return VitalsPacket(
      timestamp: DateTime.parse(json['timestamp'] as String),
      heartRate: (json['heartRate'] as num).toInt(),
      spo2: (json['spo2'] as num).toInt(),
      ecgSamples: (json['ecgSamples'] as List<dynamic>? ?? const [])
          .map((e) => (e as num).toDouble())
          .toList(),
      motion: json['motion'] == null
          ? const MotionData()
          : MotionData.fromJson(json['motion'] as Map<String, dynamic>),
      chestBand: json['chestBand'] == null
          ? const BandStatus()
          : BandStatus.fromJson(json['chestBand'] as Map<String, dynamic>),
      wristBand: json['wristBand'] == null
          ? const BandStatus()
          : BandStatus.fromJson(json['wristBand'] as Map<String, dynamic>),
      deviceRisk: json['deviceRisk'] == null
          ? null
          : RiskAssessment.fromJson(json['deviceRisk'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'heartRate': heartRate,
        'spo2': spo2,
        'ecgSamples': ecgSamples,
        'motion': motion.toJson(),
        'chestBand': chestBand.toJson(),
        'wristBand': wristBand.toJson(),
        'deviceRisk': deviceRisk?.toJson(),
      };
}