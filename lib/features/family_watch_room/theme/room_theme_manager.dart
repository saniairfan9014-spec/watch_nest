import 'package:flutter/material.dart';
import '../../rooms/presentation/room_type.dart';
import 'room_theme_config.dart';

class RoomThemeManager {
  RoomThemeConfig getConfig(RoomType type) {
    switch (type) {
      case RoomType.general:
        return const RoomThemeConfig(
          roomType: RoomType.general,
          primarySwatch: Colors.blue,
          seatOccupiedColor: Color(0xFFE3F2FD),
          seatEmptyColor: Color(0xFFF5F5F5),
          seatLockedColor: Color(0xFFFFEBEE),
          accentColor: Color(0xFF2196F3),
          roomIcon: Icons.dashboard_rounded,
          seatIcon: Icons.person_rounded,
          backgroundHint: 'General room - choose your vibe',
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
    }
  }
}
