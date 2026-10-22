import re

print("Applying UI updates...")

# 1. Remove bottomNavigationBar & add Back button in main_scaffold.dart
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
print("  ✓ main_scaffold: bottom bar removed, back navigation added")

# 2. Add Professional Studio Section to home_screen.dart
with open('lib/screens/home_screen.dart', 'r') as f:
    hs = f.read()

prof_section = '''
          // Section Header: Professional Studio
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Professional Studio',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(1);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen()));
                  }
                },
                child: const Text('See All', style: TextStyle(color: AppColors.darkPrimary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // AutoCAD 2D Studio Hero Launch Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2433), Color(0xFF131C35)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkPrimary.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.darkPrimary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ACTIVE 2D VECTOR CAD',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.darkPrimary, letterSpacing: 0.5),
                      ),
                    ),
                    const Text('📐 26 Ready Blocks', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'AutoCAD 2D Studio',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Interactive drafting canvas: walls, rooms, columns, dimensions, dual themes & 26 vector blocks.',
                  style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkPrimary,
                      foregroundColor: const Color(0xFF0A1128),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CadEditorScreen()));
                    },
                    icon: const Icon(Icons.architecture, size: 18),
                    label: const Text('OPEN CAD STUDIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2x2 Grid of Professional Modules
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _buildShortcutCard(
                context,
                icon: '📐',
                title: 'CAD Workspace',
                sub: 'Grid & Snap drafting',
                action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadEditorScreen(projectName: 'CAD Workspace'))),
              ),
              _buildShortcutCard(
                context,
                icon: '🛋️',
                title: '2D Ready Blocks',
                sub: 'Beds, sofas, chulha, WC',
                action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadEditorScreen(projectName: 'CAD Blocks Studio'))),
              ),
              _buildShortcutCard(
                context,
                icon: '📑',
                title: 'Layer Manager',
                sub: 'Discipline isolation',
                action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CadEditorScreen(projectName: 'CAD Layers'))),
              ),
              _buildShortcutCard(
                context,
                icon: '⚖️',
                title: 'Standards & Codes',
                sub: 'NBC / AIA specifications',
                action: () {
                  if (onNavigateTab != null) {
                    onNavigateTab!(1);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalScreen()));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
'''

if 'Professional Studio' not in hs:
    target = '          // Design Studio Modules Shortcut'
    hs = hs.replace(target, prof_section + target)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(hs)
print("  ✓ home_screen: Professional section added")

# 3. Ensure onSelectTab exists in app_drawer.dart
with open('lib/widgets/app_drawer.dart', 'r') as f:
    ad = f.read()

if 'onSelectTab' not in ad:
    ad = ad.replace(
        'const AppDrawer({super.key});',
        'final Function(int)? onSelectTab;\n\n  const AppDrawer({super.key, this.onSelectTab});'
    )
    with open('lib/widgets/app_drawer.dart', 'w') as f:
        f.write(ad)
    print("  ✓ app_drawer: onSelectTab added")
else:
    print("  ✓ app_drawer: onSelectTab already present")

print("All updates completed successfully!")
