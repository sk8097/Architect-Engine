import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF1A2540);
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
    _tabController.addListener(() {
      setState(() {}); // tab change pe button update hoga
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _getBottomButton() {
    String label = 'OPEN PHOTO MARKUP';
    IconData icon = Icons.camera_alt;
    Color color = Colors.redAccent;

    if (_tabController.index == 1) {
      label = 'OPEN SKETCH TO CAD';
      icon = Icons.document_scanner;
      color = kAccent;
    } else if (_tabController.index == 2) {
      label = 'OPEN WHITEBOARD';
      icon = Icons.edit;
      color = Colors.orangeAccent;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () {
          if (_tabController.index == 0) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo Markup Opening...')));
          } else if (_tabController.index == 1) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sketch to CAD Opening...')));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Whiteboard Opening...')));
          }
        },
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: kPrimary,
        title: const Text('DRAW TOOLS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: kPrimary,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kAccent,
              labelColor: kAccent,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(icon: Icon(Icons.photo_camera, size: 20), text: 'PHOTO MARKUP'),
                Tab(icon: Icon(Icons.auto_fix_high, size: 20), text: 'SKETCH TO CAD'),
                Tab(icon: Icon(Icons.draw, size: 20), text: 'WHITEBOARD'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPhotoMarkupTab(),
                _buildSketchToCadTab(),
                _buildWhiteboardTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
          child: _getBottomButton(),
        ),
      ),
    );
  }

  Widget _buildPhotoMarkupTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _buildHeaderCard(icon: Icons.photo_camera, title: 'SITE PHOTO MARKUP', subtitle: 'Mark defects directly on site photos', color: Colors.redAccent),
      const SizedBox(height: 16),
      _buildGuideSection(what: 'Takes a real site photo (column, beam, tile) and lets you draw, add arrows, text, and measurements directly on it for instant sharing.', how: ['Tap CAMERA / GALLERY to import site photo','Select Tool: Pen (Red=Error, Green=OK), Arrow, Text, Dimension Line','Mark defect: Circle crack, add text "Remove & Redo"','Tap SAVE -> JPG saved in /PhotoMarkup/ -> Share via WhatsApp / Punch List'], example: 'Tile mason installed wrong pattern. Photo > Mark cross with Red Pen > Text "Replace with Design B" > Share.'),
    ]));
  }

  Widget _buildSketchToCadTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _buildHeaderCard(icon: Icons.auto_fix_high, title: 'HAND SKETCH TO CAD', subtitle: 'AI converts paper sketch to editable CAD', color: kAccent),
      const SizedBox(height: 16),
      _buildGuideSection(what: 'Converts photo of hand-drawn plan on paper into vector CAD drawing. Saves hours of manual redrawing.', how: ['Take top-down photo of hand sketch in good light','Use 4-point crop to select exact boundary (auto perspective fix)','Tap "CONVERT TO CAD" -> AI detects walls & openings in 5 sec','Auto-opens in main CAD Workspace for adding dimensions & doors'], example: 'Client gives 40x30 rough plan on paper. Photo > Convert > Opens in CAD > Add 40\'-0" dimensions & LIVING ROOM labels.'),
    ]));
  }

  Widget _buildWhiteboardTab() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      _buildHeaderCard(icon: Icons.draw, title: 'QUICK WHITEBOARD', subtitle: '30-second rough sketch for instant explanation', color: Colors.orangeAccent),
      const SizedBox(height: 16),
      _buildGuideSection(what: 'Blank infinite canvas with no grid, snap, or scale. Like a physical whiteboard for fastest explanation on site.', how: ['Open Blank Board -> White canvas opens instantly','Finger Draw: Draw walls, arrows, boxes. No precision needed','Color Codes: Black=Existing, Red=Demolish, Blue=New','Add Text anywhere: "Gate Here", "Shift 2 ft" -> 1-tap Save as PNG'], example: 'Client says "Remove this wall" on site. Open Whiteboard > Draw 2 lines "This wall to be removed" > Show instantly. No CAD needed.'),
    ]));
  }

  Widget _buildHeaderCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)))]))]));
  }

  Widget _buildGuideSection({required String what, required List<String> how, required String example}) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E2A4A), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('WHAT IT DOES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(what, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.4)),
      const SizedBox(height: 12),
      const Text('HOW IT WORKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1)),
      const SizedBox(height: 6),
      ...how.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 20, height: 20, decoration: BoxDecoration(color: kAccent.withOpacity(0.2), shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent)))), const SizedBox(width: 8), Expanded(child: Text(e.value, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))))]))),
      const SizedBox(height: 12),
      const Text('EXAMPLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)), child: Text(example, style: const TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic))),
      const SizedBox(height: 80),
    ]));
  }
}
