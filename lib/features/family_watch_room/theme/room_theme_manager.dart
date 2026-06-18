import 'package:flutter/material.dart';
import '../../rooms/presentation/room_type.dart';
import 'room_theme_config.dart';

class RoomThemeManager {
  RoomThemeConfig getConfig(RoomType type) {
    switch (type) {
      case RoomType.family:
        return const RoomThemeConfig(
          roomType: RoomType.family,
          primarySwatch: Colors.orange,
          seatOccupiedColor: Color(0xFFFFF3E0),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFFFF9800),
          roomIcon: Icons.home_rounded,
          seatIcon: Icons.weekend_rounded,
          backgroundHint: 'Cozy living room atmosphere',
        );
      case RoomType.movie:
        return const RoomThemeConfig(
          roomType: RoomType.movie,
          primarySwatch: Colors.deepPurple,
          seatOccupiedColor: Color(0xFFEDE7F6),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFF7C4DFF),
          roomIcon: Icons.movie_rounded,
          seatIcon: Icons.theater_comedy_rounded,
          backgroundHint: 'Cinema theater atmosphere',
        );
      case RoomType.music:
        return const RoomThemeConfig(
          roomType: RoomType.music,
          primarySwatch: Colors.pink,
          seatOccupiedColor: Color(0xFFFCE4EC),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFFE91E63),
          roomIcon: Icons.music_note_rounded,
          seatIcon: Icons.album_rounded,
          backgroundHint: 'Vinyl records & music vibes',
        );
      case RoomType.gaming:
        return const RoomThemeConfig(
          roomType: RoomType.gaming,
          primarySwatch: Colors.red,
          seatOccupiedColor: Color(0xFFFFEBEE),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFE0F7FA),
          accentColor: Color(0xFFF44336),
          roomIcon: Icons.sports_esports_rounded,
          seatIcon: Icons.videogame_asset_rounded,
          backgroundHint: 'Gaming room setup',
        );
      case RoomType.study:
        return const RoomThemeConfig(
          roomType: RoomType.study,
          primarySwatch: Colors.teal,
          seatOccupiedColor: Color(0xFFE0F2F1),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFF009688),
          roomIcon: Icons.menu_book_rounded,
          seatIcon: Icons.lightbulb_rounded,
          backgroundHint: 'Library & workspace focus',
        );
      case RoomType.chill:
        return const RoomThemeConfig(
          roomType: RoomType.chill,
          primarySwatch: Colors.indigo,
          seatOccupiedColor: Color(0xFFE8EAF6),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFF5C6BC0),
          roomIcon: Icons.air_rounded,
          seatIcon: Icons.whatshot_rounded,
          backgroundHint: 'Relaxed hangout space',
        );
      case RoomType.party:
        return const RoomThemeConfig(
          roomType: RoomType.party,
          primarySwatch: Colors.amber,
          seatOccupiedColor: Color(0xFFFFF8E1),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFFFFC107),
          roomIcon: Icons.celebration_rounded,
          seatIcon: Icons.celebration_rounded,
          backgroundHint: 'Celebration & fun atmosphere',
        );
    }
  }
}
