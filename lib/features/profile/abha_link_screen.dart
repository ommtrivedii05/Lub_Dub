import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/risk_assessment.dart';
import '../../providers/profile_providers.dart';
import '../../services/abha_service.dart';

/// Mock ABHA linking: enter the 14-digit ID, request an OTP, verify it.
class AbhaLinkScreen extends ConsumerStatefulWidget {
  const AbhaLinkScreen({super.key});

  @override
  ConsumerState<AbhaLinkScreen> createState() => _AbhaLinkScreenState();
}

class _AbhaLinkScreenState extends ConsumerState<AbhaLinkScreen> {
  final _idForm = GlobalKey<FormState>();
  final _otpForm = GlobalKey<FormState>();
  late final _id = TextEditingController(text: Formatters.abhaId(ref.read(profileProvider).abhaId));
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _otp.dispose();
    super.dispose();
  }

  String get _digits => _id.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _sendOtp() async {
    if (!_idForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(abhaServiceProvider).sendOtp(_digits);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _otpSent = ok;
      _error = ok ? null : 'Could not send the OTP.';
    });
  }

  Future<void> _verify() async {
    if (!_otpForm.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(abhaServiceProvider).verifyOtp(_otp.text);
    if (!mounted) return;
    if (ok) {
      ref.read(profileProvider.notifier).update((p) {
        final handle = p.name.isEmpty
            ? 'user${_digits.substring(10)}'
            : p.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        return p.copyWith(
          abhaId: _digits,
          abhaLinked: true,
          abhaAddress: p.abhaAddress.isEmpty ? '$handle@abdm' : p.abhaAddress,
        );
      });
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _error = 'That OTP is not correct. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.linkAbha)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (profile.abhaLinked)
            Card(
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(Icons.verified, color: RiskLevel.normal.color(context)),
                title: Text(AppStrings.abhaLinked,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                subtitle: Text(Formatters.abhaId(profile.abhaId)),
              ),
            ),
          const SizedBox(height: 12),
          Form(
            key: _idForm,
            child: TextFormField(
              controller: _id,
              enabled: !_otpSent,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: AppStrings.abhaId,
                hintText: 'XX-XXXX-XXXX-XXXX',
                helperText: '14 digits',
              ),
              validator: (v) => Validators.abhaId(v, optional: false),
            ),
          ),
          const SizedBox(height: 16),
          if (!_otpSent)
            FilledButton(
              onPressed: _busy ? null : _sendOtp,
              child: _busy
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                  : const Text(AppStrings.sendOtp),
            )
          else ...[
            Form(
              key: _otpForm,
              child: TextFormField(
                controller: _otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  helperText: 'Demo: use ${AbhaService.demoOtp}',
                ),
                validator: Validators.otp,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _verify,
              child: _busy
                  ? const SizedBox(
                      width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                  : const Text(AppStrings.verifyOtp),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Icon(Icons.error_outline, color: RiskLevel.emergency.color(context)),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: theme.textTheme.titleMedium)),
              ]),
            ),
          const SizedBox(height: 20),
          Text(
            'This is a demo. No request is sent to ABDM yet.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
