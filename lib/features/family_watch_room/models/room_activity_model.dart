import 'package:equatable/equatable.dart';

enum ActivityType { join, leave, like, announcement }

class RoomActivity extends Equatable {
  final String id;
  final String userName;
  final ActivityType type;
  final DateTime timestamp;

  const RoomActivity({
    required this.id,
    required this.userName,
    required this.type,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, userName, type, timestamp];
}
