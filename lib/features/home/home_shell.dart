import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';

/// Bottom navigation around the five main tabs.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _destinations = <({IconData icon, IconData selected, String label})>[
    (icon: Icons.dashboard_outlined, selected: Icons.dashboard, label: AppStrings.navDashboard),
    (icon: Icons.monitor_heart_outlined, selected: Icons.monitor_heart, label: AppStrings.navEcg),
    (icon: Icons.insights_outlined, selected: Icons.insights, label: AppStrings.navHistory),
    (icon: Icons.notifications_none, selected: Icons.notifications, label: AppStrings.navAlerts),
    (icon: Icons.person_outline, selected: Icons.person, label: AppStrings.navProfile),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
              tooltip: d.label,
            ),
        ],
      ),
    );
  }
}