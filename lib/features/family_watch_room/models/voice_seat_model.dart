import 'package:equatable/equatable.dart';

enum SeatStatus { empty, occupied, locked }

class VoiceSeat extends Equatable {
  final int seatNumber;
  final SeatStatus status;
  final String? userId;
  final String? userName;
  final String? avatarUrl;
  final bool isMuted;
  final bool isHost;

  const VoiceSeat({
    required this.seatNumber,
    this.status = SeatStatus.empty,
    this.userId,
    this.userName,
    this.avatarUrl,
    this.isMuted = false,
    this.isHost = false,
  });

  VoiceSeat copyWith({
    int? seatNumber,
    SeatStatus? status,
    String? userId,
    String? userName,
    String? avatarUrl,
    bool? isMuted,
    bool? isHost,
  }) {
    return VoiceSeat(
      seatNumber: seatNumber ?? this.seatNumber,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isMuted: isMuted ?? this.isMuted,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  List<Object?> get props => [seatNumber, status, userId, userName, avatarUrl, isMuted, isHost];
}
