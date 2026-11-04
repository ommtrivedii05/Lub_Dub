import 'package:cardio_guard/core/constants/app_strings.dart';
import 'package:cardio_guard/core/theme/app_theme.dart';
import 'package:cardio_guard/features/dashboard/dashboard_screen.dart';
import 'package:cardio_guard/providers/location_providers.dart';
import 'package:cardio_guard/providers/vitals_providers.dart';
import 'package:cardio_guard/data/models/vitals_packet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeOnline extends OnlineNotifier {
  @override
  bool build() => true;
}

class _FakeLocation extends LocationNotifier {
  @override
  LocationState build() => const LocationState();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('dashboard shows the waiting state, then live vitals at 200% text',
      (tester) async {
    final container = ProviderContainer(overrides: [
      onlineProvider.overrideWith(_FakeOnline.new),
      locationProvider.overrideWith(_FakeLocation.new),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2.0),
          ),
          child: DashboardScreen(),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text(AppStrings.waitingForData), findsOneWidget);

    container.read(vitalsProvider.notifier).onPacket(
          VitalsPacket(timestamp: DateTime(2025, 1, 1, 12), heartRate: 72, spo2: 98),
        );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(AppStrings.riskNormal), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}