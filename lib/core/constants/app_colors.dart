import 'package:material_ui/material_ui.dart';

import '../../data/models/risk_assessment.dart';
import 'app_strings.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF00695C);
  static const Color primaryDark = Color(0xFF4DB6AC);

  static const Color normal = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color emergency = Color(0xFFC62828);

  static const Color normalDark = Color(0xFF66BB6A);
  static const Color warningDark = Color(0xFFFFCA28);
  static const Color emergencyDark = Color(0xFFEF5350);

  static const Color backgroundLight = Color(0xFFF4F6F6);
  static const Color backgroundDark = Color(0xFF101616);
  static const Color surfaceDark = Color(0xFF1B2323);

  static const Color ecgPaperLight = Color(0xFFFFF1F1);
  static const Color ecgGridMinor = Color(0xFFF3C6C6);
  static const Color ecgGridMajor = Color(0xFFE59A9A);

  static Color forLevel(RiskLevel level, {bool dark = false}) {
    switch (level) {
      case RiskLevel.normal:
        return dark ? normalDark : normal;
      case RiskLevel.warning:
        return dark ? warningDark : warning;
      case RiskLevel.emergency:
        return dark ? emergencyDark : emergency;
    }
  }

  /// Text colour that is readable on top of [forLevel].
  static Color onLevel(RiskLevel level) =>
      level == RiskLevel.warning ? const Color(0xFF1A1300) : Colors.white;

  static IconData iconForLevel(RiskLevel level) {
    switch (level) {
      case RiskLevel.normal:
        return Icons.check_circle;
      case RiskLevel.warning:
        return Icons.warning_amber_rounded;
      case RiskLevel.emergency:
        return Icons.emergency;
    }
  }
}
extension RiskLevelUi on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.normal:
        return AppStrings.riskNormal;
      case RiskLevel.warning:
        return AppStrings.riskWarning;
      case RiskLevel.emergency:
        return AppStrings.riskEmergency;
    }
  }

  IconData get icon => AppColors.iconForLevel(this);

  Color color(BuildContext context) =>
      AppColors.forLevel(this, dark: Theme.of(context).brightness == Brightness.dark);
}