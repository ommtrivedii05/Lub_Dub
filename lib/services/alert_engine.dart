import 'dart:math';

import '../data/models/alert_event.dart';
import '../data/models/risk_assessment.dart';
import '../data/models/vitals_packet.dart';

enum AlertState { monitoring, warning, emergency, dispatched, resolved }

class AlertEngineConfig {
  const AlertEngineConfig({
    this.escalateAfter = 3,
    this.deescalateAfter = 5,
    this.checkInTimeout = const Duration(seconds: 20),
    this.countdown = const Duration(seconds: 30),
    this.snooze = const Duration(seconds: 60),
  });

  /// Consecutive classifier outputs needed to raise the stable level.
  final int escalateAfter;

  /// Consecutive classifier outputs needed to lower it again.
  final int deescalateAfter;

  /// How long the wearer has to answer "Are you OK?".
  final Duration checkInTimeout;

  /// Emergency countdown before auto-dispatch (10-60 s).
  final Duration countdown;

  /// After "I'm OK" / resolve, the same condition is ignored for this long.
  final Duration snooze;

  /// A detected fall halves the countdown (never below 10 s).
  Duration countdownFor({required bool fall}) =>
      fall ? Duration(seconds: max(10, countdown.inSeconds ~/ 2)) : countdown;

  AlertEngineConfig copyWith({
    int? escalateAfter,
    int? deescalateAfter,
    Duration? checkInTimeout,
    Duration? countdown,
    Duration? snooze,
  }) {
    return AlertEngineConfig(
      escalateAfter: escalateAfter ?? this.escalateAfter,
      deescalateAfter: deescalateAfter ?? this.deescalateAfter,
      checkInTimeout: checkInTimeout ?? this.checkInTimeout,
      countdown: countdown ?? this.countdown,
      snooze: snooze ?? this.snooze,
    );
  }
}

/// Pure state machine (no timers, no I/O). Callers feed it classifier output
/// with [ingest], call [tick] regularly, and persist the returned events.
///
/// Monitoring -> Warning -> Emergency -> Dispatched -> Resolved
class AlertEngine {
  AlertEngine({
    this.config = const AlertEngineConfig(),
    List<String> Function()? notifiedNames,
  }) : _notifiedNames = notifiedNames ?? (() => const []);

  AlertEngineConfig config;
  final List<String> Function() _notifiedNames;

  AlertState _state = AlertState.monitoring;
  RiskLevel _stable = RiskLevel.normal;
  final List<RiskLevel> _history = [];
  RiskAssessment? _trigger;
  VitalsPacket? _vitals;
  List<double> _strip = const [];
  GeoPoint? _location;

  DateTime? _checkInDeadline;
  DateTime? _countdownDeadline;
  Duration _countdownTotal = Duration.zero;
  DateTime? _snoozeUntil;
  bool _fallTriggered = false;
  int _seq = 0;

  AlertState get state => _state;
  RiskLevel get stableLevel => _stable;
  RiskAssessment? get trigger => _trigger;
  bool get fallTriggered => _fallTriggered;
  Duration get countdownTotal => _countdownTotal;

  Duration checkInRemaining(DateTime now) => _remaining(_checkInDeadline, now);
  Duration countdownRemaining(DateTime now) => _remaining(_countdownDeadline, now);

  Duration _remaining(DateTime? deadline, DateTime now) {
    if (deadline == null) return Duration.zero;
    final d = deadline.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  bool _snoozed(DateTime now) => _snoozeUntil != null && now.isBefore(_snoozeUntil!);

  /// Feed one classifier output. Returns events for any transitions.
  List<AlertEvent> ingest({
    required RiskAssessment assessment,
    required VitalsPacket vitals,
    required List<double> ecgStrip,
    GeoPoint? location,
    required DateTime now,
  }) {
    _vitals = vitals;
    _strip = ecgStrip;
    _location = location ?? _location;
    if (assessment.level != RiskLevel.normal) _trigger = assessment;
    _updateStable(assessment.level);
    return _advance(now);
  }

  /// Advance timers without new data.
  List<AlertEvent> tick(DateTime now) => _advance(now);

  /// Debounce: raise only after [escalateAfter] consecutive samples at or
  /// above the new level, lower only after [deescalateAfter] below.
  void _updateStable(RiskLevel raw) {
    _history.add(raw);
    final keep = max(config.escalateAfter, config.deescalateAfter);
    if (_history.length > keep) _history.removeRange(0, _history.length - keep);

    if (_history.length >= config.escalateAfter) {
      final recent = _history.sublist(_history.length - config.escalateAfter);
      final lowest = recent.reduce((a, b) => a.index < b.index ? a : b);
      if (lowest > _stable) _stable = lowest;
    }
    if (_history.length >= config.deescalateAfter) {
      final recent = _history.sublist(_history.length - config.deescalateAfter);
      final highest = recent.reduce((a, b) => a.index > b.index ? a : b);
      if (highest < _stable) _stable = highest;
    }
  }

  List<AlertEvent> _advance(DateTime now) {
    final events = <AlertEvent>[];
    switch (_state) {
      case AlertState.monitoring:
        if (_snoozed(now)) break;
        if (_stable == RiskLevel.emergency) {
          _enterEmergency(now, events);
        } else if (_stable == RiskLevel.warning) {
          _state = AlertState.warning;
          _checkInDeadline = now.add(config.checkInTimeout);
          events.add(_event(AlertStage.warning, RiskLevel.warning, now));
        }
        break;
      case AlertState.warning:
        if (_stable == RiskLevel.emergency) {
          _enterEmergency(now, events);
        } else if (_stable == RiskLevel.normal) {
          _state = AlertState.monitoring;
          _checkInDeadline = null;
          events.add(_event(AlertStage.resolved, RiskLevel.normal, now,
              outcome: AlertOutcome.resolved));
        } else if (!now.isBefore(_checkInDeadline ?? now)) {
          _enterEmergency(now, events);
        }
        break;
      case AlertState.emergency:
        if (!now.isBefore(_countdownDeadline ?? now)) {
          _state = AlertState.dispatched;
          events.add(_event(AlertStage.dispatched, RiskLevel.emergency, now,
              outcome: AlertOutcome.dispatched, notified: true));
        }
        break;
      case AlertState.dispatched:
        break;
      case AlertState.resolved:
        if (!_snoozed(now)) _state = AlertState.monitoring;
        break;
    }
    return events;
  }

  void _enterEmergency(DateTime now, List<AlertEvent> events) {
    _state = AlertState.emergency;
    _checkInDeadline = null;
    _fallTriggered = _vitals?.motion.fallDetected ?? false;
    _countdownTotal = config.countdownFor(fall: _fallTriggered);
    _countdownDeadline = now.add(_countdownTotal);
    events.add(_event(AlertStage.emergency, RiskLevel.emergency, now));
  }

  /// Wearer answered "Are you OK?" with "I'm OK".
  List<AlertEvent> respondOk(DateTime now) {
    if (_state != AlertState.warning) return const [];
    return [_cancel(now)];
  }

  /// Slide-to-cancel during the countdown - the only way to stop it.
  List<AlertEvent> cancelCountdown(DateTime now) {
    if (_state != AlertState.emergency) return const [];
    return [_cancel(now)];
  }

  AlertEvent _cancel(DateTime now) {
    _state = AlertState.monitoring;
    _checkInDeadline = null;
    _countdownDeadline = null;
    _snoozeUntil = now.add(config.snooze);
    _history.clear();
    _stable = RiskLevel.normal;
    return _event(AlertStage.resolved, RiskLevel.normal, now,
        outcome: AlertOutcome.cancelledByUser);
  }

  /// Wearer pressed "I need help": dispatch immediately.
  List<AlertEvent> requestHelp(DateTime now) {
    if (_state != AlertState.warning && _state != AlertState.monitoring) {
      return const [];
    }
    _state = AlertState.dispatched;
    _checkInDeadline = null;
    _fallTriggered = _vitals?.motion.fallDetected ?? false;
    return [
      _event(AlertStage.dispatched, RiskLevel.emergency, now,
          outcome: AlertOutcome.dispatched, notified: true),
    ];
  }

  /// "I'm OK / Resolve" after dispatch.
  List<AlertEvent> resolve(DateTime now) {
    if (_state != AlertState.dispatched && _state != AlertState.emergency) {
      return const [];
    }
    _state = AlertState.resolved;
    _countdownDeadline = null;
    _snoozeUntil = now.add(config.snooze);
    _history.clear();
    _stable = RiskLevel.normal;
    return [
      _event(AlertStage.resolved, RiskLevel.normal, now,
          outcome: AlertOutcome.resolved, notified: true),
    ];
  }

  AlertEvent _event(
    AlertStage stage,
    RiskLevel level,
    DateTime now, {
    AlertOutcome outcome = AlertOutcome.pending,
    bool notified = false,
  }) {
    _seq++;
    return AlertEvent(
      id: '${now.microsecondsSinceEpoch}-$_seq',
      time: now,
      level: level,
      stage: stage,
      reasons: _trigger?.reasons ?? const [],
      vitals: _vitals,
      ecgStrip: _strip,
      location: _location,
      notified: notified ? _notifiedNames() : const [],
      outcome: outcome,
    );
  }
}