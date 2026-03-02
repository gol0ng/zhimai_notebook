import 'dart:convert';
import 'package:flutter/material.dart';
import 'stroke_style.dart';

class StrokePoint {
  final double x;
  final double y;
  final double? pressure;

  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure,
  });

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'pressure': pressure,
    };
  }

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      pressure: json['pressure'] != null
          ? (json['pressure'] as num).toDouble()
          : null,
    );
  }
}

class Stroke {
  final String id;
  final List<StrokePoint> points;
  final StrokeStyle style;
  final DateTime createdAt;

  const Stroke({
    required this.id,
    required this.points,
    required this.style,
    required this.createdAt,
  });

  Stroke copyWith({
    String? id,
    List<StrokePoint>? points,
    StrokeStyle? style,
    DateTime? createdAt,
  }) {
    return Stroke(
      id: id ?? this.id,
      points: points ?? this.points,
      style: style ?? this.style,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'style': style.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      style: StrokeStyle.fromJson(json['style'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  factory Stroke.fromJsonString(String jsonString) {
    return Stroke.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
