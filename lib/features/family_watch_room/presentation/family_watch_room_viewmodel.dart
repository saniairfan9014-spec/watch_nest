import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rooms/presentation/room_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';
import 'family_watch_room_state.dart';
import '../models/voice_seat_model.dart';
import '../models/room_member_model.dart';
import '../models/chat_message_model.dart';
import '../models/announcement_model.dart';
import '../models/room_activity_model.dart';
import '../models/family_watch_room_model.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/data/profile_model.dart';

class FamilyWatchRoomViewModel extends Notifier<FamilyWatchRoomState> {
  RealtimeChannel? _channel;

  @override
  FamilyWatchRoomState build() {
    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    final profile = ref.read(currentUserProfileProvider).value;
    final userId = profile?.id ?? '';

    return FamilyWatchRoomState(
      isLoading: true,
      room: FamilyWatchRoom(
        id: '',
        name: '',
        roomId: '',
        hostId: '',
        currentUserId: userId,
        announcement: Announcement(text: '', updatedAt: DateTime.now()),
      ),
    );
  }

  Future<void> loadRoom(String roomId) async {
    try {
      final client = ref.read(supabaseClientProvider);
      
      // Fetch room data
      final roomResponse = await client.from('rooms').select().eq('id', roomId).maybeSingle();
      if (roomResponse == null) return;

      // Wait for profile to load so we have the correct userId and name
      ProfileModel? profile;
      try {
        profile = await ref.read(currentUserProfileProvider.future);
      } catch (_) {}
      
      final userId = profile?.id ?? client.auth.currentUser?.id ?? '';
      final userName = profile?.username ?? 'User';
      final avatarUrl = profile?.avatarUrl;

      final hostId = roomResponse['host_id'] as String;
      final roomTypeStr = roomResponse['room_type'] as String?;
      RoomType type = RoomType.general;
      if (roomTypeStr != null) {
        type = RoomType.values.firstWhere((e) => e.name == roomTypeStr, orElse: () => RoomType.general);
      }

      // Register current user in room_members (upsert so no duplicates)
      if (userId.isNotEmpty) {
        try {
          await client.from('room_members').upsert({
            'room_id': roomId,
            'user_id': userId,
            'user_name': userName,
            'avatar_url': avatarUrl,
            'is_host': userId == hostId,
            'joined_at': DateTime.now().toIso8601String(),
          }, onConflict: 'room_id,user_id');
        } catch (_) {}
      }

      // Fetch all seats
      final seatsResponse = await client.from('room_seats').select().eq('room_id', roomId);
      
      final List<VoiceSeat> seats = List.generate(10, (i) {
        final seatNum = i + 1;
        final seatData = seatsResponse.cast<Map<String, dynamic>>().firstWhere(
          (s) => s['seat_number'] == seatNum, 
          orElse: () => <String, dynamic>{},
        );

        if (seatData.isNotEmpty) {
          final sUserId = seatData['user_id'] as String?;
          final isLocked = seatData['is_locked'] as bool? ?? false;
          
          SeatStatus status = SeatStatus.empty;
          if (sUserId != null) status = SeatStatus.occupied;
          else if (isLocked) status = SeatStatus.locked;

          return VoiceSeat(
            seatNumber: seatNum,
            status: status,
            userId: sUserId,
            userName: seatData['user_name'] as String?,
            avatarUrl: seatData['avatar_url'] as String?,
            isMuted: seatData['is_muted'] as bool? ?? false,
            isHost: seatData['is_host'] as bool? ?? false,
            joinedAt: seatData['joined_at'] != null ? DateTime.parse(seatData['joined_at']) : null,
          );
        }
        return VoiceSeat(seatNumber: seatNum);
      });

      // Fetch all room members (everyone present in the room)
      final membersResponse = await client.from('room_members').select().eq('room_id', roomId);
      final List<RoomMember> allMembers = membersResponse.cast<Map<String, dynamic>>().map((m) {
        final mUserId = m['user_id'] as String? ?? '';
        return RoomMember(
          id: mUserId,
          name: m['user_name'] as String? ?? 'User',
          avatarUrl: m['avatar_url'] as String?,
          score: mUserId == hostId ? 5000 : 1500,
          isHost: mUserId == hostId,
        );
      }).toList();

      // If room_members table empty, fall back to seats-based members
      final members = allMembers.isNotEmpty ? allMembers : _buildMembersFromSeats(seats);

      // Get announcement
      String announcementText = 'Welcome to the room';
      try {
        final ann = await client.from('room_announcements')
            .select().eq('room_id', roomId).order('updated_at', ascending: false).limit(1).maybeSingle();
        if (ann != null) announcementText = ann['text'] as String? ?? announcementText;
      } catch (_) {}

      final room = FamilyWatchRoom(
        id: roomResponse['id'],
        name: roomResponse['name'],
        roomId: roomResponse['id'],
        hostId: hostId,
        currentUserId: userId,
        roomType: type,
        currentVideoId: roomResponse['current_video_id'],
        currentPosition: roomResponse['current_position'] ?? 0,
        isPlaying: roomResponse['is_playing'] ?? false,
        micLocked: roomResponse['mic_locked'] ?? false,
        seats: seats,
        members: members,
        announcement: Announcement(text: announcementText, updatedAt: DateTime.now()),
      );

      state = state.copyWith(
        isLoading: false,
        room: room,
      );

      _initRealtime(roomId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }


  List<RoomMember> _buildMembersFromSeats(List<VoiceSeat> seats) {
    return seats
        .where((s) => s.status == SeatStatus.occupied)
        .map((s) => RoomMember(
              id: s.userId ?? '',
              name: s.userName ?? 'Unknown',
              avatarUrl: s.avatarUrl,
              score: s.isHost ? 5000 : 1500,
              isHost: s.isHost,
            ))
        .toList();
  }

  // --- Room Type ---

  Future<void> setRoomType(RoomType type) async {
    final updatedRoom = FamilyWatchRoom(
      id: state.room.id,
      name: state.room.name,
      roomId: state.room.roomId,
      points: state.room.points,
      seats: state.room.seats,
      members: state.room.members,
      announcement: state.room.announcement,
      messages: state.room.messages,
      activities: state.room.activities,
      hostId: state.room.hostId,
      currentUserId: state.room.currentUserId,
      roomType: type,
    );
    state = state.copyWith(room: updatedRoom);

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('rooms').update({
        'room_type': type.name,
      }).eq('id', state.room.id);
    } catch (_) {}
  }

  void updateRoomLocally({required String name, required RoomType type}) {
    final updatedRoom = FamilyWatchRoom(
      id: state.room.id,
      name: name,
      roomId: state.room.roomId,
      points: state.room.points,
      seats: state.room.seats,
      members: state.room.members,
      announcement: state.room.announcement,
      messages: state.room.messages,
      activities: state.room.activities,
      hostId: state.room.hostId,
      currentUserId: state.room.currentUserId,
      roomType: type,
    );
    state = state.copyWith(room: updatedRoom);
  }

  // --- Realtime Sync ---

  void _initRealtime(String roomId) {
    if (roomId.startsWith('room-')) return; // Skip realtime for dummy room

    final client = ref.read(supabaseClientProvider);
    _channel = client.channel('room:data:$roomId');
    
    // Listen for room updates (movie state, etc.)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'rooms',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: roomId,
      ),
      callback: (payload) {
        _handleMovieSync(payload.newRecord);
      },
    );

    // Listen for seat updates (mic management)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'room_seats',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        _handleSeatSync(payload.newRecord);
      },
    );

    // Listen for member join/leave (room_members table)
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'room_members',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'room_id',
        value: roomId,
      ),
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.delete) {
          _handleMemberLeft(payload.oldRecord);
        } else {
          _handleMemberSync(payload.newRecord);
        }
      },
    );

    // Listen for chat messages (broadcast)
    _channel!.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        _handleIncomingChatMessage(payload);
      },
    );
    
    _channel!.subscribe();
  }

  void _handleMemberSync(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final mUserId = data['user_id'] as String? ?? '';
    final hostId = state.room.hostId;

    final newMember = RoomMember(
      id: mUserId,
      name: data['user_name'] as String? ?? 'User',
      avatarUrl: data['avatar_url'] as String?,
      score: mUserId == hostId ? 5000 : 1500,
      isHost: mUserId == hostId,
    );

    final existing = state.room.members.any((m) => m.id == mUserId);
    if (!existing) {
      state = state.copyWith(
        members: [...state.room.members, newMember],
      );
    }
  }

  void _handleMemberLeft(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final mUserId = data['user_id'] as String? ?? '';
    state = state.copyWith(
      members: state.room.members.where((m) => m.id != mUserId).toList(),
    );
  }

  void _handleIncomingChatMessage(Map<String, dynamic> payload) {
    // For broadcasts, the data might be wrapped in 'payload', or it might be the top-level map
    final payloadData = payload['payload'] is Map ? payload['payload'] : payload;
    
    final message = ChatMessage(
      id: payloadData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: payloadData['sender_id'] as String? ?? '',
      senderName: payloadData['sender_name'] as String? ?? 'User',
      senderAvatarUrl: payloadData['sender_avatar_url'] as String?,
      text: payloadData['text'] as String? ?? '',
      timestamp: payloadData['timestamp'] != null 
          ? DateTime.parse(payloadData['timestamp']) 
          : DateTime.now(),
      isHost: payloadData['is_host'] as bool? ?? false,
    );

    // Prevent duplicates if we sent it
    if (message.senderId == state.room.currentUserId) return;

    state = state.copyWith(
      messages: [...state.room.messages, message],
    );
  }

  void _handleSeatSync(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    
    final seatNumber = data['seat_number'] as int?;
    if (seatNumber == null) return;

    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;

    final userId = data['user_id'] as String?;
    final isLocked = data['is_locked'] as bool? ?? false;
    final isMuted = data['is_muted'] as bool? ?? false;
    
    SeatStatus status;
    if (userId != null) {
      status = SeatStatus.occupied;
    } else if (isLocked) {
      status = SeatStatus.locked;
    } else {
      status = SeatStatus.empty;
    }

    seats[index] = seats[index].copyWith(
      status: status,
      userId: userId,
      userName: data['user_name'] as String?,
      avatarUrl: data['avatar_url'] as String?,
      isMuted: isMuted,
      isHost: data['is_host'] as bool? ?? false,
      joinedAt: data['joined_at'] != null ? DateTime.parse(data['joined_at']) : null,
    );

    state = state.copyWith(
      seats: seats,
      members: _buildMembersFromSeats(seats),
    );
  }

  void _handleMovieSync(Map<String, dynamic> data) {
    final videoId = data['current_video_id'] as String?;
    final position = data['current_position'] as int? ?? 0;
    final isPlaying = data['is_playing'] as bool? ?? false;
    final micLocked = data['mic_locked'] as bool? ?? false;

    final updatedRoom = FamilyWatchRoom(
      id: state.room.id,
      name: state.room.name,
      roomId: state.room.roomId,
      points: state.room.points,
      seats: state.room.seats,
      members: state.room.members,
      announcement: state.room.announcement,
      messages: state.room.messages,
      activities: state.room.activities,
      hostId: state.room.hostId,
      currentUserId: state.room.currentUserId,
      roomType: state.room.roomType,
      currentVideoId: videoId,
      currentPosition: position,
      isPlaying: isPlaying,
      micLocked: micLocked,
    );
    state = state.copyWith(room: updatedRoom);
  }

  Future<void> updateMovieState(String? videoId, bool isPlaying, int position) async {
    final updatedRoom = FamilyWatchRoom(
      id: state.room.id,
      name: state.room.name,
      roomId: state.room.roomId,
      points: state.room.points,
      seats: state.room.seats,
      members: state.room.members,
      announcement: state.room.announcement,
      messages: state.room.messages,
      activities: state.room.activities,
      hostId: state.room.hostId,
      currentUserId: state.room.currentUserId,
      roomType: state.room.roomType,
      currentVideoId: videoId,
      currentPosition: position,
      isPlaying: isPlaying,
    );
    state = state.copyWith(room: updatedRoom);

    if (!state.room.id.startsWith('room-')) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('rooms').update({
          'current_video_id': videoId,
          'current_position': position,
          'is_playing': isPlaying,
          'video_updated_at': DateTime.now().toIso8601String(),
        }).eq('id', state.room.id);
      } catch (_) {}
    }
  }

  // --- Search ---

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  // --- Social ---

  void toggleSocialPanel() {
    state = state.copyWith(
      showSocialPanel: !state.showSocialPanel,
      showMembersPanel: false,
      showInvitePanel: false,
      showSettingsPanel: false,
    );
  }

  void inviteFriendToRoom(String friendId) {
    // Placeholder: send invite to friend
  }

  void toggleFollowUser(String userId) {
    final followed = Set<String>.from(state.followedUserIds);
    if (followed.contains(userId)) {
      followed.remove(userId);
    } else {
      followed.add(userId);
    }
    state = state.copyWith(followedUserIds: followed);
  }

  void acceptFriendRequest(String userId) {
    // Placeholder: accept request
  }

  void declineFriendRequest(String userId) {
    // Placeholder: decline request
  }

  // --- Mute / Chat ---

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  void setChatInput(String value) {
    state = state.copyWith(chatInput: value);
  }

  Future<void> sendMessage() async {
    final text = state.chatInput.trim();
    if (text.isEmpty) return;

    ProfileModel? profile;
    try {
      profile = await ref.read(currentUserProfileProvider.future);
    } catch (_) {}

    final senderName = profile?.username ?? 'User';
    final senderAvatarUrl = profile?.avatarUrl;

    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: state.room.currentUserId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      text: text,
      timestamp: DateTime.now(),
      isHost: state.room.isHost,
    );

    state = state.copyWith(
      messages: [...state.room.messages, message],
      chatInput: '',
    );

    if (!state.room.id.startsWith('room-') && _channel != null) {
      try {
        await _channel!.sendBroadcastMessage(
          event: 'chat_message',
          payload: {
            'id': message.id,
            'sender_id': message.senderId,
            'sender_name': message.senderName,
            'sender_avatar_url': message.senderAvatarUrl,
            'text': message.text,
            'timestamp': message.timestamp.toIso8601String(),
            'is_host': message.isHost,
          },
        );
      } catch (_) {}
    }
  }

  // --- Seats ---

  void joinSeat(int seatNumber) async {
    // Mic 1 is strictly for the Host
    if (seatNumber == 1 && !state.room.isHost) return;
    if (state.room.isHost && seatNumber != 1) return;

    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;
    if (seats[index].status != SeatStatus.empty) return;

    // Check if user is already on a seat and remove them from it (prevent double seat grabbing)
    final existingIndex = seats.indexWhere((s) => s.userId == state.room.currentUserId);
    if (existingIndex != -1) {
      seats[existingIndex] = seats[existingIndex].copyWith(
        status: SeatStatus.empty,
        userId: null,
        userName: null,
        avatarUrl: null,
        isMuted: false,
        isHost: false,
        isSpeaking: false,
        joinedAt: null,
      );
      _syncSeatToSupabase(seats[existingIndex]);
    }

    ProfileModel? profile;
    try {
      profile = await ref.read(currentUserProfileProvider.future);
    } catch (_) {}
    
    final userName = profile?.username ?? 'User';
    final avatarUrl = profile?.avatarUrl;

    seats[index] = seats[index].copyWith(
      status: SeatStatus.occupied,
      userId: state.room.currentUserId,
      userName: userName,
      avatarUrl: avatarUrl,
      isHost: state.room.currentUserId == state.room.hostId,
      joinedAt: DateTime.now(),
    );

    state = state.copyWith(
      seats: seats,
      members: _updateMembersFromSeats(seats, existingIndex != -1 ? existingIndex : null, index),
    );
    _syncSeatToSupabase(seats[index]);
  }

  void leaveSeat(int seatNumber) {
    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;

    final leavingUserId = seats[index].userId;

    seats[index] = seats[index].copyWith(
      status: SeatStatus.empty,
      userId: null,
      userName: null,
      avatarUrl: null,
      isMuted: false,
      isHost: false,
      isSpeaking: false,
      joinedAt: null,
    );

    state = state.copyWith(
      seats: seats,
      members: state.room.members.where((m) => m.id != leavingUserId).toList(),
    );
    _syncSeatToSupabase(seats[index]);
  }

  List<RoomMember> _updateMembersFromSeats(List<VoiceSeat> seats, int? oldSeatIndex, int newSeatIndex) {
    final members = List<RoomMember>.from(state.room.members);
    
    // Remove user from old seat (if moving seats)
    if (oldSeatIndex != null) {
      final oldUserId = state.room.seats[oldSeatIndex].userId;
      members.removeWhere((m) => m.id == oldUserId);
    }

    // Add user to new seat
    final seat = seats[newSeatIndex];
    if (seat.status == SeatStatus.occupied && seat.userId != null) {
      members.add(RoomMember(
        id: seat.userId!,
        name: seat.userName ?? 'Unknown',
        avatarUrl: seat.avatarUrl,
        score: seat.isHost ? 5000 : 1500,
        isHost: seat.isHost,
      ));
    }

    return members;
  }

  void toggleLockSeat(int seatNumber) {
    if (!state.room.isHost) return;
    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;

    final seat = seats[index];
    if (seat.status == SeatStatus.occupied) return;
    if (seat.status == SeatStatus.empty) {
      seats[index] = seat.copyWith(status: SeatStatus.locked);
    } else {
      seats[index] = seat.copyWith(status: SeatStatus.empty);
    }

    state = state.copyWith(seats: seats);
    _syncSeatToSupabase(seats[index]);
  }

  void toggleMuteUser(int seatNumber) {
    if (!state.room.isHost && state.room.currentUserId != state.room.seats.firstWhere((s) => s.seatNumber == seatNumber).userId) return;
    
    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;
    if (seats[index].status != SeatStatus.occupied) return;

    seats[index] = seats[index].copyWith(isMuted: !seats[index].isMuted);
    state = state.copyWith(seats: seats);
    _syncSeatToSupabase(seats[index]);
  }

  // --- Host Controls ---
  Future<void> lockAllSeats(bool lock) async {
    if (!state.room.isHost) return;
    
    // Update seats locally and sync to Supabase
    final seats = state.room.seats.map((seat) {
      if (seat.status == SeatStatus.occupied) return seat;
      final updatedSeat = seat.copyWith(status: lock ? SeatStatus.locked : SeatStatus.empty);
      _syncSeatToSupabase(updatedSeat);
      return updatedSeat;
    }).toList();
    
    state = state.copyWith(
      seats: seats,
      micLocked: lock,
    );

    // Update mic_locked in rooms table
    if (!state.room.id.startsWith('room-')) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('rooms').update({
          'mic_locked': lock,
        }).eq('id', state.room.id);
      } catch (_) {}
    }
  }

  void muteAllExceptHost(bool mute) {
    if (!state.room.isHost) return;
    final seats = state.room.seats.map((seat) {
      if (seat.status == SeatStatus.occupied && !seat.isHost) {
        final updatedSeat = seat.copyWith(isMuted: mute);
        _syncSeatToSupabase(updatedSeat);
        return updatedSeat;
      }
      return seat;
    }).toList();
    state = state.copyWith(seats: seats);
  }

  Future<void> transferHost(String newHostId) async {
    if (!state.room.isHost) return;

    // Remove old host flag from current seat
    final oldHostSeatIndex = state.room.seats.indexWhere((s) => s.userId == state.room.currentUserId);
    if (oldHostSeatIndex != -1) {
      final updatedOldHostSeat = state.room.seats[oldHostSeatIndex].copyWith(isHost: false);
      _syncSeatToSupabase(updatedOldHostSeat);
    }

    // Add host flag to new host's seat if they are on one
    final newHostSeatIndex = state.room.seats.indexWhere((s) => s.userId == newHostId);
    if (newHostSeatIndex != -1) {
      final updatedNewHostSeat = state.room.seats[newHostSeatIndex].copyWith(isHost: true);
      _syncSeatToSupabase(updatedNewHostSeat);
    }

    if (!state.room.id.startsWith('room-')) {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.from('rooms').update({
          'host_id': newHostId,
        }).eq('id', state.room.id);
      } catch (_) {}
    }
  }

  void inviteToMic(String userId) {
    if (!state.room.isHost) return;
    // In a full implementation, this would send a realtime broadcast or push notification
    // For now, we can log it or show a local toast
  }

  Future<void> _syncSeatToSupabase(VoiceSeat seat) async {
    if (state.room.id.startsWith('room-')) return; // Skip for dummy rooms
    
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('room_seats').upsert({
        'room_id': state.room.id,
        'seat_number': seat.seatNumber,
        'user_id': seat.userId,
        'user_name': seat.userName,
        'avatar_url': seat.avatarUrl,
        'is_muted': seat.isMuted,
        'is_locked': seat.status == SeatStatus.locked,
        'is_host': seat.isHost,
        'joined_at': seat.joinedAt?.toIso8601String(),
      }, onConflict: 'room_id,seat_number');
    } catch (e) {
      // Ignore
    }
  }

  // --- Panels ---

  void toggleMembersPanel() {
    state = state.copyWith(
      showMembersPanel: !state.showMembersPanel,
      showInvitePanel: false,
      showSettingsPanel: false,
      showSocialPanel: false,
    );
  }

  void toggleInvitePanel() {
    state = state.copyWith(
      showInvitePanel: !state.showInvitePanel,
      showMembersPanel: false,
      showSettingsPanel: false,
      showSocialPanel: false,
    );
  }

  void toggleSettingsPanel() {
    state = state.copyWith(
      showSettingsPanel: !state.showSettingsPanel,
      showMembersPanel: false,
      showInvitePanel: false,
      showSocialPanel: false,
    );
  }

  void closeAllPanels() {
    state = state.copyWith(
      showMembersPanel: false,
      showInvitePanel: false,
      showSettingsPanel: false,
      showSocialPanel: false,
    );
  }

  // --- Announcement ---

  void startEditAnnouncement() {
    state = state.copyWith(
      isEditingAnnouncement: true,
      announcementDraft: state.room.announcement.text,
    );
  }

  void setAnnouncementDraft(String value) {
    state = state.copyWith(announcementDraft: value);
  }

  void saveAnnouncement() {
    final text = state.announcementDraft.trim();
    if (text.isEmpty) return;

    final newAnnouncement = Announcement(text: text, updatedAt: DateTime.now());
    final activity = RoomActivity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: 'Ali',
      type: ActivityType.announcement,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      announcement: newAnnouncement,
      activities: [...state.room.activities, activity],
      isEditingAnnouncement: false,
    );
  }

  void cancelEditAnnouncement() {
    state = state.copyWith(
      isEditingAnnouncement: false,
      announcementDraft: '',
    );
  }

  void copyRoomId() {}

  Future<void> leaveRoom() async {
    final userId = state.room.currentUserId;
    final roomId = state.room.id;
    if (userId.isEmpty || roomId.isEmpty) return;

    // Leave any occupied seat
    final seatIndex = state.room.seats.indexWhere((s) => s.userId == userId);
    if (seatIndex != -1) {
      leaveSeat(state.room.seats[seatIndex].seatNumber);
    }

    // Remove from room_members table
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
    } catch (_) {}
  }
}

final familyWatchRoomViewModelProvider =
    NotifierProvider<FamilyWatchRoomViewModel, FamilyWatchRoomState>(
  FamilyWatchRoomViewModel.new,
);
