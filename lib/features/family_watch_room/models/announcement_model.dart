import 'package:equatable/equatable.dart';

class Announcement extends Equatable {
  final String text;
  final DateTime updatedAt;

  const Announcement({
    required this.text,
    required this.updatedAt,
  });

  Announcement copyWith({
    String? text,
    DateTime? updatedAt,
  }) {
    return Announcement(
      text: text ?? this.text,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [text, updatedAt];
}
