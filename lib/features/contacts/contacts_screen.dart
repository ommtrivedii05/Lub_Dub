import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/validators.dart';
import '../../data/models/emergency_contact.dart';
import '../../providers/profile_providers.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});


  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, EmergencyContact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('${AppStrings.deleteContact}?'),
        content: Text(c.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: const Text(AppStrings.delete)),
        ],
      ),
    );
    if (ok == true) ref.read(contactsProvider.notifier).delete(c.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contacts = ref.watch(contactsProvider);
    final notifier = ref.read(contactsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.contacts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showContactSheet(context),
        icon: const Icon(Icons.person_add),
        label: const Text(AppStrings.addContact),
      ),
      body: contacts.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppStrings.noContacts,
                    textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = contacts[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            child: Text('${i + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name,
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w800)),
                                Text('${c.relationship}  -  ${c.phone}',
                                    style: theme.textTheme.titleMedium),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 4, children: [
                          if (c.notifyOnWarning)
                            const Chip(
                                avatar: Icon(Icons.warning_amber_rounded, size: 18),
                                label: Text('Warning')),
                          if (c.notifyOnEmergency)
                            const Chip(avatar: Icon(Icons.emergency, size: 18), label: Text('Emergency')),
                        ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Move up',
                              onPressed: i == 0 ? null : () => notifier.move(c.id, -1),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Move down',
                              onPressed: i == contacts.length - 1 ? null : () => notifier.move(c.id, 1),
                              icon: const Icon(Icons.arrow_downward),
                            ),
                            IconButton(
                              tooltip: AppStrings.editContact,
                              onPressed: () => showContactSheet(context, existing: c),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: AppStrings.deleteContact,
                              onPressed: () => _confirmDelete(context, ref, c),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

Future<void> showContactSheet(BuildContext context, {EmergencyContact? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ContactSheet(existing: existing),
  );
}

class ContactSheet extends ConsumerStatefulWidget {
  const ContactSheet({super.key, this.existing});

  final EmergencyContact? existing;

  @override
  ConsumerState<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends ConsumerState<ContactSheet> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _relation = TextEditingController(text: widget.existing?.relationship ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late bool _onWarning = widget.existing?.notifyOnWarning ?? false;
  late bool _onEmergency = widget.existing?.notifyOnEmergency ?? true;

  @override
  void dispose() {
    _name.dispose();
    _relation.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final notifier = ref.read(contactsProvider.notifier);
    final old = widget.existing;
    notifier.upsert(EmergencyContact(
      id: old?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      relationship: _relation.text.trim(),
      phone: _phone.text.trim(),
      priority: old?.priority ?? notifier.nextPriority,
      notifyOnWarning: _onWarning,
      notifyOnEmergency: _onEmergency,
    ));
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
                Text(widget.existing == null ? AppStrings.addContact : AppStrings.editContact,
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
                  controller: _relation,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Relationship'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.notifyEmergency),
                  value: _onEmergency,
                  onChanged: (v) => setState(() => _onEmergency = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppStrings.notifyWarning),
                  value: _onWarning,
                  onChanged: (v) => setState(() => _onWarning = v),
                ),
                const SizedBox(height: 12),
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
