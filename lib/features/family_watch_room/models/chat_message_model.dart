import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String text;
  final DateTime timestamp;
  final bool isHost;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.text,
    required this.timestamp,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [id, senderId, senderName, senderAvatarUrl, text, timestamp, isHost];
}
