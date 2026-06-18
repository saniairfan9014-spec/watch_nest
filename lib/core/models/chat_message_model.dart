import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderName;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, senderName, text, timestamp];
}
