import 'package:equatable/equatable.dart';

class MusicTrack extends Equatable {
  final String title;
  final String artist;
  final Duration duration;

  const MusicTrack({
    required this.title,
    required this.artist,
    this.duration = const Duration(minutes: 4, seconds: 23),
  });

  @override
  List<Object?> get props => [title, artist, duration];
}
