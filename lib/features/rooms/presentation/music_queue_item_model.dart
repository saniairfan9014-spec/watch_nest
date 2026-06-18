import 'package:equatable/equatable.dart';

class MusicQueueItem extends Equatable {
  final int position;
  final String title;
  final String artist;

  const MusicQueueItem({
    required this.position,
    required this.title,
    required this.artist,
  });

  @override
  List<Object?> get props => [position, title, artist];
}
