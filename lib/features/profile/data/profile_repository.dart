import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import 'profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(client: ref.watch(supabaseClientProvider));
});

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository({required SupabaseClient client}) : _client = client;

  Future<ProfileModel?> fetchProfile(String userId) async {
    final data = await _client
        .from('profile')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> updateProfile({
    required String userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null) updates['username'] = username;
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (bio != null) updates['bio'] = bio;
    if (isOnline != null) updates['is_online'] = isOnline;

    final data = await _client
        .from('profile')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    return ProfileModel.fromJson(data);
  }
}
