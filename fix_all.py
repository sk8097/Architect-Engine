import re

print("Applying fixes...")

# 1. Fix app_drawer.dart (Build error fix)
with open('lib/widgets/app_drawer.dart', 'r') as f:
    ad = f.read()
if 'onSelectTab' not in ad:
    ad = ad.replace(
        'const AppDrawer({super.key});',
        'final Function(int)? onSelectTab;\n\n  const AppDrawer({super.key, this.onSelectTab});'
    )
    with open('lib/widgets/app_drawer.dart', 'w') as f:
        f.write(ad)
    print("  ✓ app_drawer.dart fixed")

# 2. Fix main_scaffold.dart (Remove bottom menu & add back button)
with open('lib/screens/main_scaffold.dart', 'r') as f:
    ms = f.read()

old_leading = '''        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),'''

new_leading = '''        leading: _currentIndex != 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Home',
                onPressed: () => setState(() => _currentIndex = 0),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),'''

if old_leading in ms:
    ms = ms.replace(old_leading, new_leading)

if 'Icons.home_outlined' not in ms:
    ms = ms.replace('        actions: [', '''        actions: [
          if (_currentIndex != 0)
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Home',
              onPressed: () => setState(() => _currentIndex = 0),
            ),''', 1)

ms = re.sub(r'      bottomNavigationBar:\s*NavigationBar\(.*?\),\s*\n\s*\);', '    );', ms, flags=re.DOTALL)
with open('lib/screens/main_scaffold.dart', 'w') as f:
    f.write(ms)
print("  ✓ main_scaffold.dart: bottom bar removed")

# 3. Add Professional Section to home_screen.dart
with open('lib/screens/home_screen.dart', 'r') as f:
    hs = f.read()

prof_section = '''
          // Professional Studio Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Professional Studio', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  if (onNavigateTab != null) onNavigateTab!(1);
                  else Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen()));
                },
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E2433), Color(0xFF131C35)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkPrimary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AutoCAD 2D Studio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Wall drafting, rooms, dimensions & 26 vector blocks.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, foregroundColor: const Color(0xFF0A1128)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadEditorScreen())),
                    icon: const Icon(Icons.architecture, size: 18),
                    label: const Text('OPEN CAD STUDIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
'''

if 'Professional Studio' not in hs:
    hs = hs.replace('          // Design Studio Modules Shortcut', prof_section + '          // Design Studio Modules Shortcut')
    with open('lib/screens/home_screen.dart', 'w') as f:
        f.write(hs)
    print("  ✓ home_screen.dart: Professional section added")

# 4. Zoom buttons in cad_editor_screen.dart
with open('lib/screens/cad_editor_screen.dart', 'r') as f:
    cad = f.read()

cad = cad.replace('${widget.plotWidth?.toStringAsFixed(0)}', '${(widget.plotWidth ?? 30.0).toStringAsFixed(0)}')
cad = cad.replace('${widget.plotLength?.toStringAsFixed(0)}', '${(widget.plotLength ?? 40.0).toStringAsFixed(0)}')

zoom_panel = '''
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
'''
if 'Zoom In' not in cad and 'm.scale(1.25)' not in cad:
    cad = cad.replace('          // Bottom Status Bar', zoom_panel + '\n          // Bottom Status Bar')
    with open('lib/screens/cad_editor_screen.dart', 'w') as f:
        f.write(cad)
    print("  ✓ cad_editor_screen.dart: zoom buttons & null ft fixed")

print("All fixes ready!")
