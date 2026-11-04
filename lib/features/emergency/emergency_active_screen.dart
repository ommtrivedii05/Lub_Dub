import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/emergency_numbers.dart';
import '../../providers/alert_providers.dart';
import '../../providers/location_providers.dart';
import '../../shared/widgets/connection_chip.dart';
import '../../shared/widgets/location_map_card.dart';
import '../../shared/widgets/section_header.dart';

/// Shown after dispatch: checklist, live map and the quick actions.
class EmergencyActiveScreen extends ConsumerWidget {
  const EmergencyActiveScreen({super.key});

  Future<void> _call(BuildContext context, WidgetRef ref, String number) async {
    final ok = await ref.read(dispatcherProvider).call(number);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.callFailed)));
    }
  }

  Future<void> _confirmResolve(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.resolveTitle),
        content: const Text(AppStrings.resolveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.confirm),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(alertControllerProvider.notifier).resolve();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(alertControllerProvider);
    final location = ref.watch(locationProvider);
    final online = ref.watch(onlineProvider);
    final theme = Theme.of(context);
    final d = alert.dispatch;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.emergency,
          foregroundColor: Colors.white,
          title: const Text(AppStrings.emergencyActive),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (!online) const Align(alignment: Alignment.centerLeft, child: OfflineChip()),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _Step(label: AppStrings.contactsNotified, done: d.contactsNotified),
                    _Step(label: AppStrings.gpsShared, done: d.gpsShared),
                    _Step(label: AppStrings.responderLinkSent, done: d.responderLinkSent),
                  ],
                ),
              ),
            ),
            const SectionHeader(AppStrings.liveLocation),
            LocationMapCard(location: location.position, height: 220),
            const SizedBox(height: 16),
            _BigButton(
              icon: Icons.call,
              label: AppStrings.call112,
              color: AppColors.emergency,
              onPressed: () => _call(context, ref, EmergencyNumbers.national),
            ),
            const SizedBox(height: 10),
            _BigButton(
              icon: Icons.local_hospital,
              label: AppStrings.callAmbulance,
              color: const Color(0xFFD84315),
              onPressed: () => _call(context, ref, EmergencyNumbers.ambulance),
            ),
            const SizedBox(height: 10),
            _BigButton(
              icon: Icons.favorite,
              label: AppStrings.openCpr,
              color: const Color(0xFF00695C),
              onPressed: () => context.push('/cpr'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/responder'),
              icon: const Icon(Icons.badge),
              label: const Text(AppStrings.responderView),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.onSurface),
              onPressed: () => _confirmResolve(context, ref),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(AppStrings.imOkResolve),
            ),
            const SizedBox(height: 8),
            Text(AppStrings.disclaimerFooter,
                textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label, ${done ? AppStrings.dispatchDone : AppStrings.dispatchPending}',
      excludeSemantics: true,
      child: ListTile(
        minTileHeight: 56,
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: done
              ? const Icon(Icons.check_circle,
                  key: ValueKey('done'), color: AppColors.normal, size: 32)
              : const SizedBox(
                  key: ValueKey('wait'),
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
        ),
        title: Text(label,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        trailing: Text(done ? AppStrings.dispatchDone : AppStrings.dispatchPending),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
        onPressed: onPressed,
        icon: Icon(icon, size: 30),
        label: Text(label, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
