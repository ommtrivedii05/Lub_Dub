import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../providers/alert_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/profile_providers.dart';
import '../../providers/vitals_providers.dart';
import '../../shared/widgets/ecg_paper_chart.dart';
import '../../shared/widgets/location_map_card.dart';
import '../../shared/widgets/section_header.dart';

/// Read-only, no-login view for first responders.
class ResponderViewScreen extends ConsumerWidget {
  const ResponderViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final contacts = ref.watch(contactsProvider);
    final vitals = ref.watch(vitalsProvider).latest;
    final location = ref.watch(locationProvider);
    final history = ref.watch(alertHistoryProvider);
    final theme = Theme.of(context);
    final share = profile.shareWithResponders;
    final buffer = ref.watch(ecgBufferProvider);
    final strip = buffer.length > 250
        ? buffer.last(2500)
        : (history.isNotEmpty ? history.first.ecgStrip : const <double>[]);

    String list(List<String> v) => v.isEmpty ? AppStrings.none : v.join(', ');

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.responderView)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.visibility),
              const SizedBox(width: 8),
              Expanded(
                child: Text(AppStrings.responderReadOnly,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          if (!share)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text(AppStrings.consentOffTitle),
                  subtitle: Text(AppStrings.sharingOff),
                ),
              ),
            ),
          const SectionHeader(AppStrings.patient),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name.isEmpty ? '-' : profile.name,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  _Row(AppStrings.ageLabel, profile.age > 0 ? '${profile.age}' : '-'),
                  _Row(AppStrings.abhaId,
                      profile.abhaId.isEmpty ? '-' : Formatters.abhaId(profile.abhaId)),
                  if (share) ...[
                    _Row(AppStrings.bloodGroup,
                        profile.bloodGroup.isEmpty ? '-' : profile.bloodGroup),
                    _Row(AppStrings.allergies, list(profile.allergies)),
                    _Row(AppStrings.conditions, list(profile.conditions)),
                    _Row(AppStrings.medications, list(profile.medications)),
                  ],
                ],
              ),
            ),
          ),
          if (share) ...[
            const SectionHeader(AppStrings.lastVitals),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: vitals == null
                    ? const Text(AppStrings.noData)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Row(AppStrings.heartRate,
                              vitals.heartRate > 0 ? '${vitals.heartRate} ${AppStrings.bpm}' : '--'),
                          _Row(AppStrings.spo2, vitals.spo2 > 0 ? '${vitals.spo2}%' : '--'),
                          _Row(AppStrings.lastUpdated, Formatters.time(vitals.timestamp)),
                        ],
                      ),
              ),
            ),
            const SectionHeader(AppStrings.lastEcg),
            if (strip.isEmpty)
              const Card(
                  child: Padding(padding: EdgeInsets.all(16), child: Text(AppStrings.noData)))
            else
              EcgPaperChart.strip(samples: strip, height: 150, pxPerMm: 1.2),
          ],
          const SectionHeader(AppStrings.liveLocation),
          LocationMapCard(location: location.position, height: 200),
          const SectionHeader(AppStrings.emergencyContacts),
          if (contacts.isEmpty)
            const Card(
                child: Padding(padding: EdgeInsets.all(16), child: Text(AppStrings.noContactsYet)))
          else
            for (final c in contacts)
              Card(
                child: ListTile(
                  minTileHeight: 64,
                  leading: const Icon(Icons.person),
                  title: Text('${c.name} (${c.relationship})'),
                  subtitle: Text(c.phone),
                ),
              ),
          const SectionHeader('Share link'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(width: 160, height: 160, child: _QrPlaceholder()),
                  const SizedBox(height: 8),
                  Text(AppStrings.qrPlaceholder,
                      textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: theme.textTheme.titleMedium?.copyWith(color: theme.hintColor)),
          ),
          Expanded(
            child: Text(value,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// QR-looking placeholder; the real link is generated in Phase 3.
class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.qrPlaceholder,
      image: true,
      child: CustomPaint(painter: _QrPainter(Theme.of(context).colorScheme.onSurface)),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 21;
    final cell = size.width / n;
    final rng = Random(5);
    final paint = Paint()..color = color;
    bool finder(int x, int y) =>
        (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (finder(x, y)) continue;
        if (rng.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    void eye(double ox, double oy) {
      canvas.drawRect(Rect.fromLTWH(ox, oy, cell * 7, cell * 7), paint);
      canvas.drawRect(
        Rect.fromLTWH(ox + cell, oy + cell, cell * 5, cell * 5),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRect(Rect.fromLTWH(ox + cell * 2, oy + cell * 2, cell * 3, cell * 3), paint);
    }

    eye(0, 0);
    eye((n - 7) * cell, 0);
    eye(0, (n - 7) * cell);
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.color != color;
}
