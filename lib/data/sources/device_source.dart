import '../models/vitals_packet.dart';

enum DeviceConnectionState { disconnected, connecting, connected, failed }

/// Where vitals come from: the ESP32 over WebSocket, or the simulator.
abstract class DeviceSource {
  /// Fused vitals, about once per second. Each packet carries the ECG
  /// samples of the second it covers (for the classifier and alert strips).
  Stream<VitalsPacket> get packets;

  /// Small ECG chunks (10 samples every 40 ms) for the live trace, so the UI
  /// never updates at the 250 Hz sample rate.
  Stream<List<double>> get ecgChunks;

  Stream<DeviceConnectionState> get connectionStates;
  DeviceConnectionState get connectionState;
  String? get lastError;

  Future<void> connect();
  Future<void> disconnect();
  Future<void> dispose();
}