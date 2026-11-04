/// State of one wearable band (chest band: ECG + motion, wrist band: SpO2 + HR).
class BandStatus {
  const BandStatus({
    this.connected = true,
    this.leadOff = false,
    this.fingerOff = false,
    this.batteryPercent = 100,
    this.signalQuality = 1.0,
  });

  /// Band is reachable by the ESP32.
  final bool connected;

  /// Chest band only: an ECG electrode is not touching the skin.
  final bool leadOff;

  /// Wrist band only: the optical sensor has lost contact with the skin.
  final bool fingerOff;
  final int batteryPercent;

  /// 0..1, where 1 is a perfect signal.
  final double signalQuality;

  /// True when the band is delivering usable data.
  bool get usable => connected && !leadOff && !fingerOff;

  BandStatus copyWith({
    bool? connected,
    bool? leadOff,
    bool? fingerOff,
    int? batteryPercent,
    double? signalQuality,
  }) {
    return BandStatus(
      connected: connected ?? this.connected,
      leadOff: leadOff ?? this.leadOff,
      fingerOff: fingerOff ?? this.fingerOff,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      signalQuality: signalQuality ?? this.signalQuality,
    );
  }

  factory BandStatus.fromJson(Map<String, dynamic> json) {
    return BandStatus(
      connected: json['connected'] as bool? ?? true,
      leadOff: json['leadOff'] as bool? ?? false,
      fingerOff: json['fingerOff'] as bool? ?? false,
      batteryPercent: (json['batteryPercent'] as num?)?.toInt() ?? 100,
      signalQuality: (json['signalQuality'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'connected': connected,
        'leadOff': leadOff,
        'fingerOff': fingerOff,
        'batteryPercent': batteryPercent,
        'signalQuality': signalQuality,
      };
}