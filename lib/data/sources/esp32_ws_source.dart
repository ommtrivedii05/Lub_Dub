import 'dart:async';

import '../models/vitals_packet.dart';
import 'device_source.dart';

/// Phase 2: real ESP32 link over WebSocket. Phase 1 is a stub that reports a
/// connection failure so the Connect Device screen can show its error path.
class Esp32WsSource implements DeviceSource {
  Esp32WsSource({required this.host, this.port = 81});

  final String host;
  final int port;

  final _packets = StreamController<VitalsPacket>.broadcast();
  final _chunks = StreamController<List<double>>.broadcast();
  final _states = StreamController<DeviceConnectionState>.broadcast();
  DeviceConnectionState _state = DeviceConnectionState.disconnected;
  String? _error;

  @override
  Stream<VitalsPacket> get packets => _packets.stream;
  @override
  Stream<List<double>> get ecgChunks => _chunks.stream;
  @override
  Stream<DeviceConnectionState> get connectionStates => _states.stream;
  @override
  DeviceConnectionState get connectionState => _state;
  @override
  String? get lastError => _error;

  void _set(DeviceConnectionState s) {
    _state = s;
    _states.add(s);
  }

  @override
  Future<void> connect() async {
    _set(DeviceConnectionState.connecting);
    // TODO(phase2): open ws://$host:$port with WebSocketChannel.connect and
    //   listen for frames; reconnect with exponential backoff.
    // TODO(phase2): decode JSON frames: {"type":"vitals", ...} ->
    //   VitalsPacket.fromJson; {"type":"ecg","samples":[...]} -> _chunks.add.
    // TODO(phase2): heartbeat/ping; mark failed after 5 s without frames.
    // TODO(phase2): parse the optional on-device risk label into
    //   VitalsPacket.deviceRisk.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _error = 'Live ESP32 link arrives in Phase 2. Use Demo Mode for now.';
    _set(DeviceConnectionState.failed);
  }

  @override
  Future<void> disconnect() async {
    // TODO(phase2): close the WebSocket sink.
    _set(DeviceConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await _packets.close();
    await _chunks.close();
    await _states.close();
  }
}