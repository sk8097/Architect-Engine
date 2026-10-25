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

# The sample plan was drawn at 10 px per foot, but the editor works at 20 px = 1 m
# (about 6.1 px per foot). Scale the sample by 0.6096 so a 40' x 30' plan is really
# 12.19 m x 9.14 m, and labels, measurements and exports all agree.
edit('lib/screens/cad_editor_screen.dart', [
    ("(9.14 m)'),\n    ];\n  }\n",
     r'''(9.14 m)'),
    ];
    const k = 0.6096;
    const o = Offset(100, 100);
    for (final el in _elements) {
      el.start = o + (el.start - o) * k;
      el.end = o + (el.end - o) * k;
    }
  }
'''),
])
