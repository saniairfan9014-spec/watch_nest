enum RoomType {
  family,
  movie,
  music,
  gaming,
  study,
  chill,
  party;

  String get label {
    switch (this) {
      case RoomType.family:
        return 'Family Mode';
      case RoomType.movie:
        return 'Movie Mode';
      case RoomType.music:
        return 'Music Mode';
      case RoomType.gaming:
        return 'Gaming Mode';
      case RoomType.study:
        return 'Study Mode';
      case RoomType.chill:
        return 'Chill Mode';
      case RoomType.party:
        return 'Party Mode';
    }
  }

  String get subtitle {
    switch (this) {
      case RoomType.family:
        return 'Cozy living room watch party';
      case RoomType.movie:
        return 'Cinema theater experience';
      case RoomType.music:
        return 'Vinyl records & music vibes';
      case RoomType.gaming:
        return 'Gaming room setup';
      case RoomType.study:
        return 'Library & workspace focus';
      case RoomType.chill:
        return 'Relaxed hangout space';
      case RoomType.party:
        return 'Celebration & fun';
    }
  }
}
