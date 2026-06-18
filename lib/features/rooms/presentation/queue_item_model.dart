import 'package:equatable/equatable.dart';

class QueueItem extends Equatable {
  final String id;
  final String title;
  final String addedBy;

  const QueueItem({
    required this.id,
    required this.title,
    required this.addedBy,
  });

  QueueItem copyWith({
    String? id,
    String? title,
    String? addedBy,
  }) {
    return QueueItem(
      id: id ?? this.id,
      title: title ?? this.title,
      addedBy: addedBy ?? this.addedBy,
    );
  }

  @override
  List<Object?> get props => [id, title, addedBy];
}
