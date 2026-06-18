import 'package:equatable/equatable.dart';

class QueueItem extends Equatable {
  final int position;
  final String title;
  final String addedBy;
  final String? thumbnailUrl;

  const QueueItem({
    required this.position,
    required this.title,
    required this.addedBy,
    this.thumbnailUrl,
  });

  @override
  List<Object?> get props => [position, title, addedBy, thumbnailUrl];
}
