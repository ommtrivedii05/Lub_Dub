import 'package:url_launcher/url_launcher.dart';

import '../data/models/alert_event.dart';
import '../data/models/emergency_contact.dart';
import '../data/models/user_profile.dart';

/// Progress of the three dispatch steps shown on the Emergency Active screen.
class DispatchProgress {
  const DispatchProgress({
    this.contactsNotified = false,
    this.gpsShared = false,
    this.responderLinkSent = false,
  });

  final bool contactsNotified;
  final bool gpsShared;
  final bool responderLinkSent;

  bool get complete => contactsNotified && gpsShared && responderLinkSent;

  DispatchProgress copyWith({
    bool? contactsNotified,
    bool? gpsShared,
    bool? responderLinkSent,
  }) {
    return DispatchProgress(
      contactsNotified: contactsNotified ?? this.contactsNotified,
      gpsShared: gpsShared ?? this.gpsShared,
      responderLinkSent: responderLinkSent ?? this.responderLinkSent,
    );
  }
}

/// Phase 1: simulated. Each step "succeeds" after a short delay.
class EmergencyDispatcher {
  Future<void> dispatch({
    required AlertEvent event,
    required List<EmergencyContact> contacts,
    required UserProfile profile,
    required GeoPoint? location,
    required void Function(DispatchProgress) onProgress,
  }) async {
    var progress = const DispatchProgress();
    void step(DispatchProgress p) {
      progress = p;
      onProgress(p);
    }

    // TODO(phase2): send an SMS to each contact (Android: SmsManager through
    //   a platform channel; iOS: server-side SMS gateway such as MSG91).
    //   Include name, reason, a maps link to `location` and the responder link.
    // TODO(phase2): place a call to the first contact (tel: intent) and fall
    //   back down the priority list when unanswered.
    // TODO(phase3): POST the event to the backend so it works when the phone
    //   has no data connection (SMS fallback) and so responders can open the
    //   link without a login; the backend returns the share URL.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    step(progress.copyWith(contactsNotified: true));
    await Future<void>.delayed(const Duration(milliseconds: 700));
    step(progress.copyWith(gpsShared: true));
    await Future<void>.delayed(const Duration(milliseconds: 900));
    step(progress.copyWith(responderLinkSent: true));
  }

  /// Warning-level heads-up to contacts that opted in. Simulated.
  Future<void> notifyWarning({
    required List<EmergencyContact> contacts,
    required AlertEvent event,
  }) async {
    // TODO(phase2): send a softer SMS ("X may be unwell") to these contacts.
  }

  /// Opens the phone dialer. Returns false if it cannot be opened.
  Future<bool> call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}