import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/alerts/alert_detail_screen.dart';
import '../../features/alerts/alerts_history_screen.dart';
import '../../features/contacts/contacts_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/device/connect_device_screen.dart';
import '../../features/device/device_status_screen.dart';
import '../../features/ecg/live_ecg_screen.dart';
import '../../features/emergency/cpr_guide_screen.dart';
import '../../features/emergency/emergency_active_screen.dart';
import '../../features/emergency/emergency_countdown_screen.dart';
import '../../features/emergency/responder_view_screen.dart';
import '../../features/emergency/warning_checkin_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/abha_link_screen.dart';
import '../../features/profile/data_consent_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/setup/profile_setup_screen.dart';
import '../../features/splash/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/ecg', builder: (c, s) => const LiveEcgScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (c, s) => const HistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/alerts', builder: (c, s) => const AlertsHistoryScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
        ]),
      ],
    ),
    GoRoute(path: '/device', builder: (c, s) => const DeviceStatusScreen()),
    GoRoute(path: '/connect', builder: (c, s) => const ConnectDeviceScreen()),
    GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/setup', builder: (c, s) => const ProfileSetupScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    GoRoute(
      path: '/alert/:id',
      builder: (c, s) => AlertDetailScreen(id: s.pathParameters['id'] ?? ''),
    ),
    GoRoute(path: '/profile/abha', builder: (c, s) => const AbhaLinkScreen()),
    GoRoute(path: '/profile/consent', builder: (c, s) => const DataConsentScreen()),
    GoRoute(path: '/contacts', builder: (c, s) => const ContactsScreen()),
    GoRoute(path: '/warning', builder: (c, s) => const WarningCheckinScreen()),
    GoRoute(path: '/countdown', builder: (c, s) => const EmergencyCountdownScreen()),
    GoRoute(path: '/emergency', builder: (c, s) => const EmergencyActiveScreen()),
    GoRoute(path: '/cpr', builder: (c, s) => const CprGuideScreen()),
    GoRoute(path: '/responder', builder: (c, s) => const ResponderViewScreen()),
  ],
);