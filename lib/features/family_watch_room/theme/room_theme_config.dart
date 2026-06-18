import 'package:flutter/material.dart';
import '../../rooms/presentation/room_type.dart';

class RoomThemeConfig {
  final RoomType roomType;
  final MaterialColor primarySwatch;
  final Color seatOccupiedColor;
  final Color seatEmptyColor;
  final Color seatLockedColor;
  final Color accentColor;
  final IconData roomIcon;
  final IconData seatIcon;
  final String backgroundHint;

  const RoomThemeConfig({
    required this.roomType,
    required this.primarySwatch,
    required this.seatOccupiedColor,
    required this.seatEmptyColor,
    required this.seatLockedColor,
    required this.accentColor,
    required this.roomIcon,
    required this.seatIcon,
    required this.backgroundHint,
  });
}
