import 'package:equatable/equatable.dart';

class MediaQueueItem extends Equatable {
  final String id;
  final String roomId;
  final String title;
  final String mediaUrl;
  final String? thumbnailUrl;
  final String mediaType;
  final String addedBy;
  final int position;
  final DateTime createdAt;

  const MediaQueueItem({
    required this.id,
    required this.roomId,
    required this.title,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.mediaType,
    required this.addedBy,
    required this.position,
    required this.createdAt,
  });

  factory MediaQueueItem.fromJson(Map<String, dynamic> json) {
    return MediaQueueItem(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      title: json['title'] as String,
      mediaUrl: json['media_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      mediaType: json['media_type'] as String,
      addedBy: json['added_by'] as String,
      position: json['position'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'title': title,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'media_type': mediaType,
      'added_by': addedBy,
      'position': position,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MediaQueueItem copyWith({
    String? id,
    String? roomId,
    String? title,
    String? mediaUrl,
    String? thumbnailUrl,
    String? mediaType,
    String? addedBy,
    int? position,
    DateTime? createdAt,
  }) {
    return MediaQueueItem(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mediaType: mediaType ?? this.mediaType,
      addedBy: addedBy ?? this.addedBy,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roomId,
        title,
        mediaUrl,
        thumbnailUrl,
        mediaType,
        addedBy,
        position,
        createdAt,
      ];
}
