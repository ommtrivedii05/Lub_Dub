import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/emergency_contact.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../services/abha_service.dart';

final profileRepositoryProvider =
    Provider<ProfileRepository>((ref) => InMemoryProfileRepository());

final contactsRepositoryProvider =
    Provider<ContactsRepository>((ref) => InMemoryContactsRepository());

final abhaServiceProvider = Provider<AbhaService>((ref) => AbhaService());

/// Set once the 4 onboarding slides were completed.
final onboardingCompleteProvider = StateProvider<bool>((ref) => false);

class ProfileNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() => ref.read(profileRepositoryProvider).load();

  void save(UserProfile profile) {
    ref.read(profileRepositoryProvider).save(profile);
    state = profile;
  }

  void update(UserProfile Function(UserProfile p) change) => save(change(state));
}

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

class ContactsNotifier extends Notifier<List<EmergencyContact>> {
  @override
  List<EmergencyContact> build() => ref.read(contactsRepositoryProvider).all();

  void upsert(EmergencyContact c) {
    ref.read(contactsRepositoryProvider).upsert(c);
    state = ref.read(contactsRepositoryProvider).all();
  }

  void delete(String id) {
    ref.read(contactsRepositoryProvider).delete(id);
    state = ref.read(contactsRepositoryProvider).all();
  }

  /// Swaps priority with the neighbour above (-1) or below (+1).
  void move(String id, int delta) {
    final list = state;
    final i = list.indexWhere((c) => c.id == id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return;
    final a = list[i];
    final b = list[j];
    final repo = ref.read(contactsRepositoryProvider);
    repo.upsert(a.copyWith(priority: b.priority));
    repo.upsert(b.copyWith(priority: a.priority));
    state = repo.all();
  }

  /// Next free priority number for a new contact.
  int get nextPriority =>
      state.isEmpty ? 1 : state.map((c) => c.priority).reduce((a, b) => a > b ? a : b) + 1;
}

final contactsProvider =
    NotifierProvider<ContactsNotifier, List<EmergencyContact>>(ContactsNotifier.new);

/// Where the splash screen (and the end of onboarding) sends the user. Reads
/// the current state each time, so it must not be a cached provider.
String resolveStartupRoute(WidgetRef ref) {
  if (!ref.read(onboardingCompleteProvider)) return '/onboarding';
  if (!ref.read(profileProvider).isComplete) return '/setup';
  return '/dashboard';
}