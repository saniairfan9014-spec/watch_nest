import 'package:equatable/equatable.dart';

class RoomMember extends Equatable {
  final String id;
  final String name;
  final int score;
  final bool isHost;

  const RoomMember({
    required this.id,
    required this.name,
    this.score = 0,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [id, name, score, isHost];
}
