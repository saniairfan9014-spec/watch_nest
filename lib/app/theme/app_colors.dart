import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryLight = Color(0xFFB47CFF);
  static const Color primaryDark = Color(0xFF4A148C);
  static const Color accent = Color(0xFFFF4081);

  // Background
  static const Color bg = Color(0xFF0A0A0F);
  static const Color bgCard = Color(0xFF13131A);
  static const Color bgElevated = Color(0xFF1C1C28);
  static const Color bgSurface = Color(0xFF22222F);

  // Text
  static const Color textPrimary = Color(0xFFF5F5FF);
  static const Color textSecondary = Color(0xFF9898B0);
  static const Color textMuted = Color(0xFF5A5A70);

  // Semantic
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD740);
  static const Color error = Color(0xFFFF5252);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFFB54DFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0D0D18), Color(0xFF0A0A0F), Color(0xFF0F0A18)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
