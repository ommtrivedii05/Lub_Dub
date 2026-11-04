import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/device_source.dart';
import '../data/sources/esp32_ws_source.dart';
import '../data/sources/mock_device_source.dart';
import 'vitals_providers.dart';

class DeviceState {
  const DeviceState({
    this.connection = DeviceConnectionState.disconnected,
    this.demo = false,
    this.scenario = SimScenario.normal,
    this.error,
  });

  final DeviceConnectionState connection;
  final bool demo;
  final SimScenario scenario;
  final String? error;

  bool get connected => connection == DeviceConnectionState.connected;

  DeviceState copyWith({
    DeviceConnectionState? connection,
    bool? demo,
    SimScenario? scenario,
    String? error,
    bool clearError = false,
  }) {
    return DeviceState(
      connection: connection ?? this.connection,
      demo: demo ?? this.demo,
      scenario: scenario ?? this.scenario,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DeviceController extends Notifier<DeviceState> {
  DeviceSource? _source;
  final List<StreamSubscription<Object?>> _subs = [];

  @override
  DeviceState build() {
    ref.onDispose(_teardown);
    return const DeviceState();
  }

  Future<void> _teardown() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    final old = _source;
    _source = null;
    await old?.disconnect();
    await old?.dispose();
  }

  Future<void> _attach(DeviceSource source, {required bool demo}) async {
    await _teardown();
    _source = source;
    final vitals = ref.read(vitalsProvider.notifier);
    _subs
      ..add(source.packets.listen(vitals.onPacket))
      ..add(source.ecgChunks.listen(vitals.onEcgChunk))
      ..add(source.connectionStates.listen((s) {
        state = state.copyWith(
          connection: s,
          error: source.lastError,
          clearError: source.lastError == null,
        );
      }));
    state = state.copyWith(
      demo: demo,
      connection: DeviceConnectionState.connecting,
      clearError: true,
    );
    await source.connect();
  }

  /// Starts the built-in simulator.
  Future<void> startDemo() async {
    if (state.demo && state.connected) return;
    final mock = MockDeviceSource()..setScenario(state.scenario);
    await _attach(mock, demo: true);
  }

  Future<void> connectEsp32(String host, int port) =>
      _attach(Esp32WsSource(host: host, port: port), demo: false);

  Future<void> disconnect() async {
    await _teardown();
    state = state.copyWith(
      connection: DeviceConnectionState.disconnected,
      demo: false,
      clearError: true,
    );
  }

  Future<void> reconnect() async {
    final src = _source;
    if (src == null) return startDemo();
    await src.connect();
  }

  void setScenario(SimScenario scenario) {
    state = state.copyWith(scenario: scenario);
    final src = _source;
    if (src is MockDeviceSource) src.setScenario(scenario);
  }
}

final deviceControllerProvider =
    NotifierProvider<DeviceController, DeviceState>(DeviceController.new);