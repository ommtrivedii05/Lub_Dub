import 'dart:async';
import 'dart:math';

import '../../core/constants/sensor_config.dart';
import '../models/band_status.dart';
import '../models/motion_data.dart';
import '../models/risk_assessment.dart';
import '../models/vitals_packet.dart';
import 'device_source.dart';
import 'ecg_synthesizer.dart';

enum SimScenario {
  normal,
  exercise,
  tachycardia,
  bradycardia,
  lowSpo2,
  irregular,
  fallWarning,
  fullEmergency,
  chestLeadOff,
  wristDisconnected,
}

class ScenarioProfile {
  const ScenarioProfile({
    required this.label,
    required this.description,
    required this.hr,
    required this.spo2,
    required this.rhythm,
    this.activity = 0.1,
    this.posture = Posture.upright,
    this.fall = false,
    this.motionNoise = 0,
    this.chestLeadOff = false,
    this.wristOff = false,
    this.deviceLevel = RiskLevel.normal,
    this.deviceReason = '',
    this.hrJitter = 2,
  });

  final String label;
  final String description;
  final int hr;
  final int spo2;
  final EcgRhythm rhythm;
  final double activity;
  final Posture posture;
  final bool fall;
  final double motionNoise;
  final bool chestLeadOff;
  final bool wristOff;
  final RiskLevel deviceLevel;
  final String deviceReason;
  final int hrJitter;
}

extension SimScenarioX on SimScenario {
  ScenarioProfile get profile {
    switch (this) {
      case SimScenario.normal:
        return const ScenarioProfile(
          label: 'Normal',
          description: 'Resting, healthy readings.',
          hr: 72,
          spo2: 98,
          rhythm: EcgRhythm.normalSinus,
        );
      case SimScenario.exercise:
        return const ScenarioProfile(
          label: 'Exercise',
          description: 'High HR with high motion. Must not alarm.',
          hr: 135,
          spo2: 96,
          rhythm: EcgRhythm.tachycardia,
          activity: 0.85,
          motionNoise: 0.45,
          hrJitter: 4,
        );
      case SimScenario.tachycardia:
        return const ScenarioProfile(
          label: 'Tachycardia',
          description: 'Fast heart rate at rest.',
          hr: 145,
          spo2: 96,
          rhythm: EcgRhythm.tachycardia,
          deviceLevel: RiskLevel.warning,
          deviceReason: 'HR high',
        );
      case SimScenario.bradycardia:
        return const ScenarioProfile(
          label: 'Bradycardia',
          description: 'Slow heart rate.',
          hr: 44,
          spo2: 96,
          rhythm: EcgRhythm.bradycardia,
          deviceLevel: RiskLevel.warning,
          deviceReason: 'HR low',
        );
      case SimScenario.lowSpo2:
        return const ScenarioProfile(
          label: 'Low SpO2',
          description: 'Oxygen saturation dropping.',
          hr: 96,
          spo2: 86,
          rhythm: EcgRhythm.normalSinus,
          deviceLevel: RiskLevel.warning,
          deviceReason: 'SpO2 low',
        );
      case SimScenario.irregular:
        return const ScenarioProfile(
          label: 'Irregular rhythm',
          description: 'AF-like irregular R-R intervals.',
          hr: 108,
          spo2: 96,
          rhythm: EcgRhythm.afib,
          deviceLevel: RiskLevel.warning,
          deviceReason: 'Irregular rhythm',
          hrJitter: 8,
        );
      case SimScenario.fallWarning:
        return const ScenarioProfile(
          label: 'Fall + Warning',
          description: 'Fall detected, lying still, vitals borderline.',
          hr: 112,
          spo2: 95,
          rhythm: EcgRhythm.normalSinus,
          activity: 0.05,
          posture: Posture.lying,
          fall: true,
          deviceLevel: RiskLevel.warning,
          deviceReason: 'Fall detected',
        );
      case SimScenario.fullEmergency:
        return const ScenarioProfile(
          label: 'Full Emergency',
          description: 'Flatline ECG, SpO2 drop and a fall.',
          hr: 22,
          spo2: 78,
          rhythm: EcgRhythm.asystole,
          activity: 0.03,
          posture: Posture.lying,
          fall: true,
          deviceLevel: RiskLevel.emergency,
          deviceReason: 'ECG flatline, SpO2 critical, fall',
          hrJitter: 1,
        );
      case SimScenario.chestLeadOff:
        return const ScenarioProfile(
          label: 'Chest lead-off',
          description: 'An ECG electrode has come off.',
          hr: 72,
          spo2: 98,
          rhythm: EcgRhythm.normalSinus,
          chestLeadOff: true,
        );
      case SimScenario.wristDisconnected:
        return const ScenarioProfile(
          label: 'Wrist band disconnected',
          description: 'No SpO2 or wrist heart rate.',
          hr: 72,
          spo2: 0,
          rhythm: EcgRhythm.normalSinus,
          wristOff: true,
        );
    }
  }
}

/// Simulated ESP32: 1 Hz vitals packets and 10-sample ECG chunks every 40 ms.
class MockDeviceSource implements DeviceSource {
  MockDeviceSource({int? seed, EcgSynthesizer? synthesizer})
      : _rng = Random(seed),
        _synth = synthesizer ?? EcgSynthesizer(seed: seed) {
    _applyProfile();
  }

  final Random _rng;
  final EcgSynthesizer _synth;

  final _packets = StreamController<VitalsPacket>.broadcast();
  final _chunks = StreamController<List<double>>.broadcast();
  final _states = StreamController<DeviceConnectionState>.broadcast();

  DeviceConnectionState _state = DeviceConnectionState.disconnected;
  SimScenario _scenario = SimScenario.normal;
  DateTime _scenarioStart = DateTime.now();
  Timer? _vitalsTimer;
  Timer? _chunkTimer;
  final List<double> _secondBuffer = [];
  double _battery = 87;

  SimScenario get scenario => _scenario;

  @override
  Stream<VitalsPacket> get packets => _packets.stream;
  @override
  Stream<List<double>> get ecgChunks => _chunks.stream;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;
  @override
  DeviceConnectionState get connectionState => _state;
  @override
  String? get lastError => null;

  void setScenario(SimScenario s) {
    _scenario = s;
    _scenarioStart = DateTime.now();
    _applyProfile();
  }

  void _applyProfile() {
    final p = _scenario.profile;
    _synth
      ..rhythm = p.rhythm
      ..heartRate = p.hr.clamp(20, 220)
      ..motionNoise = p.motionNoise
      ..leadOff = p.chestLeadOff;
  }

  void _setState(DeviceConnectionState s) {
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  @override
  Future<void> connect() async {
    if (_state == DeviceConnectionState.connected) return;
    _setState(DeviceConnectionState.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _chunkTimer = Timer.periodic(SensorConfig.ecgChunkInterval, (_) => _emitChunk());
    _vitalsTimer = Timer.periodic(SensorConfig.vitalsInterval, (_) => _emitPacket());
    _setState(DeviceConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _chunkTimer?.cancel();
    _vitalsTimer?.cancel();
    _chunkTimer = null;
    _vitalsTimer = null;
    _setState(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _packets.close();
    await _chunks.close();
    await _states.close();
  }

  void _emitChunk() {
    final chunk = _synth.nextChunk(SensorConfig.ecgChunkSamples);
    _secondBuffer.addAll(chunk);
    if (!_chunks.isClosed) _chunks.add(chunk);
  }

  /// Synchronously generates one second of ECG into the packet buffer (tests).
  void pumpSecond() {
    const chunks = SensorConfig.ecgSampleRate ~/ SensorConfig.ecgChunkSamples;
    for (var i = 0; i < chunks; i++) {
      _secondBuffer.addAll(_synth.nextChunk(SensorConfig.ecgChunkSamples));
    }
  }

  void _emitPacket() {
    if (_packets.isClosed) return;
    _packets.add(buildPacket());
  }

  /// Builds the packet for the current scenario. Public for tests.
  VitalsPacket buildPacket({DateTime? now}) {
    final p = _scenario.profile;
    final t = now ?? DateTime.now();
    final fallAge = p.fall ? 4 + t.difference(_scenarioStart).inSeconds : null;
    final ecg = List<double>.from(_secondBuffer);
    _secondBuffer.clear();
    _battery = max(5, _battery - 0.01);

    double j(double amp) => (_rng.nextDouble() * 2 - 1) * amp;
    final hr = p.hr == 0 ? 0 : max(0, p.hr + (j(p.hrJitter.toDouble())).round());
    final spo2 = p.wristOff ? 0 : (p.spo2 + j(1).round()).clamp(0, 100);
    final level = p.deviceLevel;

    return VitalsPacket(
      timestamp: t,
      heartRate: hr,
      spo2: spo2,
      ecgSamples: ecg,
      motion: MotionData(
        accelX: j(0.3) + p.activity,
        accelY: j(0.3),
        accelZ: p.posture == Posture.lying ? j(0.1) : 1 + j(0.1),
        gyroX: j(10 + 150 * p.activity),
        gyroY: j(10 + 150 * p.activity),
        gyroZ: j(10 + 150 * p.activity),
        activityLevel: (p.activity + j(0.05)).clamp(0.0, 1.0),
        posture: p.posture,
        fallDetected: p.fall,
        fallAgeSeconds: fallAge,
      ),
      chestBand: BandStatus(
        connected: true,
        leadOff: p.chestLeadOff,
        batteryPercent: _battery.round(),
        signalQuality: p.chestLeadOff ? 0.05 : (0.93 - p.motionNoise * 0.3),
      ),
      wristBand: BandStatus(
        connected: !p.wristOff,
        fingerOff: false,
        batteryPercent: p.wristOff ? 0 : (_battery - 6).round(),
        signalQuality: p.wristOff ? 0 : 0.88,
      ),
      deviceRisk: RiskAssessment(
        level: level,
        confidence: 0.8,
        reasons: p.deviceReason.isEmpty ? const [] : [p.deviceReason],
      ),
    );
  }
}