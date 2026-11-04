import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/risk_assessment.dart';
import '../services/classifier/device_label_classifier.dart';
import '../services/classifier/risk_classifier.dart';
import '../services/classifier/rule_based_classifier.dart';
import '../services/classifier/tflite_classifier.dart';
import 'alert_providers.dart';
import 'settings_providers.dart';

/// The classifier chosen in Settings (and its thresholds).
final classifierProvider = Provider<RiskClassifier>((ref) {
  final settings = ref.watch(settingsProvider);
  final rules = RuleBasedClassifier(settings.thresholds);
  switch (settings.classifier) {
    case ClassifierSource.device:
      return DeviceLabelClassifier();
    case ClassifierSource.rules:
      return rules;
    case ClassifierSource.tflite:
      return TfliteClassifier(fallback: rules);
  }
});

class RiskNotifier extends Notifier<RiskAssessment> {
  @override
  RiskAssessment build() => const RiskAssessment.normal();

  /// Classifies [window], publishes the result and feeds the alert engine.
  RiskAssessment update(VitalsWindow window) {
    final assessment = ref.read(classifierProvider).assess(window);
    state = assessment;
    ref.read(alertControllerProvider.notifier).onAssessment(assessment, window.latest);
    return assessment;
  }
}

final riskProvider = NotifierProvider<RiskNotifier, RiskAssessment>(RiskNotifier.new);