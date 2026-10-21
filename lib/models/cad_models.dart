# -*- coding: utf-8 -*-
"""
Script to generate enhanced CAD models and CAD Editor screen matching images 1 to 6.
"""
import os
import base64

# ==============================================================
# 1. lib/models/cad_models.dart
# ==============================================================
CAD_MODELS_DART = '''import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CadTool {
  select,
  pan,
  line,
  wall,
  rectangle,
  circle,
  door,
  window,
  dimension,
  text,
  erase,
  block,
  column,
}

enum CadBlockCategory {
  bedroom,
  kitchen,
  toilet,
  living,
  stairs,
  structural,
}

enum CadBlockType {
  // Bedroom
  bedDouble,
  bedSingle,
  wardrobe,
  sideTable,
  // Kitchen
  chulha2,
  chulha3,
  chulha4,
  sinkSingle,
  sinkDouble,
  refrigerator,
  dining4,
  dining6,
  // Toilet
  toiletWestern,
  toiletIndian,
  washBasin,
  bathTub,
  showerArea,
  // Living
  sofa3,
  sofa2,
  sofaSingle,
  sofaL,
  coffeeTable,
  tvUnit,
  // Stairs
  stairsDogLeg,
  stairsStraight,
  // Structural
  column9x9,
  column9x12,
}

class CadBlockDefinition {
  final CadBlockType type;
  final String name;
  final CadBlockCategory category;
  final String icon;
  final double defaultWidthFt;
  final double defaultHeightFt;
  final String description;

  const CadBlockDefinition({
    required this.type,
    required this.name,
    required this.category,
    required this.icon,
    required this.defaultWidthFt,
    required this.defaultHeightFt,
    required this.description,
  });
}

class CadBlockLibrary {
  static const List<CadBlockDefinition> blocks = [
    // Bedroom
    CadBlockDefinition(
      type: CadBlockType.bedDouble,
      name: "Double Bed (King)",
      category: CadBlockCategory.bedroom,
      icon: "\\u{1F6CF}\\u{FE0F}",
      defaultWidthFt: 6.0,
      defaultHeightFt: 6.5,
      description: "6.0 x 6.5 ft Master King Bed with pillows",
    ),
    CadBlockDefinition(
      type: CadBlockType.bedSingle,
      name: "Single Bed",
      category: CadBlockCategory.bedroom,
      icon: "\\u{1F6CF}\\u{FE0F}",
      defaultWidthFt: 3.5,
      defaultHeightFt: 6.5,
      description: "3.5 x 6.5 ft Single Bed with pillow",
    ),
    CadBlockDefinition(
      type: CadBlockType.wardrobe,
      name: "Wardrobe / Almirah",
      category: CadBlockCategory.bedroom,
      icon: "\\u{1F6AA}",
      defaultWidthFt: 5.0,
      defaultHeightFt: 2.0,
      description: "5.0 x 2.0 ft Bedroom Almirah / Closet",
    ),
    CadBlockDefinition(
      type: CadBlockType.sideTable,
      name: "Side / Night Table",
      category: CadBlockCategory.bedroom,
      icon: "\\u{1FA91}",
      defaultWidthFt: 1.5,
      defaultHeightFt: 1.5,
      description: "1.5 x 1.5 ft Bedside nightstand",
    ),

    // Kitchen
    CadBlockDefinition(
      type: CadBlockType.chulha2,
      name: "Gas Stove (2-Burner)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F373}",
      defaultWidthFt: 2.2,
      defaultHeightFt: 1.6,
      description: "2-Burner standard gas chulha",
    ),
    CadBlockDefinition(
      type: CadBlockType.chulha3,
      name: "Gas Stove (3-Burner)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F373}",
      defaultWidthFt: 2.6,
      defaultHeightFt: 1.8,
      description: "3-Burner triangle/inline gas chulha",
    ),
    CadBlockDefinition(
      type: CadBlockType.chulha4,
      name: "Gas Stove (4-Burner)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F373}",
      defaultWidthFt: 2.8,
      defaultHeightFt: 2.0,
      description: "4-Burner luxury gas cooktop",
    ),
    CadBlockDefinition(
      type: CadBlockType.sinkSingle,
      name: "Kitchen Sink (Single)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F6B0}",
      defaultWidthFt: 2.0,
      defaultHeightFt: 1.5,
      description: "Single bowl stainless steel sink",
    ),
    CadBlockDefinition(
      type: CadBlockType.sinkDouble,
      name: "Kitchen Sink (Double Bowl)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F6B0}",
      defaultWidthFt: 3.5,
      defaultHeightFt: 1.8,
      description: "Double bowl sink with drain board",
    ),
    CadBlockDefinition(
      type: CadBlockType.refrigerator,
      name: "Refrigerator / Fridge",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F9CA}",
      defaultWidthFt: 2.5,
      defaultHeightFt: 2.5,
      description: "2.5 x 2.5 ft Double-door refrigerator",
    ),
    CadBlockDefinition(
      type: CadBlockType.dining4,
      name: "Dining Table (4-Seater)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F37D}\\u{FE0F}",
      defaultWidthFt: 4.0,
      defaultHeightFt: 3.0,
      description: "4-Person rectangular dining set",
    ),
    CadBlockDefinition(
      type: CadBlockType.dining6,
      name: "Dining Table (6-Seater)",
      category: CadBlockCategory.kitchen,
      icon: "\\u{1F37D}\\u{FE0F}",
      defaultWidthFt: 5.5,
      defaultHeightFt: 3.2,
      description: "6-Person rectangular family dining set",
    ),

    // Toilet
    CadBlockDefinition(
      type: CadBlockType.toiletWestern,
      name: "Western WC (Commode)",
      category: CadBlockCategory.toilet,
      icon: "\\u{1F6BD}",
      defaultWidthFt: 1.6,
      defaultHeightFt: 2.3,
      description: "European water closet with cistern",
    ),
    CadBlockDefinition(
      type: CadBlockType.toiletIndian,
      name: "Indian Toilet (Orissa Pan)",
      category: CadBlockCategory.toilet,
      icon: "\\u{1F6BD}",
      defaultWidthFt: 1.8,
      defaultHeightFt: 2.2,
      description: "Squatting Orissa pan with footrests",
    ),
    CadBlockDefinition(
      type: CadBlockType.washBasin,
      name: "Wash Basin",
      category: CadBlockCategory.toilet,
      icon: "\\u{1F6B0}",
      defaultWidthFt: 1.8,
      defaultHeightFt: 1.4,
      description: "Ceramic vanity wash basin with faucet",
    ),
    CadBlockDefinition(
      type: CadBlockType.bathTub,
      name: "Bath Tub",
      category: CadBlockCategory.toilet,
      icon: "\\u{1F6C1}",
      defaultWidthFt: 5.0,
      defaultHeightFt: 2.6,
      description: "Full length bathing tub",
    ),
    CadBlockDefinition(
      type: CadBlockType.showerArea,
      name: "Shower Enclosure",
      category: CadBlockCategory.toilet,
      icon: "\\u{1F6BF}",
      defaultWidthFt: 3.0,
      defaultHeightFt: 3.0,
      description: "Square glass shower cubicle",
    ),

    // Living
    CadBlockDefinition(
      type: CadBlockType.sofa3,
      name: "Sofa (3-Seater)",
      category: CadBlockCategory.living,
      icon: "\\u{1F6CB}\\u{FE0F}",
      defaultWidthFt: 6.5,
      defaultHeightFt: 2.8,
      description: "3-Seater cushioned living room sofa",
    ),
    CadBlockDefinition(
      type: CadBlockType.sofa2,
      name: "Sofa (2-Seater / Loveseat)",
      category: CadBlockCategory.living,
      icon: "\\u{1F6CB}\\u{FE0F}",
      defaultWidthFt: 4.8,
      defaultHeightFt: 2.8,
      description: "2-Seater compact sofa",
    ),
    CadBlockDefinition(
      type: CadBlockType.sofaSingle,
      name: "Armchair (1-Seater)",
      category: CadBlockCategory.living,
      icon: "\\u{1FA91}",
      defaultWidthFt: 2.8,
      defaultHeightFt: 2.8,
      description: "Single lounge armchair",
    ),
    CadBlockDefinition(
      type: CadBlockType.sofaL,
      name: "L-Shape Sectional Sofa",
      category: CadBlockCategory.living,
      icon: "\\u{1F6CB}\\u{FE0F}",
      defaultWidthFt: 8.0,
      defaultHeightFt: 6.0,
      description: "Corner L-sectional living sofa",
    ),
    CadBlockDefinition(
      type: CadBlockType.coffeeTable,
      name: "Center / Coffee Table",
      category: CadBlockCategory.living,
      icon: "\\u{2615}",
      defaultWidthFt: 3.5,
      defaultHeightFt: 2.0,
      description: "Living room coffee table",
    ),
    CadBlockDefinition(
      type: CadBlockType.tvUnit,
      name: "TV Console / Unit",
      category: CadBlockCategory.living,
      icon: "\\u{1F4FA}",
      defaultWidthFt: 5.0,
      defaultHeightFt: 1.5,
      description: "Wall entertainment console",
    ),

    // Stairs
    CadBlockDefinition(
      type: CadBlockType.stairsDogLeg,
      name: "Dog-Legged Staircase",
      category: CadBlockCategory.stairs,
      icon: "\\u{1FA9C}",
      defaultWidthFt: 6.0,
      defaultHeightFt: 10.0,
      description: "Dog-legged stairs with landing and UP arrow",
    ),
    CadBlockDefinition(
      type: CadBlockType.stairsStraight,
      name: "Straight Flight Stairs",
      category: CadBlockCategory.stairs,
      icon: "\\u{1FA9C}",
      defaultWidthFt: 3.0,
      defaultHeightFt: 10.0,
      description: "Straight one-way stair flight",
    ),

    // Structural
    CadBlockDefinition(
      type: CadBlockType.column9x9,
      name: "Column 9x9 inch (RCC)",
      category: CadBlockCategory.structural,
      icon: "\\u{1F3DB}\\u{FE0F}",
      defaultWidthFt: 0.75,
      defaultHeightFt: 0.75,
      description: "9x9 inch red reinforced concrete column",
    ),
    CadBlockDefinition(
      type: CadBlockType.column9x12,
      name: "Column 9x12 inch (RCC)",
      category: CadBlockCategory.structural,
      icon: "\\u{1F3DB}\\u{FE0F}",
      defaultWidthFt: 0.75,
      defaultHeightFt: 1.0,
      description: "9x12 inch load-bearing concrete column",
    ),
  ];
}

class CadLayer {
  final String id;
  String name;
  Color color;
  bool isVisible;
  bool isLocked;
  double strokeWidth;

  CadLayer({
    required this.id,
    required this.name,
    required this.color,
    this.isVisible = true,
    this.isLocked = false,
    this.strokeWidth = 2.0,
  });
}

class CadEntity {
  final String id;
  CadTool type;
  String layerId;
  List<Offset> points;
  String text;
  double radius;
  Color? color;
  Color? fillColor;
  double strokeWidth;
  bool isSelected;

  // Enhanced block & transform attributes
  CadBlockType? blockType;
  double widthFt;
  double heightFt;
  double rotationDeg;
  bool showName;
  bool showDimensions;

  CadEntity({
    required this.id,
    required this.type,
    required this.layerId,
    required this.points,
    this.text = "",
    this.radius = 0.0,
    this.color,
    this.fillColor,
    this.strokeWidth = 2.0,
    this.isSelected = false,
    this.blockType,
    this.widthFt = 0.0,
    this.heightFt = 0.0,
    this.rotationDeg = 0.0,
    this.showName = true,
    this.showDimensions = true,
  });

  CadEntity clone() {
    return CadEntity(
      id: id,
      type: type,
      layerId: layerId,
      points: List<Offset>.from(points),
      text: text,
      radius: radius,
      color: color,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      isSelected: isSelected,
      blockType: blockType,
      widthFt: widthFt,
      heightFt: heightFt,
      rotationDeg: rotationDeg,
      showName: showName,
      showDimensions: showDimensions,
    );
  }

  Rect getBounds() {
    if (points.isEmpty) return Rect.zero;
    if (points.length == 1) {
      if (widthFt > 0 && heightFt > 0) {
        final wPx = widthFt * 15.0;
        final hPx = heightFt * 15.0;
        return Rect.fromCenter(center: points[0], width: wPx, height: hPx);
      }
      return Rect.fromCircle(center: points[0], radius: radius > 0 ? radius : 20.0);
    }
    return Rect.fromPoints(points[0], points[1]);
  }
}
'''

with open("cad_models.dart", "w", encoding="utf-8") as f:
    f.write(CAD_MODELS_DART)

print("✓ Generated cad_models.dart")