import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/alert_event.dart';

/// Wraps geolocator. When GPS or permission is unavailable (emulator, demo,
/// denied permission) it falls back to a fixed demo location so the
/// emergency flow always has something to show.
class LocationService {
  static const GeoPoint demoLocation = GeoPoint(12.9716, 77.5946);

  /// Asks for location, notifications and phone access (onboarding). Each
  /// request is independent and failures (web, desktop) are ignored.
  Future<Map<String, bool>> requestAppPermissions() async {
    final result = <String, bool>{};
    Future<void> ask(String key, Permission p) async {
      try {
        result[key] = (await p.request()).isGranted;
      } catch (_) {
        result[key] = false;
      }
    }

    await ask('location', Permission.locationWhenInUse);
    await ask('notifications', Permission.notification);
    await ask('phone', Permission.phone);
    return result;
  }

  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<GeoPoint?> current() async {
    try {
      if (!await ensurePermission()) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return GeoPoint(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  Stream<GeoPoint> watch() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).map((p) => GeoPoint(p.latitude, p.longitude));
  }
}