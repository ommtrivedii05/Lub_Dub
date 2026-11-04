import '../models/emergency_contact.dart';

abstract class ContactsRepository {
  /// Sorted by priority (1 first).
  List<EmergencyContact> all();
  void upsert(EmergencyContact contact);
  void delete(String id);
}

class InMemoryContactsRepository implements ContactsRepository {
  final List<EmergencyContact> _contacts = [];

  @override
  List<EmergencyContact> all() {
    final copy = List<EmergencyContact>.from(_contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return copy;
  }

  @override
  void upsert(EmergencyContact contact) {
    final i = _contacts.indexWhere((c) => c.id == contact.id);
    if (i >= 0) {
      _contacts[i] = contact;
    } else {
      _contacts.add(contact);
    }
  }

  @override
  void delete(String id) => _contacts.removeWhere((c) => c.id == id);
}