import 'package:flutter/material.dart';

/// All app colors. Never hardcode Color() in widgets — use AppColors.
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF4F46E5);       // Indigo
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF3730A3);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  // Neutral
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);

  // Surface
  static const surface = Colors.white;
  static const background = neutral50;
  static const cardBackground = Colors.white;

  // Text
  static const textPrimary = neutral900;
  static const textSecondary = neutral500;
  static const textHint = neutral400;
}
