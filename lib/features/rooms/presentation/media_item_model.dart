import 'package:equatable/equatable.dart';

class MediaItem extends Equatable {
  final String id;
  final String title;
  final String duration;

  const MediaItem({
    required this.id,
    required this.title,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, title, duration];
}
