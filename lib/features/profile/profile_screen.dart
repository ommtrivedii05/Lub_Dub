import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../data/models/risk_assessment.dart';
import '../../data/models/user_profile.dart';
import '../../providers/profile_providers.dart';
import '../../shared/widgets/section_header.dart';

List<String> parseCsv(String text) =>
    text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
const sexOptions = ['Female', 'Male', 'Other'];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final contacts = ref.watch(contactsProvider);
    final theme = Theme.of(context);

    Widget nav(IconData icon, String title, String route, {String? subtitle}) => Card(
          child: ListTile(
            minTileHeight: 64,
            leading: Icon(icon),
            title: Text(title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            subtitle: subtitle == null ? null : Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(route),
          ),
        );

    String list(List<String> v) => v.isEmpty ? AppStrings.none : v.join(', ');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            tooltip: AppStrings.edit,
            icon: const Icon(Icons.edit),
            onPressed: () => showEditProfileSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    p.name.isEmpty ? '?' : p.name.characters.first.toUpperCase(),
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name.isEmpty ? '-' : p.name,
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        [
                          if (p.age > 0) '${p.age} yrs',
                          if (p.sex.isNotEmpty) p.sex,
                          if (p.bloodGroup.isNotEmpty) p.bloodGroup,
                        ].join('  -  '),
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
          const SectionHeader(AppStrings.abhaId),
          Card(
            child: ListTile(
              minTileHeight: 72,
              leading: Icon(
                p.abhaLinked ? Icons.verified : Icons.link_off,
                color: p.abhaLinked ? RiskLevel.normal.color(context) : null,
              ),
              title: Text(
                p.abhaId.isEmpty ? AppStrings.linkAbha : Formatters.abhaId(p.abhaId),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(p.abhaLinked
                  ? '${AppStrings.abhaLinked}${p.abhaAddress.isEmpty ? '' : '  -  ${p.abhaAddress}'}'
                  : AppStrings.linkAbha),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile/abha'),
            ),
          ),
          const SectionHeader('Medical information'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Info(AppStrings.conditions, list(p.conditions)),
                  _Info(AppStrings.allergies, list(p.allergies)),
                  _Info(AppStrings.medications, list(p.medications)),
                  _Info('Doctor',
                      p.doctorName.isEmpty ? AppStrings.none : '${p.doctorName}  ${p.doctorPhone}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          nav(Icons.privacy_tip_outlined, AppStrings.dataConsent, '/profile/consent',
              subtitle: p.shareWithResponders ? 'Sharing on' : 'Sharing off'),
          const SizedBox(height: 8),
          nav(Icons.contact_phone, AppStrings.contacts, '/contacts',
              subtitle: contacts.isEmpty ? AppStrings.noContacts : '${contacts.length} saved'),
          const SizedBox(height: 8),
          nav(Icons.watch, AppStrings.deviceStatus, '/device'),
          const SizedBox(height: 8),
          nav(Icons.badge, AppStrings.responderView, '/responder'),
          const SizedBox(height: 8),
          nav(Icons.settings, AppStrings.settings, '/settings'),
          const DisclaimerFooter(),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

Future<void> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _EditProfileSheet(),
  );
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _form = GlobalKey<FormState>();
  late final UserProfile _p = ref.read(profileProvider);
  late final _name = TextEditingController(text: _p.name);
  late final _age = TextEditingController(text: _p.age > 0 ? '${_p.age}' : '');
  late final _conditions = TextEditingController(text: _p.conditions.join(', '));
  late final _allergies = TextEditingController(text: _p.allergies.join(', '));
  late final _medications = TextEditingController(text: _p.medications.join(', '));
  late final _doctor = TextEditingController(text: _p.doctorName);
  late final _doctorPhone = TextEditingController(text: _p.doctorPhone);
  late String _sex = sexOptions.contains(_p.sex) ? _p.sex : sexOptions.first;
  late String _blood = bloodGroups.contains(_p.bloodGroup) ? _p.bloodGroup : bloodGroups.first;

  @override
  void dispose() {
    for (final c in [_name, _age, _conditions, _allergies, _medications, _doctor, _doctorPhone]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    ref.read(profileProvider.notifier).update(
          (p) => p.copyWith(
            name: _name.text.trim(),
            age: int.parse(_age.text),
            sex: _sex,
            bloodGroup: _blood,
            conditions: parseCsv(_conditions.text),
            allergies: parseCsv(_allergies.text),
            medications: parseCsv(_medications.text),
            doctorName: _doctor.text.trim(),
            doctorPhone: _doctorPhone.text.trim(),
          ),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.edit,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: AppStrings.name),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, AppStrings.name),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _age,
                  decoration: const InputDecoration(labelText: AppStrings.age),
                  keyboardType: TextInputType.number,
                  validator: Validators.age,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: AppStrings.sex),
                  items: [for (final s in sexOptions) DropdownMenuItem(value: s, child: Text(s))],
                  onChanged: (v) => _sex = v ?? _sex,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _blood,
                  decoration: const InputDecoration(labelText: AppStrings.bloodGroup),
                  items: [for (final s in bloodGroups) DropdownMenuItem(value: s, child: Text(s))],
                  onChanged: (v) => _blood = v ?? _blood,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conditions,
                  decoration: const InputDecoration(
                      labelText: AppStrings.conditions, helperText: 'Separate with commas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _allergies,
                  decoration: const InputDecoration(
                      labelText: AppStrings.allergies, helperText: 'Separate with commas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _medications,
                  decoration: const InputDecoration(
                      labelText: AppStrings.medications, helperText: 'Separate with commas'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctor,
                  decoration: const InputDecoration(labelText: 'Doctor name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _doctorPhone,
                  decoration: const InputDecoration(labelText: 'Doctor phone'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty) ? null : Validators.phone(v),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: _save, child: const Text(AppStrings.save)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
