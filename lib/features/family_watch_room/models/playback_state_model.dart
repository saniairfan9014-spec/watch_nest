import 'package:equatable/equatable.dart';

class PlaybackState extends Equatable {
  final String roomId;
  final String? currentQueueItemId;
  final bool isPlaying;
  final int currentPosition;
  final String updatedBy;
  final DateTime updatedAt;

  const PlaybackState({
    required this.roomId,
    this.currentQueueItemId,
    required this.isPlaying,
    required this.currentPosition,
    required this.updatedBy,
    required this.updatedAt,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      roomId: json['room_id'] as String,
      currentQueueItemId: json['current_queue_item_id'] as String?,
      isPlaying: json['is_playing'] as bool? ?? false,
      currentPosition: json['current_position'] as int? ?? 0,
      updatedBy: json['updated_by'] as String,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'current_queue_item_id': currentQueueItemId,
      'is_playing': isPlaying,
      'current_position': currentPosition,
      'updated_by': updatedBy,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlaybackState copyWith({
    String? roomId,
    String? currentQueueItemId,
    bool? isPlaying,
    int? currentPosition,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return PlaybackState(
      roomId: roomId ?? this.roomId,
      currentQueueItemId: currentQueueItemId ?? this.currentQueueItemId,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        roomId,
        currentQueueItemId,
        isPlaying,
        currentPosition,
        updatedBy,
        updatedAt,
      ];
}
