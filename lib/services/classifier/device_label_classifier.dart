import '../../data/models/risk_assessment.dart';
import 'risk_classifier.dart';

/// Trusts the label computed on the ESP32.
class DeviceLabelClassifier implements RiskClassifier {
  @override
  String get id => 'device';

  @override
  RiskAssessment assess(VitalsWindow window) {
    if (window.isEmpty) return const RiskAssessment.normal();
    return window.latest.deviceRisk ??
        const RiskAssessment(
          level: RiskLevel.normal,
          confidence: 0.3,
          reasons: ['No risk label received from the device'],
        );
  }
}