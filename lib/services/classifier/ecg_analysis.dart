import 'dart:math';

import '../../core/constants/sensor_config.dart';

/// Simple feature extraction on an ECG window: R peaks, R-R intervals and
/// shape statistics used to tell sinus rhythm, AF-like, VF-like and flatline.
class EcgAnalysis {
  EcgAnalysis._({
    required this.length,
    required this.sampleRate,
    required this.std,
    required this.kurtosis,
    required this.rPeaks,
  });

  final int length;
  final int sampleRate;
  final double std;
  final double kurtosis;
  final List<int> rPeaks;

  factory EcgAnalysis.analyze(
    List<double> x, {
    int sampleRate = SensorConfig.ecgSampleRate,
  }) {
    if (x.isEmpty) {
      return EcgAnalysis._(
        length: 0,
        sampleRate: sampleRate,
        std: 0,
        kurtosis: 0,
        rPeaks: const [],
      );
    }
    final n = x.length;
    final mean = x.reduce((a, b) => a + b) / n;
    var m2 = 0.0;
    var m4 = 0.0;
    var maxAbs = 0.0;
    final c = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final d = x[i] - mean;
      c[i] = d;
      m2 += d * d;
      m4 += d * d * d * d;
      maxAbs = max(maxAbs, d.abs());
    }
    m2 /= n;
    m4 /= n;
    final std = sqrt(m2);
    final kurt = m2 < 1e-12 ? 0.0 : m4 / (m2 * m2);

    final peaks = <int>[];
    if (std >= 0.03) {
      final thr = 0.5 * maxAbs;
      final half = (0.06 * sampleRate).round();
      final refractory = (0.25 * sampleRate).round();
      for (var i = half; i < n - half; i++) {
        if (c[i] < thr) continue;
        var isMax = true;
        for (var k = i - half; k <= i + half; k++) {
          if (c[k] > c[i]) {
            isMax = false;
            break;
          }
        }
        if (!isMax) continue;
        if (peaks.isNotEmpty && i - peaks.last < refractory) continue;
        peaks.add(i);
      }
    }
    return EcgAnalysis._(
      length: n,
      sampleRate: sampleRate,
      std: std,
      kurtosis: kurt,
      rPeaks: peaks,
    );
  }

  double get seconds => length / sampleRate;

  /// Enough data to judge the rhythm.
  bool get hasSignal => seconds >= 3;

  bool get flatline => hasSignal && std < 0.03;

  /// Large, smooth, spike-free oscillation: VF-like.
  bool get chaotic => hasSignal && std > 0.12 && kurtosis < 4;

  List<double> get rrSeconds => [
        for (var i = 1; i < rPeaks.length; i++)
          (rPeaks[i] - rPeaks[i - 1]) / sampleRate,
      ];

  double? get heartRate {
    final rr = rrSeconds;
    if (rr.isEmpty) return null;
    return 60 / (rr.reduce((a, b) => a + b) / rr.length);
  }

  /// Coefficient of variation of R-R intervals.
  double get rrVariation {
    final rr = rrSeconds;
    if (rr.length < 4) return 0;
    final mean = rr.reduce((a, b) => a + b) / rr.length;
    final v = rr.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / rr.length;
    return sqrt(v) / mean;
  }

  bool get irregular => rrSeconds.length >= 5 && rrVariation > 0.18;
}