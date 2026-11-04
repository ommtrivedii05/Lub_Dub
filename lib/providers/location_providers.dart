import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/alert_event.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationState {
  const LocationState({this.position, this.live = false});

  /// Last known position (the demo location when GPS is unavailable).
  final GeoPoint? position;

  /// True when the position came from real GPS.
  final bool live;
}

class LocationNotifier extends Notifier<LocationState> {
  StreamSubscription<GeoPoint>? _sub;

  @override
  LocationState build() {
    ref.onDispose(() => _sub?.cancel());
    state = const LocationState(position: LocationService.demoLocation);
    Future.microtask(start);
    return state;
  }

  Future<void> start() async {
    final service = ref.read(locationServiceProvider);
    final first = await service.current();
    if (first != null) {
      state = LocationState(position: first, live: true);
      _sub?.cancel();
      try {
        _sub = service.watch().listen(
              (p) => state = LocationState(position: p, live: true),
              onError: (_) {},
            );
      } catch (_) {}
    }
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);

/// Rough internet reachability for the offline indicator. The emergency flow
/// itself does not depend on it.
class OnlineNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    Future.microtask(_check);
    return true;
  }

  Future<void> _check() async {
    try {
      final r = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      state = r.isNotEmpty && r.first.rawAddress.isNotEmpty;
    } catch (_) {
      state = false;
    }
  }
}

final onlineProvider = NotifierProvider<OnlineNotifier, bool>(OnlineNotifier.new);