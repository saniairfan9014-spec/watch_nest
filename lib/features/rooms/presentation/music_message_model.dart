import 'package:equatable/equatable.dart';

class MusicMessage extends Equatable {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const MusicMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, senderName, text, timestamp];
}
