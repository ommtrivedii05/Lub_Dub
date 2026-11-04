import '../models/user_profile.dart';

abstract class ProfileRepository {
  UserProfile load();
  void save(UserProfile profile);
}

class InMemoryProfileRepository implements ProfileRepository {
  UserProfile _profile = const UserProfile();

  @override
  UserProfile load() => _profile;

  @override
  void save(UserProfile profile) => _profile = profile;
}