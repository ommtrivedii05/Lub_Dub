import 'dart:convert';

import 'package:share_plus/share_plus.dart';

import '../data/models/health_log_entry.dart';
import '../data/models/risk_assessment.dart';

class ExportService {
  static const header = 'timestamp,heart_rate_bpm,spo2_percent,risk_level,activity,note';

  /// CSV for clinical review. Fields with commas / quotes are escaped.
  String buildCsv(List<HealthLogEntry> entries) {
    String esc(String s) =>
        s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    final b = StringBuffer()..writeln(header);
    for (final e in entries) {
      b.writeln([
        e.time.toIso8601String(),
        e.heartRate,
        e.spo2,
        e.level.name,
        e.activityLevel.toStringAsFixed(2),
        esc(e.note),
      ].join(','));
    }
    return b.toString();
  }

  Future<void> shareCsv(List<HealthLogEntry> entries) async {
    final bytes = utf8.encode(buildCsv(entries));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/csv')],
      fileNameOverrides: ['cardioguard_health_log.csv'],
      subject: 'CardioGuard health log (for clinical review)',
    );
  }

  Future<void> exportPdf(List<HealthLogEntry> entries) async {
    // TODO(phase3): render a clinical summary (trends, alerts, ECG strips)
    //   with the `pdf` package and share it.
    throw UnimplementedError('PDF export is not available yet');
  }

  /// Summary counts used by the export sheet.
  Map<RiskLevel, int> countByLevel(List<HealthLogEntry> entries) {
    final out = {for (final l in RiskLevel.values) l: 0};
    for (final e in entries) {
      out[e.level] = out[e.level]! + 1;
    }
    return out;
  }
}