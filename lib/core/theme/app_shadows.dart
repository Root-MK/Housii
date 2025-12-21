import 'package:flutter/material.dart';

/// Housii App Shadows - 2025 Soft shadows
class AppShadows {
  AppShadows._();

  // Subtle elevation
  static List<BoxShadow> get shadow1 => [
    BoxShadow(
      color: const Color(0x0A000000),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Medium elevation
  static List<BoxShadow> get shadow2 => [
    BoxShadow(
      color: const Color(0x14000000),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // High elevation
  static List<BoxShadow> get shadow3 => [
    BoxShadow(
      color: const Color(0x1F000000),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // Purple glow (for buttons, FAB)
  static List<BoxShadow> get purpleGlow => [
    BoxShadow(
      color: const Color(0x405B21B6),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
}
