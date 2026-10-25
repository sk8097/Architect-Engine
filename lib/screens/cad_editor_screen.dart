import 'dart:convert' as conv;
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
    CadLayer(id: 'A_FURNITURE', name: 'A - FURNITURE', color: const Color(0xFFFB923C), strokeWidth: 2.0),
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
  final List<Offset> _arcPts = [];
  String? _pendingBlock;

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
        if (el.type == CadElementType.hatch) continue;
        if (_selectHit(el, snapped)) {
          hit = el;
          break;
        }
      }
      if (hit == null) {
        for (final el in _elements.reversed) {
          if (el.type == CadElementType.hatch && el.boundingBox.contains(snapped)) {
            hit = el;
            break;
          }
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
        if (_selectHit(_elements[i], snapped)) {
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

    if (_activeTool == CadTool.trim || _activeTool == CadTool.extend) {
      setState(() => _currentCursor = snapped);
      if (_activeTool == CadTool.trim) {
        _trimAt(worldPos);
      } else {
        _extendAt(worldPos);
      }
      return;
    }

    if (_activeTool == CadTool.block) {
      setState(() => _currentCursor = snapped);
      return;
    }

    if (_activeTool == CadTool.arc) {
      setState(() {
        _currentCursor = snapped;
        _commandPrompt = 'ARC - point ${_arcPts.length + 1} of 3';
      });
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

    if (_dragStart != null && _orthoMode && _activeTool != CadTool.hatch) {
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
    if (_activeTool == CadTool.arc) {
      _arcAddPoint();
      return;
    }
    if (_activeTool == CadTool.block) {
      _placeBlock();
      return;
    }
    if (_activeTool == CadTool.hatch && _dragStart != null && _currentCursor != null) {
      _hatchFinish(_dragStart!, _currentCursor!);
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
    if (el.type == CadElementType.block) {
      _saveStateForUndo();
      final upd = el.copyWith(radius: ((el.radius ?? 0.0) + deg) % 360);
      setState(() {
        final i = _elements.indexWhere((e) => e.id == el.id);
        if (i >= 0) _elements[i] = upd;
        _selectedElement = upd;
        _commandPrompt = 'ROTATE - block rotated';
      });
      return;
    }
    if (el.type == CadElementType.circle || el.type == CadElementType.text) {
      setState(() => _commandPrompt = 'ROTATE - not applicable to this object');
      return;
    }
    var angle = deg;
    if (el.type == CadElementType.rectangle || el.type == CadElementType.column || el.type == CadElementType.hatch) {
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

  bool _selectHit(CadElement el, Offset p) {
    if (el.type == CadElementType.block) {
      final rect = Rect.fromPoints(el.start, el.end);
      final ang = -(el.radius ?? 0.0) * math.pi / 180;
      final d = p - rect.center;
      final q = Offset(d.dx * math.cos(ang) - d.dy * math.sin(ang), d.dx * math.sin(ang) + d.dy * math.cos(ang));
      return Rect.fromCenter(center: Offset.zero, width: rect.width + 20, height: rect.height + 20).contains(q);
    }
    if (el.type == CadElementType.arc) {
      final r = (el.end - el.start).distance;
      if (((p - el.start).distance - r).abs() > 15) return false;
      final a0 = math.atan2(el.end.dy - el.start.dy, el.end.dx - el.start.dx);
      final ap = math.atan2(p.dy - el.start.dy, p.dx - el.start.dx);
      final sw = el.radius ?? 0.0;
      final rel = sw >= 0 ? (ap - a0) % (2 * math.pi) : -((a0 - ap) % (2 * math.pi));
      return sw >= 0 ? rel <= sw + 0.15 : rel >= sw - 0.15;
    }
    return el.boundingBox.inflate(15).contains(p);
  }

  // ---------- ARC (3 points: start, through, end) ----------
  void _arcAddPoint() {
    final pt = _currentCursor;
    if (pt == null) return;
    if (_arcPts.isNotEmpty && (pt - _arcPts.last).distance < 4) return;
    if (_arcPts.length < 2) {
      setState(() {
        _arcPts.add(pt);
        _commandPrompt = _arcPts.length == 1 ? 'ARC - tap a point the arc passes through' : 'ARC - tap the end point';
      });
      return;
    }
    final g = _arcGeometry(_arcPts[0], _arcPts[1], pt);
    if (g == null) {
      setState(() => _commandPrompt = 'ARC - points are in a straight line, pick another end point');
      return;
    }
    _saveStateForUndo();
    final first = _arcPts[0];
    setState(() {
      _elements.add(CadElement(
        id: 'el_${DateTime.now().microsecondsSinceEpoch}',
        type: CadElementType.arc,
        layerId: _activeLayerId,
        start: g.center,
        end: first,
        radius: g.sweep,
      ));
      _arcPts.clear();
      _commandPrompt = 'ARC - created. Tap 3 points for the next arc';
    });
  }

  // ---------- TRIM / EXTEND ----------
  double _distToSeg(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = math.max(0.0, math.min(1.0, ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2));
    return (p - (a + ab * t)).distance;
  }

  List<double>? _lineHit(Offset a, Offset b, Offset c, Offset d) {
    final r = b - a;
    final s = d - c;
    final den = r.dx * s.dy - r.dy * s.dx;
    if (den.abs() < 1e-9) return null;
    final qp = c - a;
    final t = (qp.dx * s.dy - qp.dy * s.dx) / den;
    final u = (qp.dx * r.dy - qp.dy * r.dx) / den;
    return [t, u];
  }

  List<List<Offset>> _cutEdges(String excludeId) {
    final segs = <List<Offset>>[];
    for (final e in _elements) {
      if (e.id == excludeId) continue;
      if (e.type == CadElementType.line || e.type == CadElementType.wall) {
        segs.add([e.start, e.end]);
      } else if (e.type == CadElementType.rectangle) {
        final r = Rect.fromPoints(e.start, e.end);
        segs.add([r.topLeft, r.topRight]);
        segs.add([r.topRight, r.bottomRight]);
        segs.add([r.bottomRight, r.bottomLeft]);
        segs.add([r.bottomLeft, r.topLeft]);
      }
    }
    return segs;
  }

  CadElement? _pickLineAt(Offset p, double maxDist) {
    CadElement? target;
    var best = maxDist;
    for (final e in _elements) {
      if (e.type != CadElementType.line && e.type != CadElementType.wall) continue;
      final dist = _distToSeg(p, e.start, e.end);
      if (dist < best) {
        best = dist;
        target = e;
      }
    }
    return target;
  }

  void _trimAt(Offset p) {
    final target = _pickLineAt(p, 14);
    if (target == null) {
      setState(() => _commandPrompt = 'TRIM - tap on a line or wall');
      return;
    }
    final a = target.start;
    final b = target.end;
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return;
    final tp = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    double? left;
    double? right;
    for (final seg in _cutEdges(target.id)) {
      final h = _lineHit(a, b, seg[0], seg[1]);
      if (h == null) continue;
      final t = h[0];
      final u = h[1];
      if (u < 0 || u > 1 || t <= 0.001 || t >= 0.999) continue;
      if (t < tp) {
        if (left == null || t > left) left = t;
      } else {
        if (right == null || t < right) right = t;
      }
    }
    if (left == null && right == null) {
      setState(() => _commandPrompt = 'TRIM - no other line crosses here');
      return;
    }
    final l = left;
    final r = right;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final keep = <CadElement>[];
    if (l != null) {
      keep.add(target.copyWith(id: 'el_${stamp}a', start: a, end: a + ab * l, isSelected: false));
    }
    if (r != null) {
      keep.add(target.copyWith(id: 'el_${stamp}b', start: a + ab * r, end: b, isSelected: false));
    }
    _saveStateForUndo();
    setState(() {
      _elements.removeWhere((e) => e.id == target.id);
      _elements.addAll(keep);
      _selectedElement = null;
      _commandPrompt = 'TRIM - done';
    });
  }

  void _extendAt(Offset p) {
    final target = _pickLineAt(p, 18);
    if (target == null) {
      setState(() => _commandPrompt = 'EXTEND - tap near the end of a line or wall');
      return;
    }
    final a = target.start;
    final b = target.end;
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return;
    final tp = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / len2;
    final forward = tp >= 0.5;
    double? bestT;
    for (final seg in _cutEdges(target.id)) {
      final h = _lineHit(a, b, seg[0], seg[1]);
      if (h == null) continue;
      final t = h[0];
      final u = h[1];
      if (u < 0 || u > 1) continue;
      if (forward) {
        if (t > 1.001 && (bestT == null || t < bestT)) bestT = t;
      } else {
        if (t < -0.001 && (bestT == null || t > bestT)) bestT = t;
      }
    }
    final nt = bestT;
    if (nt == null) {
      setState(() => _commandPrompt = 'EXTEND - no line found in that direction');
      return;
    }
    _saveStateForUndo();
    setState(() {
      if (forward) {
        target.end = a + ab * nt;
      } else {
        target.start = a + ab * nt;
      }
      _commandPrompt = 'EXTEND - done';
    });
  }

  // ---------- HATCH ----------
  void _hatchFinish(Offset start, Offset end) {
    var s = start;
    var e = end;
    if ((end - start).distance <= 8) {
      CadElement? room;
      var bestArea = double.infinity;
      for (final el in _elements) {
        if (el.type != CadElementType.rectangle) continue;
        final r = el.boundingBox;
        if (r.contains(start) && r.width * r.height < bestArea) {
          bestArea = r.width * r.height;
          room = el;
        }
      }
      if (room == null) {
        setState(() {
          _dragStart = null;
          _commandPrompt = 'HATCH - drag an area, or tap inside a room rectangle';
        });
        return;
      }
      s = room.start;
      e = room.end;
    }
    _saveStateForUndo();
    setState(() {
      _elements.add(CadElement(
        id: 'el_${DateTime.now().microsecondsSinceEpoch}',
        type: CadElementType.hatch,
        layerId: _activeLayerId,
        start: s,
        end: e,
        text: 'diag',
        radius: 10,
      ));
      _dragStart = null;
      _commandPrompt = 'HATCH - created. Select it and open Props to change pattern';
    });
  }

  // ---------- PROPERTIES PANEL ----------
  String _dimText(double distM) {
    final feet = distM * 3.28084;
    final feetInt = feet.floor();
    final inches = ((feet - feetInt) * 12).round();
    return "$feetInt'-$inches\" (${distM.toStringAsFixed(2)}m)";
  }

  double? _num(Map<String, String> v, String k) {
    return double.tryParse((v[k] ?? '').replaceAll(',', '.'));
  }

  void _showPropertiesDialog() {
    final el = _selectedElement;
    if (el == null) return;
    String f(double v) => v.toStringAsFixed(2);
    final keys = <String>[];
    final labels = <String, String>{};
    final ctrls = <String, TextEditingController>{};
    void add(String key, String label, String value) {
      keys.add(key);
      labels[key] = label;
      ctrls[key] = TextEditingController(text: value);
    }

    final t = el.type;
    if (t == CadElementType.line || t == CadElementType.wall || t == CadElementType.window || t == CadElementType.door || t == CadElementType.dimension) {
      final v = el.end - el.start;
      add('x', 'Start X (m)', f(el.start.dx / 20));
      add('y', 'Start Y (m)', f(el.start.dy / 20));
      add('len', 'Length (m)', f(v.distance / 20));
      add('ang', 'Angle (deg: 0 = right, 90 = down)', f(math.atan2(v.dy, v.dx) * 180 / math.pi));
    } else if (t == CadElementType.rectangle || t == CadElementType.column || t == CadElementType.hatch) {
      final r = Rect.fromPoints(el.start, el.end);
      add('x', 'X (m)', f(r.left / 20));
      add('y', 'Y (m)', f(r.top / 20));
      add('w', 'Width (m)', f(r.width / 20));
      add('h', 'Height (m)', f(r.height / 20));
      if (t == CadElementType.hatch) add('gap', 'Hatch spacing (m)', f((el.radius ?? 10) / 20));
    } else if (t == CadElementType.circle) {
      add('x', 'Center X (m)', f(el.start.dx / 20));
      add('y', 'Center Y (m)', f(el.start.dy / 20));
      add('r', 'Radius (m)', f((el.radius ?? (el.end - el.start).distance) / 20));
    } else if (t == CadElementType.arc) {
      add('x', 'Center X (m)', f(el.start.dx / 20));
      add('y', 'Center Y (m)', f(el.start.dy / 20));
      add('r', 'Radius (m)', f((el.end - el.start).distance / 20));
      add('sweep', 'Sweep (deg, + = clockwise)', f((el.radius ?? 0) * 180 / math.pi));
    } else if (t == CadElementType.block) {
      final r = Rect.fromPoints(el.start, el.end);
      add('x', 'Center X (m)', f(r.center.dx / 20));
      add('y', 'Center Y (m)', f(r.center.dy / 20));
      add('w', 'Width (m)', f(r.width / 20));
      add('h', 'Depth (m)', f(r.height / 20));
      add('rot', 'Rotation (deg, + = clockwise)', f(el.radius ?? 0));
    } else if (t == CadElementType.text) {
      add('txt', 'Text', el.text ?? '');
    }

    var layerId = el.layerId;
    var pattern = (el.text == 'cross' || el.text == 'solid') ? el.text! : 'diag';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF131C35),
          title: Text('PROPERTIES - ${t.name.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final k in keys)
                  TextField(
                    controller: ctrls[k],
                    keyboardType: k == 'txt' ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(labelText: labels[k], labelStyle: const TextStyle(color: Colors.grey)),
                  ),
                const SizedBox(height: 12),
                const Text('Layer', style: TextStyle(color: Colors.grey, fontSize: 12)),
                DropdownButton<String>(
                  value: _layers.any((l) => l.id == layerId) ? layerId : null,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF131C35),
                  style: const TextStyle(color: Colors.white),
                  items: [for (final l in _layers) DropdownMenuItem<String>(value: l.id, child: Text(l.name))],
                  onChanged: (v) {
                    if (v != null) setD(() => layerId = v);
                  },
                ),
                if (t == CadElementType.hatch) ...[
                  const SizedBox(height: 8),
                  const Text('Pattern', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  DropdownButton<String>(
                    value: pattern,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF131C35),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem<String>(value: 'diag', child: Text('Diagonal lines')),
                      DropdownMenuItem<String>(value: 'cross', child: Text('Cross hatch')),
                      DropdownMenuItem<String>(value: 'solid', child: Text('Solid fill')),
                    ],
                    onChanged: (v) {
                      if (v != null) setD(() => pattern = v);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final vals = <String, String>{for (final k in keys) k: ctrls[k]!.text.trim()};
                Navigator.pop(ctx);
                _applyProperties(el, vals, layerId, pattern);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyProperties(CadElement el, Map<String, String> v, String layerId, String pattern) {
    final t = el.type;
    var newStart = el.start;
    var newEnd = el.end;
    var newRadius = el.radius;
    var newText = el.text;
    var ok = true;

    if (t == CadElementType.line || t == CadElementType.wall || t == CadElementType.window || t == CadElementType.door || t == CadElementType.dimension) {
      final x = _num(v, 'x');
      final y = _num(v, 'y');
      final len = _num(v, 'len');
      final ang = _num(v, 'ang');
      if (x == null || y == null || len == null || ang == null || len <= 0) {
        ok = false;
      } else {
        newStart = Offset(x * 20, y * 20);
        final rad = ang * math.pi / 180;
        newEnd = newStart + Offset(math.cos(rad), math.sin(rad)) * (len * 20);
        if (t == CadElementType.dimension) newText = _dimText(len);
      }
    } else if (t == CadElementType.rectangle || t == CadElementType.column || t == CadElementType.hatch) {
      final x = _num(v, 'x');
      final y = _num(v, 'y');
      final w = _num(v, 'w');
      final h = _num(v, 'h');
      if (x == null || y == null || w == null || h == null || w <= 0 || h <= 0) {
        ok = false;
      } else {
        newStart = Offset(x * 20, y * 20);
        newEnd = Offset((x + w) * 20, (y + h) * 20);
        if (t == CadElementType.hatch) {
          final gap = _num(v, 'gap');
          if (gap != null && gap >= 0.15) newRadius = gap * 20;
          newText = pattern;
        }
      }
    } else if (t == CadElementType.circle) {
      final x = _num(v, 'x');
      final y = _num(v, 'y');
      final r = _num(v, 'r');
      if (x == null || y == null || r == null || r <= 0) {
        ok = false;
      } else {
        newStart = Offset(x * 20, y * 20);
        newRadius = r * 20;
        newEnd = newStart + Offset(r * 20, 0);
      }
    } else if (t == CadElementType.arc) {
      final x = _num(v, 'x');
      final y = _num(v, 'y');
      final r = _num(v, 'r');
      final sw = _num(v, 'sweep');
      if (x == null || y == null || r == null || sw == null || r <= 0) {
        ok = false;
      } else {
        final a0 = math.atan2(el.end.dy - el.start.dy, el.end.dx - el.start.dx);
        newStart = Offset(x * 20, y * 20);
        newEnd = newStart + Offset(math.cos(a0), math.sin(a0)) * (r * 20);
        newRadius = sw * math.pi / 180;
      }
    } else if (t == CadElementType.block) {
      final x = _num(v, 'x');
      final y = _num(v, 'y');
      final w = _num(v, 'w');
      final h = _num(v, 'h');
      final rot = _num(v, 'rot');
      if (x == null || y == null || w == null || h == null || rot == null || w <= 0 || h <= 0) {
        ok = false;
      } else {
        newStart = Offset((x - w / 2) * 20, (y - h / 2) * 20);
        newEnd = Offset((x + w / 2) * 20, (y + h / 2) * 20);
        newRadius = rot;
      }
    } else if (t == CadElementType.text) {
      newText = v['txt'] ?? el.text;
    }

    if (!ok) {
      setState(() => _commandPrompt = 'PROPERTIES - invalid value, nothing changed');
      return;
    }
    _saveStateForUndo();
    final updated = el.copyWith(layerId: layerId, start: newStart, end: newEnd, radius: newRadius, text: newText);
    setState(() {
      final i = _elements.indexWhere((e) => e.id == el.id);
      if (i >= 0) _elements[i] = updated;
      _selectedElement = updated;
      _commandPrompt = 'PROPERTIES - updated';
    });
  }

  // ---------- 2D BLOCK LIBRARY ----------
  void _startBlockPlacement(String key) {
    final def = _blockDefs[key];
    if (def == null) return;
    setState(() {
      _activeTool = CadTool.block;
      _pendingBlock = key;
      _selectedElement = null;
      _isPanMode = false;
      _polyFirst = null;
      _polyLast = null;
      _polyCount = 0;
      _dragStart = null;
      _arcPts.clear();
      _commandPrompt = 'BLOCK - ${def.name}: tap on the drawing to place it';
    });
  }

  void _placeBlock() {
    final key = _pendingBlock;
    final c = _currentCursor;
    if (key == null || c == null) return;
    final def = _blockDefs[key];
    if (def == null) return;
    final half = Offset(def.w * 20 / 2, def.h * 20 / 2);
    _saveStateForUndo();
    final el = CadElement(
      id: 'el_${DateTime.now().microsecondsSinceEpoch}',
      type: CadElementType.block,
      layerId: 'A_FURNITURE',
      start: c - half,
      end: c + half,
      text: key,
      radius: 0,
    );
    setState(() {
      _elements.add(el);
      _selectedElement = el;
      _activeTool = CadTool.select;
      _pendingBlock = null;
      _commandPrompt = 'BLOCK - ${def.name} placed. Drag to move, or use Rotate / Props';
    });
  }

  void _showBlockLibrary() {
    var cat = 'All';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final keys = _blockDefs.keys.where((k) => cat == 'All' || _blockDefs[k]!.category == cat).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.62,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text('2D BLOCK LIBRARY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final c in ['All', 'Furniture', 'Kitchen', 'Bath', 'Misc'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(c),
                            selected: cat == c,
                            onSelected: (_) => setS(() => cat = c),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    padding: const EdgeInsets.all(12),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                    children: [
                      for (final k in keys)
                        InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            _startBlockPlacement(k);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF131C35),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: CustomPaint(painter: _BlockThumbPainter(k), child: const SizedBox.expand()),
                                  ),
                                ),
                                Text(_blockDefs[k]!.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text('${_blockDefs[k]!.w} x ${_blockDefs[k]!.h} m', style: const TextStyle(color: Colors.grey, fontSize: 9)),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------- REAL EXPORT: DXF + PDF ----------
  List<_Prim> _buildPrims() {
    final out = <_Prim>[];
    double mx(double v) => v / 20.0;
    double my(double v) => -v / 20.0;
    void line(Offset a, Offset b, String ly) {
      out.add(_Prim(0, mx(a.dx), my(a.dy), mx(b.dx), my(b.dy), 0, 0, 0, '', ly));
    }
    void circle(Offset c, double r, String ly) {
      out.add(_Prim(1, mx(c.dx), my(c.dy), 0, 0, r / 20.0, 0, 0, '', ly));
    }
    void arc(Offset c, double r, double s, double e, String ly) {
      out.add(_Prim(2, mx(c.dx), my(c.dy), 0, 0, r / 20.0, s % 360.0, e % 360.0, '', ly));
    }
    void text(Offset p, String s, double h, String ly) {
      final parts = s.split('\n');
      for (int i = 0; i < parts.length; i++) {
        out.add(_Prim(3, mx(p.dx), my(p.dy + i * h * 28.0), 0, 0, h, 0, 0, parts[i], ly));
      }
    }
    void box(Rect r, String ly) {
      line(r.topLeft, r.topRight, ly);
      line(r.topRight, r.bottomRight, ly);
      line(r.bottomRight, r.bottomLeft, ly);
      line(r.bottomLeft, r.topLeft, ly);
    }

    for (final el in _elements) {
      final found = _layers.where((l) => l.id == el.layerId);
      if (found.isNotEmpty && !found.first.isVisible) continue;
      final ly = el.layerId;
      final t = el.type;
      final s = el.start;
      final e = el.end;
      final dir = e - s;
      final dist = dir.distance;
      if (t == CadElementType.line) {
        line(s, e, ly);
      } else if (t == CadElementType.wall) {
        if (dist > 0) {
          final nrm = Offset(-dir.dy, dir.dx) / dist * 5.0;
          line(s + nrm, e + nrm, ly);
          line(s - nrm, e - nrm, ly);
        }
      } else if (t == CadElementType.rectangle) {
        box(Rect.fromPoints(s, e), ly);
      } else if (t == CadElementType.column) {
        final r = Rect.fromPoints(s, e);
        box(r, ly);
        line(r.topLeft, r.bottomRight, ly);
        line(r.bottomLeft, r.topRight, ly);
      } else if (t == CadElementType.circle) {
        circle(s, el.radius ?? dist, ly);
      } else if (t == CadElementType.arc) {
        if (dist > 0) {
          final a0 = math.atan2(dir.dy, dir.dx) * 180 / math.pi;
          final sw = (el.radius ?? 0.0) * 180 / math.pi;
          if (sw >= 0) {
            arc(s, dist, -(a0 + sw), -a0, ly);
          } else {
            arc(s, dist, -a0, -(a0 + sw), ly);
          }
        }
      } else if (t == CadElementType.door) {
        line(s, e, ly);
        arc(s, dist, -90, 0, ly);
      } else if (t == CadElementType.window) {
        if (dist > 0) {
          final nrm = Offset(-dir.dy, dir.dx) / dist * 4.0;
          line(s + nrm, e + nrm, ly);
          line(s, e, ly);
          line(s - nrm, e - nrm, ly);
        }
      } else if (t == CadElementType.dimension) {
        line(s, e, ly);
        line(s - const Offset(5, 5), s + const Offset(5, 5), ly);
        line(e - const Offset(5, 5), e + const Offset(5, 5), ly);
        text(Offset((s.dx + e.dx) / 2, (s.dy + e.dy) / 2 - 12), el.text ?? '', 0.25, ly);
      } else if (t == CadElementType.text) {
        text(s + const Offset(0, 11), el.text ?? 'TEXT', 0.25, ly);
      } else if (t == CadElementType.hatch) {
        final r = Rect.fromPoints(s, e);
        box(r, ly);
        final pat = el.text ?? 'diag';
        var gap = el.radius ?? 10.0;
        if (gap < 3.0) gap = 3.0;
        if (pat == 'solid') gap = 4.0;
        final span = r.width + r.height;
        for (double d = 0; d <= span; d += gap) {
          final c1 = r.left + d + r.top;
          final lo = math.max(r.left, c1 - r.bottom);
          final hi = math.min(r.right, c1 - r.top);
          if (hi - lo > 0.5) line(Offset(lo, c1 - lo), Offset(hi, c1 - hi), ly);
        }
        if (pat == 'cross') {
          for (double d = 0; d <= span; d += gap) {
            final c2 = r.right - d - r.top;
            final lo = math.max(r.left, r.top + c2);
            final hi = math.min(r.right, r.bottom + c2);
            if (hi - lo > 0.5) line(Offset(lo, lo - c2), Offset(hi, hi - c2), ly);
          }
        }
      } else if (t == CadElementType.block) {
        final rect = Rect.fromPoints(s, e);
        final cc = rect.center;
        final ang = (el.radius ?? 0.0) * math.pi / 180;
        final ca = math.cos(ang);
        final sa = math.sin(ang);
        Offset tf(double x, double y) => Offset(cc.dx + x * ca - y * sa, cc.dy + x * sa + y * ca);
        final seg = _blockSegments(el.text ?? '', rect.width, rect.height);
        for (final q in seg.lines) {
          line(tf(q[0], q[1]), tf(q[2], q[3]), ly);
        }
        for (final q in seg.circles) {
          circle(tf(q[0], q[1]), q[2], ly);
        }
      }
    }
    return out;
  }

  int _aci(String id) {
    switch (id) {
      case '0_WALLS':
        return 2;
      case 'A_DOORS':
        return 4;
      case 'A_WINDOWS':
        return 5;
      case 'A_DIMS':
        return 3;
      case 'S_COLUMNS':
        return 1;
      case 'A_FURNITURE':
        return 30;
      default:
        return 7;
    }
  }

  String _asciiOnly(String s) {
    final sb = StringBuffer();
    for (final u in s.codeUnits) {
      if (u >= 32 && u <= 126) {
        sb.writeCharCode(u);
      } else if (u == 0xD7) {
        sb.write('x');
      } else if (u == 0xB0) {
        sb.write(' deg');
      } else if (u == 0xB2) {
        sb.write('2');
      } else if (u == 0xB7 || u == 0x2013 || u == 0x2014) {
        sb.write('-');
      } else if (u == 0x2018 || u == 0x2019) {
        sb.write("'");
      } else if (u == 0x201C || u == 0x201D) {
        sb.write('"');
      } else {
        sb.write('?');
      }
    }
    return sb.toString();
  }

  String _toDxf(List<_Prim> prims) {
    final b = StringBuffer();
    void g(int code, Object value) {
      b.write('$code\n$value\n');
    }
    String n(double v) => v.toStringAsFixed(4);

    g(0, 'SECTION');
    g(2, 'HEADER');
    g(9, r'$ACADVER');
    g(1, 'AC1009');
    g(0, 'ENDSEC');

    final layerSet = <String>{'0'};
    for (final p in prims) {
      layerSet.add(p.layer);
    }
    final names = layerSet.toList()..sort();
    g(0, 'SECTION');
    g(2, 'TABLES');
    g(0, 'TABLE');
    g(2, 'LTYPE');
    g(70, 1);
    g(0, 'LTYPE');
    g(2, 'CONTINUOUS');
    g(70, 0);
    g(3, 'Solid line');
    g(72, 65);
    g(73, 0);
    g(40, '0.0');
    g(0, 'ENDTAB');
    g(0, 'TABLE');
    g(2, 'LAYER');
    g(70, names.length);
    for (final name in names) {
      g(0, 'LAYER');
      g(2, name);
      g(70, 0);
      g(62, _aci(name));
      g(6, 'CONTINUOUS');
    }
    g(0, 'ENDTAB');
    g(0, 'ENDSEC');

    g(0, 'SECTION');
    g(2, 'ENTITIES');
    for (final p in prims) {
      if (p.kind == 0) {
        g(0, 'LINE');
        g(8, p.layer);
        g(10, n(p.x1));
        g(20, n(p.y1));
        g(30, '0.0');
        g(11, n(p.x2));
        g(21, n(p.y2));
        g(31, '0.0');
      } else if (p.kind == 1) {
        g(0, 'CIRCLE');
        g(8, p.layer);
        g(10, n(p.x1));
        g(20, n(p.y1));
        g(30, '0.0');
        g(40, n(p.r));
      } else if (p.kind == 2) {
        g(0, 'ARC');
        g(8, p.layer);
        g(10, n(p.x1));
        g(20, n(p.y1));
        g(30, '0.0');
        g(40, n(p.r));
        g(50, n(p.a0));
        g(51, n(p.a1));
      } else {
        g(0, 'TEXT');
        g(8, p.layer);
        g(10, n(p.x1));
        g(20, n(p.y1));
        g(30, '0.0');
        g(40, n(p.r));
        g(1, _asciiOnly(p.text));
      }
    }
    g(0, 'ENDSEC');
    g(0, 'EOF');
    return b.toString();
  }

  List<int> _toPdf(List<_Prim> prims, String title, DateTime now) {
    const pageW = 841.89;
    const pageH = 595.28;
    const mm = 72 / 25.4;
    var minx = double.infinity;
    var maxx = -double.infinity;
    var miny = double.infinity;
    var maxy = -double.infinity;
    void ext(double x, double y) {
      if (x < minx) minx = x;
      if (x > maxx) maxx = x;
      if (y < miny) miny = y;
      if (y > maxy) maxy = y;
    }
    for (final p in prims) {
      if (p.kind == 0) {
        ext(p.x1, p.y1);
        ext(p.x2, p.y2);
      } else if (p.kind == 3) {
        ext(p.x1, p.y1);
        ext(p.x1 + p.text.length * p.r * 0.6, p.y1 + p.r);
      } else {
        ext(p.x1 - p.r, p.y1 - p.r);
        ext(p.x1 + p.r, p.y1 + p.r);
      }
    }
    final dw = math.max(maxx - minx, 0.5);
    final dh = math.max(maxy - miny, 0.5);
    const availW = 277.0;
    const availH = 165.0;
    final need = math.max(dw * 1000 / availW, dh * 1000 / availH);
    const scales = [1, 2, 5, 10, 20, 25, 50, 75, 100, 125, 150, 200, 250, 300, 400, 500, 750, 1000, 2000, 5000];
    var n = 10000;
    for (final sc in scales) {
      if (sc >= need) {
        n = sc;
        break;
      }
    }
    final oxMm = 10 + (availW - dw * 1000 / n) / 2;
    final oyMm = 28 + (availH - dh * 1000 / n) / 2;
    double px(double xm) => (oxMm + (xm - minx) * 1000 / n) * mm;
    double py(double ym) => (oyMm + (ym - miny) * 1000 / n) * mm;
    String f(double v) => v.toStringAsFixed(2);

    String esc(String s) {
      final sb = StringBuffer();
      for (final u in s.codeUnits) {
        if (u < 32 || u > 126) {
          sb.write('?');
        } else if (u == 92 || u == 40 || u == 41) {
          sb.write('\\');
          sb.writeCharCode(u);
        } else {
          sb.writeCharCode(u);
        }
      }
      return sb.toString();
    }

    final c = StringBuffer();
    void txt(double x, double y, double size, String s) {
      c.write('BT /F1 ${f(size)} Tf ${f(x)} ${f(y)} Td (${esc(s)}) Tj ET\n');
    }

    c.write('0.25 w 0 G 0 g\n');
    c.write('${f(10 * mm)} ${f(10 * mm)} ${f(277 * mm)} ${f(190 * mm)} re S\n');
    c.write('${f(10 * mm)} ${f(10 * mm)} ${f(277 * mm)} ${f(18 * mm)} re S\n');
    String two(int v) => v.toString().padLeft(2, '0');
    final dateStr = '${now.year}-${two(now.month)}-${two(now.day)}';
    txt(14 * mm, 19 * mm, 12, title);
    txt(14 * mm, 13 * mm, 8, 'Scale 1:$n   |   Sheet A4   |   $dateStr   |   Architect Engine');

    for (final p in prims) {
      if (p.kind == 0) {
        c.write('${f(px(p.x1))} ${f(py(p.y1))} m ${f(px(p.x2))} ${f(py(p.y2))} l S\n');
      } else if (p.kind == 1) {
        final cx = px(p.x1);
        final cy = py(p.y1);
        final r = p.r * 1000 / n * mm;
        final k = 0.5523 * r;
        c.write('${f(cx + r)} ${f(cy)} m ${f(cx + r)} ${f(cy + k)} ${f(cx + k)} ${f(cy + r)} ${f(cx)} ${f(cy + r)} c ');
        c.write('${f(cx - k)} ${f(cy + r)} ${f(cx - r)} ${f(cy + k)} ${f(cx - r)} ${f(cy)} c ');
        c.write('${f(cx - r)} ${f(cy - k)} ${f(cx - k)} ${f(cy - r)} ${f(cx)} ${f(cy - r)} c ');
        c.write('${f(cx + k)} ${f(cy - r)} ${f(cx + r)} ${f(cy - k)} ${f(cx + r)} ${f(cy)} c S\n');
      } else if (p.kind == 2) {
        final cx = px(p.x1);
        final cy = py(p.y1);
        final r = p.r * 1000 / n * mm;
        final a0 = p.a0;
        var a1 = p.a1;
        if (a1 <= a0) a1 += 360;
        final steps = math.max(2, ((a1 - a0) / 5).floor() + 1);
        for (int i = 0; i <= steps; i++) {
          final a = (a0 + (a1 - a0) * i / steps) * math.pi / 180;
          c.write('${f(cx + r * math.cos(a))} ${f(cy + r * math.sin(a))} ${i == 0 ? 'm' : 'l'} ');
        }
        c.write('S\n');
      } else {
        final size = math.max(3.0, p.r * 1000 / n * mm);
        txt(px(p.x1), py(p.y1), size, _asciiOnly(p.text));
      }
    }

    final content = c.toString();
    final objs = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageW $pageH] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${content.length} >>\nstream\n${content}endstream',
    ];
    final out = StringBuffer('%PDF-1.4\n');
    final offs = <int>[];
    for (int i = 0; i < objs.length; i++) {
      offs.add(out.length);
      out.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
    }
    final xr = out.length;
    out.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
    for (final o in offs) {
      out.write('${o.toString().padLeft(10, '0')} 00000 n \n');
    }
    out.write('trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n$xr\n%%EOF\n');
    return conv.ascii.encode(out.toString());
  }

  Future<void> _exportDrawing({required bool dxf}) async {
    final prims = _buildPrims();
    if (prims.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to export yet - draw something first')));
      return;
    }
    try {
      final title = (widget.projectTitle ?? 'Drawing1').replaceAll(RegExp(r'\.dwg$', caseSensitive: false), '');
      final safe = title.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final stamp = '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
      final ext = dxf ? 'dxf' : 'pdf';
      final name = '${safe}_$stamp.$ext';
      final dir = await getTemporaryDirectory();
      final file = io.File('${dir.path}/$name');
      if (dxf) {
        await file.writeAsString(_toDxf(prims));
      } else {
        await file.writeAsBytes(_toPdf(prims, _asciiOnly(title), now));
      }
      await Share.shareXFiles([XFile(file.path)], text: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported $name')));
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $err')));
      }
    }
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
              title: const Text('AutoCAD DXF (.dxf)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Compatible with AutoCAD, Revit & SketchUp', style: TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                _exportDrawing(dxf: true);
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Text('📄', style: TextStyle(fontSize: 24)),
              title: const Text('Architectural Blueprint PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Vector print with scale & title block', style: TextStyle(fontSize: 11, color: Colors.grey)),
              onTap: () {
                Navigator.pop(ctx);
                _exportDrawing(dxf: false);
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
                  arcPoints: List<Offset>.from(_arcPts),
                  pendingBlock: _pendingBlock,
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
                    _buildToolIcon(CadTool.arc, Icons.rounded_corner, 'Arc (A)'),
                    _buildToolIcon(CadTool.trim, Icons.content_cut, 'Trim (TR)'),
                    _buildToolIcon(CadTool.extend, Icons.open_in_full, 'Extend (EX)'),
                    _buildToolIcon(CadTool.hatch, Icons.texture, 'Hatch (H)'),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: IconButton(
                        icon: const Icon(Icons.widgets_outlined, size: 22),
                        color: _activeTool == CadTool.block ? AppColors.darkPrimary : Colors.white70,
                        tooltip: 'Blocks (B)',
                        style: IconButton.styleFrom(
                          backgroundColor: _activeTool == CadTool.block ? AppColors.darkPrimary.withOpacity(0.2) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _showBlockLibrary,
                      ),
                    ),
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
          if (_activeTool == CadTool.block && _pendingBlock != null)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionChip(Icons.widgets_outlined, 'Library', _showBlockLibrary),
                  const SizedBox(width: 8),
                  _buildActionChip(Icons.close, 'Cancel', () {
                    setState(() {
                      _pendingBlock = null;
                      _activeTool = CadTool.select;
                      _commandPrompt = 'BLOCK - cancelled';
                    });
                  }),
                ],
              ),
            ),
          if (_activeTool == CadTool.arc && _arcPts.isNotEmpty)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildActionChip(Icons.close, 'Cancel arc', () {
                    setState(() {
                      _arcPts.clear();
                      _commandPrompt = 'ARC - cancelled';
                    });
                  }),
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
                    _buildActionChip(Icons.tune, 'Props', _showPropertiesDialog),
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
            _arcPts.clear();
            _pendingBlock = null;
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
  final List<Offset> arcPoints;
  final String? pendingBlock;

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
    required this.arcPoints,
    required this.pendingBlock,
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

    if (activeTool == CadTool.arc && arcPoints.isNotEmpty && currentCursor != null) {
      _drawArcPreview(canvas);
    }

    if (activeTool == CadTool.block && pendingBlock != null && currentCursor != null) {
      final def = _blockDefs[pendingBlock!];
      if (def != null) {
        canvas.save();
        canvas.translate(currentCursor!.dx, currentCursor!.dy);
        _paintBlockSymbol(canvas, pendingBlock!, Rect.fromCenter(center: Offset.zero, width: def.w * 20, height: def.h * 20), activeLayer.color.withOpacity(0.7), 1.5);
        canvas.restore();
      }
    }

    if (currentCursor != null) {
      _drawCrosshair(canvas, currentCursor!, size);
    }
  }

  void _drawArcPreview(Canvas canvas) {
    final p = Paint()..color = activeLayer.color.withOpacity(0.85)..strokeWidth = activeLayer.strokeWidth..style = PaintingStyle.stroke;
    final guide = Paint()..color = Colors.white38..strokeWidth = 1.0..style = PaintingStyle.stroke;
    final cur = currentCursor!;
    for (final pt in arcPoints) {
      canvas.drawCircle(pt, 4, guide);
    }
    if (arcPoints.length == 1) {
      canvas.drawLine(arcPoints[0], cur, guide);
    } else if (arcPoints.length >= 2) {
      final g = _arcGeometry(arcPoints[0], arcPoints[1], cur);
      if (g == null) {
        canvas.drawLine(arcPoints[0], arcPoints[1], guide);
        canvas.drawLine(arcPoints[1], cur, guide);
      } else {
        canvas.drawArc(Rect.fromCircle(center: g.center, radius: g.radius), g.startAngle, g.sweep, false, p);
      }
    }
  }

  void _drawHatch(Canvas canvas, CadElement el, Color color, bool isSelected) {
    final rect = Rect.fromPoints(el.start, el.end);
    if (rect.width < 2 || rect.height < 2) return;
    final c = isSelected ? const Color(0xFF38BDF8) : color;
    final pattern = el.text ?? 'diag';
    final rawGap = el.radius ?? 10.0;
    final gap = rawGap < 3.0 ? 3.0 : rawGap;
    canvas.save();
    canvas.clipRect(rect);
    if (pattern == 'solid') {
      canvas.drawRect(rect, Paint()..color = c.withOpacity(0.35)..style = PaintingStyle.fill);
    } else {
      final hp = Paint()..color = c.withOpacity(0.8)..strokeWidth = 1.0..style = PaintingStyle.stroke;
      final span = rect.width + rect.height;
      for (double d = 0; d <= span; d += gap) {
        canvas.drawLine(Offset(rect.left + d, rect.top), Offset(rect.left + d - rect.height, rect.bottom), hp);
      }
      if (pattern == 'cross') {
        for (double d = 0; d <= span; d += gap) {
          canvas.drawLine(Offset(rect.right - d, rect.top), Offset(rect.right - d + rect.height, rect.bottom), hp);
        }
      }
    }
    canvas.restore();
    canvas.drawRect(rect, Paint()..color = c.withOpacity(0.6)..strokeWidth = 1.0..style = PaintingStyle.stroke);
  }

  void _drawBlock(Canvas canvas, CadElement el, Color color, double strokeWidth) {
    final rect = Rect.fromPoints(el.start, el.end);
    final c = rect.center;
    final ang = (el.radius ?? 0.0) * math.pi / 180;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(ang);
    _paintBlockSymbol(canvas, el.text ?? '', Rect.fromCenter(center: Offset.zero, width: rect.width, height: rect.height), color, strokeWidth);
    canvas.restore();
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
      case CadElementType.arc:
        final arcR = (el.end - el.start).distance;
        if (arcR > 0) {
          final a0 = math.atan2(el.end.dy - el.start.dy, el.end.dx - el.start.dx);
          canvas.drawArc(Rect.fromCircle(center: el.start, radius: arcR), a0, el.radius ?? 0, false, paint);
        }
        break;
      case CadElementType.hatch:
        _drawHatch(canvas, el, color, isSelected);
        break;
      case CadElementType.block:
        _drawBlock(canvas, el, paint.color, strokeWidth);
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

    if (isSelected && el.type != CadElementType.block) {
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
      case CadTool.hatch:
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

class _ArcGeom {
  final Offset center;
  final double radius;
  final double startAngle;
  final double sweep;
  _ArcGeom(this.center, this.radius, this.startAngle, this.sweep);
}

_ArcGeom? _arcGeometry(Offset a, Offset b, Offset c) {
  final d = 2 * (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy));
  if (d.abs() < 1e-6) return null;
  final sa = a.dx * a.dx + a.dy * a.dy;
  final sb = b.dx * b.dx + b.dy * b.dy;
  final sc = c.dx * c.dx + c.dy * c.dy;
  final ux = (sa * (b.dy - c.dy) + sb * (c.dy - a.dy) + sc * (a.dy - b.dy)) / d;
  final uy = (sa * (c.dx - b.dx) + sb * (a.dx - c.dx) + sc * (b.dx - a.dx)) / d;
  final center = Offset(ux, uy);
  final r = (a - center).distance;
  if (r > 5000) return null;
  final a0 = math.atan2(a.dy - center.dy, a.dx - center.dx);
  final a1 = math.atan2(c.dy - center.dy, c.dx - center.dx);
  final cross = (b.dx - a.dx) * (c.dy - b.dy) - (b.dy - a.dy) * (c.dx - b.dx);
  const full = 2 * math.pi;
  final sweep = cross > 0 ? (a1 - a0) % full : -((a0 - a1) % full);
  return _ArcGeom(center, r, a0, sweep);
}

class _BlockDef {
  final String name;
  final String category;
  final double w;
  final double h;
  const _BlockDef(this.name, this.category, this.w, this.h);
}

const Map<String, _BlockDef> _blockDefs = {
  'bed_double': _BlockDef('Bed - Double', 'Furniture', 1.8, 2.0),
  'bed_single': _BlockDef('Bed - Single', 'Furniture', 0.9, 2.0),
  'sofa_3': _BlockDef('Sofa - 3 Seater', 'Furniture', 2.1, 0.9),
  'armchair': _BlockDef('Armchair', 'Furniture', 0.9, 0.9),
  'dining_6': _BlockDef('Dining Table (6)', 'Furniture', 2.2, 1.6),
  'round_table': _BlockDef('Round Table (4)', 'Furniture', 1.4, 1.4),
  'chair': _BlockDef('Chair', 'Furniture', 0.5, 0.5),
  'wardrobe': _BlockDef('Wardrobe', 'Furniture', 1.8, 0.6),
  'tv_unit': _BlockDef('TV Unit', 'Furniture', 1.5, 0.45),
  'kitchen_counter': _BlockDef('Kitchen Counter', 'Kitchen', 2.4, 0.6),
  'sink': _BlockDef('Kitchen Sink', 'Kitchen', 0.9, 0.5),
  'fridge': _BlockDef('Refrigerator', 'Kitchen', 0.7, 0.7),
  'wc': _BlockDef('WC / Commode', 'Bath', 0.4, 0.7),
  'wash_basin': _BlockDef('Wash Basin', 'Bath', 0.55, 0.45),
  'bathtub': _BlockDef('Bathtub', 'Bath', 1.7, 0.75),
  'shower': _BlockDef('Shower Tray', 'Bath', 0.9, 0.9),
  'stairs': _BlockDef('Staircase', 'Misc', 1.0, 3.0),
  'plant': _BlockDef('Plant', 'Misc', 0.5, 0.5),
};

void _paintBlockSymbol(Canvas canvas, String key, Rect r, Color color, double stroke) {
  final p = Paint()
    ..color = color
    ..strokeWidth = stroke
    ..style = PaintingStyle.stroke;
  final t = Paint()
    ..color = color
    ..strokeWidth = stroke * 0.55
    ..style = PaintingStyle.stroke;
  final w = r.width;
  final h = r.height;
  final l = r.left;
  final top = r.top;
  final rt = r.right;
  final bt = r.bottom;
  switch (key) {
    case 'bed_double':
    case 'bed_single':
      canvas.drawRect(r, p);
      final pad = w * 0.06;
      final pillowH = h * 0.14;
      if (key == 'bed_double') {
        final pw = (w - pad * 3) / 2;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + pad, top + pad, pw, pillowH), const Radius.circular(3)), t);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + pad * 2 + pw, top + pad, pw, pillowH), const Radius.circular(3)), t);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + pad, top + pad, w - pad * 2, pillowH), const Radius.circular(3)), t);
      }
      canvas.drawLine(Offset(l, top + h * 0.30), Offset(rt, top + h * 0.30), t);
      break;
    case 'sofa_3':
    case 'armchair':
      canvas.drawRect(r, p);
      final back = h * 0.28;
      final arm = w * (key == 'sofa_3' ? 0.09 : 0.18);
      canvas.drawLine(Offset(l, top + back), Offset(rt, top + back), t);
      canvas.drawLine(Offset(l + arm, top + back), Offset(l + arm, bt), t);
      canvas.drawLine(Offset(rt - arm, top + back), Offset(rt - arm, bt), t);
      if (key == 'sofa_3') {
        final seatW = (w - arm * 2) / 3;
        canvas.drawLine(Offset(l + arm + seatW, top + back), Offset(l + arm + seatW, bt), t);
        canvas.drawLine(Offset(l + arm + seatW * 2, top + back), Offset(l + arm + seatW * 2, bt), t);
      }
      break;
    case 'dining_6':
      canvas.drawRect(Rect.fromLTRB(l + w * 0.06, top + h * 0.27, rt - w * 0.06, bt - h * 0.27), p);
      for (final f in [0.25, 0.5, 0.75]) {
        final cx = l + w * f;
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, top + h * 0.12), width: w * 0.16, height: h * 0.2), t);
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, bt - h * 0.12), width: w * 0.16, height: h * 0.2), t);
      }
      break;
    case 'round_table':
      canvas.drawCircle(r.center, w * 0.28, p);
      final cs = w * 0.16;
      canvas.drawRect(Rect.fromCenter(center: Offset(r.center.dx, top + cs * 0.6), width: cs, height: cs * 0.8), t);
      canvas.drawRect(Rect.fromCenter(center: Offset(r.center.dx, bt - cs * 0.6), width: cs, height: cs * 0.8), t);
      canvas.drawRect(Rect.fromCenter(center: Offset(l + cs * 0.6, r.center.dy), width: cs * 0.8, height: cs), t);
      canvas.drawRect(Rect.fromCenter(center: Offset(rt - cs * 0.6, r.center.dy), width: cs * 0.8, height: cs), t);
      break;
    case 'chair':
      canvas.drawRect(r, p);
      canvas.drawLine(Offset(l, top + h * 0.22), Offset(rt, top + h * 0.22), t);
      break;
    case 'wardrobe':
      canvas.drawRect(r, p);
      canvas.drawLine(Offset(r.center.dx, top), Offset(r.center.dx, bt), t);
      canvas.drawLine(Offset(l, top + h * 0.2), Offset(rt, top + h * 0.2), t);
      break;
    case 'tv_unit':
      canvas.drawRect(r, p);
      canvas.drawRect(Rect.fromLTWH(l + w * 0.2, top + h * 0.2, w * 0.6, h * 0.3), t);
      break;
    case 'kitchen_counter':
      canvas.drawRect(r, p);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + w * 0.08, top + h * 0.18, w * 0.22, h * 0.64), const Radius.circular(3)), t);
      canvas.drawCircle(Offset(l + w * 0.19, top + h * 0.5), h * 0.07, t);
      for (final cx in [0.66, 0.84]) {
        for (final cy in [0.3, 0.7]) {
          canvas.drawCircle(Offset(l + w * cx, top + h * cy), h * 0.12, t);
        }
      }
      break;
    case 'sink':
      canvas.drawRect(r, p);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + w * 0.08, top + h * 0.15, w * 0.38, h * 0.7), const Radius.circular(3)), t);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + w * 0.54, top + h * 0.15, w * 0.38, h * 0.7), const Radius.circular(3)), t);
      break;
    case 'fridge':
      canvas.drawRect(r, p);
      canvas.drawRect(Rect.fromLTRB(l + w * 0.12, top + h * 0.12, rt - w * 0.12, bt - h * 0.12), t);
      canvas.drawLine(Offset(l + w * 0.12, top + h * 0.38), Offset(rt - w * 0.12, top + h * 0.38), t);
      break;
    case 'wc':
      canvas.drawRect(Rect.fromLTWH(l + w * 0.1, top, w * 0.8, h * 0.25), p);
      canvas.drawOval(Rect.fromLTWH(l, top + h * 0.22, w, h * 0.78), p);
      canvas.drawOval(Rect.fromLTWH(l + w * 0.15, top + h * 0.34, w * 0.7, h * 0.54), t);
      break;
    case 'wash_basin':
      canvas.drawRect(r, p);
      canvas.drawOval(Rect.fromLTWH(l + w * 0.12, top + h * 0.18, w * 0.76, h * 0.64), t);
      canvas.drawCircle(r.center, h * 0.06, t);
      break;
    case 'bathtub':
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), p);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(l + w * 0.05, top + h * 0.12, rt - w * 0.05, bt - h * 0.12), const Radius.circular(8)), t);
      canvas.drawCircle(Offset(l + w * 0.1, r.center.dy), h * 0.06, t);
      break;
    case 'shower':
      canvas.drawRect(r, p);
      canvas.drawLine(r.topLeft, r.bottomRight, t);
      canvas.drawCircle(r.center, w * 0.07, t);
      break;
    case 'stairs':
      canvas.drawRect(r, p);
      for (int i = 1; i < 12; i++) {
        final y = top + h * i / 12;
        canvas.drawLine(Offset(l, y), Offset(rt, y), t);
      }
      final ax = r.center.dx;
      canvas.drawLine(Offset(ax, bt - h * 0.06), Offset(ax, top + h * 0.08), p);
      canvas.drawLine(Offset(ax, top + h * 0.08), Offset(ax - w * 0.14, top + h * 0.16), p);
      canvas.drawLine(Offset(ax, top + h * 0.08), Offset(ax + w * 0.14, top + h * 0.16), p);
      break;
    case 'plant':
      canvas.drawCircle(r.center, w * 0.5, p);
      canvas.drawCircle(Offset(r.center.dx - w * 0.14, r.center.dy), w * 0.2, t);
      canvas.drawCircle(Offset(r.center.dx + w * 0.14, r.center.dy), w * 0.2, t);
      canvas.drawCircle(Offset(r.center.dx, r.center.dy - w * 0.14), w * 0.2, t);
      break;
    default:
      canvas.drawRect(r, p);
      canvas.drawLine(r.topLeft, r.bottomRight, t);
      canvas.drawLine(r.bottomLeft, r.topRight, t);
  }
}

class _BlockThumbPainter extends CustomPainter {
  final String keyName;
  _BlockThumbPainter(this.keyName);

  @override
  void paint(Canvas canvas, Size size) {
    final def = _blockDefs[keyName];
    if (def == null) return;
    final bw = def.w * 20;
    final bh = def.h * 20;
    final s = math.min((size.width - 8) / bw, (size.height - 8) / bh);
    if (s <= 0) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(s);
    _paintBlockSymbol(canvas, keyName, Rect.fromCenter(center: Offset.zero, width: bw, height: bh), Colors.white70, 1.6 / s);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Prim {
  final int kind;
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double r;
  final double a0;
  final double a1;
  final String text;
  final String layer;
  const _Prim(this.kind, this.x1, this.y1, this.x2, this.y2, this.r, this.a0, this.a1, this.text, this.layer);
}

class _Seg {
  final List<List<double>> lines = [];
  final List<List<double>> circles = [];
}

_Seg _blockSegments(String key, double w, double h) {
  final s = _Seg();
  final l = -w / 2;
  final top = -h / 2;
  final rt = w / 2;
  final bt = h / 2;
  void ln(double a, double b, double c, double d) {
    s.lines.add([a, b, c, d]);
  }
  void rc(double a, double b, double c, double d) {
    ln(a, b, c, b);
    ln(c, b, c, d);
    ln(c, d, a, d);
    ln(a, d, a, b);
  }
  void ci(double x, double y, double r) {
    s.circles.add([x, y, r]);
  }
  void ov(double a, double b, double c, double d) {
    final cx = (a + c) / 2;
    final cy = (b + d) / 2;
    final rx = (c - a) / 2;
    final ry = (d - b) / 2;
    for (int i = 0; i < 24; i++) {
      final t0 = 2 * math.pi * i / 24;
      final t1 = 2 * math.pi * (i + 1) / 24;
      ln(cx + rx * math.cos(t0), cy + ry * math.sin(t0), cx + rx * math.cos(t1), cy + ry * math.sin(t1));
    }
  }

  switch (key) {
    case 'bed_double':
    case 'bed_single':
      rc(l, top, rt, bt);
      final pad = w * 0.06;
      final ph = h * 0.14;
      if (key == 'bed_double') {
        final pw = (w - pad * 3) / 2;
        rc(l + pad, top + pad, l + pad + pw, top + pad + ph);
        rc(l + pad * 2 + pw, top + pad, l + pad * 2 + pw + pw, top + pad + ph);
      } else {
        rc(l + pad, top + pad, rt - pad, top + pad + ph);
      }
      ln(l, top + h * 0.30, rt, top + h * 0.30);
      break;
    case 'sofa_3':
    case 'armchair':
      rc(l, top, rt, bt);
      final back = h * 0.28;
      final arm = w * (key == 'sofa_3' ? 0.09 : 0.18);
      ln(l, top + back, rt, top + back);
      ln(l + arm, top + back, l + arm, bt);
      ln(rt - arm, top + back, rt - arm, bt);
      if (key == 'sofa_3') {
        final seatW = (w - arm * 2) / 3;
        ln(l + arm + seatW, top + back, l + arm + seatW, bt);
        ln(l + arm + seatW * 2, top + back, l + arm + seatW * 2, bt);
      }
      break;
    case 'dining_6':
      rc(l + w * 0.06, top + h * 0.27, rt - w * 0.06, bt - h * 0.27);
      for (final f in [0.25, 0.5, 0.75]) {
        final cx = l + w * f;
        rc(cx - w * 0.08, top + h * 0.02, cx + w * 0.08, top + h * 0.22);
        rc(cx - w * 0.08, bt - h * 0.22, cx + w * 0.08, bt - h * 0.02);
      }
      break;
    case 'round_table':
      ci(0, 0, w * 0.28);
      final cs = w * 0.16;
      rc(-cs / 2, top + cs * 0.2, cs / 2, top + cs * 1.0);
      rc(-cs / 2, bt - cs * 1.0, cs / 2, bt - cs * 0.2);
      rc(l + cs * 0.2, -cs / 2, l + cs * 1.0, cs / 2);
      rc(rt - cs * 1.0, -cs / 2, rt - cs * 0.2, cs / 2);
      break;
    case 'chair':
      rc(l, top, rt, bt);
      ln(l, top + h * 0.22, rt, top + h * 0.22);
      break;
    case 'wardrobe':
      rc(l, top, rt, bt);
      ln(0, top, 0, bt);
      ln(l, top + h * 0.2, rt, top + h * 0.2);
      break;
    case 'tv_unit':
      rc(l, top, rt, bt);
      rc(l + w * 0.2, top + h * 0.2, l + w * 0.8, top + h * 0.5);
      break;
    case 'kitchen_counter':
      rc(l, top, rt, bt);
      rc(l + w * 0.08, top + h * 0.18, l + w * 0.30, top + h * 0.82);
      ci(l + w * 0.19, top + h * 0.5, h * 0.07);
      for (final cx in [0.66, 0.84]) {
        for (final cy in [0.3, 0.7]) {
          ci(l + w * cx, top + h * cy, h * 0.12);
        }
      }
      break;
    case 'sink':
      rc(l, top, rt, bt);
      rc(l + w * 0.08, top + h * 0.15, l + w * 0.46, top + h * 0.85);
      rc(l + w * 0.54, top + h * 0.15, l + w * 0.92, top + h * 0.85);
      break;
    case 'fridge':
      rc(l, top, rt, bt);
      rc(l + w * 0.12, top + h * 0.12, rt - w * 0.12, bt - h * 0.12);
      ln(l + w * 0.12, top + h * 0.38, rt - w * 0.12, top + h * 0.38);
      break;
    case 'wc':
      rc(l + w * 0.1, top, l + w * 0.9, top + h * 0.25);
      ov(l, top + h * 0.22, rt, bt);
      ov(l + w * 0.15, top + h * 0.34, l + w * 0.85, top + h * 0.88);
      break;
    case 'wash_basin':
      rc(l, top, rt, bt);
      ov(l + w * 0.12, top + h * 0.18, l + w * 0.88, top + h * 0.82);
      ci(0, 0, h * 0.06);
      break;
    case 'bathtub':
      rc(l, top, rt, bt);
      rc(l + w * 0.05, top + h * 0.12, rt - w * 0.05, bt - h * 0.12);
      ci(l + w * 0.1, 0, h * 0.06);
      break;
    case 'shower':
      rc(l, top, rt, bt);
      ln(l, top, rt, bt);
      ci(0, 0, w * 0.07);
      break;
    case 'stairs':
      rc(l, top, rt, bt);
      for (int i = 1; i < 12; i++) {
        final y = top + h * i / 12;
        ln(l, y, rt, y);
      }
      ln(0, bt - h * 0.06, 0, top + h * 0.08);
      ln(0, top + h * 0.08, -w * 0.14, top + h * 0.16);
      ln(0, top + h * 0.08, w * 0.14, top + h * 0.16);
      break;
    case 'plant':
      ci(0, 0, w * 0.5);
      ci(-w * 0.14, 0, w * 0.2);
      ci(w * 0.14, 0, w * 0.2);
      ci(0, -w * 0.14, w * 0.2);
      break;
    default:
      rc(l, top, rt, bt);
      ln(l, top, rt, bt);
      ln(l, bt, rt, top);
  }
  return s;
}
