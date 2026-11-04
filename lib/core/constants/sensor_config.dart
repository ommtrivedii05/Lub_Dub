class SensorConfig {
  SensorConfig._();

  /// ECG sampling rate delivered by the chest band.
  static const int ecgSampleRate = 250;

  /// ECG samples per streamed chunk (10 samples = 40 ms at 250 Hz), so the UI
  /// repaints at ~25 Hz instead of 250 Hz.
  static const int ecgChunkSamples = 10;
  static const Duration ecgChunkInterval = Duration(milliseconds: 40);

  /// Vitals packet cadence.
  static const Duration vitalsInterval = Duration(seconds: 1);

  /// Window the classifier looks at.
  static const int classifierWindowSeconds = 10;

  /// ECG strip stored with each alert event.
  static const int alertStripSeconds = 10;

  /// Ring-buffer length of the live ECG view.
  static const int ecgBufferSeconds = 12;

  /// Default WebSocket port exposed by the ESP32.
  static const int defaultPort = 81;
  static const String hotspotHost = '192.168.4.1';

  static const int ecgBufferSamples = ecgSampleRate * ecgBufferSeconds;
  static const int alertStripSamples = ecgSampleRate * alertStripSeconds;
}