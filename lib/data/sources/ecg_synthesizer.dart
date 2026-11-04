import 'dart:math';

import '../../core/constants/sensor_config.dart';

enum EcgRhythm { normalSinus, tachycardia, bradycardia, afib, vf, asystole }

/// Generates a continuous synthetic single-lead ECG (millivolts) sample by
/// sample, so chunks can be requested at any time and stay phase-continuous.
class EcgSynthesizer {
  EcgSynthesizer({this.sampleRate = SensorConfig.ecgSampleRate, int? seed})
      : _rng = Random(seed);

  final int sampleRate;
  final Random _rng;

  EcgRhythm rhythm = EcgRhythm.normalSinus;

  /// Beats per minute for regular rhythms (sinus / tachycardia / bradycardia).
  int heartRate = 72;

  /// 0..1 amount of motion-artifact noise mixed into the signal.
  double motionNoise = 0;

  /// Simulates a detached electrode: almost no signal.
  bool leadOff = false;

  int _sample = 0;
  final List<double> _beats = [];

  double _gauss() {
    // Box-Muller.
    final u1 = 1 - _rng.nextDouble();
    final u2 = _rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  /// Next [count] samples.
  List<double> nextChunk(int count) {
    final out = List<double>.filled(count, 0);
    for (var i = 0; i < count; i++) {
      out[i] = _valueAt(_sample / sampleRate);
      _sample++;
    }
    return out;
  }

  static double _g(double x, double mu, double sigma) {
    final d = x - mu;
    return exp(-(d * d) / (2 * sigma * sigma));
  }

  /// One PQRST complex relative to the R peak at dt = 0 (seconds).
  static double _template(double dt, {required bool withP}) {
    var v = 1.0 * _g(dt, 0, 0.012) +
        -0.12 * _g(dt, -0.025, 0.010) +
        -0.25 * _g(dt, 0.028, 0.011) +
        0.30 * _g(dt, 0.25, 0.05);
    if (withP) v += 0.12 * _g(dt, -0.16, 0.025);
    return v;
  }

  double _nextRr() {
    switch (rhythm) {
      case EcgRhythm.afib:
        return 60.0 / heartRate.clamp(20, 220) * (0.55 + 0.9 * _rng.nextDouble());
      default:
        final base = 60.0 / heartRate.clamp(20, 220);
        return base * (1 + 0.02 * _gauss());
    }
  }

  double _valueAt(double t) {
    if (leadOff) return 0.004 * _gauss();

    double v;
    switch (rhythm) {
      case EcgRhythm.asystole:
        v = 0.012 * _gauss() + 0.015 * sin(2 * pi * 0.25 * t);
        break;
      case EcgRhythm.vf:
        final f1 = 4.5 + 1.5 * sin(2 * pi * 0.3 * t);
        final mod = 0.6 + 0.4 * sin(2 * pi * 0.7 * t + 1);
        v = mod * (0.5 * sin(2 * pi * f1 * t) + 0.25 * sin(2 * pi * 7.3 * t + 2)) +
            0.03 * _gauss();
        break;
      default:
        while (_beats.isEmpty || _beats.last < t + 0.7) {
          _beats.add((_beats.isEmpty ? t : _beats.last) + _nextRr());
        }
        _beats.removeWhere((b) => b < t - 0.8);
        final withP = rhythm != EcgRhythm.afib;
        v = 0;
        for (final b in _beats) {
          v += _template(t - b, withP: withP);
        }
        if (!withP) v += 0.04 * sin(2 * pi * 6.5 * t + 0.4 * _gauss());
        v += 0.03 * sin(2 * pi * 0.3 * t) + 0.01 * _gauss();
    }

    if (motionNoise > 0) {
      v += motionNoise *
          (0.35 * sin(2 * pi * 1.7 * t) +
              0.3 * sin(2 * pi * 0.6 * t + 1) +
              0.25 * _gauss());
      if (_rng.nextDouble() < 0.004 * motionNoise) v += (_rng.nextDouble() - 0.5) * 1.5;
    }
    return v;
  }
}