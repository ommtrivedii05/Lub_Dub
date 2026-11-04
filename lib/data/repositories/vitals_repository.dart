import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/constants/sensor_config.dart';
import '../models/health_log_entry.dart';
import '../models/risk_assessment.dart';
import '../models/vitals_packet.dart';

/// Fixed-size ring of ECG samples. Listeners are notified after each write,
/// so a CustomPainter can repaint without any widget rebuild.
class EcgRingBuffer extends ChangeNotifier {
  EcgRingBuffer([this.capacity = SensorConfig.ecgBufferSamples])
      : _data = List<double>.filled(capacity, 0);

  final int capacity;
  final List<double> _data;
  int _head = 0;
  int _count = 0;

  int get length => _count;

  void write(List<double> samples) {
    for (final s in samples) {
      _data[_head] = s;
      _head = (_head + 1) % capacity;
    }
    _count = min(capacity, _count + samples.length);
    notifyListeners();
  }

  /// Sample [i] counted from the oldest (0) to the newest (length - 1).
  double at(int i) => _data[(_head - _count + i + capacity * 2) % capacity];

  /// The last [n] samples (or fewer), oldest first.
  List<double> last(int n) {
    final take = min(n, _count);
    return [for (var i = _count - take; i < _count; i++) at(i)];
  }

  void clear() {
    _head = 0;
    _count = 0;
    notifyListeners();
  }
}

abstract class VitalsRepository {
  EcgRingBuffer get ecgBuffer;
  VitalsPacket? get latest;
  void addPacket(VitalsPacket packet);

  /// Recent packets, oldest first.
  List<VitalsPacket> window(int seconds);

  List<HealthLogEntry> get log;
  void addLog(HealthLogEntry entry);
  void prune(DateTime cutoff);
}

class InMemoryVitalsRepository implements VitalsRepository {
  @override
  final EcgRingBuffer ecgBuffer = EcgRingBuffer();

  final List<VitalsPacket> _packets = [];
  final List<HealthLogEntry> _log = [];

  @override
  VitalsPacket? get latest => _packets.isEmpty ? null : _packets.last;

  @override
  void addPacket(VitalsPacket packet) {
    _packets.add(packet);
    if (_packets.length > 120) _packets.removeRange(0, _packets.length - 120);
  }

  @override
  List<VitalsPacket> window(int seconds) => _packets.length <= seconds
      ? List.unmodifiable(_packets)
      : List.unmodifiable(_packets.sublist(_packets.length - seconds));

  @override
  List<HealthLogEntry> get log => List.unmodifiable(_log);

  @override
  void addLog(HealthLogEntry entry) => _log.add(entry);

  @override
  void prune(DateTime cutoff) => _log.removeWhere((e) => e.time.isBefore(cutoff));

  /// Fills the log with 30 days of plausible demo history: 5-minute
  /// resolution for the last two days and 30-minute before that.
  void seedDemoHistory(DateTime now, {int days = 30, int seed = 42}) {
    final rng = Random(seed);
    final start = now.subtract(Duration(days: days));
    final fine = now.subtract(const Duration(days: 2));
    var t = start;
    while (t.isBefore(now)) {
      final hour = t.hour + t.minute / 60;
      // Circadian rhythm: lower overnight, higher in the afternoon.
      final base = 68 + 8 * sin((hour - 9) / 24 * 2 * pi);
      final active = hour > 8 && hour < 20 && rng.nextDouble() < 0.18;
      double hr = base + (active ? 25 + rng.nextInt(20) : 0) + rng.nextInt(5) - 2;
      var spo2 = 97 + rng.nextInt(3) - (rng.nextDouble() < 0.03 ? 6 : 0);
      var level = RiskLevel.normal;
      if (rng.nextDouble() < 0.004) {
        hr = 128.0 + rng.nextInt(12);
        level = RiskLevel.warning;
      }
      if (spo2 < 92) level = RiskLevel.warning;
      // One emergency blip nine days ago.
      if (now.difference(t).inDays == 9 && t.hour == 15 && t.minute == 0) {
        hr = 34.0;
        spo2 = 84;
        level = RiskLevel.emergency;
      }
      _log.add(HealthLogEntry(
        time: t,
        heartRate: hr.round(),
        spo2: spo2,
        level: level,
        activityLevel: active ? 0.7 : 0.1,
        note: level == RiskLevel.emergency ? 'Alert dispatched' : '',
      ));
      t = t.add(t.isBefore(fine) ? const Duration(minutes: 30) : const Duration(minutes: 5));
    }
  }
}