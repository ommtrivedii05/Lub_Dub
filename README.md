# LubDub (Phase 1: UI + mock data)

Mobile app of a multi-sensor-fusion cardiac risk monitoring and emergency response
system. Phase 1 has no networking, ML, backend or ABHA calls: everything sits behind
interfaces with mock implementations.

## Run

```bash
flutter pub get
flutter run                 # a connected Android/iOS device or emulator
flutter run -d chrome       # quick preview in a browser (alarm/GPS behave differently)
flutter analyze             # must stay clean
flutter test                # 28 tests: alert engine, classifier, dashboard at 200% text
```

Built with Flutter master (Dart 3.15). The code imports `package:material_ui/material_ui.dart`
because `package:flutter/material.dart` is deprecated on that channel. On older stable
releases, replace that import with `package:flutter/material.dart` and drop the
`material_ui` dependency.

## Architecture

```
lib/
  core/        constants (strings, colours, thresholds, sensor config), theme, router, utils
  data/        models (immutable, copyWith, fromJson/toJson), sources, in-memory repositories
  services/    classifiers, alert engine (pure state machine), alarm, CPR metronome, dispatcher, export
  providers/   Riverpod glue: device -> vitals -> risk -> alert
  features/    one folder per screen group
  shared/      reusable widgets
```

Data flow: `DeviceSource` (mock or ESP32) -> `VitalsNotifier` (1 Hz) -> `RiskNotifier`
(selected `RiskClassifier`) -> `AlertController` (wraps the pure `AlertEngine`, plays the
alarm, dispatches) -> `_AlertRouteListener` opens the warning / countdown / emergency
screens. ECG chunks (10 samples every 40 ms) go straight into a ring buffer that the
`CustomPainter` listens to, so widgets never rebuild at 250 Hz.

Alert state machine: Monitoring -> Warning (check-in) -> Emergency (countdown, shortened
by a fall) -> Dispatched -> Resolved. Classifier output is debounced (3 samples to
escalate, 5 to de-escalate). Only slide-to-cancel stops the countdown.

Phase 2/3 hooks are marked with `TODO(phase2)` / `TODO(phase3)`:
`esp32_ws_source.dart` (WebSocket), `emergency_dispatcher.dart` (SMS/call/backend),
`tflite_classifier.dart`, `abha_service.dart`, `export_service.dart` (PDF).

## Demo steps

1. First launch: skip the onboarding slides, tap "I understand", then **Use demo profile**
   on the setup screen (or fill the 4 steps). On Connect Device tap **Use Demo Mode**.
2. Open **Settings > Simulator** (or long-press the Dashboard title in a debug build) and
   pick a scenario, then go back to the Dashboard:

| Scenario | What to expect |
| --- | --- |
| Normal | NORMAL, HR ~72, SpO2 ~98 |
| Exercise | HR ~130 with high motion stays NORMAL ("Possible motion artifact") |
| Tachycardia | WARNING, then the "Are you OK?" screen. Tap "I'm OK" or let it time out |
| Bradycardia | WARNING (HR 44) |
| Low SpO2 | WARNING (SpO2 86%) |
| Irregular rhythm | WARNING (R-R variation), AF-like ECG on the ECG tab |
| Fall + Warning | WARNING with the fall; if unanswered it escalates with a shortened countdown |
| Full Emergency | Straight to the red countdown (15 s with the fall). Slide to cancel, or let it dispatch |
| Chest lead-off | Stays NORMAL, ECG tab shows the electrode banner, band tile explains the fix |
| Wrist band disconnected | Stays NORMAL, wrist tile shows the disconnected help text |

3. After dispatch: checklist ticks, live map, Call 112 / 108, **Open CPR guide** (START the
   110 BPM metronome), **Responder view**, then **I'm OK / Resolve**.
4. Other screens: History (trends, risk timeline, health log, export CSV), Alerts (seeded
   past incidents with ECG strips), Profile > ABHA (demo OTP `123456`), Consent, Contacts,
   Settings (thresholds, countdown 10-60 s, classifier source, theme, retention).

## Platform setup

Already applied in this repo:

* Android `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`,
  `POST_NOTIFICATIONS`, `USE_FULL_SCREEN_INTENT`, `VIBRATE`, `CALL_PHONE`, `INTERNET`,
  `ACCESS_NETWORK_STATE`, `CHANGE_WIFI_STATE`, `WAKE_LOCK`, cleartext traffic (for the
  ESP32's `ws://`), and a `tel:` query.
* iOS `Info.plist`: location usage strings, local-network usage string, local networking
  exception, `tel` query scheme, `audio` background mode.

iOS cannot place calls or send SMS silently; the Phase 2 dispatcher needs a server-side SMS
gateway for iOS.

## Known Phase 1 limits

* Everything is in memory: onboarding, profile, contacts and history reset on restart
  (history is re-seeded with 30 days of demo data).
* The "offline" chip uses a DNS lookup via `dart:io`, so on web it always shows offline.
* Contacts, SMS and calls are simulated; Call 112 / 108 open the phone dialer only.
* Not a medical device. The thresholds are illustrative, not clinically validated.
