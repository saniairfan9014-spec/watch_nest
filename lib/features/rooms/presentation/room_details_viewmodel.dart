import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/room_model.dart';
import '../../../core/models/member_model.dart';
import '../../../core/models/queue_item_model.dart';
import '../../../core/models/chat_message_model.dart';
import 'room_type.dart';

class RoomDetailsState {
  final RoomModel room;
  final List<QueueItem> queue;
  final List<ChatMessage> messages;
  final List<Member> members;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;

  RoomDetailsState({
    required this.room,
    this.queue = const [],
    this.messages = const [],
    this.members = const [],
    this.isPlaying = true,
    this.currentPosition = const Duration(minutes: 45, seconds: 10),
    this.totalDuration = const Duration(hours: 2, minutes: 10, seconds: 45),
  });

  RoomDetailsState copyWith({
    RoomModel? room,
    List<QueueItem>? queue,
    List<ChatMessage>? messages,
    List<Member>? members,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return RoomDetailsState(
      room: room ?? this.room,
      queue: queue ?? this.queue,
      messages: messages ?? this.messages,
      members: members ?? this.members,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }
}

class RoomDetailsViewModel extends Notifier<RoomDetailsState> {
  @override
  RoomDetailsState build() {
    return _createSampleState();
  }

  RoomDetailsState _createSampleState() {
    final user = Supabase.instance.client.auth.currentUser;

    return RoomDetailsState(
      room: RoomModel(
        id: 'room-1',
        name: 'Family Movie Night',
        hostId: user?.id ?? 'host-1',
        roomType: RoomType.movie,
        isPrivate: false,
        currentMemberCount: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      queue: [
        const QueueItem(position: 1, title: 'Avengers: Endgame', addedBy: 'Sara'),
        const QueueItem(position: 2, title: 'The Dark Knight', addedBy: 'Ahmed'),
        const QueueItem(position: 3, title: 'Interstellar', addedBy: 'Dad'),
      ],
      messages: [
        ChatMessage(
          id: '1',
          senderName: 'Sara',
          text: 'Is everyone ready?',
          timestamp: DateTime(2026, 6, 18, 11, 30),
        ),
        ChatMessage(
          id: '2',
          senderName: 'Ahmed',
          text: 'Yes, start whenever!',
          timestamp: DateTime(2026, 6, 18, 11, 31),
        ),
        ChatMessage(
          id: '3',
          senderName: 'Dad',
          text: 'Let me grab popcorn first 🍿',
          timestamp: DateTime(2026, 6, 18, 11, 32),
        ),
      ],
      members: [
        const Member(id: '1', name: 'Sara', role: 'Host'),
        const Member(id: '2', name: 'Ahmed', role: 'Member'),
        const Member(id: '3', name: 'Dad', role: 'Member'),
      ],
    );
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void rewind10() {
    final newPosition = state.currentPosition - const Duration(seconds: 10);
    state = state.copyWith(
      currentPosition: newPosition.isNegative ? Duration.zero : newPosition,
    );
  }

  void forward10() {
    final newPosition = state.currentPosition + const Duration(seconds: 10);
    state = state.copyWith(
      currentPosition: newPosition > state.totalDuration
          ? state.totalDuration
          : newPosition,
    );
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: user?.userMetadata?['name'] as String? ?? 'You',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }
}

final roomDetailsViewModelProvider =
    NotifierProvider.autoDispose<RoomDetailsViewModel, RoomDetailsState>(
  RoomDetailsViewModel.new,
);
