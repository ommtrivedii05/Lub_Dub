import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// 14 digits -> XX-XXXX-XXXX-XXXX.
  static String abhaId(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length != 14) return digits;
    return '${d.substring(0, 2)}-${d.substring(2, 6)}-${d.substring(6, 10)}-${d.substring(10)}';
  }

  static String time(DateTime t) => DateFormat('HH:mm:ss').format(t);
  static String shortTime(DateTime t) => DateFormat('HH:mm').format(t);
  static String dateTime(DateTime t) => DateFormat('d MMM, HH:mm').format(t);
  static String day(DateTime t) => DateFormat('EEE, d MMM yyyy').format(t);

  /// 95 -> "95%".
  static String percent(num v) => '${v.round()}%';

  /// 125 -> "02:05".
  static String mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String coords(double lat, double lng) =>
      '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  static String ago(DateTime t, [DateTime? now]) {
    final s = (now ?? DateTime.now()).difference(t).inSeconds;
    if (s < 5) return 'just now';
    if (s < 60) return '$s s ago';
    if (s < 3600) return '${s ~/ 60} min ago';
    if (s < 86400) return '${s ~/ 3600} h ago';
    return '${s ~/ 86400} d ago';
  }
}