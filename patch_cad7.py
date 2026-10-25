import sys

files = {}

def load(p):
    if p not in files:
        files[p] = open(p, encoding='utf-8').read()

def edit(path, pairs):
    load(path)
    s = files[path]
    for i, (old, new) in enumerate(pairs, 1):
        c = s.count(old)
        if c != 1:
            print(f"STOP: {path} edit #{i} anchor found {c} times (need 1). Nothing saved.")
            print("First line of the anchor:", old.split('\n')[0][:90])
            sys.exit(1)
        s = s.replace(old, new, 1)
    files[path] = s

# =====================================================================
# New methods inside the editor state class
# =====================================================================
METHODS = r'''  // ---------- AUTO-SAVE / REOPEN ----------
  String _storageKey() {
    final raw = widget.projectTitle ?? 'Drawing1';
    return 'cad_drawing_${raw.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')}';
  }

  Map<String, dynamic> _elToJson(CadElement e) {
    final m = <String, dynamic>{
      'id': e.id,
      't': e.type.name,
      'l': e.layerId,
      'sx': e.start.dx,
      'sy': e.start.dy,
      'ex': e.end.dx,
      'ey': e.end.dy,
    };
    if (e.radius != null) m['r'] = e.radius;
    if (e.text != null) m['x'] = e.text;
    if (e.customStrokeWidth != null) m['cw'] = e.customStrokeWidth;
    return m;
  }

  CadElement? _elFromJson(Map<String, dynamic> m) {
    final typeName = m['t'];
    CadElementType? type;
    for (final v in CadElementType.values) {
      if (v.name == typeName) type = v;
    }
    if (type == null) return null;
    final sx = m['sx'];
    final sy = m['sy'];
    final ex = m['ex'];
    final ey = m['ey'];
    final id = m['id'];
    final layer = m['l'];
    if (sx is! num || sy is! num || ex is! num || ey is! num || id is! String || layer is! String) return null;
    final r = m['r'];
    final x = m['x'];
    final cw = m['cw'];
    return CadElement(
      id: id,
      type: type,
      layerId: layer,
      start: Offset(sx.toDouble(), sy.toDouble()),
      end: Offset(ex.toDouble(), ey.toDouble()),
      radius: r is num ? r.toDouble() : null,
      text: x is String ? x : null,
      customStrokeWidth: cw is num ? cw.toDouble() : null,
    );
  }

  Map<String, dynamic> _serialize() {
    return <String, dynamic>{
      'v': 1,
      'elements': _elements.map(_elToJson).toList(),
      'hidden': _layers.where((l) => !l.isVisible).map((l) => l.id).toList(),
      'locked': _layers.where((l) => l.isLocked).map((l) => l.id).toList(),
    };
  }

  Future<void> _autoSave() async {
    if (!_loaded) return;
    try {
      final json = conv.jsonEncode(_serialize());
      if (json == _lastSavedJson) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey(), json);
      _lastSavedJson = json;
    } catch (_) {}
  }

  Future<void> _loadSaved() async {
    var restored = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey());
      if (raw != null && raw.isNotEmpty && mounted) {
        final data = conv.jsonDecode(raw);
        if (data is Map<String, dynamic>) {
          final list = data['elements'];
          if (list is List) {
            final loaded = <CadElement>[];
            for (final m in list) {
              if (m is Map<String, dynamic>) {
                final el = _elFromJson(m);
                if (el != null) loaded.add(el);
              }
            }
            final hidden = data['hidden'];
            final locked = data['locked'];
            setState(() {
              _elements = loaded;
              for (final l in _layers) {
                l.isVisible = !(hidden is List && hidden.contains(l.id));
                l.isLocked = locked is List && locked.contains(l.id);
              }
              _undoStack.clear();
              _redoStack.clear();
              _selectedElement = null;
            });
            _lastSavedJson = raw;
            restored = true;
          }
        }
      }
    } catch (_) {}
    _loaded = true;
    if (restored && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved drawing restored'), duration: Duration(seconds: 2)));
    }
  }

  // ---------- MORE SNAPS: CENTER / INTERSECTION / PERPENDICULAR ----------
  SnapPoint? _extraSnap(Offset p, double th) {
    for (final el in _elements) {
      if ((el.type == CadElementType.circle || el.type == CadElementType.arc) && (el.start - p).distance < th) {
        return SnapPoint(point: el.start, label: 'CENTER', color: const Color(0xFFF59E0B));
      }
    }
    final near = <List<Offset>>[];
    for (final s in _cutEdges('')) {
      if (_distToSeg(p, s[0], s[1]) < th * 2) near.add(s);
      if (near.length >= 14) break;
    }
    for (int i = 0; i < near.length; i++) {
      for (int j = i + 1; j < near.length; j++) {
        final h = _lineHit(near[i][0], near[i][1], near[j][0], near[j][1]);
        if (h == null) continue;
        if (h[0] < 0 || h[0] > 1 || h[1] < 0 || h[1] > 1) continue;
        final ip = near[i][0] + (near[i][1] - near[i][0]) * h[0];
        if ((ip - p).distance < th) {
          return SnapPoint(point: ip, label: 'INTERSECTION', color: const Color(0xFFEF4444));
        }
      }
    }
    final base = _dragStart ?? _polyLast;
    if (base != null) {
      for (final s in near) {
        final ab = s[1] - s[0];
        final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
        if (len2 == 0) continue;
        final t = ((base.dx - s[0].dx) * ab.dx + (base.dy - s[0].dy) * ab.dy) / len2;
        if (t <= 0 || t >= 1) continue;
        final foot = s[0] + ab * t;
        if ((foot - p).distance < th) {
          return SnapPoint(point: foot, label: 'PERPENDICULAR', color: const Color(0xFFA855F7));
        }
      }
    }
    return null;
  }

  // ---------- TYPE-IN (exact length / angle) ----------
  void _showTypeInDialog() {
    final tool = _activeTool;
    final base = _polyLast ?? _lastPoint ?? _currentCursor ?? Offset.zero;
    String f(double v) => v.toStringAsFixed(2);
    final keys = <String>[];
    final labels = <String, String>{};
    final ctrls = <String, TextEditingController>{};
    void add(String key, String label, String value) {
      keys.add(key);
      labels[key] = label;
      ctrls[key] = TextEditingController(text: value);
    }

    if (tool == CadTool.rectangle) {
      add('x', 'Corner X (m)', f(base.dx / 20));
      add('y', 'Corner Y (m)', f(base.dy / 20));
      add('w', 'Width (m)', '3.00');
      add('h', 'Height (m)', '3.00');
    } else if (tool == CadTool.circle) {
      add('x', 'Center X (m)', f(base.dx / 20));
      add('y', 'Center Y (m)', f(base.dy / 20));
      add('r', 'Radius (m)', '1.00');
    } else {
      add('x', 'Start X (m)', f(base.dx / 20));
      add('y', 'Start Y (m)', f(base.dy / 20));
      add('len', 'Length (m)', '3.00');
      add('ang', 'Angle (deg: 0 = right, 90 = down)', '0');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: Text('TYPE-IN ${tool.name.toUpperCase()}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final k in keys)
                TextField(
                  controller: ctrls[k],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(labelText: labels[k], labelStyle: const TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final vals = <String, String>{for (final k in keys) k: ctrls[k]!.text.trim()};
              Navigator.pop(ctx);
              _typeInCreate(tool, vals);
            },
            child: const Text('Draw'),
          ),
        ],
      ),
    );
  }

  void _typeInCreate(CadTool tool, Map<String, String> v) {
    final x = _num(v, 'x');
    final y = _num(v, 'y');
    if (x == null || y == null) {
      setState(() => _commandPrompt = 'TYPE-IN - invalid start point');
      return;
    }
    final start = Offset(x * 20, y * 20);
    final id = 'el_${DateTime.now().microsecondsSinceEpoch}';
    CadElement? made;
    Offset? lastEnd;
    if (tool == CadTool.rectangle) {
      final w = _num(v, 'w');
      final h = _num(v, 'h');
      if (w != null && h != null && w > 0 && h > 0) {
        lastEnd = start + Offset(w * 20, h * 20);
        made = CadElement(id: id, type: CadElementType.rectangle, layerId: '0_WALLS', start: start, end: lastEnd);
      }
    } else if (tool == CadTool.circle) {
      final r = _num(v, 'r');
      if (r != null && r > 0) {
        lastEnd = start + Offset(r * 20, 0);
        made = CadElement(id: id, type: CadElementType.circle, layerId: _activeLayerId, start: start, end: lastEnd, radius: r * 20);
      }
    } else {
      final len = _num(v, 'len');
      final ang = _num(v, 'ang');
      if (len != null && ang != null && len > 0) {
        final rad = ang * math.pi / 180;
        lastEnd = start + Offset(math.cos(rad), math.sin(rad)) * (len * 20);
        if (tool == CadTool.wall) {
          made = CadElement(id: id, type: CadElementType.wall, layerId: '0_WALLS', start: start, end: lastEnd, radius: _wallThickness);
        } else {
          made = CadElement(id: id, type: CadElementType.line, layerId: _activeLayerId, start: start, end: lastEnd);
        }
      }
    }
    if (made == null || lastEnd == null) {
      setState(() => _commandPrompt = 'TYPE-IN - invalid value, nothing drawn');
      return;
    }
    final newEl = made;
    final newEnd = lastEnd;
    _saveStateForUndo();
    setState(() {
      _elements.add(newEl);
      _lastPoint = newEnd;
      if (tool == CadTool.polyline) {
        _polyFirst ??= start;
        _polyLast = newEnd;
        _polyCount++;
        _dragStart = newEnd;
      }
      _commandPrompt = 'TYPE-IN - drawn. Press Type again for the next one (starts at the last end point)';
    });
  }

  // ---------- MULTI-SELECT ----------
  void _toggleMulti() {
    setState(() {
      _multiMode = !_multiMode;
      _activeTool = CadTool.select;
      _selectedElement = null;
      _multi.clear();
      _winStart = null;
      _groupDragging = false;
      _pendingBlock = null;
      _polyFirst = null;
      _polyLast = null;
      _polyCount = 0;
      _dragStart = null;
      _arcPts.clear();
      _commandPrompt = _multiMode ? 'MULTI - tap objects, or drag a box (right = inside only, left = touching)' : 'Command: SELECT';
    });
  }

  CadElement? _pickAt(Offset p) {
    for (final el in _elements.reversed) {
      if (el.type == CadElementType.hatch) continue;
      if (_selectHit(el, p)) return el;
    }
    for (final el in _elements.reversed) {
      if (el.type == CadElementType.hatch && el.boundingBox.contains(p)) return el;
    }
    return null;
  }

  void _multiDown(Offset p) {
    final hit = _pickAt(p);
    setState(() {
      _selectedElement = null;
      _currentCursor = p;
      _multiMoved = false;
      _moveUndoSaved = false;
      if (hit != null) {
        _multiDownId = hit.id;
        _multiDownWasMember = _multi.contains(hit.id);
        _multi.add(hit.id);
        _groupDragging = true;
        _moveLast = p;
        _winStart = null;
        _commandPrompt = 'MULTI - ${_multi.length} selected. Drag to move, tap again to deselect';
      } else {
        _multiDownId = null;
        _groupDragging = false;
        _winStart = p;
        _commandPrompt = 'MULTI - drag a box: right = inside only, left = touching';
      }
    });
  }

  void _multiMove(Offset p) {
    if (_groupDragging && _moveLast != null && _multi.isNotEmpty) {
      final delta = p - _moveLast!;
      if (delta.distance < 0.5) return;
      if (!_moveUndoSaved) {
        _saveStateForUndo();
        _moveUndoSaved = true;
      }
      _multiMoved = true;
      for (final el in _elements) {
        if (_multi.contains(el.id)) {
          el.start += delta;
          el.end += delta;
        }
      }
      _moveLast = p;
    }
  }

  void _multiUp() {
    setState(() {
      if (_groupDragging) {
        if (!_multiMoved && _multiDownWasMember && _multiDownId != null) {
          _multi.remove(_multiDownId);
        }
        _groupDragging = false;
        _multiDownId = null;
      } else if (_winStart != null && _currentCursor != null) {
        final a = _winStart!;
        final b = _currentCursor!;
        final rect = Rect.fromPoints(a, b);
        if (rect.width + rect.height < 8) {
          _multi.clear();
        } else {
          final crossing = b.dx < a.dx;
          for (final el in _elements) {
            final lay = _layers.where((l) => l.id == el.layerId);
            if (lay.isNotEmpty && !lay.first.isVisible) continue;
            final bb = el.boundingBox;
            final inside = bb.left >= rect.left && bb.right <= rect.right && bb.top >= rect.top && bb.bottom <= rect.bottom;
            if (crossing ? bb.overlaps(rect) : inside) _multi.add(el.id);
          }
        }
      }
      _winStart = null;
      _commandPrompt = 'MULTI - ${_multi.length} selected';
    });
  }

  void _multiSelectAll() {
    setState(() {
      for (final el in _elements) {
        final lay = _layers.where((l) => l.id == el.layerId);
        if (lay.isNotEmpty && !lay.first.isVisible) continue;
        _multi.add(el.id);
      }
      _commandPrompt = 'MULTI - ${_multi.length} selected';
    });
  }

  void _multiCopy() {
    if (_multi.isEmpty) return;
    _saveStateForUndo();
    const shift = Offset(20, 20);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final copies = <CadElement>[];
    var i = 0;
    for (final el in _elements) {
      if (_multi.contains(el.id)) {
        copies.add(el.copyWith(id: 'el_${stamp}_$i', start: el.start + shift, end: el.end + shift, isSelected: false));
        i++;
      }
    }
    setState(() {
      _elements.addAll(copies);
      _multi.clear();
      for (final c in copies) {
        _multi.add(c.id);
      }
      _commandPrompt = 'COPY - ${copies.length} objects copied 1 m away, drag to place';
    });
  }

  void _multiDelete() {
    if (_multi.isEmpty) return;
    _saveStateForUndo();
    setState(() {
      _elements.removeWhere((e) => _multi.contains(e.id));
      _multi.clear();
      _commandPrompt = 'ERASE - selection deleted';
    });
  }

  void _multiRotateDialog() {
    if (_multi.isEmpty) return;
    final controller = TextEditingController(text: '90');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131C35),
        title: const Text('ROTATE SELECTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              if (deg != null) _multiRotate(deg);
            },
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
  }

  void _multiRotate(double deg) {
    if (_multi.isEmpty) return;
    Rect? box;
    for (final el in _elements) {
      if (_multi.contains(el.id)) {
        final bb = el.boundingBox;
        box = box == null ? bb : box.expandToInclude(bb);
      }
    }
    if (box == null) return;
    final c = box.center;
    final quarter = (deg / 90).round() * 90.0;
    _saveStateForUndo();
    setState(() {
      for (int i = 0; i < _elements.length; i++) {
        final el = _elements[i];
        if (!_multi.contains(el.id)) continue;
        final rectLike = el.type == CadElementType.rectangle || el.type == CadElementType.column || el.type == CadElementType.hatch;
        final a = rectLike ? quarter : deg;
        final rad = a * math.pi / 180;
        final cs = math.cos(rad);
        final sn = math.sin(rad);
        Offset rot(Offset p) {
          final d = p - c;
          return c + Offset(d.dx * cs - d.dy * sn, d.dx * sn + d.dy * cs);
        }
        if (el.type == CadElementType.block) {
          final ctr = rot(_centerOf(el));
          final half = Offset((el.end.dx - el.start.dx) / 2, (el.end.dy - el.start.dy) / 2);
          _elements[i] = el.copyWith(start: ctr - half, end: ctr + half, radius: ((el.radius ?? 0.0) + deg) % 360);
        } else {
          el.start = rot(el.start);
          el.end = rot(el.end);
        }
      }
      _commandPrompt = 'ROTATE - ${_multi.length} objects rotated about the group centre';
    });
  }

'''

CHOICE_CHIP = r'''  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.darkPrimary.withOpacity(0.25) : const Color(0xFF0F172A).withOpacity(0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: selected ? AppColors.darkPrimary : Colors.white24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? AppColors.darkPrimary : Colors.white)),
        ),
      ),
    );
  }

'''

MULTI_BUTTON = r'''                        onPressed: _showBlockLibrary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: IconButton(
                        icon: const Icon(Icons.select_all, size: 22),
                        color: _multiMode ? AppColors.darkPrimary : Colors.white70,
                        tooltip: 'Multi-select',
                        style: IconButton.styleFrom(
                          backgroundColor: _multiMode ? AppColors.darkPrimary.withOpacity(0.2) : Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _toggleMulti,
                      ),
                    ),
'''

BARS = r'''          if (_activeTool == CadTool.wall || _activeTool == CadTool.line || _activeTool == CadTool.polyline || _activeTool == CadTool.rectangle || _activeTool == CadTool.circle)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_activeTool == CadTool.wall) ...[
                      _buildChoiceChip('4.5"', (_wallThickness - 0.1143).abs() < 0.002, () => setState(() => _wallThickness = 0.1143)),
                      const SizedBox(width: 6),
                      _buildChoiceChip('9"', (_wallThickness - 0.2286).abs() < 0.002, () => setState(() => _wallThickness = 0.2286)),
                      const SizedBox(width: 6),
                      _buildChoiceChip('12"', (_wallThickness - 0.3048).abs() < 0.002, () => setState(() => _wallThickness = 0.3048)),
                      const SizedBox(width: 6),
                      _buildChoiceChip('0.5 m', (_wallThickness - 0.5).abs() < 0.002, () => setState(() => _wallThickness = 0.5)),
                      const SizedBox(width: 12),
                    ],
                    _buildActionChip(Icons.keyboard, 'Type', _showTypeInDialog),
                  ],
                ),
              ),
            ),
          if (_multiMode)
            Positioned(
              left: 70,
              right: 12,
              bottom: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionChip(Icons.select_all, 'All', _multiSelectAll),
                    if (_multi.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _buildActionChip(Icons.content_copy, 'Copy', _multiCopy),
                      const SizedBox(width: 8),
                      _buildActionChip(Icons.rotate_right, 'Rotate', _multiRotateDialog),
                      const SizedBox(width: 8),
                      _buildActionChip(Icons.delete_outline, 'Delete', _multiDelete),
                      const SizedBox(width: 8),
                      _buildActionChip(Icons.clear, 'Clear', () {
                        setState(() {
                          _multi.clear();
                          _commandPrompt = 'MULTI - cleared';
                        });
                      }),
                    ],
                  ],
                ),
              ),
            ),
'''

WINDOW_DRAW = r'''    if (windowRect != null) {
      final wcol = windowCrossing ? const Color(0xFF22C55E) : const Color(0xFF38BDF8);
      canvas.drawRect(windowRect!, Paint()..color = wcol.withOpacity(0.12)..style = PaintingStyle.fill);
      canvas.drawRect(windowRect!, Paint()..color = wcol..strokeWidth = 1.2..style = PaintingStyle.stroke);
    }

'''

edit('lib/screens/cad_editor_screen.dart', [
    # imports
    ("import 'dart:convert' as conv;\n", "import 'dart:async';\nimport 'dart:convert' as conv;\n"),
    ("import 'package:path_provider/path_provider.dart';\n",
     "import 'package:path_provider/path_provider.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\n"),
    # state
    ("  final List<Offset> _arcPts = [];\n  String? _pendingBlock;\n",
     "  final List<Offset> _arcPts = [];\n  String? _pendingBlock;\n"
     "  Timer? _saveTimer;\n  bool _loaded = false;\n  String _lastSavedJson = '';\n"
     "  double _wallThickness = 0.5;\n  Offset? _lastPoint;\n"
     "  bool _multiMode = false;\n  final Set<String> _multi = {};\n  Offset? _winStart;\n"
     "  bool _groupDragging = false;\n  bool _multiMoved = false;\n  String? _multiDownId;\n  bool _multiDownWasMember = false;\n"),
    # init / dispose
    ("    _activeLayerId = _layers.first.id;\n    _loadSampleBlueprint();\n  }\n\n  @override\n  void dispose() {\n    _transformationController.dispose();\n    super.dispose();\n  }\n",
     "    _activeLayerId = _layers.first.id;\n    _loadSampleBlueprint();\n    _loadSaved();\n    _saveTimer = Timer.periodic(const Duration(seconds: 3), (_) => _autoSave());\n  }\n\n  @override\n  void dispose() {\n    _saveTimer?.cancel();\n    _autoSave();\n    _transformationController.dispose();\n    super.dispose();\n  }\n"),
    # extra snaps
    ("    if (foundSnap != null) {\n      _currentSnap = foundSnap;\n      return foundSnap.point;\n    }\n",
     "    foundSnap ??= _extraSnap(rawPoint, snapThreshold);\n\n    if (foundSnap != null) {\n      _currentSnap = foundSnap;\n      return foundSnap.point;\n    }\n"),
    # pointer down: multi
    ("    if (_activeTool == CadTool.select) {\n      CadElement? hit;\n",
     "    if (_activeTool == CadTool.select) {\n      if (_multiMode) {\n        _multiDown(snapped);\n        return;\n      }\n      CadElement? hit;\n"),
    # pointer move: group drag
    ("        _selectedElement!.end += delta;\n        _moveLast = snapped;\n      }\n    });\n  }\n",
     "        _selectedElement!.end += delta;\n        _moveLast = snapped;\n      }\n      if (_multiMode && _activeTool == CadTool.select) {\n        _multiMove(snapped);\n      }\n    });\n  }\n"),
    # pointer up
    ("    if (_isPanMode) return;\n    _moveLast = null;\n    if (_activeTool == CadTool.polyline) {\n      _polyAddPoint();\n",
     "    if (_isPanMode) return;\n    _moveLast = null;\n    if (_multiMode && _activeTool == CadTool.select) {\n      _multiUp();\n      return;\n    }\n    if (_activeTool == CadTool.polyline) {\n      _polyAddPoint();\n"),
    # remember last end point
    ("        _saveStateForUndo();\n        _createElement(start, end);\n",
     "        _saveStateForUndo();\n        _createElement(start, end);\n        _lastPoint = end;\n"),
    # new walls carry the chosen thickness
    ("        _elements.add(CadElement(id: id, type: CadElementType.wall, layerId: '0_WALLS', start: start, end: end));\n",
     "        _elements.add(CadElement(id: id, type: CadElementType.wall, layerId: '0_WALLS', start: start, end: end, radius: _wallThickness));\n"),
    # methods
    ("  void _showTextInputDialog(Offset position) {\n", METHODS + "  void _showTextInputDialog(Offset position) {\n"),
    # chip helper
    ("  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {\n",
     CHOICE_CHIP + "  Widget _buildActionChip(IconData icon, String label, VoidCallback onTap) {\n"),
    # left toolbar multi button
    ("                        onPressed: _showBlockLibrary,\n                      ),\n                    ),\n", MULTI_BUTTON),
    # polyline Done/Close bar moves up to make room for the Type chip
    ("          if (_activeTool == CadTool.polyline && _polyLast != null)\n            Positioned(\n              left: 70,\n              right: 12,\n              bottom: 64,\n",
     "          if (_activeTool == CadTool.polyline && _polyLast != null)\n            Positioned(\n              left: 70,\n              right: 12,\n              bottom: 108,\n"),
    # draw / multi bars
    ("          if (_activeTool == CadTool.block && _pendingBlock != null)\n",
     BARS + "          if (_activeTool == CadTool.block && _pendingBlock != null)\n"),
    # switching tool leaves multi mode
    ("            _arcPts.clear();\n            _pendingBlock = null;\n",
     "            _arcPts.clear();\n            _pendingBlock = null;\n            _multiMode = false;\n            _multi.clear();\n            _winStart = null;\n            _groupDragging = false;\n"),
    # painter wiring
    ("                  pendingBlock: _pendingBlock,\n                ),\n",
     "                  pendingBlock: _pendingBlock,\n                  multiIds: Set<String>.from(_multi),\n                  windowRect: (_winStart != null && _currentCursor != null) ? Rect.fromPoints(_winStart!, _currentCursor!) : null,\n                  windowCrossing: _winStart != null && _currentCursor != null && _currentCursor!.dx < _winStart!.dx,\n                ),\n"),
    ("  final String? pendingBlock;\n\n  _CadCanvasPainter({",
     "  final String? pendingBlock;\n  final Set<String> multiIds;\n  final Rect? windowRect;\n  final bool windowCrossing;\n\n  _CadCanvasPainter({"),
    ("    required this.pendingBlock,\n  });\n",
     "    required this.pendingBlock,\n    required this.multiIds,\n    required this.windowRect,\n    required this.windowCrossing,\n  });\n"),
    ("      final isSel = selectedElement?.id == el.id;\n",
     "      final isSel = selectedElement?.id == el.id || multiIds.contains(el.id);\n"),
    ("    if (currentCursor != null) {\n      _drawCrosshair(canvas, currentCursor!, size);\n    }\n",
     WINDOW_DRAW + "    if (currentCursor != null) {\n      _drawCrosshair(canvas, currentCursor!, size);\n    }\n"),
    # wall thickness in painter
    ("      case CadElementType.wall:\n        final dir = el.end - el.start;\n        if (dir.distance > 0) {\n          final norm = Offset(-dir.dy, dir.dx) / dir.distance * 5.0;\n",
     "      case CadElementType.wall:\n        final dir = el.end - el.start;\n        if (dir.distance > 0) {\n          final norm = Offset(-dir.dy, dir.dx) / dir.distance * (((el.radius ?? 0.5) * 20.0) / 2);\n"),
    # wall thickness in Props
    ("      add('ang', 'Angle (deg: 0 = right, 90 = down)', f(math.atan2(v.dy, v.dx) * 180 / math.pi));\n",
     "      add('ang', 'Angle (deg: 0 = right, 90 = down)', f(math.atan2(v.dy, v.dx) * 180 / math.pi));\n      if (t == CadElementType.wall) add('th', 'Wall thickness (m)', f(el.radius ?? 0.5));\n"),
    ("        if (t == CadElementType.dimension) newText = _dimText(len);\n",
     "        if (t == CadElementType.dimension) newText = _dimText(len);\n        if (t == CadElementType.wall) {\n          final th = _num(v, 'th');\n          if (th != null && th >= 0.05 && th <= 2.0) newRadius = th;\n        }\n"),
    # wall thickness in exports
    ("          final nrm = Offset(-dir.dy, dir.dx) / dist * 5.0;\n",
     "          final nrm = Offset(-dir.dy, dir.dx) / dist * (((el.radius ?? 0.5) * 20.0) / 2);\n"),
])

# all anchors matched -> write everything
for p, s in files.items():
    open(p, 'w', encoding='utf-8').write(s)
    print(f"OK: {p}")
