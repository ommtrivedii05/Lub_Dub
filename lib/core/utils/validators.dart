class Validators {
  Validators._();

  static String? required(String? v, [String label = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$label is required' : null;

  static String? age(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 120) return 'Enter an age between 1 and 120';
    return null;
  }

  /// ABHA numbers are 14 digits; dashes and spaces are ignored.
  static String? abhaId(String? v, {bool optional = true}) {
    final d = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (d.isEmpty) return optional ? null : 'ABHA ID is required';
    if (!RegExp(r'^\d{14}$').hasMatch(d)) return 'ABHA ID must be 14 digits';
    return null;
  }

  static String? abhaAddress(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (!RegExp(r'^[a-zA-Z0-9._]{3,}@[a-zA-Z]+$').hasMatch(s)) {
      return 'Use the form name@abdm';
    }
    return null;
  }

  static String? phone(String? v) {
    final d = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(d)) {
      return 'Enter a 10-digit mobile number';
    }
    return null;
  }

  static String? otp(String? v) =>
      RegExp(r'^\d{6}$').hasMatch(v ?? '') ? null : 'Enter the 6-digit OTP';

  /// IPv4 address or hostname.
  static String? hostOrIp(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Enter an IP address or hostname';
    final ipLike = RegExp(r'^\d+\.\d+\.\d+\.\d+$');
    if (ipLike.hasMatch(s)) {
      final ok = s.split('.').every((p) {
        final n = int.tryParse(p);
        return n != null && n >= 0 && n <= 255;
      });
      return ok ? null : 'Invalid IP address';
    }
    final host = RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9-]+)*$');
    return host.hasMatch(s) ? null : 'Invalid hostname';
  }

  static String? port(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 1 || n > 65535) return 'Port must be 1-65535';
    return null;
  }
}