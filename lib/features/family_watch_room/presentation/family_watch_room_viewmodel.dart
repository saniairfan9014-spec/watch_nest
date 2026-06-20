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
    final profile = ref.watch(currentUserProfileProvider).value;

    ref.onDispose(() {
      _channel?.unsubscribe();
    });

    _initRealtime('room-1'); // Default to room-1 for now, in a real app this would be passed in

    return FamilyWatchRoomState(
      room: _createSampleRoom(profile),
      friends: const [
        RoomMember(id: 'user-6', name: 'Hassan', score: 2100),
        RoomMember(id: 'user-7', name: 'Fatima', score: 1900),
        RoomMember(id: 'user-8', name: 'Omar', score: 1600),
        RoomMember(id: 'user-9', name: 'Aisha', score: 1400),
      ],
      friendRequests: const [
        RoomMember(id: 'user-10', name: 'Bilal', score: 800),
        RoomMember(id: 'user-11', name: 'Zainab', score: 700),
      ],
      onlineFriends: const [
        RoomMember(id: 'user-6', name: 'Hassan', score: 2100),
        RoomMember(id: 'user-8', name: 'Omar', score: 1600),
      ],
      followedUserIds: {'user-2', 'user-6'},
    );
  }

  FamilyWatchRoom _createSampleRoom(ProfileModel? profile) {
    return FamilyWatchRoom(
      id: 'room-1',
      name: 'General Room',
      roomId: '25163166097',
      points: 148600,
      hostId: 'user-1',
      currentUserId: 'user-1',
      roomType: RoomType.general,
      announcement: Announcement(
        text: 'The host didn\'t add anything yet',
        updatedAt: DateTime(2026, 6, 18),
      ),
      seats: List.generate(10, (i) {
        final seatNum = i + 1;
        switch (seatNum) {
          case 1:
            return VoiceSeat(
              seatNumber: 1,
              status: SeatStatus.occupied,
              userId: 'user-1',
              userName: 'Mic 1',
              isHost: true,
            );
          case 2:
            return VoiceSeat(
              seatNumber: 2,
              status: SeatStatus.occupied,
              userId: 'user-2',
              userName: 'Mic 2',
            );
          case 3:
            return VoiceSeat(
              seatNumber: 3,
              status: SeatStatus.occupied,
              userId: 'user-3',
              userName: 'Mic 3',
            );
          default:
            return VoiceSeat(seatNumber: seatNum);
        }
      }),
      members: profile != null
          ? [
              RoomMember(
                id: profile.id,
                name: profile.username,
                avatarUrl: profile.avatarUrl,
                isHost: true,
              )
            ]
          : const [],
      messages: const [],
      activities: const [],
    );
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
    
    _channel!.subscribe();
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

    state = state.copyWith(seats: seats);
  }

  void _handleMovieSync(Map<String, dynamic> data) {
    final videoId = data['current_video_id'] as String?;
    final position = data['current_position'] as int? ?? 0;
    final isPlaying = data['is_playing'] as bool? ?? false;

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

  void sendMessage() {
    final text = state.chatInput.trim();
    if (text.isEmpty) return;

    final profile = ref.read(currentUserProfileProvider).value;
    final senderName = profile?.username ?? 'Ali';
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

    final profile = ref.read(currentUserProfileProvider).value;
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

    state = state.copyWith(seats: seats);
    _syncSeatToSupabase(seats[index]);
  }

  void leaveSeat(int seatNumber) {
    final seats = [...state.room.seats];
    final index = seats.indexWhere((s) => s.seatNumber == seatNumber);
    if (index == -1) return;

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

    state = state.copyWith(seats: seats);
    _syncSeatToSupabase(seats[index]);
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
  void lockAllSeats(bool lock) {
    if (!state.room.isHost) return;
    final seats = state.room.seats.map((seat) {
      if (seat.status == SeatStatus.occupied) return seat;
      final updatedSeat = seat.copyWith(status: lock ? SeatStatus.locked : SeatStatus.empty);
      _syncSeatToSupabase(updatedSeat);
      return updatedSeat;
    }).toList();
    state = state.copyWith(seats: seats);
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

  void leaveRoom() {}
}

final familyWatchRoomViewModelProvider =
    NotifierProvider<FamilyWatchRoomViewModel, FamilyWatchRoomState>(
  FamilyWatchRoomViewModel.new,
);
