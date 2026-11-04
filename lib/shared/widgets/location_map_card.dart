import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/alert_event.dart';

/// OpenStreetMap tile map with a marker. Needs no API key. Without internet
/// the tiles stay blank but the coordinates caption is still shown, so a
/// responder can read the position.
class LocationMapCard extends StatefulWidget {
  const LocationMapCard({super.key, required this.location, this.height = 200, this.zoom = 15});

  final GeoPoint? location;
  final double height;
  final double zoom;

  @override
  State<LocationMapCard> createState() => _LocationMapCardState();
}

class _LocationMapCardState extends State<LocationMapCard> {
  final MapController _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(LocationMapCard old) {
    super.didUpdateWidget(old);
    final loc = widget.location;
    if (_ready && loc != null && loc != old.location) {
      _controller.move(LatLng(loc.latitude, loc.longitude), widget.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    final theme = Theme.of(context);
    if (loc == null) {
      return Card(
        child: SizedBox(
          height: widget.height,
          child: const Center(child: Icon(Icons.location_off, size: 40)),
        ),
      );
    }
    final point = LatLng(loc.latitude, loc.longitude);
    return Semantics(
      label: 'Map, location ${Formatters.coords(loc.latitude, loc.longitude)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: widget.zoom,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                    onMapReady: () => _ready = true,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.cardioguard.cardio_guard',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: point,
                        width: 48,
                        height: 48,
                        child: const Icon(Icons.location_on, size: 48, color: AppColors.emergency),
                      ),
                    ]),
                  ],
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    Formatters.coords(loc.latitude, loc.longitude),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}