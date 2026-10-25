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

edit('lib/screens/cad_editor_screen.dart', [
    # 1) symbols the PDF/DXF basic font cannot show -> readable ASCII
    ("    for (final u in s.codeUnits) {\n      sb.write((u < 32 || u > 126) ? '?' : String.fromCharCode(u));\n    }\n",
     r'''    for (final u in s.codeUnits) {
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
'''),
    # 2) multi-line labels become real separate lines
    ("    void text(Offset p, String s, double h, String ly) {\n      out.add(_Prim(3, mx(p.dx), my(p.dy), 0, 0, h, 0, 0, s, ly));\n    }\n",
     r'''    void text(Offset p, String s, double h, String ly) {
      final parts = s.split('\n');
      for (int i = 0; i < parts.length; i++) {
        out.add(_Prim(3, mx(p.dx), my(p.dy + i * h * 28.0), 0, 0, h, 0, 0, parts[i], ly));
      }
    }
'''),
    # 3) PDF text goes through the same cleaner
    ("        txt(px(p.x1), py(p.y1), size, p.text);\n",
     "        txt(px(p.x1), py(p.y1), size, _asciiOnly(p.text));\n"),
])
