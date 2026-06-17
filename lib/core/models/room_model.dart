import 'package:equatable/equatable.dart';

enum RoomType { movie, music }

class RoomModel extends Equatable {
  final String id;
  final String name;
  final String hostId;
  final RoomType type;
  final bool isPublic;
  final int memberCount;
  final String? currentMediaTitle;
  final String? thumbnailUrl;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    required this.type,
    required this.isPublic,
    required this.memberCount,
    this.currentMediaTitle,
    this.thumbnailUrl,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hostId: json['host_id'] as String,
      type: json['type'] == 'music' ? RoomType.music : RoomType.movie,
      isPublic: json['is_public'] as bool? ?? true,
      memberCount: json['member_count'] as int? ?? 0,
      currentMediaTitle: json['current_media_title'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host_id': hostId,
        'type': type.name,
        'is_public': isPublic,
        'member_count': memberCount,
        'current_media_title': currentMediaTitle,
        'thumbnail_url': thumbnailUrl,
        'created_at': createdAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        hostId,
        type,
        isPublic,
        memberCount,
        currentMediaTitle,
        thumbnailUrl,
        createdAt,
      ];
}
