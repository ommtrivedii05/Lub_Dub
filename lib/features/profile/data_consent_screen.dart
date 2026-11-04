import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../providers/profile_providers.dart';

/// Explains and controls what first responders can see.
class DataConsentScreen extends ConsumerWidget {
  const DataConsentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = ref.watch(profileProvider.select((p) => p.shareWithResponders));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.dataConsent)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(AppStrings.shareWithResponders,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              subtitle: Text(share ? 'On' : 'Off'),
              value: share,
              onChanged: (v) => ref
                  .read(profileProvider.notifier)
                  .update((p) => p.copyWith(shareWithResponders: v)),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.consentIntro,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final item in AppStrings.consentItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(share ? Icons.check_circle : Icons.lock_outline,
                      color: share ? theme.colorScheme.primary : theme.hintColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: theme.textTheme.titleMedium)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'You can turn this off at any time. Your ABHA ID and name are always '
            'visible to responders so they can identify you.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
