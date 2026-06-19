import 'package:equatable/equatable.dart';

class RoomMember extends Equatable {
  final String id;
  final String name;
  final String? avatarUrl;
  final int score;
  final bool isHost;

  const RoomMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.score = 0,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [id, name, avatarUrl, score, isHost];
}
