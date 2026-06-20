enum RoomType {
  general,
  movie,
  music;

  String get label {
    switch (this) {
      case RoomType.general:
        return 'General Mode';
      case RoomType.movie:
        return 'Movie Mode';
      case RoomType.music:
        return 'Music Mode';
    }
  }

  String get subtitle {
    switch (this) {
      case RoomType.general:
        return 'Choose between movie and music';
      case RoomType.movie:
        return 'Cinema theater experience';
      case RoomType.music:
        return 'Vinyl records & music vibes';
    }
  }
}
