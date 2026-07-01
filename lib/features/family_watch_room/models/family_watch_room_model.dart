import 'package:equatable/equatable.dart';
import '../../rooms/presentation/room_type.dart';
import 'voice_seat_model.dart';
import 'room_member_model.dart';
import 'chat_message_model.dart';
import 'announcement_model.dart';
import 'room_activity_model.dart';
import 'playback_state_model.dart';
import 'media_queue_item_model.dart';

class FamilyWatchRoom extends Equatable {
  final String id;
  final String name;
  final String roomId;
  final int points;
  final List<VoiceSeat> seats;
  final List<RoomMember> members;
  final Announcement announcement;
  final List<ChatMessage> messages;
  final List<RoomActivity> activities;
  final String hostId;
  final String currentUserId;
  final RoomType roomType;
  final bool micLocked;

  // --- New: Queue & Playback State ---
  final PlaybackState? playbackState;
  final List<MediaQueueItem> queue;

  const FamilyWatchRoom({
    required this.id,
    required this.name,
    required this.roomId,
    this.points = 0,
    this.seats = const [],
    this.members = const [],
    required this.announcement,
    this.messages = const [],
    this.activities = const [],
    required this.hostId,
    required this.currentUserId,
    this.roomType = RoomType.general,
    this.micLocked = false,
    this.playbackState,
    this.queue = const [],
  });

  bool get isHost => currentUserId == hostId;

  /// Returns the currently-playing queue item, or null.
  MediaQueueItem? get currentQueueItem {
    if (playbackState?.currentQueueItemId == null) return null;
    final idx = queue.indexWhere((q) => q.id == playbackState!.currentQueueItemId);
    return idx != -1 ? queue[idx] : null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        roomId,
        points,
        seats,
        members,
        announcement,
        messages,
        activities,
        hostId,
        currentUserId,
        roomType,
        micLocked,
        playbackState,
        queue,
      ];
}

