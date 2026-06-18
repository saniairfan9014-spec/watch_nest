import '../models/family_watch_room_model.dart';
import '../models/voice_seat_model.dart';
import '../models/room_member_model.dart';
import '../models/chat_message_model.dart';
import '../models/announcement_model.dart';
import '../models/room_activity_model.dart';

class FamilyWatchRoomState {
  final FamilyWatchRoom room;
  final bool isMuted;
  final String chatInput;
  final bool showMembersPanel;
  final bool showInvitePanel;
  final bool showSettingsPanel;
  final bool showSocialPanel;
  final bool isEditingAnnouncement;
  final String announcementDraft;
  final String searchQuery;
  final List<RoomMember> friends;
  final List<RoomMember> friendRequests;
  final List<RoomMember> onlineFriends;
  final Set<String> followedUserIds;

  const FamilyWatchRoomState({
    required this.room,
    this.isMuted = false,
    this.chatInput = '',
    this.showMembersPanel = false,
    this.showInvitePanel = false,
    this.showSettingsPanel = false,
    this.showSocialPanel = false,
    this.isEditingAnnouncement = false,
    this.announcementDraft = '',
    this.searchQuery = '',
    this.friends = const [],
    this.friendRequests = const [],
    this.onlineFriends = const [],
    this.followedUserIds = const {},
  });

  FamilyWatchRoomState copyWith({
    FamilyWatchRoom? room,
    bool? isMuted,
    String? chatInput,
    bool? showMembersPanel,
    bool? showInvitePanel,
    bool? showSettingsPanel,
    bool? showSocialPanel,
    bool? isEditingAnnouncement,
    String? announcementDraft,
    String? searchQuery,
    List<VoiceSeat>? seats,
    List<RoomMember>? members,
    List<RoomMember>? friends,
    List<RoomMember>? friendRequests,
    List<RoomMember>? onlineFriends,
    Set<String>? followedUserIds,
    List<ChatMessage>? messages,
    List<RoomActivity>? activities,
    Announcement? announcement,
  }) {
    var updatedRoom = room ?? this.room;
    if (seats != null || members != null || messages != null ||
        activities != null || announcement != null) {
      updatedRoom = FamilyWatchRoom(
        id: updatedRoom.id,
        name: updatedRoom.name,
        roomId: updatedRoom.roomId,
        points: updatedRoom.points,
        seats: seats ?? updatedRoom.seats,
        members: members ?? updatedRoom.members,
        announcement: announcement ?? updatedRoom.announcement,
        messages: messages ?? updatedRoom.messages,
        activities: activities ?? updatedRoom.activities,
        hostId: updatedRoom.hostId,
        currentUserId: updatedRoom.currentUserId,
      );
    }
    return FamilyWatchRoomState(
      room: updatedRoom,
      isMuted: isMuted ?? this.isMuted,
      chatInput: chatInput ?? this.chatInput,
      showMembersPanel: showMembersPanel ?? this.showMembersPanel,
      showInvitePanel: showInvitePanel ?? this.showInvitePanel,
      showSettingsPanel: showSettingsPanel ?? this.showSettingsPanel,
      showSocialPanel: showSocialPanel ?? this.showSocialPanel,
      isEditingAnnouncement: isEditingAnnouncement ?? this.isEditingAnnouncement,
      announcementDraft: announcementDraft ?? this.announcementDraft,
      searchQuery: searchQuery ?? this.searchQuery,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      onlineFriends: onlineFriends ?? this.onlineFriends,
      followedUserIds: followedUserIds ?? this.followedUserIds,
    );
  }
}
