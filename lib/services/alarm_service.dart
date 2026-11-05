import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

/// Local alarm: looping siren, vibration and heads-up notification. Every
/// platform call is guarded, so the alarm never throws into the alert flow.
class AlarmService {
  AlarmService();

  final AudioPlayer _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsReady = false;
  bool _playing = false;

  bool soundEnabled = true;
  bool vibrationEnabled = true;

  static Uint8List? _soft;
  static Uint8List? _loud;

  /// 16-bit mono PCM WAV of an alternating two-tone siren.
  static Uint8List buildSiren({
    required double lowHz,
    required double highHz,
    required double secondsPerTone,
    int tones = 2,
    int sampleRate = 16000,
  }) {
    final perTone = (sampleRate * secondsPerTone).round();
    final n = perTone * tones;
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
      final freq = (i ~/ perTone).isEven ? lowHz : highHz;
      final env = min(1.0, min(i % perTone, perTone - i % perTone) / 200);
      final v = sin(2 * pi * freq * i / sampleRate) * 0.8 * env;
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  Future<void> init() async {
    try {
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _notificationsReady = true;
    } catch (_) {
      _notificationsReady = false;
    }
  }

  /// Gentle repeating tone for the "Are you OK?" check-in.
  Future<void> startWarning() async {
    _soft ??= buildSiren(lowHz: 660, highHz: 880, secondsPerTone: 0.6);
    await _start(_soft!, vibrate: false);
    await notify('Are you OK?', 'LubDub noticed something unusual.');
  }

  /// Loud siren with continuous vibration.
  Future<void> startEmergency() async {
    _loud ??= buildSiren(lowHz: 700, highHz: 1400, secondsPerTone: 0.35);
    await _start(_loud!, vibrate: true);
    await notify('EMERGENCY', 'Slide to cancel if you are OK. Help will be called.');
  }

  Future<void> _start(Uint8List wav, {required bool vibrate}) async {
    await stop();
    if (soundEnabled) {
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(1);
        await _player.play(BytesSource(wav));
        _playing = true;
      } catch (_) {}
    }
    if (vibrate && vibrationEnabled) {
      try {
        if (await Vibration.hasVibrator()) {
          await Vibration.vibrate(pattern: [0, 600, 300, 600, 300], repeat: 0);
        } else {
          await HapticFeedback.vibrate();
        }
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    try {
      if (_playing) await _player.stop();
      _playing = false;
      await Vibration.cancel();
    } catch (_) {}
  }

  Future<void> notify(String title, String body) async {
    if (!_notificationsReady) return;
    try {
      await _notifications.show(
        id: 1,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'cardioguard_alerts',
            'Cardiac alerts',
            importance: Importance.max,
            priority: Priority.high,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(interruptionLevel: InterruptionLevel.critical),
        ),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}