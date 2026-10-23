import 'dart:ui';
import 'package:flutter/material.dart';

enum CadTool {
  select,
  line,
  wall,
  rectangle,
  circle,
  door,
  window,
  dimension,
  text,
  column,
  eraser,
  polyline,
}

enum CadElementType {
  line,
  wall,
  rectangle,
  circle,
  door,
  window,
  dimension,
  text,
  column,
}

class CadLayer {
  final String id;
  final String name;
  final Color color;
  final double strokeWidth;
  bool isVisible;
  bool isLocked;

  CadLayer({
    required this.id,
    required this.name,
    required this.color,
    this.strokeWidth = 2.0,
    this.isVisible = true,
    this.isLocked = false,
  });

  CadLayer copyWith({
    String? id,
    String? name,
    Color? color,
    double? strokeWidth,
    bool? isVisible,
    bool? isLocked,
  }) {
    return CadLayer(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class CadElement {
  final String id;
  final CadElementType type;
  final String layerId;
  Offset start;
  Offset end;
  final Color? customColor;
  final double? customStrokeWidth;
  final String? text;
  final double? radius;
  final bool isSelected;

  CadElement({
    required this.id,
    required this.type,
    required this.layerId,
    required this.start,
    required this.end,
    this.customColor,
    this.customStrokeWidth,
    this.text,
    this.radius,
    this.isSelected = false,
  });

  CadElement copyWith({
    String? id,
    CadElementType? type,
    String? layerId,
    Offset? start,
    Offset? end,
    Color? customColor,
    double? customStrokeWidth,
    String? text,
    double? radius,
    bool? isSelected,
  }) {
    return CadElement(
      id: id ?? this.id,
      type: type ?? this.type,
      layerId: layerId ?? this.layerId,
      start: start ?? this.start,
      end: end ?? this.end,
      customColor: customColor ?? this.customColor,
      customStrokeWidth: customStrokeWidth ?? this.customStrokeWidth,
      text: text ?? this.text,
      radius: radius ?? this.radius,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  Rect get boundingBox {
    switch (type) {
      case CadElementType.circle:
        final r = radius ?? (end - start).distance;
        return Rect.fromCircle(center: start, radius: r);
      default:
        return Rect.fromPoints(start, end);
    }
  }
}

class SnapPoint {
  final Offset point;
  final String label;
  final Color color;

  SnapPoint({
    required this.point,
    required this.label,
    this.color = const Color(0xFF22C55E),
  });
}
