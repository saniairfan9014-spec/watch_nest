import 'package:equatable/equatable.dart';

class RoomInvite extends Equatable {
  final String roomId;
  final String inviteCode;
  final String createdBy;
  final DateTime expiresAt;

  const RoomInvite({
    required this.roomId,
    required this.inviteCode,
    required this.createdBy,
    required this.expiresAt,
  });

  factory RoomInvite.fromJson(Map<String, dynamic> json) {
    return RoomInvite(
      roomId: json['room_id'] as String,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        roomId,
        inviteCode,
        createdBy,
        expiresAt,
      ];
}
