import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/room_model.dart';
import '../../../core/network/supabase_client.dart';
import '../presentation/room_type.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(client: ref.watch(supabaseClientProvider));
});

class RoomRepository {
  final SupabaseClient _client;

  RoomRepository({required SupabaseClient client}) : _client = client;

  Future<List<RoomModel>> fetchRooms() async {
    final data = await _client
        .from('rooms')
        .select()
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).map((e) => RoomModel.fromJson(e)).toList();
  }

  Future<RoomModel> createRoom({
    required String name,
    required String hostId,
    RoomType? roomType,
    bool isPrivate = false,
    String? password,
  }) async {
    final data = await _client
        .from('rooms')
        .insert({
          'name': name,
          'host_id': hostId,
          if (roomType != null)
            'room_type': roomType.name
          else
            'room_type': null,
          'is_private': isPrivate,
          if (password != null && password.isNotEmpty) 'password': password,
          'current_member_count': 1,
        })
        .select()
        .single();
    return RoomModel.fromJson(data);
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final data = await _client
        .from('rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    if (data == null) return null;
    return RoomModel.fromJson(data);
  }
}
