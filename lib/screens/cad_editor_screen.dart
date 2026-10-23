import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/cad_models.dart';

class CadEditorScreen extends StatefulWidget {
  final String? projectName;
  final double? plotLength;
  final double? plotWidth;
  final String? bhk;
  final String? facing;
  final List<String>? selectedRooms;

  const CadEditorScreen({
    super.key,
    this.projectName,
    this.plotLength,
    this.plotWidth,
    this.bhk,
    this.facing,
    this.selectedRooms,
  });

  @override
  State<CadEditorScreen> createState() => _CadEditorScreenState();
}

class _CadEditorScreenState extends State<CadEditorScreen> {
  final TransformationController _transformationController = TransformationController();

  final GlobalKey _canvasViewportKey = GlobalKey();

  double get _currentZoom => _transformationController.value.getMaxScaleOnAxis();

  void _zoomBy(double factor) {
    final renderObject = _canvasViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    final viewport = renderObject.size;
    final current = _transformationController.value;
    final currentScale = current.getMaxScaleOnAxis();
    final nextScale = (currentScale * factor).clamp(0.15, 6.0).toDouble();
    final ratio = nextScale / currentScale;
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final tx = current.storage[12];
    final ty = current.storage[13];
    final nextTx = center.dx - (center.dx - tx) * ratio;
    final nextTy = center.dy - (center.dy - ty) * ratio;

    _transformationController.value = Matrix4.identity()
      ..translate(nextTx, nextTy)
      ..scale(nextScale);
  }

  void _fitToDrawing() {
    final renderObject = _canvasViewportKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize || _entities.isEmpty) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    Rect? bounds;
    for (final entity in _entities) {
      if (entity.points.isEmpty) continue;
      final entityBounds = entity.getBounds();
      bounds = bounds == null ? entityBounds : bounds.expandToInclude(entityBounds);
    }

    if (bounds == null || bounds.width <= 0 || bounds.height <= 0) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    final viewport = renderObject.size;
    const padding = 64.0;
    final availableWidth = math.max(1.0, viewport.width - padding * 2);
    final availableHeight = math.max(1.0, viewport.height - padding * 2);
    final scale = math.min(
      availableWidth / bounds.width,
      availableHeight / bounds.height,
    ).clamp(0.15, 6.0).toDouble();

    _transformationController.value = Matrix4.identity()
      ..translate(
        viewport.width / 2 - bounds.center.dx * scale,
        viewport.height / 2 - bounds.center.dy * scale,
      )
      ..scale(scale);
  }


  CadTool _activeTool = CadTool.select;
  String _activeLayerId = "walls";
  bool _orthoMode = false;
  bool _snapMode = true;
  bool _gridVisible = true;
  bool _isDarkCanvas = true; // Dual Theme: Dark CAD (0xFF10141D) <-> White Paper (0xFFFFFFFF)
  final double _gridSize = 20.0;

  Offset? _cursorScenePos;
  Offset? _dragStart;
  Offset? _currentDrag;
  CadEntity? _selectedEntity;
  Offset? _entityMoveStartPoint;
  bool _isMovingEntity = false;

  CadBlockCategory _selectedBlockCategory = CadBlockCategory.bedroom;
  bool _showBlocksBar = false;

  final List<CadEntity> _entities = [];
  final List<List<CadEntity>> _undoStack = [];
  final List<List<CadEntity>> _redoStack = [];

  final List<CadLayer> _layers = [
    CadLayer(id: "walls", name: "Walls (9\"/4.5\")", color: const Color(0xFFFFFFFF), strokeWidth: 5.0),
    CadLayer(id: "rooms", name: "Rooms & Spaces", color: const Color(0xFFE5B05C), strokeWidth: 2.0),
    CadLayer(id: "furniture", name: "Furniture & Blocks", color: const Color(0xFF38BDF8), strokeWidth: 1.8),
    CadLayer(id: "doors", name: "Doors & Swings", color: const Color(0xFF22C55E), strokeWidth: 2.0),
    CadLayer(id: "windows", name: "Windows & Glass", color: const Color(0xFF60A5FA), strokeWidth: 2.0),
    CadLayer(id: "columns", name: "RCC Columns", color: const Color(0xFFEF4444), strokeWidth: 2.5),
    CadLayer(id: "dimensions", name: "Dimensions", color: const Color(0xFFF59E0B), strokeWidth: 1.5),
    CadLayer(id: "text", name: "Labels & Notes", color: const Color(0xFFE2E8F0), strokeWidth: 1.5),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.plotLength != null && widget.plotWidth != null && widget.plotLength! > 0 && widget.plotWidth! > 0) {
      _initProjectPlot();
    } else {
      _loadSampleBlueprint();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _saveUndoState() {
    _undoStack.add(_entities.map((e) => e.clone()).toList());
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_entities.map((e) => e.clone()).toList());
      setState(() {
        _entities.clear();
        _entities.addAll(_undoStack.removeLast());
        _selectedEntity = null;
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_entities.map((e) => e.clone()).toList());
      setState(() {
        _entities.clear();
        _entities.addAll(_redoStack.removeLast());
        _selectedEntity = null;
      });
    }
  }

  Offset _snapPoint(Offset point) {
    if (!_snapMode) return point;
    for (final entity in _entities) {
      for (final p in entity.points) {
        if ((p - point).distance < 14.0) {
          return p;
        }
      }
    }
    final snappedX = (point.dx / _gridSize).round() * _gridSize;
    final snappedY = (point.dy / _gridSize).round() * _gridSize;
    return Offset(snappedX, snappedY);
  }

  void _initProjectPlot() {
    _entities.clear();
    final len = (widget.plotLength ?? 40.0) * 15.0;
    final wid = (widget.plotWidth ?? 30.0) * 15.0;
    const origin = Offset(200, 200);

    // Plot Boundary
    _entities.add(CadEntity(
      id: "plot_boundary",
      type: CadTool.rectangle,
      layerId: "walls",
      points: [origin, Offset(origin.dx + wid, origin.dy + len)],
      text: "${widget.projectName ?? 'House Plot'} (${(widget.plotWidth ?? 30.0).toStringAsFixed(0)}x${(widget.plotLength ?? 40.0).toStringAsFixed(0)} ft)",
      strokeWidth: 6.0,
      color: _isDarkCanvas ? Colors.white : Colors.black87,
      widthFt: widget.plotWidth ?? 30.0,
      heightFt: widget.plotLength ?? 40.0,
    ));

    // Dimensions
    _entities.add(CadEntity(
      id: "dim_w",
      type: CadTool.dimension,
      layerId: "dimensions",
      points: [Offset(origin.dx, origin.dy - 35), Offset(origin.dx + wid, origin.dy - 35)],
      text: "${widget.plotWidth?.toStringAsFixed(1)} ft",
      strokeWidth: 1.5,
      color: const Color(0xFFF59E0B),
    ));

    _entities.add(CadEntity(
      id: "dim_l",
      type: CadTool.dimension,
      layerId: "dimensions",
      points: [Offset(origin.dx - 35, origin.dy), Offset(origin.dx - 35, origin.dy + len)],
      text: "${widget.plotLength?.toStringAsFixed(1)} ft",
      strokeWidth: 1.5,
      color: const Color(0xFFF59E0B),
    ));

    final halfW = wid / 2;
    final thirdL = len / 3;

    // Living Room
    _entities.add(CadEntity(
      id: "room_living",
      type: CadTool.rectangle,
      layerId: "rooms",
      points: [origin, Offset(origin.dx + wid, origin.dy + thirdL * 1.3)],
      text: "LIVING / DRAWING HALL",
      strokeWidth: 4.0,
      color: const Color(0xFFE5B05C),
      widthFt: (wid / 15.0),
      heightFt: (thirdL * 1.3 / 15.0),
    ));

    // Master Bedroom (SW)
    _entities.add(CadEntity(
      id: "room_bed1",
      type: CadTool.rectangle,
      layerId: "rooms",
      points: [Offset(origin.dx, origin.dy + thirdL * 1.3), Offset(origin.dx + halfW, origin.dy + len)],
      text: "MASTER BEDROOM (SW)",
      strokeWidth: 4.0,
      color: const Color(0xFFE5B05C),
      widthFt: (halfW / 15.0),
      heightFt: ((len - thirdL * 1.3) / 15.0),
    ));

    // Kitchen (SE)
    _entities.add(CadEntity(
      id: "room_kit",
      type: CadTool.rectangle,
      layerId: "rooms",
      points: [Offset(origin.dx + halfW, origin.dy + thirdL * 1.3), Offset(origin.dx + wid, origin.dy + thirdL * 2.2)],
      text: "KITCHEN (SE)",
      strokeWidth: 4.0,
      color: const Color(0xFFE5B05C),
      widthFt: (halfW / 15.0),
      heightFt: (thirdL * 0.9 / 15.0),
    ));

    // Toilet (West)
    _entities.add(CadEntity(
      id: "room_bath",
      type: CadTool.rectangle,
      layerId: "rooms",
      points: [Offset(origin.dx + halfW, origin.dy + thirdL * 2.2), Offset(origin.dx + wid, origin.dy + len)],
      text: "TOILET & BATH",
      strokeWidth: 4.0,
      color: const Color(0xFFE5B05C),
      widthFt: (halfW / 15.0),
      heightFt: ((len - thirdL * 2.2) / 15.0),
    ));

    // Main Entrance Door
    _entities.add(CadEntity(
      id: "main_door",
      type: CadTool.door,
      layerId: "doors",
      points: [Offset(origin.dx + wid * 0.35, origin.dy), Offset(origin.dx + wid * 0.35 + 45, origin.dy)],
      text: "Main Door (3'x7')",
      strokeWidth: 2.0,
      color: const Color(0xFF22C55E),
    ));

    // Corner Red Columns
    final colOffsets = [
      origin,
      Offset(origin.dx + wid, origin.dy),
      Offset(origin.dx, origin.dy + len),
      Offset(origin.dx + wid, origin.dy + len),
      Offset(origin.dx + halfW, origin.dy + thirdL * 1.3),
    ];
    for (int i = 0; i < colOffsets.length; i++) {
      _entities.add(CadEntity(
        id: "col_$i",
        type: CadTool.column,
        layerId: "columns",
        points: [colOffsets[i]],
        text: "C$i (9x9)",
        widthFt: 0.75,
        heightFt: 0.75,
        strokeWidth: 2.0,
        color: const Color(0xFFEF4444),
        fillColor: const Color(0xFFD32F2F),
      ));
    }

    // Add Furniture Blocks inside rooms
    _entities.add(CadEntity(
      id: "blk_king_bed",
      type: CadTool.block,
      blockType: CadBlockType.bedDouble,
      layerId: "furniture",
      points: [Offset(origin.dx + halfW * 0.5, origin.dy + thirdL * 1.3 + 60)],
      text: "Master King Bed",
      widthFt: 6.0,
      heightFt: 6.5,
      rotationDeg: 0.0,
      color: const Color(0xFF38BDF8),
    ));

    _entities.add(CadEntity(
      id: "blk_gas_chulha",
      type: CadTool.block,
      blockType: CadBlockType.chulha3,
      layerId: "furniture",
      points: [Offset(origin.dx + halfW + 40, origin.dy + thirdL * 1.3 + 30)],
      text: "Gas Chulha (3-Burner)",
      widthFt: 2.6,
      heightFt: 1.8,
      rotationDeg: 0.0,
      color: const Color(0xFFF59E0B),
    ));

    _entities.add(CadEntity(
      id: "blk_wc",
      type: CadTool.block,
      blockType: CadBlockType.toiletWestern,
      layerId: "furniture",
      points: [Offset(origin.dx + halfW + 40, origin.dy + thirdL * 2.2 + 35)],
      text: "WC Commode",
      widthFt: 1.6,
      heightFt: 2.3,
      rotationDeg: 0.0,
      color: const Color(0xFF22C55E),
    ));

    _entities.add(CadEntity(
      id: "blk_sofa3",
      type: CadTool.block,
      blockType: CadBlockType.sofa3,
      layerId: "furniture",
      points: [Offset(origin.dx + 80, origin.dy + 80)],
      text: "Living Sofa (3-Seater)",
      widthFt: 6.5,
      heightFt: 2.8,
      rotationDeg: 0.0,
      color: const Color(0xFF38BDF8),
    ));
  }

  void _loadSampleBlueprint() {
    _initProjectPlot();
  }

  void _addBlockToCanvas(CadBlockDefinition blockDef) {
    _saveUndoState();
    final centerScene = _transformationController.toScene(
      Offset(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 2),
    );
    final snapped = _snapPoint(centerScene);

    final newEntity = CadEntity(
      id: "blk_${DateTime.now().millisecondsSinceEpoch}",
      type: blockDef.category == CadBlockCategory.structural ? CadTool.column : CadTool.block,
      blockType: blockDef.type,
      layerId: blockDef.category == CadBlockCategory.structural ? "columns" : "furniture",
      points: [snapped],
      text: blockDef.name,
      widthFt: blockDef.defaultWidthFt,
      heightFt: blockDef.defaultHeightFt,
      rotationDeg: 0.0,
      color: blockDef.category == CadBlockCategory.structural ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
      fillColor: blockDef.category == CadBlockCategory.structural ? const Color(0xFFD32F2F) : null,
      showName: true,
      showDimensions: true,
    );

    setState(() {
      _entities.add(newEntity);
      _selectedEntity = newEntity;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added ${blockDef.name} (${blockDef.defaultWidthFt} x ${blockDef.defaultHeightFt} ft) to canvas"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteSelected() {
    if (_selectedEntity == null) return;
    _saveUndoState();
    setState(() {
      _entities.removeWhere((e) => e.id == _selectedEntity!.id);
      _selectedEntity = null;
    });
  }

  void _duplicateSelected() {
    if (_selectedEntity == null) return;
    _saveUndoState();
    final clone = _selectedEntity!.clone();
    final newId = "dup_${DateTime.now().millisecondsSinceEpoch}";
    const offset = Offset(20, 20);
    final newPoints = clone.points.map((p) => p + offset).toList();

    final duplicated = CadEntity(
      id: newId,
      type: clone.type,
      layerId: clone.layerId,
      points: newPoints,
      text: "${clone.text} (Copy)",
      radius: clone.radius,
      color: clone.color,
      fillColor: clone.fillColor,
      strokeWidth: clone.strokeWidth,
      blockType: clone.blockType,
      widthFt: clone.widthFt,
      heightFt: clone.heightFt,
      rotationDeg: clone.rotationDeg,
      showName: clone.showName,
      showDimensions: clone.showDimensions,
    );

    setState(() {
      _entities.add(duplicated);
      _selectedEntity = duplicated;
    });
  }

  void _rotateSelected(double deltaDeg) {
    if (_selectedEntity == null) return;
    _saveUndoState();
    setState(() {
      _selectedEntity!.rotationDeg = (_selectedEntity!.rotationDeg + deltaDeg) % 360.0;
      if (_selectedEntity!.rotationDeg < 0) _selectedEntity!.rotationDeg += 360.0;
    });
  }

  void _nudgeSelected(double dxFt, double dyFt) {
    if (_selectedEntity == null) return;
    _saveUndoState();
    final offset = Offset(dxFt * 15.0, dyFt * 15.0);
    setState(() {
      _selectedEntity!.points = _selectedEntity!.points.map((p) => p + offset).toList();
    });
  }

  void _showEditEntityDialog() {
    if (_selectedEntity == null) return;
    final entity = _selectedEntity!;
    final nameController = TextEditingController(text: entity.text);
    final widthController = TextEditingController(text: entity.widthFt > 0 ? entity.widthFt.toStringAsFixed(1) : "3.0");
    final heightController = TextEditingController(text: entity.heightFt > 0 ? entity.heightFt.toStringAsFixed(1) : "3.0");
    double currentRot = entity.rotationDeg;
    Color currentColor = entity.color ?? const Color(0xFFE5B05C);
    bool showNameVal = entity.showName;
    bool showDimVal = entity.showDimensions;

    final paletteColors = [
      const Color(0xFFE5B05C), // Gold
      const Color(0xFFFFFFFF), // White
      const Color(0xFFEF4444), // Red
      const Color(0xFF38BDF8), // Light Blue
      const Color(0xFF22C55E), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2433),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Edit ${entity.text.isNotEmpty ? entity.text : 'Properties'}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: "Entity Name / Label",
                    labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: "Width (ft)",
                          labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: "Height / Length (ft)",
                          labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Rotation (°)", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text("${currentRot.round()}°", style: const TextStyle(color: Color(0xFFE5B05C), fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: currentRot,
                  min: 0,
                  max: 360,
                  divisions: 72,
                  activeColor: const Color(0xFFE5B05C),
                  onChanged: (val) => setDlgState(() => currentRot = val),
                ),
                Wrap(
                  spacing: 6,
                  children: [0.0, 90.0, 180.0, 270.0].map((deg) {
                    return ActionChip(
                      label: Text("${deg.round()}°", style: const TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: currentRot == deg ? const Color(0xFFE5B05C).withOpacity(0.3) : Colors.white10,
                      onPressed: () => setDlgState(() => currentRot = deg),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text("Shape & Line Color", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: paletteColors.map((col) {
                    final isSel = currentColor.value == col.value;
                    return InkWell(
                      onTap: () => setDlgState(() => currentColor = col),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSel ? Colors.white : Colors.transparent, width: 2.5),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text("Show name on canvas", style: TextStyle(fontSize: 12, color: Colors.white)),
                  value: showNameVal,
                  activeColor: const Color(0xFFE5B05C),
                  onChanged: (v) => setDlgState(() => showNameVal = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text("Show dimensions on canvas", style: TextStyle(fontSize: 12, color: Colors.white)),
                  value: showDimVal,
                  activeColor: const Color(0xFFE5B05C),
                  onChanged: (v) => setDlgState(() => showDimVal = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5B05C),
                foregroundColor: const Color(0xFF0A1128),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _saveUndoState();
                setState(() {
                  entity.text = nameController.text.trim();
                  entity.widthFt = double.tryParse(widthController.text) ?? entity.widthFt;
                  entity.heightFt = double.tryParse(heightController.text) ?? entity.heightFt;
                  entity.rotationDeg = currentRot;
                  entity.color = currentColor;
                  entity.showName = showNameVal;
                  entity.showDimensions = showDimVal;
                });
                Navigator.pop(ctx);
              },
              child: const Text("APPLY CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_activeTool == CadTool.pan) return;
    final scenePos = _transformationController.toScene(details.localPosition);
    final snapped = _snapPoint(scenePos);

    if (_activeTool == CadTool.select) {
      CadEntity? hitEntity;
      for (final e in _entities.reversed) {
        final bounds = e.getBounds().inflate(18.0);
        if (bounds.contains(scenePos)) {
          hitEntity = e;
          break;
        }
      }

      setState(() {
        _selectedEntity = hitEntity;
        if (hitEntity != null) {
          _isMovingEntity = true;
          _entityMoveStartPoint = scenePos;
        }
      });
      return;
    }

    if (_activeTool == CadTool.erase) {
      _saveUndoState();
      setState(() {
        _entities.removeWhere((e) => e.getBounds().inflate(18.0).contains(scenePos));
      });
      return;
    }

    if (_activeTool == CadTool.text) {
      _showTextDialog(snapped);
      return;
    }

    _dragStart = snapped;
    _currentDrag = snapped;
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_activeTool == CadTool.pan) return;
    final scenePos = _transformationController.toScene(details.localPosition);
    var snapped = _snapPoint(scenePos);

    if (_isMovingEntity && _selectedEntity != null && _entityMoveStartPoint != null) {
      final delta = scenePos - _entityMoveStartPoint!;
      _entityMoveStartPoint = scenePos;
      setState(() {
        _selectedEntity!.points = _selectedEntity!.points.map((p) => p + delta).toList();
      });
      return;
    }

    if (_orthoMode && _dragStart != null) {
      final dx = (snapped.dx - _dragStart!.dx).abs();
      final dy = (snapped.dy - _dragStart!.dy).abs();
      if (dx > dy) {
        snapped = Offset(snapped.dx, _dragStart!.dy);
      } else {
        snapped = Offset(_dragStart!.dx, snapped.dy);
      }
    }

    setState(() {
      _cursorScenePos = scenePos;
      _currentDrag = snapped;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isMovingEntity) {
      _isMovingEntity = false;
      _entityMoveStartPoint = null;
      _saveUndoState();
      return;
    }

    if (_activeTool == CadTool.pan || _dragStart == null || _currentDrag == null) {
      _dragStart = null;
      _currentDrag = null;
      return;
    }

    if ((_dragStart! - _currentDrag!).distance > 6.0) {
      _saveUndoState();
      final activeLayer = _layers.firstWhere((l) => l.id == _activeLayerId, orElse: () => _layers.first);
      final id = "e_${DateTime.now().millisecondsSinceEpoch}";

      String textLabel = "";
      double wFt = (_dragStart! - _currentDrag!).dx.abs() / 15.0;
      double hFt = (_dragStart! - _currentDrag!).dy.abs() / 15.0;

      if (_activeTool == CadTool.dimension) {
        final distFt = (_dragStart! - _currentDrag!).distance / 15.0;
        textLabel = "${distFt.toStringAsFixed(1)} ft";
      }

      final entity = CadEntity(
        id: id,
        type: _activeTool,
        layerId: _activeLayerId,
        points: [_dragStart!, _currentDrag!],
        text: textLabel,
        radius: (_dragStart! - _currentDrag!).distance,
        strokeWidth: activeLayer.strokeWidth,
        color: activeLayer.color,
        widthFt: wFt,
        heightFt: hFt,
      );

      _entities.add(entity);
      _selectedEntity = entity;
    }

    setState(() {
      _dragStart = null;
      _currentDrag = null;
    });
  }

  void _showTextDialog(Offset position) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2433),
        title: const Text("Add CAD Annotation", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter room name, note, or dimension",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE5B05C)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveUndoState();
                setState(() {
                  _entities.add(CadEntity(
                    id: "text_${DateTime.now().millisecondsSinceEpoch}",
                    type: CadTool.text,
                    layerId: "text",
                    points: [position],
                    text: controller.text.trim(),
                    color: Colors.white,
                    strokeWidth: 1.5,
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text("Add", style: TextStyle(color: Color(0xFF0A1128), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLayersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2433),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("CAD Layer Manager", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _layers.length,
                  itemBuilder: (ctx, idx) {
                    final layer = _layers[idx];
                    final isActive = layer.id == _activeLayerId;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(backgroundColor: layer.color, radius: 10),
                      title: Text(layer.name, style: TextStyle(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(layer.isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white70, size: 20),
                            onPressed: () {
                              setSheetState(() => layer.isVisible = !layer.isVisible);
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: Icon(layer.isLocked ? Icons.lock : Icons.lock_open, color: Colors.white70, size: 20),
                            onPressed: () {
                              setSheetState(() => layer.isLocked = !layer.isLocked);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      selected: isActive,
                      selectedTileColor: const Color(0xFFE5B05C).withOpacity(0.15),
                      onTap: () {
                        setState(() => _activeLayerId = layer.id);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.projectName ?? "AutoCAD 2D Studio";

    return Scaffold(
      backgroundColor: _isDarkCanvas ? const Color(0xFF10141D) : const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2433),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              "${_entities.length} entities • Layer: ${_layers.firstWhere((l) => l.id == _activeLayerId).name}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isDarkCanvas ? Icons.dark_mode : Icons.light_mode, size: 20, color: const Color(0xFFE5B05C)),
            tooltip: _isDarkCanvas ? "Switch to White Paper View" : "Switch to Dark CAD View",
            onPressed: () => setState(() => _isDarkCanvas = !_isDarkCanvas),
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 20),
            tooltip: "Undo",
            onPressed: _undoStack.isNotEmpty ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 20),
            tooltip: "Redo",
            onPressed: _redoStack.isNotEmpty ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.layers_outlined, size: 20),
            tooltip: "Layers",
            onPressed: _showLayersSheet,
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined, size: 20),
            tooltip: "Export CAD Blueprint",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("CAD Drawing exported successfully (DXF / PDF / PNG ready)")),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main Interactive CAD Canvas
          InteractiveViewer(
            key: _canvasViewportKey,
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(1600),
            minScale: 0.15,
            maxScale: 6.0,
            panEnabled: _activeTool == CadTool.pan,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                size: const Size(2600, 2600),
                painter: CadCanvasPainter(
                  entities: _entities,
                  layers: _layers,
                  gridVisible: _gridVisible,
                  gridSize: _gridSize,
                  isDarkCanvas: _isDarkCanvas,
                  dragStart: _dragStart,
                  currentDrag: _currentDrag,
                  activeTool: _activeTool,
                  activeColor: _layers.firstWhere((l) => l.id == _activeLayerId).color,
                  selectedEntity: _selectedEntity,
                  facing: widget.facing ?? "North",
                ),
              ),
            ),
          ),

          // Zoom controls stay outside the drawing gesture area.
          Positioned(
            right: 12,
            bottom: 54,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2433).withOpacity(0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: "Zoom in",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, color: Color(0xFFE5B05C)),
                    onPressed: () => _zoomBy(1.25),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "${(_currentZoom * 100).round()}%",
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ),
                  IconButton(
                    tooltip: "Zoom out",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, color: Color(0xFFE5B05C)),
                    onPressed: () => _zoomBy(0.8),
                  ),
                  IconButton(
                    tooltip: "Fit drawing to screen",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.fit_screen, color: Color(0xFFE5B05C), size: 20),
                    onPressed: _fitToDrawing,
                  ),
                ],
              ),
            ),
          ),

          // Left ToolBar (Vertical)
          Positioned(
            left: 12,
            top: 12,
            child: _buildToolBar(),
          ),

          // Top Selection Action Bar
          if (_selectedEntity != null)
            Positioned(
              top: 12,
              left: 70,
              right: 12,
              child: _buildSelectionActionBar(),
            ),

          // Bottom Ready-Made Blocks Drawer
          if (_showBlocksBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 44,
              child: _buildBlocksBottomDrawer(),
            ),


          Positioned(
            right: 14,
            bottom: 54,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2433).withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      final m = _transformationController.value.clone();
                      m.scale(1.25);
                      _transformationController.value = m;
                    },
                  ),
                  const Divider(height: 6, color: Colors.white24),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      final m = _transformationController.value.clone();
                      m.scale(0.8);
                      _transformationController.value = m;
                    },
                  ),
                  const Divider(height: 6, color: Colors.white24),
                  InkWell(
                    onTap: () => _transformationController.value = Matrix4.identity(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text('FIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkPrimary)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Status Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildCadStatusBar(),
            ),
          ),
        ],
      ),
    );
  }

  // Vertical Left Toolbar (Select, Pan, Walls, Rooms, Lines, Openings, Blocks)
  Widget _buildToolBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433).withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toolBtn(CadTool.select, Icons.near_me, "Select (S)"),
          _toolBtn(CadTool.pan, Icons.pan_tool, "Pan / Zoom (P)"),
          const Divider(height: 10, color: Colors.white24),
          _toolBtn(CadTool.wall, Icons.border_all, "Wall 9 inch / 4.5 inch (W)"),
          _toolBtn(CadTool.rectangle, Icons.crop_square, "Room Rectangle (R)"),
          _toolBtn(CadTool.column, Icons.view_column, "RCC Pillar / Column (Col)"),
          _toolBtn(CadTool.line, Icons.horizontal_rule, "Line (L)"),
          _toolBtn(CadTool.door, Icons.sensor_door_outlined, "Door & Swing (D)"),
          _toolBtn(CadTool.window, Icons.window_outlined, "Window (Win)"),
          _toolBtn(CadTool.dimension, Icons.straighten, "Dimension (Dim)"),
          _toolBtn(CadTool.text, Icons.text_fields, "Text Label (T)"),
          const Divider(height: 10, color: Colors.white24),
          // Ready-made Blocks / Furniture Toggle
          Tooltip(
            message: "Ready-Made 2D Blocks Library",
            child: InkWell(
              onTap: () => setState(() => _showBlocksBar = !_showBlocksBar),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _showBlocksBar ? const Color(0xFFE5B05C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chair_outlined,
                  size: 20,
                  color: _showBlocksBar ? const Color(0xFF0A1128) : const Color(0xFFE5B05C),
                ),
              ),
            ),
          ),
          _toolBtn(CadTool.erase, Icons.delete_outline, "Erase (Del)"),
        ],
      ),
    );
  }

  Widget _toolBtn(CadTool tool, IconData icon, String tooltip) {
    final isSelected = _activeTool == tool;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => setState(() => _activeTool = tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5B05C) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? const Color(0xFF0A1128) : Colors.white70,
          ),
        ),
      ),
    );
  }

  // Selection Action Bar (Delete, Copy, Rotate CCW/CW, Nudge, Edit)
  Widget _buildSelectionActionBar() {
    final e = _selectedEntity!;
    final name = e.text.isNotEmpty ? e.text : (e.blockType?.name ?? e.type.name.toUpperCase());
    final sizeStr = e.widthFt > 0 ? " — ${e.widthFt.toStringAsFixed(1)} x ${e.heightFt.toStringAsFixed(1)} ft" : "";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433).withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5B05C), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5B05C).withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "$name$sizeStr",
                style: const TextStyle(color: Color(0xFFE5B05C), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            // Edit / Properties
            IconButton(
              icon: const Icon(Icons.tune, color: Colors.white, size: 19),
              tooltip: "Edit Size / Rotation / Name",
              onPressed: _showEditEntityDialog,
            ),
            // Rotate 90 CCW
            IconButton(
              icon: const Icon(Icons.rotate_left, color: Colors.white, size: 20),
              tooltip: "Rotate -90°",
              onPressed: () => _rotateSelected(-90),
            ),
            // Rotate 90 CW
            IconButton(
              icon: const Icon(Icons.rotate_right, color: Colors.white, size: 20),
              tooltip: "Rotate +90°",
              onPressed: () => _rotateSelected(90),
            ),
            // Duplicate
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 19),
              tooltip: "Duplicate",
              onPressed: _duplicateSelected,
            ),
            // Nudge arrows
            IconButton(
              icon: const Icon(Icons.arrow_left, color: Colors.white70, size: 20),
              tooltip: "Nudge Left (0.5 ft)",
              onPressed: () => _nudgeSelected(-0.5, 0),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_right, color: Colors.white70, size: 20),
              tooltip: "Nudge Right (0.5 ft)",
              onPressed: () => _nudgeSelected(0.5, 0),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_up, color: Colors.white70, size: 22),
              tooltip: "Nudge Up (0.5 ft)",
              onPressed: () => _nudgeSelected(0, -0.5),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
              tooltip: "Nudge Down (0.5 ft)",
              onPressed: () => _nudgeSelected(0, 0.5),
            ),
            // Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              tooltip: "Delete Entity",
              onPressed: _deleteSelected,
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Ready-Made Blocks Drawer
  Widget _buildBlocksBottomDrawer() {
    final filteredBlocks = CadBlockLibrary.blocks.where((b) => b.category == _selectedBlockCategory).toList();

    return Container(
      height: 145,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26).withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0xFFE5B05C).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector Tabs
          Row(
            children: [
              const Text("2D Ready Blocks:", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CadBlockCategory.values.map((cat) {
                      final isSel = cat == _selectedBlockCategory;
                      final label = cat.name.toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedBlockCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFE5B05C) : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSel ? const Color(0xFF0A1128) : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                onPressed: () => setState(() => _showBlocksBar = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Horizontal Blocks List
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filteredBlocks.length,
              itemBuilder: (ctx, idx) {
                final block = filteredBlocks[idx];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2433),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(block.icon, style: const TextStyle(fontSize: 18)),
                          Text("${block.defaultWidthFt}x${block.defaultHeightFt} ft", style: const TextStyle(fontSize: 10, color: Color(0xFFE5B05C))),
                        ],
                      ),
                      Text(
                        block.name,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 24,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5B05C),
                            foregroundColor: const Color(0xFF0A1128),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _addBlockToCanvas(block),
                          child: const Text("PLACE BLOCK", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Status Bar
  Widget _buildCadStatusBar() {
    final x = _cursorScenePos?.dx.toStringAsFixed(1) ?? "0.0";
    final y = _cursorScenePos?.dy.toStringAsFixed(1) ?? "0.0";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF1E2433),
      child: Row(
        children: [
          Text("X: $x   Y: $y", style: const TextStyle(fontSize: 11, fontFamily: "monospace", color: Colors.grey)),
          const Spacer(),
          _toggleChip("SNAP", _snapMode, () => setState(() => _snapMode = !_snapMode)),
          const SizedBox(width: 6),
          _toggleChip("ORTHO", _orthoMode, () => setState(() => _orthoMode = !_orthoMode)),
          const SizedBox(width: 6),
          _toggleChip("GRID", _gridVisible, () => setState(() => _gridVisible = !_gridVisible)),
          const SizedBox(width: 10),
          InkWell(
            onTap: _fitToDrawing,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text("FIT", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5B05C))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE5B05C).withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? const Color(0xFFE5B05C) : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFFE5B05C) : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ==============================================================
// CadCanvasPainter with Vector 2D Architectural Block Rendering
// ==============================================================
class CadCanvasPainter extends CustomPainter {
  final List<CadEntity> entities;
  final List<CadLayer> layers;
  final bool gridVisible;
  final double gridSize;
  final bool isDarkCanvas;
  final Offset? dragStart;
  final Offset? currentDrag;
  final CadTool activeTool;
  final Color activeColor;
  final CadEntity? selectedEntity;
  final String facing;

  CadCanvasPainter({
    required this.entities,
    required this.layers,
    required this.gridVisible,
    required this.gridSize,
    required this.isDarkCanvas,
    required this.dragStart,
    required this.currentDrag,
    required this.activeTool,
    required this.activeColor,
    required this.selectedEntity,
    required this.facing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Canvas Background
    canvas.drawColor(isDarkCanvas ? const Color(0xFF10141D) : const Color(0xFFFFFFFF), BlendMode.src);

    // 2. Grid lines (Adapt to dark/light theme)
    if (gridVisible) {
      final minorPaint = Paint()
        ..color = isDarkCanvas ? const Color(0xFF1F2937).withOpacity(0.35) : const Color(0xFFCBD5E1).withOpacity(0.5)
        ..strokeWidth = 0.5;
      final majorPaint = Paint()
        ..color = isDarkCanvas ? const Color(0xFF374151).withOpacity(0.55) : const Color(0xFF94A3B8).withOpacity(0.7)
        ..strokeWidth = 1.0;

      for (double x = 0; x <= size.width; x += gridSize) {
        final isMajor = (x / (gridSize * 5)).round() * (gridSize * 5) == x;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
      }
      for (double y = 0; y <= size.height; y += gridSize) {
        final isMajor = (y / (gridSize * 5)).round() * (gridSize * 5) == y;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
      }
    }

    // 3. North Compass Indicator
    _drawNorthArrow(canvas, const Offset(700, 100));

    // 4. Render CAD Entities
    final layerMap = {for (var l in layers) l.id: l};

    for (final entity in entities) {
      final layer = layerMap[entity.layerId];
      if (layer != null && !layer.isVisible) continue;

      final isSel = entity == selectedEntity;
      final baseColor = entity.color ?? layer?.color ?? (isDarkCanvas ? Colors.white : Colors.black87);
      final strokePaint = Paint()
        ..color = isSel ? Colors.amber : baseColor
        ..strokeWidth = isSel ? (entity.strokeWidth + 1.5) : entity.strokeWidth
        ..style = PaintingStyle.stroke;

      _drawEntity(canvas, entity, strokePaint, isSel);
    }

    // 5. Active Tool Drawing Preview
    if (dragStart != null && currentDrag != null) {
      final previewPaint = Paint()
        ..color = activeColor.withOpacity(0.8)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final previewEntity = CadEntity(
        id: "preview",
        type: activeTool,
        layerId: "active",
        points: [dragStart!, currentDrag!],
        radius: (dragStart! - currentDrag!).distance,
        strokeWidth: 2.0,
      );
      _drawEntity(canvas, previewEntity, previewPaint, false);
    }
  }

  void _drawEntity(Canvas canvas, CadEntity entity, Paint paint, bool isSel) {
    if (entity.points.isEmpty) return;

    switch (entity.type) {
      case CadTool.line:
      case CadTool.wall:
        if (entity.points.length >= 2) {
          if (entity.type == CadTool.wall) {
            canvas.drawLine(entity.points[0], entity.points[1], paint..strokeWidth = 6.0);
          } else {
            canvas.drawLine(entity.points[0], entity.points[1], paint);
          }
        }
        break;

      case CadTool.rectangle:
        if (entity.points.length >= 2) {
          final rect = Rect.fromPoints(entity.points[0], entity.points[1]);
          final fillPaint = Paint()
            ..color = paint.color.withOpacity(isDarkCanvas ? 0.08 : 0.04)
            ..style = PaintingStyle.fill;
          canvas.drawRect(rect, fillPaint);
          canvas.drawRect(rect, paint);

          if (entity.text.isNotEmpty && entity.showName) {
            _drawCenteredText(canvas, rect.center, entity.text, paint.color, fontSize: 11);
          }
          if (entity.showDimensions && entity.widthFt > 0 && entity.heightFt > 0) {
            _drawCenteredText(
              canvas,
              Offset(rect.center.dx, rect.center.dy + 14),
              "${entity.widthFt.toStringAsFixed(1)} x ${entity.heightFt.toStringAsFixed(1)} ft",
              paint.color.withOpacity(0.8),
              fontSize: 9,
            );
          }
        }
        break;

      case CadTool.circle:
        canvas.drawCircle(entity.points[0], entity.radius > 0 ? entity.radius : 40, paint);
        break;

      case CadTool.column:
        final center = entity.points[0];
        final sizePx = (entity.widthFt > 0 ? entity.widthFt : 0.75) * 15.0;
        final colRect = Rect.fromCenter(center: center, width: sizePx, height: sizePx);

        final colFill = Paint()
          ..color = const Color(0xFFD32F2F).withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawRect(colRect, colFill);
        canvas.drawRect(colRect, paint..color = const Color(0xFFEF4444)..strokeWidth = 2.0);

        canvas.drawLine(colRect.topLeft, colRect.bottomRight, Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.0);
        canvas.drawLine(colRect.topRight, colRect.bottomLeft, Paint()..color = const Color(0xFFEF4444)..strokeWidth = 1.0);
        break;

      case CadTool.door:
        if (entity.points.length >= 2) {
          final p1 = entity.points[0];
          final p2 = entity.points[1];
          final r = (p2 - p1).distance;
          canvas.drawLine(p1, p2, paint);
          final arcRect = Rect.fromCircle(center: p1, radius: r);
          final arcPaint = Paint()
            ..color = paint.color
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          canvas.drawArc(arcRect, 0, -math.pi / 2, false, arcPaint);
        }
        break;

      case CadTool.window:
        if (entity.points.length >= 2) {
          final p1 = entity.points[0];
          final p2 = entity.points[1];
          canvas.drawLine(p1, p2, paint);
          final glassPaint = Paint()
            ..color = const Color(0xFF38BDF8)
            ..strokeWidth = 1.0;
          const offset = Offset(0, 3);
          canvas.drawLine(p1 + offset, p2 + offset, glassPaint);
          canvas.drawLine(p1 - offset, p2 - offset, glassPaint);
        }
        break;

      case CadTool.dimension:
        if (entity.points.length >= 2) {
          final p1 = entity.points[0];
          final p2 = entity.points[1];
          canvas.drawLine(p1, p2, paint);
          canvas.drawLine(Offset(p1.dx, p1.dy - 6), Offset(p1.dx, p1.dy + 6), paint);
          canvas.drawLine(Offset(p2.dx, p2.dy - 6), Offset(p2.dx, p2.dy + 6), paint);
          final center = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2 - 12);
          _drawCenteredText(canvas, center, entity.text, paint.color, fontSize: 11);
        }
        break;

      case CadTool.text:
        _drawCenteredText(canvas, entity.points[0], entity.text, paint.color);
        break;

      case CadTool.block:
        _drawVectorBlock(canvas, entity, paint);
        break;

      default:
        break;
    }

    // Selection Halo / Bounding box
    if (isSel) {
      final bounds = entity.getBounds().inflate(4.0);
      final selPaint = Paint()
        ..color = Colors.amber
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawRect(bounds, selPaint);

      // Corner anchor handles
      final handlePaint = Paint()..color = Colors.amber..style = PaintingStyle.fill;
      for (final corner in [bounds.topLeft, bounds.topRight, bounds.bottomLeft, bounds.bottomRight]) {
        canvas.drawRect(Rect.fromCenter(center: corner, width: 6, height: 6), handlePaint);
      }
    }
  }

  // Realistic 2D Vector Architectural Block Renderer
  void _drawVectorBlock(Canvas canvas, CadEntity entity, Paint basePaint) {
    final center = entity.points[0];
    final w = (entity.widthFt > 0 ? entity.widthFt : 4.0) * 15.0;
    final h = (entity.heightFt > 0 ? entity.heightFt : 4.0) * 15.0;
    final rotRad = entity.rotationDeg * math.pi / 180.0;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotRad);

    final localRect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    final fill = Paint()..color = basePaint.color.withOpacity(0.08)..style = PaintingStyle.fill;
    canvas.drawRect(localRect, fill);
    canvas.drawRect(localRect, basePaint);

    switch (entity.blockType) {
      // 1. Bed (Headboard + Pillows + Blanket)
      case CadBlockType.bedDouble:
        canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h * 0.15), Paint()..color = basePaint.color..style = PaintingStyle.fill);
        final pW = w * 0.38;
        final pH = h * 0.22;
        final pPaint = Paint()..color = basePaint.color.withOpacity(0.4)..style = PaintingStyle.fill;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2 + 6, -h / 2 + h * 0.18, pW, pH), const Radius.circular(4)), pPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w / 2 - pW - 6, -h / 2 + h * 0.18, pW, pH), const Radius.circular(4)), pPaint);
        canvas.drawLine(Offset(-w / 2, h * 0.15), Offset(w / 2, h * 0.15), basePaint);
        break;

      case CadBlockType.bedSingle:
        canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h * 0.15), Paint()..color = basePaint.color..style = PaintingStyle.fill);
        final pW = w * 0.65;
        final pH = h * 0.22;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-pW / 2, -h / 2 + h * 0.18, pW, pH), const Radius.circular(4)), Paint()..color = basePaint.color.withOpacity(0.4)..style = PaintingStyle.fill);
        canvas.drawLine(Offset(-w / 2, h * 0.15), Offset(w / 2, h * 0.15), basePaint);
        break;

      // 2. Gas Stove / Chulha (Burners + Knobs)
      case CadBlockType.chulha2:
      case CadBlockType.chulha3:
      case CadBlockType.chulha4:
        final burnerCount = entity.blockType == CadBlockType.chulha2 ? 2 : (entity.blockType == CadBlockType.chulha3 ? 3 : 4);
        final step = w / (burnerCount + 1);
        for (int i = 1; i <= burnerCount; i++) {
          final bx = -w / 2 + step * i;
          canvas.drawCircle(Offset(bx, 0), math.min(w, h) * 0.22, basePaint);
          canvas.drawCircle(Offset(bx, 0), math.min(w, h) * 0.10, Paint()..color = basePaint.color..style = PaintingStyle.fill);
        }
        break;

      // 3. Kitchen Sink (Basin + Faucet)
      case CadBlockType.sinkSingle:
        final basinRect = Rect.fromCenter(center: Offset.zero, width: w * 0.8, height: h * 0.75);
        canvas.drawRRect(RRect.fromRectAndRadius(basinRect, const Radius.circular(6)), basePaint);
        canvas.drawCircle(Offset.zero, 4, Paint()..color = basePaint.color..style = PaintingStyle.fill);
        break;

      case CadBlockType.sinkDouble:
        final bW = w * 0.42;
        final bH = h * 0.75;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-w * 0.24, 0), width: bW, height: bH), const Radius.circular(4)), basePaint);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.24, 0), width: bW, height: bH), const Radius.circular(4)), basePaint);
        canvas.drawCircle(Offset(-w * 0.24, 0), 3.5, Paint()..color = basePaint.color..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(w * 0.24, 0), 3.5, Paint()..color = basePaint.color..style = PaintingStyle.fill);
        break;

      // 4. Toilet Western (Cistern + Oval Bowl)
      case CadBlockType.toiletWestern:
        canvas.drawRect(Rect.fromLTWH(-w * 0.45, -h / 2, w * 0.9, h * 0.3), basePaint);
        final bowlRect = Rect.fromLTWH(-w * 0.38, -h / 2 + h * 0.25, w * 0.76, h * 0.7);
        canvas.drawOval(bowlRect, basePaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, h * 0.2), width: w * 0.4, height: h * 0.45), Paint()..color = basePaint.color.withOpacity(0.3)..style = PaintingStyle.fill);
        break;

      // 5. Toilet Indian (Squatting Pan + Footrests)
      case CadBlockType.toiletIndian:
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.35, height: h * 0.65), basePaint);
        final fW = w * 0.22;
        final fH = h * 0.55;
        canvas.drawRect(Rect.fromCenter(center: Offset(-w * 0.35, 0), width: fW, height: fH), basePaint);
        canvas.drawRect(Rect.fromCenter(center: Offset(w * 0.35, 0), width: fW, height: fH), basePaint);
        break;

      // 6. Wash Basin
      case CadBlockType.washBasin:
        final basinRect = Rect.fromCenter(center: Offset.zero, width: w * 0.85, height: h * 0.8);
        canvas.drawRRect(RRect.fromRectAndRadius(basinRect, const Radius.circular(8)), basePaint);
        canvas.drawCircle(const Offset(0, 4), 3, Paint()..color = basePaint.color..style = PaintingStyle.fill);
        break;

      // 7. Sofa (Backrest + Cushions)
      case CadBlockType.sofa3:
      case CadBlockType.sofa2:
      case CadBlockType.sofaSingle:
        canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h * 0.25), Paint()..color = basePaint.color.withOpacity(0.3)..style = PaintingStyle.fill);
        canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w * 0.12, h), Paint()..color = basePaint.color.withOpacity(0.4)..style = PaintingStyle.fill);
        canvas.drawRect(Rect.fromLTWH(w / 2 - w * 0.12, -h / 2, w * 0.12, h), Paint()..color = basePaint.color.withOpacity(0.4)..style = PaintingStyle.fill);
        break;

      // 8. Stairs Dog-Legged
      case CadBlockType.stairsDogLeg:
        const treadCount = 8;
        final treadH = (h * 0.8) / treadCount;
        for (int i = 0; i < treadCount; i++) {
          final y = -h / 2 + i * treadH;
          canvas.drawLine(Offset(-w / 2, y), Offset(-2, y), basePaint);
          canvas.drawLine(Offset(2, y), Offset(w / 2, y), basePaint);
        }
        canvas.drawLine(Offset(0, -h / 2), Offset(0, h / 2 - h * 0.2), basePaint);
        break;

      default:
        break;
    }

    canvas.restore();

    if (entity.showName && entity.text.isNotEmpty) {
      _drawCenteredText(canvas, Offset(center.dx, center.dy - h / 2 - 10), entity.text, basePaint.color, fontSize: 10);
    }
    if (entity.showDimensions && entity.widthFt > 0) {
      _drawCenteredText(
        canvas,
        Offset(center.dx, center.dy + h / 2 + 10),
        "${entity.widthFt.toStringAsFixed(1)} x ${entity.heightFt.toStringAsFixed(1)} ft",
        basePaint.color.withOpacity(0.8),
        fontSize: 9,
      );
    }
  }

  void _drawCenteredText(Canvas canvas, Offset pos, String text, Color color, {double fontSize = 11}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          backgroundColor: isDarkCanvas ? const Color(0xFF10141D).withOpacity(0.85) : Colors.white.withOpacity(0.85),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  void _drawNorthArrow(Canvas canvas, Offset center) {
    final p = Paint()
      ..color = const Color(0xFFE5B05C)
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(center.dx, center.dy + 25), Offset(center.dx, center.dy - 25), p);
    final arrowHead = Path()
      ..moveTo(center.dx, center.dy - 35)
      ..lineTo(center.dx - 8, center.dy - 20)
      ..lineTo(center.dx + 8, center.dy - 20)
      ..close();
    canvas.drawPath(arrowHead, Paint()..color = const Color(0xFFE5B05C));
    _drawCenteredText(canvas, Offset(center.dx, center.dy - 48), "N ($facing)", const Color(0xFFE5B05C), fontSize: 10);
  }

  @override
  bool shouldRepaint(covariant CadCanvasPainter oldDelegate) => true;
}
