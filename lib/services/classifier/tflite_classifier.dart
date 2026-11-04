import '../../data/models/risk_assessment.dart';
import 'risk_classifier.dart';

/// Phase 3: on-phone TFLite model over a fused feature window.
class TfliteClassifier implements RiskClassifier {
  TfliteClassifier({required this.fallback});

  /// Used until a model is loaded.
  final RiskClassifier fallback;

  @override
  String get id => 'tflite';

  @override
  RiskAssessment assess(VitalsWindow window) {
    // TODO(phase3): load the .tflite model with tflite_flutter, build the
    //   feature tensor (ECG window, HR, SpO2, motion) and run inference.
    // TODO(phase3): map the output probabilities to RiskLevel + confidence and
    //   attach explainability reasons.
    final base = fallback.assess(window);
    return base.copyWith(
      reasons: ['TFLite model not loaded - using rule-based fallback', ...base.reasons],
    );
  }
}