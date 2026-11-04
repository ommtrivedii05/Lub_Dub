import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/sensor_config.dart';
import '../../core/utils/validators.dart';
import '../../data/sources/device_source.dart';
import '../../providers/device_providers.dart';
import '../../providers/settings_providers.dart';
import '../../shared/widgets/connection_chip.dart';

/// Pick how to reach the ESP32, enter its address and connect, or use Demo Mode.
class ConnectDeviceScreen extends ConsumerStatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  ConsumerState<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends ConsumerState<ConnectDeviceScreen> {
  final _form = GlobalKey<FormState>();
  late ConnectionMode _mode = ref.read(settingsProvider).connectionMode;
  late final _host = TextEditingController(text: ref.read(settingsProvider).host);
  late final _port = TextEditingController(text: '${ref.read(settingsProvider).port}');

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _setMode(ConnectionMode m) {
    setState(() {
      _mode = m;
      if (m == ConnectionMode.hotspot) {
        _host.text = SensorConfig.hotspotHost;
        _port.text = '${SensorConfig.defaultPort}';
      } else if (_host.text == SensorConfig.hotspotHost) {
        _host.clear();
      }
    });
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    final host = _host.text.trim();
    final port = int.parse(_port.text);
    ref.read(settingsProvider.notifier).update(
          (s) => s.copyWith(connectionMode: _mode, host: host, port: port, demoMode: false),
        );
    await ref.read(deviceControllerProvider.notifier).connectEsp32(host, port);
    if (!mounted) return;
    if (ref.read(deviceControllerProvider).connected) _leave();
  }

  Future<void> _demo() async {
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(demoMode: true));
    await ref.read(deviceControllerProvider.notifier).startDemo();
    if (mounted) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.watch(deviceControllerProvider);
    final theme = Theme.of(context);
    final busy = device.connection == DeviceConnectionState.connecting;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.connectDevice)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(AppStrings.connectDeviceHelp, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ConnectionMode>(
              segments: const [
                ButtonSegment(
                    value: ConnectionMode.hotspot,
                    icon: Icon(Icons.wifi_tethering),
                    label: Text(AppStrings.modeHotspot)),
                ButtonSegment(
                    value: ConnectionMode.network,
                    icon: Icon(Icons.router),
                    label: Text(AppStrings.modeNetwork)),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _form,
            child: Column(children: [
              TextFormField(
                controller: _host,
                decoration: InputDecoration(
                  labelText: AppStrings.hostLabel,
                  helperText: _mode == ConnectionMode.hotspot
                      ? 'Join the ESP32 Wi-Fi first, then keep ${SensorConfig.hotspotHost}'
                      : 'For example 192.168.1.42 or cardioguard.local',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                validator: Validators.hostOrIp,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _port,
                decoration: const InputDecoration(labelText: AppStrings.portLabel),
                keyboardType: TextInputType.number,
                validator: Validators.port,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConnectionChip(state: device.connection, demo: device.demo),
            ],
          ),
          if (device.error != null && device.connection == DeviceConnectionState.failed)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(child: Text(device.error!, style: theme.textTheme.titleMedium)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: busy ? null : _connect,
            icon: busy
                ? const SizedBox(
                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3))
                : const Icon(Icons.link),
            label: Text(busy ? AppStrings.connecting : AppStrings.connect),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy ? null : _demo,
            icon: const Icon(Icons.science),
            label: const Text(AppStrings.useDemo),
          ),
        ],
      ),
    );
  }
}
