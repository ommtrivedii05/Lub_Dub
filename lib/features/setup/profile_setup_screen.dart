import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../data/models/emergency_contact.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';
import '../profile/profile_screen.dart' show bloodGroups, parseCsv, sexOptions;

/// Four-step wizard: personal, ABHA ID, medical info, first emergency contact.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _keys = List.generate(4, (_) => GlobalKey<FormState>());
  int _step = 0;

  final _name = TextEditingController();
  final _age = TextEditingController();
  String _sex = sexOptions.first;
  final _abha = TextEditingController();
  final _abhaAddress = TextEditingController();
  String _blood = bloodGroups.first;
  final _conditions = TextEditingController();
  final _allergies = TextEditingController();
  final _medications = TextEditingController();
  final _doctor = TextEditingController();
  final _doctorPhone = TextEditingController();
  bool _share = true;
  final _cName = TextEditingController();
  final _cRelation = TextEditingController();
  final _cPhone = TextEditingController();
  bool _cWarning = true;

  static const _titles = [
    AppStrings.stepPersonal,
    AppStrings.stepAbha,
    AppStrings.stepMedical,
    AppStrings.stepContact,
  ];

  @override
  void dispose() {
    for (final c in [
      _name, _age, _abha, _abhaAddress, _conditions, _allergies, _medications,
      _doctor, _doctorPhone, _cName, _cRelation, _cPhone, //
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_keys[_step].currentState!.validate()) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(profileProvider.notifier).save(UserProfile(
          name: _name.text.trim(),
          age: int.parse(_age.text),
          sex: _sex,
          bloodGroup: _blood,
          abhaId: _abha.text.replaceAll(RegExp(r'\D'), ''),
          abhaAddress: _abhaAddress.text.trim(),
          conditions: parseCsv(_conditions.text),
          allergies: parseCsv(_allergies.text),
          medications: parseCsv(_medications.text),
          doctorName: _doctor.text.trim(),
          doctorPhone: _doctorPhone.text.trim(),
          shareWithResponders: _share,
        ));
    final contacts = ref.read(contactsProvider.notifier);
    contacts.upsert(EmergencyContact(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _cName.text.trim(),
      relationship: _cRelation.text.trim(),
      phone: _cPhone.text.trim(),
      priority: contacts.nextPriority,
      notifyOnWarning: _cWarning,
    ));
    context.go('/connect');
  }

  /// Fills a sample profile so the demo can start immediately.
  void _useDemoProfile() {
    ref.read(profileProvider.notifier).save(const UserProfile(
          name: 'Ramesh Kumar',
          age: 68,
          sex: 'Male',
          bloodGroup: 'B+',
          abhaId: '91123456789012',
          abhaAddress: 'rameshkumar@abdm',
          abhaLinked: true,
          conditions: ['Coronary artery disease', 'Hypertension'],
          allergies: ['Penicillin'],
          medications: ['Aspirin 75 mg', 'Atorvastatin 20 mg'],
          doctorName: 'Dr. Rao',
          doctorPhone: '9845012345',
          shareWithResponders: true,
        ));
    ref.read(contactsProvider.notifier).upsert(const EmergencyContact(
          id: 'demo-1',
          name: 'Asha',
          relationship: 'Daughter',
          phone: '9886012345',
          priority: 1,
          notifyOnWarning: true,
        ));
    context.go('/connect');
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return Column(children: [
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: AppStrings.name),
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, AppStrings.name),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _age,
            decoration: const InputDecoration(labelText: AppStrings.age),
            keyboardType: TextInputType.number,
            validator: Validators.age,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _sex,
            decoration: const InputDecoration(labelText: AppStrings.sex),
            items: [for (final s in sexOptions) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => _sex = v ?? _sex,
          ),
        ]);
      case 1:
        return Column(children: [
          TextFormField(
            controller: _abha,
            decoration: const InputDecoration(
              labelText: AppStrings.abhaId,
              hintText: 'XX-XXXX-XXXX-XXXX',
              helperText: '14 digits. ${AppStrings.optional}',
            ),
            keyboardType: TextInputType.number,
            validator: Validators.abhaId,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _abhaAddress,
            decoration: const InputDecoration(
              labelText: AppStrings.abhaAddress,
              hintText: 'name@abdm',
              helperText: AppStrings.optional,
            ),
            validator: Validators.abhaAddress,
          ),
        ]);
      case 2:
        return Column(children: [
          DropdownButtonFormField<String>(
            initialValue: _blood,
            decoration: const InputDecoration(labelText: AppStrings.bloodGroup),
            items: [for (final s in bloodGroups) DropdownMenuItem(value: s, child: Text(s))],
            onChanged: (v) => _blood = v ?? _blood,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _conditions,
            decoration: const InputDecoration(
                labelText: AppStrings.conditions, helperText: 'Separate with commas'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _allergies,
            decoration: const InputDecoration(
                labelText: AppStrings.allergies, helperText: 'Separate with commas'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _medications,
            decoration: const InputDecoration(
                labelText: AppStrings.medications, helperText: 'Separate with commas'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _doctor,
            decoration: const InputDecoration(labelText: 'Doctor name'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _doctorPhone,
            decoration: const InputDecoration(labelText: 'Doctor phone'),
            keyboardType: TextInputType.phone,
            validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.phone(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.shareWithResponders),
            subtitle: const Text('Responders can see your medical details in an emergency'),
            value: _share,
            onChanged: (v) => setState(() => _share = v),
          ),
        ]);
      default:
        return Column(children: [
          TextFormField(
            controller: _cName,
            decoration: const InputDecoration(labelText: AppStrings.name),
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, AppStrings.name),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cRelation,
            decoration: const InputDecoration(labelText: 'Relationship'),
            textCapitalization: TextCapitalization.words,
            validator: (v) => Validators.required(v, 'Relationship'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _cPhone,
            decoration: const InputDecoration(labelText: 'Phone'),
            keyboardType: TextInputType.phone,
            validator: Validators.phone,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.notifyWarning),
            value: _cWarning,
            onChanged: (v) => setState(() => _cWarning = v),
          ),
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setupTitle),
        actions: [
          if (_step == 0)
            TextButton(onPressed: _useDemoProfile, child: const Text('Use demo profile')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Semantics(
                  header: true,
                  child: Text('${_step + 1} / 4   ${_titles[_step]}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(key: _keys[_step], child: _stepBody()),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _step--),
                        child: const Text(AppStrings.back),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_step == 3 ? AppStrings.finish : AppStrings.next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
