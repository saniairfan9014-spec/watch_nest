import 'package:equatable/equatable.dart';
import '../../features/rooms/presentation/room_type.dart';

class RoomModel extends Equatable {
  final String id;
  final String name;
  final String hostId;
  final RoomType? roomType;
  final bool isPrivate;
  final String? password;
  final String? inviteCode;
  final int currentMemberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoomModel({
    required this.id,
    required this.name,
    required this.hostId,
    this.roomType,
    this.isPrivate = false,
    this.password,
    this.inviteCode,
    this.currentMemberCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      hostId: json['host_id'] as String,
      roomType: json['room_type'] != null
          ? RoomType.values.firstWhere(
              (e) => e.name == json['room_type'],
              orElse: () => RoomType.family,
            )
          : RoomType.family,
      isPrivate: json['is_private'] as bool? ?? false,
      password: json['password'] as String?,
      inviteCode: json['invite_code'] as String?,
      currentMemberCount: json['current_member_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host_id': hostId,
        if (roomType != null)
          'room_type': roomType!.name
        else
          'room_type': null,
        'is_private': isPrivate,
        'password': password,
        'invite_code': inviteCode,
        'current_member_count': currentMemberCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        hostId,
        roomType,
        isPrivate,
        password,
        inviteCode,
        currentMemberCount,
        createdAt,
        updatedAt,
      ];
}
