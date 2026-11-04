import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/sensor_config.dart';
import '../data/models/alert_event.dart';
import '../data/models/risk_assessment.dart';
import '../data/models/vitals_packet.dart';
import '../data/repositories/alert_repository.dart';
import '../services/alarm_service.dart';
import '../services/alert_engine.dart';
import '../services/cpr_metronome_service.dart';
import '../services/emergency_dispatcher.dart';
import 'location_providers.dart';
import 'profile_providers.dart';
import 'settings_providers.dart';
import 'vitals_providers.dart';

final alertRepositoryProvider = Provider<InMemoryAlertRepository>((ref) {
  return InMemoryAlertRepository()..seedDemo(DateTime.now());
});

final alarmServiceProvider = Provider<AlarmService>((ref) {
  final service = AlarmService();
  ref.onDispose(service.dispose);
  return service;
});

final dispatcherProvider = Provider<EmergencyDispatcher>((ref) => EmergencyDispatcher());

/// All recorded alert events, newest first.
class AlertHistoryNotifier extends Notifier<List<AlertEvent>> {
  @override
  List<AlertEvent> build() => ref.read(alertRepositoryProvider).all();

  void add(AlertEvent e) {
    ref.read(alertRepositoryProvider).add(e);
    state = ref.read(alertRepositoryProvider).all();
  }
}

final alertHistoryProvider =
    NotifierProvider<AlertHistoryNotifier, List<AlertEvent>>(AlertHistoryNotifier.new);

/// What the alert screens need, refreshed about twice a second while active.
class AlertUiState {
  const AlertUiState({
    this.engineState = AlertState.monitoring,
    this.checkInRemaining = Duration.zero,
    this.checkInTotal = Duration.zero,
    this.countdownRemaining = Duration.zero,
    this.countdownTotal = Duration.zero,
    this.fall = false,
    this.reasons = const [],
    this.vitals,
    this.dispatch = const DispatchProgress(),
  });

  final AlertState engineState;
  final Duration checkInRemaining;
  final Duration checkInTotal;
  final Duration countdownRemaining;
  final Duration countdownTotal;
  final bool fall;
  final List<String> reasons;
  final VitalsPacket? vitals;
  final DispatchProgress dispatch;

  AlertUiState copyWith({DispatchProgress? dispatch}) => AlertUiState(
        engineState: engineState,
        checkInRemaining: checkInRemaining,
        checkInTotal: checkInTotal,
        countdownRemaining: countdownRemaining,
        countdownTotal: countdownTotal,
        fall: fall,
        reasons: reasons,
        vitals: vitals,
        dispatch: dispatch ?? this.dispatch,
      );
}

/// Glue between the pure [AlertEngine], the alarm, the dispatcher and the
/// repositories. The widgets only call its public methods.
class AlertController extends Notifier<AlertUiState> {
  late final AlertEngine _engine;
  Timer? _timer;
  DispatchProgress _dispatch = const DispatchProgress();
  AlertState _lastState = AlertState.monitoring;

  @override
  AlertUiState build() {
    _engine = AlertEngine(
      config: _config(),
      notifiedNames: () => ref
          .read(contactsProvider)
          .where((c) => c.notifyOnEmergency)
          .map((c) => '${c.name} (${c.relationship})')
          .toList(),
    );
    ref.listen(settingsProvider, (_, next) {
      _engine.config = _config();
      final alarm = ref.read(alarmServiceProvider);
      alarm.soundEnabled = next.alarmSound;
      alarm.vibrationEnabled = next.alarmVibration;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _apply(_engine.tick(DateTime.now())));
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(() => ref.read(alarmServiceProvider).init());
    return const AlertUiState();
  }

  AlertEngineConfig _config() => AlertEngineConfig(
        countdown: Duration(seconds: ref.read(settingsProvider).countdownSeconds),
      );

  void onAssessment(RiskAssessment assessment, VitalsPacket vitals) {
    final events = _engine.ingest(
      assessment: assessment,
      vitals: vitals,
      ecgStrip: ref.read(ecgBufferProvider).last(SensorConfig.alertStripSamples),
      location: ref.read(locationProvider).position,
      now: DateTime.now(),
    );
    _apply(events);
  }

  void respondOk() => _apply(_engine.respondOk(DateTime.now()));
  void cancelCountdown() => _apply(_engine.cancelCountdown(DateTime.now()));
  void requestHelp() => _apply(_engine.requestHelp(DateTime.now()));
  void resolve() => _apply(_engine.resolve(DateTime.now()));

  void _apply(List<AlertEvent> events) {
    for (final raw in events) {
      var e = raw;
      if (e.stage == AlertStage.warning) {
        final names = ref
            .read(contactsProvider)
            .where((c) => c.notifyOnWarning)
            .toList();
        if (names.isNotEmpty) {
          e = e.copyWith(notified: [for (final c in names) '${c.name} (${c.relationship})']);
          ref.read(dispatcherProvider).notifyWarning(contacts: names, event: e);
        }
      }
      ref.read(alertHistoryProvider.notifier).add(e);
      _onTransition(e);
    }
    _publish();
  }

  void _onTransition(AlertEvent e) {
    final alarm = ref.read(alarmServiceProvider);
    switch (e.stage) {
      case AlertStage.warning:
        alarm.startWarning();
        break;
      case AlertStage.emergency:
        _dispatch = const DispatchProgress();
        alarm.startEmergency();
        break;
      case AlertStage.dispatched:
        alarm.stop();
        _startDispatch(e);
        break;
      case AlertStage.resolved:
        alarm.stop();
        break;
    }
  }

  void _startDispatch(AlertEvent e) {
    _dispatch = const DispatchProgress();
    ref.read(dispatcherProvider).dispatch(
      event: e,
      contacts: ref.read(contactsProvider).where((c) => c.notifyOnEmergency).toList(),
      profile: ref.read(profileProvider),
      location: e.location,
      onProgress: (p) {
        _dispatch = p;
        _publish(force: true);
      },
    );
  }

  void _publish({bool force = false}) {
    final now = DateTime.now();
    final s = _engine.state;
    if (s == AlertState.monitoring && _lastState == AlertState.monitoring && !force) {
      return;
    }
    _lastState = s;
    state = AlertUiState(
      engineState: s,
      checkInRemaining: _engine.checkInRemaining(now),
      checkInTotal: _engine.config.checkInTimeout,
      countdownRemaining: _engine.countdownRemaining(now),
      countdownTotal: _engine.countdownTotal,
      fall: _engine.fallTriggered,
      reasons: _engine.trigger?.reasons ?? const [],
      vitals: ref.read(vitalsProvider).latest,
      dispatch: _dispatch,
    );
  }
}

final alertControllerProvider =
    NotifierProvider<AlertController, AlertUiState>(AlertController.new);


class CprState {
  const CprState({this.running = false, this.muted = false, this.elapsedSeconds = 0, this.beat = 0});

  final bool running;
  final bool muted;
  final int elapsedSeconds;
  final int beat;

  CprState copyWith({bool? running, bool? muted, int? elapsedSeconds, int? beat}) {
    return CprState(
      running: running ?? this.running,
      muted: muted ?? this.muted,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      beat: beat ?? this.beat,
    );
  }
}

/// Runs the 110 BPM metronome and the elapsed-time counter.
class CprController extends Notifier<CprState> {
  late final CprMetronomeService _metronome;
  Timer? _clock;

  @override
  CprState build() {
    _metronome = CprMetronomeService();
    ref.onDispose(() {
      _clock?.cancel();
      _metronome.dispose();
    });
    return const CprState();
  }

  void start() {
    if (state.running) return;
    _clock?.cancel();
    state = CprState(running: true, muted: state.muted);
    _metronome.muted = state.muted;
    _metronome.start((beat) => state = state.copyWith(beat: beat));
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void stop() {
    _metronome.stop();
    _clock?.cancel();
    state = state.copyWith(running: false);
  }

  void toggleMute() {
    final muted = !state.muted;
    _metronome.muted = muted;
    state = state.copyWith(muted: muted);
  }
}

final cprControllerProvider =
    NotifierProvider<CprController, CprState>(CprController.new);