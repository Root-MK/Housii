import 'package:flutter/material.dart';

/// Housii App Colors - 2025 Design
/// White and Dark Purple color scheme
class AppColors {
  AppColors._();

  // Primary Colors - Purple
  static const Color primaryPurple = Color(0xFF5B21B6);
  static const Color primaryPurpleLight = Color(0xFF7C3AED);
  static const Color primaryPurpleDark = Color(0xFF3B0764);
  static const Color primaryPurpleSubtle = Color(0xFFEDE9FE);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color gray = Color(0xFF9CA3AF);
  static const Color darkGray = Color(0xFF374151);
  static const Color black = Color(0xFF111827);

  // Accent Colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  
  // Additional accent colors
  static const Color accentGreen = Color(0xFF059669);
  static const Color accentGreenSubtle = Color(0xFFD1FAE5);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentBlueSubtle = Color(0xFFDBEAFE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkPurpleGradient = LinearGradient(
    colors: [primaryPurpleDark, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
