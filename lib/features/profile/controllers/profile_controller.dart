import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final profileControllerProvider =
    FutureProvider.autoDispose.family<ProfileModel?, String>(
  (ref, userId) async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.fetchProfile(userId);
  },
);

final currentUserProfileProvider = FutureProvider.autoDispose<ProfileModel?>(
  (ref) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return ref.watch(profileControllerProvider(user.id).future);
  },
);

class ProfileUpdater extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
  }) async {
    state = true;
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            username: username,
            fullName: fullName,
            avatarUrl: avatarUrl,
            bio: bio,
          );
      ref.invalidate(profileControllerProvider(userId));
      ref.invalidate(currentUserProfileProvider);
    } finally {
      state = false;
    }
  }
}

final profileUpdaterProvider = NotifierProvider<ProfileUpdater, bool>(
  ProfileUpdater.new,
);
