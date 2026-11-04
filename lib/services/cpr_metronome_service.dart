import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Metronome for chest compressions: 110 beats per minute with an audible
/// click and a haptic tap on every beat.
class CprMetronomeService {
  CprMetronomeService({this.bpm = 110});

  final int bpm;
  final AudioPlayer _player = AudioPlayer();
  Timer? _timer;
  int _beat = 0;
  static Uint8List? _click;

  bool muted = false;
  bool get running => _timer != null;

  Duration get interval => Duration(microseconds: (60000000 / bpm).round());

  static Uint8List buildClick({int sampleRate = 16000}) {
    final n = (sampleRate * 0.06).round();
    final data = ByteData(44 + n * 2);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        data.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final env = exp(-i / (n / 5));
      final v = sin(2 * pi * 1000 * i / sampleRate) * env * 0.9;
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  /// Starts beating; [onBeat] receives the beat count (1, 2, 3, ...).
  void start(void Function(int beat) onBeat) {
    stop();
    _beat = 0;
    _click ??= buildClick();
    void fire() {
      _beat++;
      onBeat(_beat);
      HapticFeedback.heavyImpact();
      if (!muted) {
        _player.play(BytesSource(_click!), mode: PlayerMode.lowLatency).catchError((_) {});
      }
    }

    fire();
    _timer = Timer.periodic(interval, (_) => fire());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    stop();
    await _player.dispose();
  }
}