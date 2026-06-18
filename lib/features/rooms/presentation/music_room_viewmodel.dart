import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'music_track_model.dart';
import 'music_queue_item_model.dart';
import 'music_member_model.dart';
import 'music_message_model.dart';

class MusicRoomState {
  final bool isPlaying;
  final Duration currentPosition;
  final MusicTrack currentTrack;
  final List<MusicQueueItem> queue;
  final List<MusicMessage> messages;
  final List<MusicMember> members;

  MusicRoomState({
    this.isPlaying = true,
    this.currentPosition = const Duration(minutes: 1, seconds: 20),
    required this.currentTrack,
    this.queue = const [],
    this.messages = const [],
    this.members = const [],
  });

  MusicRoomState copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    MusicTrack? currentTrack,
    List<MusicQueueItem>? queue,
    List<MusicMessage>? messages,
    List<MusicMember>? members,
  }) {
    return MusicRoomState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      messages: messages ?? this.messages,
      members: members ?? this.members,
    );
  }
}

class MusicRoomViewModel extends Notifier<MusicRoomState> {
  int _currentTrackIndex = 0;

  final List<MusicTrack> _tracks = const [
    MusicTrack(title: 'Perfect', artist: 'Ed Sheeran'),
    MusicTrack(title: 'Levitating', artist: 'Dua Lipa'),
    MusicTrack(title: 'Until I Found You', artist: 'Stephen Sanchez'),
  ];

  @override
  MusicRoomState build() {
    return MusicRoomState(
      currentTrack: _tracks[0],
      queue: const [
        MusicQueueItem(position: 1, title: 'Perfect', artist: 'Ed Sheeran'),
        MusicQueueItem(position: 2, title: 'Levitating', artist: 'Dua Lipa'),
        MusicQueueItem(position: 3, title: 'Until I Found You', artist: 'Stephen Sanchez'),
      ],
      messages: [
        MusicMessage(
          id: '1',
          senderName: 'Sara',
          text: 'Great song choice!',
          timestamp: DateTime(2026, 6, 18, 11, 30),
        ),
        MusicMessage(
          id: '2',
          senderName: 'Ahmed',
          text: 'Add more songs please',
          timestamp: DateTime(2026, 6, 18, 11, 31),
        ),
        MusicMessage(
          id: '3',
          senderName: 'Ali',
          text: 'Loving this playlist!',
          timestamp: DateTime(2026, 6, 18, 11, 32),
        ),
      ],
      members: const [
        MusicMember(id: '1', name: 'Sara', role: 'Host'),
        MusicMember(id: '2', name: 'Ahmed', role: 'Member'),
        MusicMember(id: '3', name: 'Ali', role: 'Member'),
        MusicMember(id: '4', name: 'Dad', role: 'Member'),
      ],
    );
  }

  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  void previousTrack() {
    if (_currentTrackIndex > 0) {
      _currentTrackIndex--;
      state = state.copyWith(
        currentTrack: _tracks[_currentTrackIndex],
        currentPosition: Duration.zero,
        isPlaying: true,
      );
    }
  }

  void nextTrack() {
    if (_currentTrackIndex < _tracks.length - 1) {
      _currentTrackIndex++;
      state = state.copyWith(
        currentTrack: _tracks[_currentTrackIndex],
        currentPosition: Duration.zero,
        isPlaying: true,
      );
    }
  }

  void seekTo(double value) {
    final track = state.currentTrack;
    final position = Duration(milliseconds: (value * track.duration.inMilliseconds).round());
    state = state.copyWith(currentPosition: position);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final message = MusicMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: 'You',
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, message]);
  }
}

final musicRoomViewModelProvider =
    NotifierProvider.autoDispose<MusicRoomViewModel, MusicRoomState>(
  MusicRoomViewModel.new,
);
