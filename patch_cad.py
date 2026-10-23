import sys

def edit(path, pairs):
    s = open(path, encoding='utf-8').read()
    for i, (old, new) in enumerate(pairs, 1):
        c = s.count(old)
        if c != 1:
            print(f"STOP: {path} edit #{i} anchor found {c} times (need 1). Nothing saved.")
            sys.exit(1)
        s = s.replace(old, new, 1)
    open(path, 'w', encoding='utf-8').write(s)
    print(f"OK: {path} ({len(pairs)} edits)")

# ---------- models: add polyline tool ----------
edit('lib/models/cad_models.dart', [
    ("  column,\n  eraser,\n}", "  column,\n  eraser,\n  polyline,\n}"),
])

# ---------- editor ----------
NEW_METHODS = r'''  Offset _centerOf(CadElement el) {
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

'''

BARS = r'''          if (_activeTool == CadTool.polyline && _polyLast != null)
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

'''

P = 'lib/screens/cad_editor_screen.dart'
edit(P, [
    # state
    ("  String _commandPrompt = 'Command: WALL - Tap or drag to draw architectural wall';\n",
     "  String _commandPrompt = 'Command: WALL - Tap or drag to draw architectural wall';\n"
     "  Offset? _polyFirst;\n  Offset? _polyLast;\n  int _polyCount = 0;\n"
     "  Offset? _moveLast;\n  bool _moveUndoSaved = false;\n"),
    # select: start of drag-move (fixes null crash)
    ("          _elementDragOffset = snapped - hit.start;\n",
     "          _elementDragOffset = snapped - hit.start;\n          _moveLast = snapped;\n          _moveUndoSaved = false;\n"),
    ("          _commandPrompt = 'Command: SELECT - Tap an object to select';\n",
     "          _moveLast = null;\n          _commandPrompt = 'Command: SELECT - Tap an object to select';\n"),
    # pointer down: polyline branch before the generic drawing start
    ("    setState(() {\n      _dragStart = snapped;\n      _currentCursor = snapped;\n      _commandPrompt = 'Specify next point or angle...';\n    });\n  }\n",
     "    if (_activeTool == CadTool.polyline) {\n      setState(() {\n        _currentCursor = snapped;\n        _commandPrompt = _polyLast == null ? 'PLINE - Specify start point' : 'PLINE - Specify next point (Done / Close below)';\n      });\n      return;\n    }\n\n"
     "    setState(() {\n      _dragStart = snapped;\n      _currentCursor = snapped;\n      _commandPrompt = 'Specify next point or angle...';\n    });\n  }\n"),
    # pointer move: working drag-move with undo
    ("      if (_selectedElement != null && _elementDragOffset != null && _activeTool == CadTool.select) {\n        final delta = snapped - _dragStart!;\n        _selectedElement!.start += delta;\n        _selectedElement!.end += delta;\n        _dragStart = snapped;\n      }\n",
     "      if (_selectedElement != null && _moveLast != null && _activeTool == CadTool.select) {\n        if (!_moveUndoSaved) {\n          _saveStateForUndo();\n          _moveUndoSaved = true;\n        }\n        final delta = snapped - _moveLast!;\n        _selectedElement!.start += delta;\n        _selectedElement!.end += delta;\n        _moveLast = snapped;\n      }\n"),
    # pointer up
    ("  void _onPointerUp(PointerUpEvent details) {\n    if (_isPanMode) return;\n",
     "  void _onPointerUp(PointerUpEvent details) {\n    if (_isPanMode) return;\n    _moveLast = null;\n    if (_activeTool == CadTool.polyline) {\n      _polyAddPoint();\n      return;\n    }\n"),
    # new methods
    ("  void _showTextInputDialog(Offset position) {\n", NEW_METHODS + "  void _showTextInputDialog(Offset position) {\n"),
    # toolbar button
    ("                    _buildToolIcon(CadTool.line, Icons.horizontal_rule, 'Line (L)'),\n",
     "                    _buildToolIcon(CadTool.line, Icons.horizontal_rule, 'Line (L)'),\n                    _buildToolIcon(CadTool.polyline, Icons.timeline, 'Polyline (PL)'),\n"),
    # reset polyline when switching tool
    ("            _activeTool = tool;\n            _isPanMode = false;\n            _selectedElement = null;\n",
     "            _activeTool = tool;\n            _isPanMode = false;\n            _selectedElement = null;\n            _polyFirst = null;\n            _polyLast = null;\n            _polyCount = 0;\n            _dragStart = null;\n"),
    # bars above the command bar
    ("          // Bottom Command Bar\n", BARS + "          // Bottom Command Bar\n"),
])
