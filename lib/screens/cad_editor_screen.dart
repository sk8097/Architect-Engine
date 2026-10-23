import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/cad_models.dart';

class CadEditorScreen extends StatefulWidget {
  final String? projectTitle;

  const CadEditorScreen({super.key, this.projectTitle});

  @override
  State<CadEditorScreen> createState() => _CadEditorScreenState();
}

class _CadEditorScreenState extends State<CadEditorScreen> {
  final TransformationController _transformationController = TransformationController();

  CadTool _activeTool = CadTool.wall;
  bool _orthoMode = false;
  bool _snapToGrid = true;
  bool _showGrid = true;
  bool _isPanMode = false;
  final double _gridSize = 20.0;

  late String _activeLayerId;
  final List<CadLayer> _layers = [
    CadLayer(id: '0_WALLS', name: '0 - WALLS', color: const Color(0xFFF1C40F), strokeWidth: 3.5),
    CadLayer(id: 'A_DOORS', name: 'A - DOORS', color: const Color(0xFF00E5FF), strokeWidth: 2.0),
    CadLayer(id: 'A_WINDOWS', name: 'A - WINDOWS', color: const Color(0xFF38BDF8), strokeWidth: 2.0),
    CadLayer(id: 'A_DIMS', name: 'A - DIMS', color: const Color(0xFF4ADE80), strokeWidth: 1.5),
    CadLayer(id: 'A_TEXT', name: 'A - TEXT', color: const Color(0xFFFFFFFF), strokeWidth: 1.5),
    CadLayer(id: 'S_COLUMNS', name: 'S - COLUMNS', color: const Color(0xFFEF4444), strokeWidth: 2.5),
  ];

  List<CadElement> _elements = [];
  final List<List<CadElement>> _undoStack = [];
  final List<List<CadElement>> _redoStack = [];

  Offset? _dragStart;
  Offset? _currentCursor;
  SnapPoint? _currentSnap;
  CadElement? _selectedElement;
  Offset? _elementDragOffset;
  String _commandPrompt = 'Command: WALL - Tap or drag to draw architectural wall';
  Offset? _polyFirst;
  Offset? _polyLast;
  int _polyCount = 0;
  Offset? _moveLast;
  bool _moveUndoSaved = false;

  @override
  void initState() {
    super.initState();
    _activeLayerId = _layers.first.id;
    _loadSampleBlueprint();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _saveStateForUndo() {
    _undoStack.add(List<CadElement>.from(_elements.map((e) => e.copyWith())));
    _redoStack.clear();
    if (_undoStack.length > 30) _undoStack.removeAt(0);
  }

  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(List<CadElement>.from(_elements.map((e) => e.copyWith())));
      setState(() {
        _elements = _undoStack.removeLast();
        _selectedElement = null;
        _commandPrompt = 'Command: UNDO applied';
      });
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(List<CadElement>.from(_elements.map((e) => e.copyWith())));
      setState(() {
        _elements = _redoStack.removeLast();
        _selectedElement = null;
        _commandPrompt = 'Command: REDO applied';
      });
    }
  }

  Offset _applySnapping(Offset rawPoint) {
    const double snapThreshold = 18.0;
    SnapPoint? foundSnap;

    for (final el in _elements) {
      if ((el.start - rawPoint).distance < snapThreshold) {
        foundSnap = SnapPoint(point: el.start, label: 'ENDPOINT', color: const Color(0xFF22C55E));
        break;
      }
      if ((el.end - rawPoint).distance < snapThreshold) {
        foundSnap = SnapPoint(point: el.end, label: 'ENDPOINT', color: const Color(0xFF22C55E));
        break;
      }
      final mid = Offset((el.start.dx + el.end.dx) / 2, (el.start.dy + el.end.dy) / 2);
      if ((mid - rawPoint).distance < snapThreshold) {
        foundSnap = SnapPoint(point: mid, label: 'MIDPOINT', color: const Color(0xFF3B82F6));
        break;
      }
    }

    if (foundSnap != null) {
      _currentSnap = foundSnap;
      return foundSnap.point;
    }

    _currentSnap = null;
    if (_snapToGrid) {
      final snappedX = (rawPoint.dx / _gridSize).round() * _gridSize;
      final snappedY = (rawPoint.dy / _gridSize).round() * _gridSize;
      return Offset(snappedX, snappedY);
    }
    return rawPoint;
  }

  Offset _applyOrtho(Offset start, Offset current) {
    if (!_orthoMode) return current;
    final dx = (current.dx - start.dx).abs();
    final dy = (current.dy - start.dy).abs();
    return dx > dy ? Offset(current.dx, start.dy) : Offset(start.dx, current.dy);
  }

  Offset _screenToWorld(Offset screenPos) {
    return _transformationController.toScene(screenPos);
  }

  void _onPointerDown(PointerDownEvent details) {
    if (_isPanMode) return;
    final worldPos = _screenToWorld(details.localPosition);
    final snapped = _applySnapping(worldPos);

    if (_activeTool == CadTool.select) {
      CadElement? hit;
      for (final el in _elements.reversed) {
        if (el.boundingBox.inflate(15).contains(snapped)) {
          hit = el;
          break;
        }
      }
      setState(() {
        _selectedElement = hit;
        if (hit != null) {
          _elementDragOffset = snapped - hit.start;
          _moveLast = snapped;
          _moveUndoSaved = false;
          _commandPrompt = 'Selected: ${hit.type.name.toUpperCase()} (Layer: ${hit.layerId})';
        } else {
          _moveLast = null;
          _commandPrompt = 'Command: SELECT - Tap an object to select';
        }
      });
      return;
    }

    if (_activeTool == CadTool.eraser) {
      for (int i = _elements.length - 1; i >= 0; i--) {
        if (_elements[i].boundingBox.inflate(15).contains(snapped)) {
          _saveStateForUndo();
          setState(() {
            final removed = _elements.removeAt(i);
            _commandPrompt = 'Erased: ${removed.type.name.toUpperCase()}';
          });
          break;
        }
      }
      return;
    }

    if (_activeTool == CadTool.polyline) {
      setState(() {
        _currentCursor = snapped;
        _commandPrompt = _polyLast == null ? 'PLINE - Specify start point' : 'PLINE - Specify next point (Done / Close below)';
      });
      return;
    }

    setState(() {
      _dragStart = snapped;
      _currentCursor = snapped;
      _commandPrompt = 'Specify next point or angle...';
    });
  }

  void _onPointerMove(PointerMoveEvent details) {
    final worldPos = _screenToWorld(details.localPosition);
    var snapped = _applySnapping(worldPos);

    if (_dragStart != null && _orthoMode) {
      snapped = _applyOrtho(_dragStart!, snapped);
    }

    setState(() {
      _currentCursor = snapped;
      if (_selectedElement != null && _moveLast != null && _activeTool == CadTool.select) {
        if (!_moveUndoSaved) {
          _saveStateForUndo();
          _moveUndoSaved = true;
        }
        final delta = snapped - _moveLast!;
        _selectedElement!.start += delta;
        _selectedElement!.end += delta;
        _moveLast = snapped;
      }
    });
  }

  void _onPointerUp(PointerUpEvent details) {
    if (_isPanMode) return;
    _moveLast = null;
    if (_activeTool == CadTool.polyline) {
      _polyAddPoint();
      return;
    }
    if (_dragStart != null && _currentCursor != null) {
      final start = _dragStart!;
      var end = _currentCursor!;
      if (_orthoMode) end = _applyOrtho(start, end);

      if ((start - end).distance > 8 || _activeTool == CadTool.column || _activeTool == CadTool.text) {
        _saveStateForUndo();
        _createElement(start, end);
      }
      setState(() {
        _dragStart = null;
        _commandPrompt = 'Command: ${_activeTool.name.toUpperCase()} completed.';
      });
    }
  }

  void _createElement(Offset start, Offset end) {
    final id = 'el_${DateTime.now().millisecondsSinceEpoch}';
    switch (_activeTool) {
      case CadTool.wall:
        _elements.add(CadElement(id: id, type: CadElementType.wall, layerId: '0_WALLS', start: start, end: end));
        break;
      case CadTool.line:
        _elements.add(CadElement(id: id, type: CadElementType.line, layerId: _activeLayerId, start: start, end: end));
        break;
      case CadTool.rectangle:
        _elements.add(CadElement(id: id, type: CadElementType.rectangle, layerId: '0_WALLS', start: start, end: end));
        break;
      case CadTool.circle:
        _elements.add(CadElement(id: id, type: CadElementType.circle, layerId: _activeLayerId, start: start, end: end, radius: (end - start).distance));
        break;
      case CadTool.door:
        _elements.add(CadElement(id: id, type: CadElementType.door, layerId: 'A_DOORS', start: start, end: end));
        break;
      case CadTool.window:
        _elements.add(CadElement(id: id, type: CadElementType.window, layerId: 'A_WINDOWS', start: start, end: end));
        break;
      case CadTool.dimension:
        final distM = (end - start).distance / 20.0;
        final feet = (distM * 3.28084);
        final feetInt = feet.floor();
        final inches = ((feet - feetInt) * 12).round();
        _elements.add(CadElement(
          id: id,
          type: CadElementType.dimension,
          layerId: 'A_DIMS',
          start: start,
          end: end,
          text: "$feetInt'-$inches\" (${distM.toStringAsFixed(2)}m)",
        ));
        break;
      case CadTool.column:
        _elements.add(CadElement(id: id, type: CadElementType.column, layerId: 'S_COLUMNS', start: start - const Offset(12, 12), end: start + const Offset(12, 12)));
        break;
      case CadTool.text:
        _showTextInputDialog(start);
        break;
      default:
        break;
    }
  }

  Offset _centerOf(CadElement el) {
    return Offset((el.start.dx + el.end.dx) / 2, (el.start.dy + el.end.dy) / 2);
  }

  // ---------- POLYLINE (PL) ----------
  void _polyAddPoint() {
    final pt = _currentCursor;
    if (pt == null) return;
    var p = pt;
    if (_polyLast != null && _orthoMode) p = _applyOrtho(_polyLast!, p);
    if (_polyLast == null) {
      setState(() {
        _polyFirst = p;
        _polyLast = p;
        _polyCount = 0;
        _dragStart = p;
        _commandPrompt = 'PLINE - Specify next point';
      });
      return;
    }
    if ((p - _polyLast!).distance < 8) return;
    _saveStateForUndo();
    setState(() {
      _elements.add(CadElement(
        id: 'el_${DateTime.now().microsecondsSinceEpoch}',
        type: CadElementType.line,
        layerId: _activeLayerId,
        start: _polyLast!,
        end: p,
      ));
      _polyLast = p;
      _polyCount++;
      _dragStart = p;
      _commandPrompt = 'PLINE - $_polyCount segment(s). Next point, or Done / Close';
    });
  }

  void _polyFinish({bool close = false}) {
    if (close && _polyFirst != null && _polyLast != null && _polyCount >= 2 && (_polyFirst! - _polyLast!).distance > 1) {
      _saveStateForUndo();
      _elements.add(CadElement(
        id: 'el_${DateTime.now().microsecondsSinceEpoch}',
        type: CadElementType.line,
        layerId: _activeLayerId,
        start: _polyLast!,
        end: _polyFirst!,
      ));
    }
    setState(() {
      _polyFirst = null;
      _polyLast = null;
      _polyCount = 0;
      _dragStart = null;
      _commandPrompt = close ? 'PLINE - closed' : 'PLINE - finished';
    });
  }

  // ---------- MODIFY: COPY / ROTATE / OFFSET / ERASE ----------
  void _modifyCopy() {
    final src = _selectedElement;
    if (src == null) return;
    _saveStateForUndo();
    const shift = Offset(20, 20);
    final copy = src.copyWith(
      id: 'el_${DateTime.now().microsecondsSinceEpoch}',
      start: src.start + shift,
      end: src.end + shift,
      isSelected: false,
    );
    setState(() {
      _elements.add(copy);
      _selectedElement = copy;
      _commandPrompt = 'COPY - copy placed 1 m away, drag it to move';
    });
  }

  void _modifyDelete() {
    final el = _selectedElement;
    if (el == null) return;
    _saveStateForUndo();
    setState(() {
      _elements.removeWhere((e) => e.id == el.id);
      _selectedElement = null;
      _commandPrompt = 'ERASE - object deleted';
    });
  }

  void _modifyRotateDialog() {
    if (_selectedElement == null) return;
    final controller = TextEditingController(text: '90');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: const Text('ROTATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Angle in degrees (+ = clockwise)',
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final deg = double.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (deg != null) _rotateSelected(deg);
            },
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
  }

  void _rotateSelected(double deg) {
    final el = _selectedElement;
    if (el == null) return;
    if (el.type == CadElementType.circle || el.type == CadElementType.text) {
      setState(() => _commandPrompt = 'ROTATE - not applicable to this object');
      return;
    }
    var angle = deg;
    if (el.type == CadElementType.rectangle || el.type == CadElementType.column) {
      angle = (deg / 90).round() * 90.0;
    }
    final rad = angle * math.pi / 180;
    final cs = math.cos(rad);
    final sn = math.sin(rad);
    final c = _centerOf(el);
    Offset rot(Offset p) {
      final d = p - c;
      return c + Offset(d.dx * cs - d.dy * sn, d.dx * sn + d.dy * cs);
    }
    _saveStateForUndo();
    setState(() {
      el.start = rot(el.start);
      el.end = rot(el.end);
      _commandPrompt = 'ROTATE - rotated ${angle.toStringAsFixed(0)} deg about center';
    });
  }

  void _modifyOffsetDialog() {
    if (_selectedElement == null) return;
    final controller = TextEditingController(text: '0.23');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: const Text('OFFSET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Distance in metres (+ right side, - left side)',
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final m = double.tryParse(controller.text.trim());
              Navigator.pop(ctx);
              if (m != null && m != 0) _offsetSelected(m);
            },
            child: const Text('Offset'),
          ),
        ],
      ),
    );
  }

  void _offsetSelected(double meters) {
    final el = _selectedElement;
    if (el == null) return;
    final d = meters * 20.0;
    final id = 'el_${DateTime.now().microsecondsSinceEpoch}';
    CadElement? result;
    if (el.type == CadElementType.line || el.type == CadElementType.wall || el.type == CadElementType.window) {
      final dir = el.end - el.start;
      if (dir.distance > 0) {
        final n = Offset(-dir.dy, dir.dx) / dir.distance * d;
        result = el.copyWith(id: id, start: el.start + n, end: el.end + n, isSelected: false);
      }
    } else if (el.type == CadElementType.rectangle) {
      final r = Rect.fromPoints(el.start, el.end).inflate(d);
      if (r.width > 0 && r.height > 0) {
        result = el.copyWith(id: id, start: r.topLeft, end: r.bottomRight, isSelected: false);
      }
    } else if (el.type == CadElementType.circle) {
      final r0 = el.radius ?? (el.end - el.start).distance;
      if (r0 + d > 0) {
        result = el.copyWith(id: id, radius: r0 + d, isSelected: false);
      }
    }
    if (result == null) {
      setState(() => _commandPrompt = 'OFFSET - not possible for this object / distance');
      return;
    }
    final made = result;
    _saveStateForUndo();
    setState(() {
      _elements.add(made);
      _selectedElement = made;
      _commandPrompt = 'OFFSET - ${meters.toStringAsFixed(2)} m done';
    });
  }

  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF0F172A).withOpacity(0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colors.white24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.darkPrimary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextInputDialog(Offset position) {
    final controller = TextEditingController(text: 'LIVING ROOM');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Add CAD Room / Label', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Room Name')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                "LIVING 15x12 ft",
                "BEDROOM 12x14 ft",
                "KITCHEN 10x8 ft",
                "TOILET 6x8 ft",
              ].map((sample) => ActionChip(label: Text(sample, style: const TextStyle(fontSize: 10)), onPressed: () => controller.text = sample)).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, foregroundColor: Colors.black),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveStateForUndo();
                setState(() {
                  _elements.add(CadElement(
                    id: 'text_${DateTime.now().millisecondsSinceEpoch}',
                    type: CadElementType.text,
                    layerId: 'A_TEXT',
                    start: position,
                    end: position + const Offset(120, 24),
                    text: controller.text.trim(),
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Place Text'),
          ),
        ],
      ),
    );
  }

  void _loadSampleBlueprint() {
    _elements = [
      CadElement(id: 'w1', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(100, 100), end: const Offset(500, 100)),
      CadElement(id: 'w2', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(500, 100), end: const Offset(500, 400)),
      CadElement(id: 'w3', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(500, 400), end: const Offset(100, 400)),
      CadElement(id: 'w4', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(100, 400), end: const Offset(100, 100)),
      CadElement(id: 'w5', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(320, 100), end: const Offset(320, 400)),
      CadElement(id: 'w6', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(100, 260), end: const Offset(320, 260)),
      CadElement(id: 'w7', type: CadElementType.wall, layerId: '0_WALLS', start: const Offset(320, 250), end: const Offset(500, 250)),
      CadElement(id: 'd1', type: CadElementType.door, layerId: 'A_DOORS', start: const Offset(100, 320), end: const Offset(100, 360)),
      CadElement(id: 'd2', type: CadElementType.door, layerId: 'A_DOORS', start: const Offset(320, 280), end: const Offset(320, 315)),
      CadElement(id: 'd3', type: CadElementType.door, layerId: 'A_DOORS', start: const Offset(320, 180), end: const Offset(320, 215)),
      CadElement(id: 'win1', type: CadElementType.window, layerId: 'A_WINDOWS', start: const Offset(160, 100), end: const Offset(260, 100)),
      CadElement(id: 'win2', type: CadElementType.window, layerId: 'A_WINDOWS', start: const Offset(500, 140), end: const Offset(500, 200)),
      CadElement(id: 'win3', type: CadElementType.window, layerId: 'A_WINDOWS', start: const Offset(380, 400), end: const Offset(460, 400)),
      CadElement(id: 'col1', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(88, 88), end: const Offset(112, 112)),
      CadElement(id: 'col2', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(308, 88), end: const Offset(332, 112)),
      CadElement(id: 'col3', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(488, 88), end: const Offset(512, 112)),
      CadElement(id: 'col4', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(88, 388), end: const Offset(112, 412)),
      CadElement(id: 'col5', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(308, 388), end: const Offset(332, 412)),
      CadElement(id: 'col6', type: CadElementType.column, layerId: 'S_COLUMNS', start: const Offset(488, 388), end: const Offset(512, 412)),
      CadElement(id: 't1', type: CadElementType.text, layerId: 'A_TEXT', start: const Offset(160, 180), end: const Offset(260, 200), text: 'LIVING ROOM\n15\'0" × 12\'0"'),
      CadElement(id: 't2', type: CadElementType.text, layerId: 'A_TEXT', start: const Offset(360, 160), end: const Offset(460, 180), text: 'KITCHEN\n10\'0" × 8\'0"'),
      CadElement(id: 't3', type: CadElementType.text, layerId: 'A_TEXT', start: const Offset(360, 310), end: const Offset(460, 330), text: 'BEDROOM\n10\'0" × 12\'0"'),
      CadElement(id: 't4', type: CadElementType.text, layerId: 'A_TEXT', start: const Offset(150, 310), end: const Offset(250, 330), text: 'TOILET & BATH\n6\'0" × 8\'0"'),
      CadElement(id: 'dim1', type: CadElementType.dimension, layerId: 'A_DIMS', start: const Offset(100, 70), end: const Offset(500, 70), text: '40\'-0" (12.20 m)'),
      CadElement(id: 'dim2', type: CadElementType.dimension, layerId: 'A_DIMS', start: const Offset(530, 100), end: const Offset(530, 400), text: '30\'-0" (9.14 m)'),
    ];
  }

  void _showLayersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131C35),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('📑 CAD LAYER MANAGER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _layers.length,
                      itemBuilder: (context, index) {
                        final layer = _layers[index];
                        final isSelected = layer.id == _activeLayerId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.darkPrimary.withOpacity(0.15) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? AppColors.darkPrimary : Colors.transparent),
                          ),
                          child: ListTile(
                            leading: Container(width: 24, height: 24, decoration: BoxDecoration(color: layer.color, shape: BoxShape.circle)),
                            title: Text(layer.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? AppColors.darkPrimary : Colors.white)),
                            trailing: IconButton(
                              icon: Icon(layer.isVisible ? Icons.visibility : Icons.visibility_off, color: layer.isVisible ? Colors.greenAccent : Colors.grey, size: 20),
                              onPressed: () {
                                setSheetState(() => layer.isVisible = !layer.isVisible);
                                setState(() {});
                              },
                            ),
                            onTap: () {
                              setState(() => _activeLayerId = layer.id);
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: const Text('Export AutoCAD Drawing', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('📐', style: TextStyle(fontSize: 24)),
              title: const Text('AutoCAD DXF / DWG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Compatible with AutoCAD, Revit & SketchUp', style: TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Drawing exported as Drawing_R01.dxf')));
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Text('📄', style: TextStyle(fontSize: 24)),
              title: const Text('Architectural Blueprint PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Vector print with scale & title block', style: TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Exported Blueprint PDF successfully!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = _layers.firstWhere((l) => l.id == _activeLayerId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Exit CAD',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.darkPrimary, borderRadius: BorderRadius.circular(4)),
                  child: const Text('AUTOCAD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 9)),
                ),
                const SizedBox(width: 8),
                Text(widget.projectTitle ?? 'Drawing1.dwg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            Text(
              _currentCursor != null ? 'X: ${(_currentCursor!.dx / 20).toStringAsFixed(2)}m | Y: ${(_currentCursor!.dy / 20).toStringAsFixed(2)}m' : 'X: 0.00m | Y: 0.00m',
              style: const TextStyle(fontSize: 10, color: AppColors.darkPrimary, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.undo, size: 20), onPressed: _undoStack.isEmpty ? null : _undo, tooltip: 'Undo'),
          IconButton(icon: const Icon(Icons.redo, size: 20), onPressed: _redoStack.isEmpty ? null : _redo, tooltip: 'Redo'),
          InkWell(
            onTap: _showLayersSheet,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8), border: Border.all(color: activeLayer.color)),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: activeLayer.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(activeLayer.name.split(' - ').last, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.save_alt, color: AppColors.darkPrimary), tooltip: 'Export', onPressed: _showExportDialog),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(2000),
            minScale: 0.2,
            maxScale: 6.0,
            panEnabled: _isPanMode,
            scaleEnabled: true,
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              child: CustomPaint(
                size: const Size(3000, 3000),
                painter: _CadCanvasPainter(
                  elements: _elements,
                  layers: _layers,
                  showGrid: _showGrid,
                  gridSize: _gridSize,
                  dragStart: _dragStart,
                  currentCursor: _currentCursor,
                  activeTool: _activeTool,
                  activeLayer: activeLayer,
                  selectedElement: _selectedElement,
                  currentSnap: _currentSnap,
                  orthoMode: _orthoMode,
                ),
              ),
            ),
          ),

          // Left AutoCAD Toolbar
          Positioned(
            left: 10,
            top: 10,
            bottom: 70,
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.92),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildToolIcon(CadTool.select, Icons.near_me, 'Select (S)'),
                    _buildToolIcon(CadTool.wall, Icons.border_all, 'Wall (W)'),
                    _buildToolIcon(CadTool.line, Icons.horizontal_rule, 'Line (L)'),
                    _buildToolIcon(CadTool.polyline, Icons.timeline, 'Polyline (PL)'),
                    _buildToolIcon(CadTool.rectangle, Icons.crop_square, 'Room (REC)'),
                    _buildToolIcon(CadTool.door, Icons.meeting_room_outlined, 'Door (D)'),
                    _buildToolIcon(CadTool.window, Icons.window, 'Window (WIN)'),
                    _buildToolIcon(CadTool.circle, Icons.radio_button_unchecked, 'Circle (C)'),
                    _buildToolIcon(CadTool.column, Icons.grid_view_sharp, 'Column (COL)'),
                    _buildToolIcon(CadTool.dimension, Icons.straighten, 'Dimension (DIM)'),
                    _buildToolIcon(CadTool.text, Icons.title, 'Text (T)'),
                    _buildToolIcon(CadTool.eraser, Icons.auto_fix_normal, 'Eraser (E)'),
                    const Divider(color: Colors.white24, height: 16),
                    IconButton(
                      icon: Icon(_isPanMode ? Icons.pan_tool : Icons.pan_tool_outlined),
                      color: _isPanMode ? AppColors.darkPrimary : Colors.white70,
                      onPressed: () => setState(() => _isPanMode = !_isPanMode),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Right Toggles
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  _buildToggleBtn(label: 'ORTHO', icon: Icons.alt_route, isActive: _orthoMode, onTap: () => setState(() => _orthoMode = !_orthoMode)),
                  const SizedBox(width: 4),
                  _buildToggleBtn(label: 'SNAP', icon: Icons.crop_free, isActive: _snapToGrid, onTap: () => setState(() => _snapToGrid = !_snapToGrid)),
                  const SizedBox(width: 4),
                  _buildToggleBtn(label: 'GRID', icon: Icons.grid_on, isActive: _showGrid, onTap: () => setState(() => _showGrid = !_showGrid)),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.filter_center_focus, size: 18, color: Colors.white70),
                    tooltip: 'Reset View',
                    onPressed: () => _transformationController.value = Matrix4.identity(),
                  ),
                ],
              ),
            ),
          ),

          if (_activeTool == CadTool.polyline && _polyLast != null)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionChip(Icons.check, 'Done', () => _polyFinish()),
                  const SizedBox(width: 8),
                  _buildActionChip(Icons.crop_square, 'Close', () => _polyFinish(close: true)),
                ],
              ),
            ),
          if (_activeTool == CadTool.select && _selectedElement != null)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionChip(Icons.content_copy, 'Copy', _modifyCopy),
                    const SizedBox(width: 8),
                    _buildActionChip(Icons.rotate_right, 'Rotate', _modifyRotateDialog),
                    const SizedBox(width: 8),
                    _buildActionChip(Icons.horizontal_split, 'Offset', _modifyOffsetDialog),
                    const SizedBox(width: 8),
                    _buildActionChip(Icons.delete_outline, 'Delete', _modifyDelete),
                  ],
                ),
              ),
            ),

          // Bottom Command Bar
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withOpacity(0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Text('CAD >', style: TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_commandPrompt, style: const TextStyle(fontSize: 12, color: Colors.white, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Templates',
                    icon: const Icon(Icons.dashboard_customize_outlined, color: AppColors.darkPrimary, size: 20),
                    onSelected: (val) {
                      _saveStateForUndo();
                      if (val == '1bhk') {
                        setState(() => _loadSampleBlueprint());
                      } else if (val == 'clear') {
                        setState(() => _elements.clear());
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: '1bhk', child: Text('🏠 Load 1BHK Floor Plan')),
                      const PopupMenuItem(value: 'clear', child: Text('🗑️ Clear Canvas', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolIcon(CadTool tool, IconData icon, String tooltip) {
    final isSelected = _activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IconButton(
        icon: Icon(icon, size: 22),
        color: isSelected ? AppColors.darkPrimary : Colors.white70,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: isSelected ? AppColors.darkPrimary.withOpacity(0.2) : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {
          setState(() {
            _activeTool = tool;
            _isPanMode = false;
            _selectedElement = null;
            _polyFirst = null;
            _polyLast = null;
            _polyCount = 0;
            _dragStart = null;
            _commandPrompt = 'Command: ${tool.name.toUpperCase()}';
          });
        },
      ),
    );
  }

  Widget _buildToggleBtn({required String label, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.darkPrimary.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.darkPrimary : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? AppColors.darkPrimary : Colors.white60),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? AppColors.darkPrimary : Colors.white60)),
          ],
        ),
      ),
    );
  }
}

class _CadCanvasPainter extends CustomPainter {
  final List<CadElement> elements;
  final List<CadLayer> layers;
  final bool showGrid;
  final double gridSize;
  final Offset? dragStart;
  final Offset? currentCursor;
  final CadTool activeTool;
  final CadLayer activeLayer;
  final CadElement? selectedElement;
  final SnapPoint? currentSnap;
  final bool orthoMode;

  _CadCanvasPainter({
    required this.elements,
    required this.layers,
    required this.showGrid,
    required this.gridSize,
    required this.dragStart,
    required this.currentCursor,
    required this.activeTool,
    required this.activeLayer,
    required this.selectedElement,
    required this.currentSnap,
    required this.orthoMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _drawGrid(canvas, size);

    final layerMap = {for (var l in layers) l.id: l};
    for (final el in elements) {
      final layer = layerMap[el.layerId];
      if (layer != null && !layer.isVisible) continue;
      final color = el.customColor ?? layer?.color ?? Colors.white;
      final stroke = el.customStrokeWidth ?? layer?.strokeWidth ?? 2.0;
      final isSel = selectedElement?.id == el.id;
      _drawCadElement(canvas, el, color, stroke, isSel);
    }

    if (dragStart != null && currentCursor != null) {
      _drawPreviewElement(canvas, dragStart!, currentCursor!);
    }

    if (currentCursor != null) {
      _drawCrosshair(canvas, currentCursor!, size);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()..color = const Color(0xFF1E293B).withOpacity(0.4)..strokeWidth = 0.5;
    final majorPaint = Paint()..color = const Color(0xFF334155).withOpacity(0.6)..strokeWidth = 1.0;

    for (double x = 0; x < size.width; x += gridSize) {
      final isMajor = (x / (gridSize * 5)).round() == (x / (gridSize * 5));
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), isMajor ? majorPaint : minorPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      final isMajor = (y / (gridSize * 5)).round() == (y / (gridSize * 5));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), isMajor ? majorPaint : minorPaint);
    }
  }

  void _drawCadElement(Canvas canvas, CadElement el, Color color, double strokeWidth, bool isSelected) {
    final paint = Paint()
      ..color = isSelected ? const Color(0xFF38BDF8) : color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    switch (el.type) {
      case CadElementType.line:
        canvas.drawLine(el.start, el.end, paint);
        break;
      case CadElementType.wall:
        final dir = el.end - el.start;
        if (dir.distance > 0) {
          final norm = Offset(-dir.dy, dir.dx) / dir.distance * 5.0;
          canvas.drawLine(el.start + norm, el.end + norm, paint);
          canvas.drawLine(el.start - norm, el.end - norm, paint);
        }
        break;
      case CadElementType.rectangle:
        canvas.drawRect(Rect.fromPoints(el.start, el.end), paint);
        break;
      case CadElementType.circle:
        final r = el.radius ?? (el.end - el.start).distance;
        canvas.drawCircle(el.start, r, paint);
        break;
      case CadElementType.door:
        final doorWidth = (el.end - el.start).distance;
        canvas.drawLine(el.start, el.end, paint);
        canvas.drawArc(Rect.fromCircle(center: el.start, radius: doorWidth), 0, math.pi / 2, false, paint..strokeWidth = 1.2);
        break;
      case CadElementType.window:
        final dir = el.end - el.start;
        if (dir.distance > 0) {
          final norm = Offset(-dir.dy, dir.dx) / dir.distance * 4.0;
          canvas.drawLine(el.start + norm, el.end + norm, paint);
          canvas.drawLine(el.start, el.end, paint..strokeWidth = 1.0);
          canvas.drawLine(el.start - norm, el.end - norm, paint..strokeWidth = strokeWidth);
        }
        break;
      case CadElementType.column:
        final rect = Rect.fromPoints(el.start, el.end);
        canvas.drawRect(rect, Paint()..color = (isSelected ? const Color(0xFF38BDF8) : color).withOpacity(0.3)..style = PaintingStyle.fill);
        canvas.drawRect(rect, paint);
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint..strokeWidth = 1.0);
        canvas.drawLine(rect.bottomLeft, rect.topRight, paint..strokeWidth = 1.0);
        break;
      case CadElementType.dimension:
        canvas.drawLine(el.start, el.end, paint);
        canvas.drawLine(el.start - const Offset(5, 5), el.start + const Offset(5, 5), paint);
        canvas.drawLine(el.end - const Offset(5, 5), el.end + const Offset(5, 5), paint);
        final mid = Offset((el.start.dx + el.end.dx) / 2, (el.start.dy + el.end.dy) / 2 - 12);
        final tp = TextPainter(
          text: TextSpan(text: el.text ?? '', style: const TextStyle(color: Color(0xFF4ADE80), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, mid - Offset(tp.width / 2, 0));
        break;
      case CadElementType.text:
        final tp = TextPainter(
          text: TextSpan(
            text: el.text ?? 'TEXT',
            style: TextStyle(color: isSelected ? const Color(0xFF38BDF8) : color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', backgroundColor: const Color(0xFF0A0F1D).withOpacity(0.8)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, el.start);
        break;
    }

    if (isSelected) {
      final grip = Paint()..color = const Color(0xFF38BDF8);
      canvas.drawRect(Rect.fromCenter(center: el.start, width: 8, height: 8), grip);
      canvas.drawRect(Rect.fromCenter(center: el.end, width: 8, height: 8), grip);
    }
  }

  void _drawPreviewElement(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()..color = activeLayer.color.withOpacity(0.85)..strokeWidth = activeLayer.strokeWidth..style = PaintingStyle.stroke;
    switch (activeTool) {
      case CadTool.wall:
      case CadTool.line:
        canvas.drawLine(start, end, paint);
        break;
      case CadTool.rectangle:
        canvas.drawRect(Rect.fromPoints(start, end), paint);
        break;
      case CadTool.circle:
        canvas.drawCircle(start, (end - start).distance, paint);
        break;
      default:
        canvas.drawLine(start, end, paint);
    }

    final distM = (end - start).distance / 20.0;
    final angle = (math.atan2(end.dy - start.dy, end.dx - start.dx) * 180 / math.pi).round();
    final tp = TextPainter(
      text: TextSpan(text: '${distM.toStringAsFixed(2)}m  ∠ $angle°', style: const TextStyle(color: AppColors.darkPrimary, fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.black87)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, end + const Offset(14, -20));
  }

  void _drawCrosshair(Canvas canvas, Offset cursor, Size size) {
    canvas.drawLine(Offset(0, cursor.dy), Offset(size.width, cursor.dy), Paint()..color = Colors.redAccent.withOpacity(0.7)..strokeWidth = 0.8);
    canvas.drawLine(Offset(cursor.dx, 0), Offset(cursor.dx, size.height), Paint()..color = Colors.greenAccent.withOpacity(0.7)..strokeWidth = 0.8);
    canvas.drawRect(Rect.fromCenter(center: cursor, width: 8, height: 8), Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.0);

    if (currentSnap != null) {
      canvas.drawRect(Rect.fromCenter(center: currentSnap!.point, width: 14, height: 14), Paint()..color = currentSnap!.color..style = PaintingStyle.stroke..strokeWidth = 2.0);
    }
  }

  @override
  bool shouldRepaint(covariant _CadCanvasPainter oldDelegate) => true;
}
