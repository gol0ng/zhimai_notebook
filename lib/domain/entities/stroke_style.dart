import 'package:flutter/material.dart';

class StrokeStyle {
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;
  final bool isEraser;
  final double opacity;

  const StrokeStyle({
    required this.color,
    required this.strokeWidth,
    this.strokeCap = StrokeCap.round,
    this.isEraser = false,
    this.opacity = 1.0,
  });

  StrokeStyle copyWith({
    Color? color,
    double? strokeWidth,
    StrokeCap? strokeCap,
    bool? isEraser,
    double? opacity,
  }) {
    return StrokeStyle(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
      isEraser: isEraser ?? this.isEraser,
      opacity: opacity ?? this.opacity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'color': color.value,
      'strokeWidth': strokeWidth,
      'strokeCap': strokeCap.index,
      'isEraser': isEraser,
      'opacity': opacity,
    };
  }

  factory StrokeStyle.fromJson(Map<String, dynamic> json) {
    return StrokeStyle(
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      strokeCap: StrokeCap.values[json['strokeCap'] as int],
      isEraser: json['isEraser'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
