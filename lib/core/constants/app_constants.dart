import 'package:flutter/material.dart';

class AppConstants {
  // Database
  static const String databaseName = 'zhimainote.db';
  static const int databaseVersion = 1;

  // Default stroke settings
  static const double defaultStrokeWidth = 3.0;
  static const double minStrokeWidth = 1.0;
  static const double maxStrokeWidth = 20.0;

  // Pen colors
  static const List<Color> penColors = [
    Colors.black,
    Color(0xFF424242), // 深灰
    Color(0xFF1565C0), // 深蓝
    Color(0xFFD32F2F), // 深红
    Color(0xFF2E7D32), // 深绿
    Color(0xFF6A1B9A), // 深紫
    Color(0xFFE65100), // 深橙
  ];

  // Highlighter colors (bright, semi-transparent)
  static const List<Color> highlighterColors = [
    Color(0xFFFFEB3B), // 黄色
    Color(0xFF4CAF50), // 绿色
    Color(0xFF2196F3), // 蓝色
    Color(0xFFFF9800), // 橙色
    Color(0xFFE91E63), // 粉色
    Color(0xFF9C27B0), // 紫色
  ];

  // Canvas settings
  static const double canvasBackgroundOpacity = 1.0;
}
