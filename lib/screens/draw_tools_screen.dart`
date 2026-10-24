import 'package:flutter/material.dart';

// Agar AppColors hai to use kar, nahi to fallback
const Color kPrimary = Color(0xFF1A2540);
const Color kPrimaryLight = Color(0xFF2A3A5C);
const Color kAccent = Color(0xFF00D4FF);
const Color kBg = Color(0xFF0A1128);
const Color kCard = Color(0xFF141E3A);

class DrawToolsScreen extends StatefulWidget {
  const DrawToolsScreen({super.key});
  @override
  State<DrawToolsScreen> createState() => _DrawToolsScreenState();
}

class _DrawToolsScreenState extends State<DrawToolsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text('DRAW TOOLS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.help_outline), onPressed: () {})],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kAccent,
          labelColor: kAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.photo_camera_back, size: 20), text: 'PHOTO MARKUP'),
            Tab(icon: Icon(Icons.auto_fix_high, size: 20), text: 'SKETCH TO CAD'),
            Tab(icon: Icon(Icons.draw, size: 20), text: 'WHITEBOARD'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPhotoMarkupTab(),
          _buildSketchToCadTab(),
          _buildWhiteboardTab(),
        ],
      ),
    );
  }

  // TAB 1: PHOTO MARKUP
  Widget _buildPhotoMarkupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            icon: Icons.photo_camera_back,
            title: 'SITE PHOTO MARKUP',
            subtitle: 'Mark defects directly on site photos',
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          _buildDemoBox(
            child: Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=500'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 40, left: 40,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                    child: const Text('CRACK HERE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const Positioned(
                  top: 60, left: 30,
                  child: Icon(Icons.arrow_downward, color: Colors.red, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            what: 'Takes a real site photo (column, beam, tile) and lets you draw, add arrows, text, and measurements directly on it for instant sharing.',
            how: [
              'Tap CAMERA / GALLERY to import site photo',
              'Select Tool: Pen (Red=Error, Green=OK), Arrow, Text, Dimension Line',
              'Mark defect: Circle crack, add text "Remove & Redo"',
              'Tap SAVE -> JPG saved in /PhotoMarkup/ -> Share via WhatsApp / Punch List',
            ],
            example: 'Tile mason installed wrong pattern. Photo > Mark cross with Red Pen > Text "Replace with Design B" > Share.',
            whenToUse: 'Daily Inspection, Punch List, Safety, Client Approval',
          ),
          _buildActionButton('OPEN PHOTO MARKUP', Icons.camera_alt, Colors.redAccent),
        ],
      ),
    );
  }

  // TAB 2: SKETCH TO CAD
  Widget _buildSketchToCadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            icon: Icons.auto_fix_high,
            title: 'HAND SKETCH TO CAD',
            subtitle: 'AI converts paper sketch to editable CAD',
            color: kAccent,
          ),
          const SizedBox(height: 16),
          _buildDemoBox(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Text('✏️\nHand Sketch\n(Rough)', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, color: kAccent)),
                Expanded(
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent.withOpacity(0.5))),
                    child: const Center(child: Text('🏗️\nAuto CAD\n(Perfect)', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            what: 'Converts photo of hand-drawn plan on paper into vector CAD drawing. Saves hours of manual redrawing.',
            how: [
              'Take top-down photo of hand sketch in good light',
              'Use 4-point crop to select exact boundary (auto perspective fix)',
              'Tap "CONVERT TO CAD" -> AI detects walls & openings in 5 sec',
              'Auto-opens in main CAD Workspace (Image 2) for adding dimensions & doors',
            ],
            example: 'Client gives 40x30 rough plan on paper. Photo > Convert > Opens in CAD > Add 40\'-0" dimensions & LIVING ROOM labels.',
            whenToUse: 'Digitizing old drawings, Client rough ideas, Site survey sketches',
          ),
          _buildActionButton('OPEN SKETCH TO CAD', Icons.document_scanner, kAccent),
        ],
      ),
    );
  }

  // TAB 3: WHITEBOARD
  Widget _buildWhiteboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(
            icon: Icons.draw,
            title: 'QUICK WHITEBOARD',
            subtitle: '30-second rough sketch for instant explanation',
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _buildDemoBox(
            child: Container(
              height: 180,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: CustomPaint(
                size: const Size(double.infinity, 180),
                painter: _WhiteboardDemoPainter(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGuideSection(
            what: 'Blank infinite canvas with no grid, snap, or scale. Like a physical whiteboard for fastest explanation on site.',
            how: [
              'Open Blank Board -> White canvas opens instantly',
              'Finger Draw: Draw walls, arrows, boxes. No precision needed',
              'Color Codes: Black=Existing, Red=Demolish, Blue=New',
              'Add Text anywhere: "Gate Here", "Shift 2 ft" -> 1-tap Save as PNG',
            ],
            example: 'Client says "Remove this wall" on site. Open Whiteboard > Draw 2 lines "This wall to be removed" > Show instantly. No CAD needed.',
            whenToUse: 'Client Meetings on Site, Quick Instructions to Mason, Brainstorming',
          ),
          _buildActionButton('OPEN WHITEBOARD', Icons.edit, Colors.orangeAccent),
        ],
      ),
    );
  }

  // COMMON WIDGETS
  Widget _buildHeaderCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
  }

  Widget _buildGuideSection({required String what, required List<String> how, required String example, required String whenToUse}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _guideTitle('WHAT IT DOES'),
          Text(what, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.4)),
          const SizedBox(height: 12),
          _guideTitle('HOW IT WORKS'),
          ...how.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: kAccent.withOpacity(0.2), shape: BoxShape.circle),
                  child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent))),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)))),
              ],
            ),
          )),
          const SizedBox(height: 12),
          _guideTitle('EXAMPLE'),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)),
            child: Text(example, style: const TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Expanded(child: Text('When to Use: $whenToUse', style: const TextStyle(fontSize: 11, color: Colors.white54))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guideTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1)),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {},
          icon: Icon(icon, size: 18),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}

class _WhiteboardDemoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87..strokeWidth = 2..style = PaintingStyle.stroke;
    final redPaint = Paint()..color = Colors.red..strokeWidth = 2..style = PaintingStyle.stroke;
    // Rough walls
    canvas.drawLine(Offset(20, 20), Offset(120, 20), paint);
    canvas.drawLine(Offset(120, 20), Offset(120, 100), paint);
    canvas.drawLine(Offset(20, 100), Offset(120, 100), paint);
    // Red cross for demolish
    canvas.drawLine(Offset(40, 40), Offset(100, 80), redPaint);
    canvas.drawLine(Offset(100, 40), Offset(40, 80), redPaint);
    // Arrow
    final bluePaint = Paint()..color = Colors.blue..strokeWidth = 2;
    canvas.drawLine(Offset(140, 60), Offset(200, 60), bluePaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
