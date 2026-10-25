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

# ---------------- state-class methods ----------------
METHODS = r'''  // ---------- REAL EXPORT: DXF + PDF ----------
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
      out.add(_Prim(3, mx(p.dx), my(p.dy), 0, 0, h, 0, 0, s, ly));
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
      sb.write((u < 32 || u > 126) ? '?' : String.fromCharCode(u));
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
        txt(px(p.x1), py(p.y1), size, p.text);
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

'''

TOP = r'''
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
'''

edit('lib/screens/cad_editor_screen.dart', [
    ("import 'dart:math' as math;\n",
     "import 'dart:convert' as conv;\nimport 'dart:io' as io;\nimport 'dart:math' as math;\nimport 'package:path_provider/path_provider.dart';\nimport 'package:share_plus/share_plus.dart';\n"),
    ("const Text('AutoCAD DXF / DWG',", "const Text('AutoCAD DXF (.dxf)',"),
    ("                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Drawing exported as Drawing_R01.dxf')));\n",
     "                _exportDrawing(dxf: true);\n"),
    ("                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Exported Blueprint PDF successfully!')));\n",
     "                _exportDrawing(dxf: false);\n"),
    ("  void _showTextInputDialog(Offset position) {\n", METHODS + "  void _showTextInputDialog(Offset position) {\n"),
    ("  @override\n  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;\n}\n",
     "  @override\n  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;\n}\n" + TOP),
])

# ---------------- pubspec: two small plugins (runs last, only if the code edits worked) ----------------
edit('pubspec.yaml', [
    ("  url_launcher: ^6.2.4\n\ndev_dependencies:",
     "  url_launcher: ^6.2.4\n  path_provider: ^2.1.2\n  share_plus: ^10.0.0\n\ndev_dependencies:"),
])
