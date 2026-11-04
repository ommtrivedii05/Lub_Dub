import '../../data/models/risk_assessment.dart';
import '../../data/models/vitals_packet.dart';

/// Recent packets (oldest first) handed to a classifier.
class VitalsWindow {
  const VitalsWindow(this.packets);

  final List<VitalsPacket> packets;

  bool get isEmpty => packets.isEmpty;
  VitalsPacket get latest => packets.last;

  /// ECG of the whole window, in time order.
  List<double> get ecg => [for (final p in packets) ...p.ecgSamples];

  /// Mean activity of the last [n] packets.
  double recentActivity([int n = 3]) {
    final recent = packets.length > n ? packets.sublist(packets.length - n) : packets;
    if (recent.isEmpty) return 0;
    return recent.map((p) => p.motion.activityLevel).reduce((a, b) => a + b) /
        recent.length;
  }
}

abstract class RiskClassifier {
  String get id;
  RiskAssessment assess(VitalsWindow window);
}