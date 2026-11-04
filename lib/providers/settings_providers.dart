import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/constants/sensor_config.dart';
import '../core/constants/thresholds.dart';

enum ClassifierSource { device, rules, tflite }

enum ConnectionMode { hotspot, network }

class SettingsState {
  const SettingsState({
    this.thresholds = const Thresholds(),
    this.countdownSeconds = 30,
    this.alarmSound = true,
    this.alarmVibration = true,
    this.classifier = ClassifierSource.rules,
    this.themeMode = ThemeMode.system,
    this.retentionDays = 30,
    this.demoMode = true,
    this.connectionMode = ConnectionMode.hotspot,
    this.host = SensorConfig.hotspotHost,
    this.port = SensorConfig.defaultPort,
  });

  final Thresholds thresholds;

  /// 10-60 s.
  final int countdownSeconds;
  final bool alarmSound;
  final bool alarmVibration;
  final ClassifierSource classifier;
  final ThemeMode themeMode;
  final int retentionDays;
  final bool demoMode;
  final ConnectionMode connectionMode;
  final String host;
  final int port;

  SettingsState copyWith({
    Thresholds? thresholds,
    int? countdownSeconds,
    bool? alarmSound,
    bool? alarmVibration,
    ClassifierSource? classifier,
    ThemeMode? themeMode,
    int? retentionDays,
    bool? demoMode,
    ConnectionMode? connectionMode,
    String? host,
    int? port,
  }) {
    return SettingsState(
      thresholds: thresholds ?? this.thresholds,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      alarmSound: alarmSound ?? this.alarmSound,
      alarmVibration: alarmVibration ?? this.alarmVibration,
      classifier: classifier ?? this.classifier,
      themeMode: themeMode ?? this.themeMode,
      retentionDays: retentionDays ?? this.retentionDays,
      demoMode: demoMode ?? this.demoMode,
      connectionMode: connectionMode ?? this.connectionMode,
      host: host ?? this.host,
      port: port ?? this.port,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() => const SettingsState();

  void update(SettingsState Function(SettingsState s) change) => state = change(state);

  void setThresholds(Thresholds t) => state = state.copyWith(thresholds: t);
  void setCountdown(int seconds) =>
      state = state.copyWith(countdownSeconds: seconds.clamp(10, 60));
  void setClassifier(ClassifierSource c) => state = state.copyWith(classifier: c);
  void setThemeMode(ThemeMode m) => state = state.copyWith(themeMode: m);
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// Axis display preferences of the live ECG, shared with the mini ECG.
final ecgSpeedProvider = StateProvider<double>((ref) => 25);
final ecgGainProvider = StateProvider<double>((ref) => 10);