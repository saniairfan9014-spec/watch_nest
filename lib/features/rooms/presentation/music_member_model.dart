import 'package:equatable/equatable.dart';

class MusicMember extends Equatable {
  final String id;
  final String name;
  final String role;

  const MusicMember({
    required this.id,
    required this.name,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, role];
}
