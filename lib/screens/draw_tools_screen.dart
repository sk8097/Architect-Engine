import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFF1A2540);
const Color kAccent = Color(0xFF00D4FF);
const Color kBg = Color(0xFF0A1128);
const Color kCard = Color(0xFF141E3A);

// ================= MAIN DRAW TOOLS SCREEN (GUIDE + TABS) =================
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
    _tabController.addListener(() => setState(() {}));
  }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(backgroundColor: kPrimary, title: const Text('DRAW TOOLS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), centerTitle: true),
      body: Column(children: [
        Container(color: kPrimary, child: TabBar(controller: _tabController, indicatorColor: kAccent, labelColor: kAccent, unselectedLabelColor: Colors.white54, labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), tabs: const [Tab(icon: Icon(Icons.photo_camera, size: 20), text: 'PHOTO MARKUP'), Tab(icon: Icon(Icons.auto_fix_high, size: 20), text: 'SKETCH TO CAD'), Tab(icon: Icon(Icons.draw, size: 20), text: 'WHITEBOARD')])),
        Expanded(child: TabBarView(controller: _tabController, children: [_buildTab1(), _buildTab2(), _buildTab3()]))
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
          child: SizedBox(height: 52, child: _buildMainButton()),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    if (_tabController.index == 0) {
      return ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoMarkupCanvasScreen())), icon: const Icon(Icons.camera_alt, color: Colors.white), label: const Text('OPEN PHOTO MARKUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)));
    } else if (_tabController.index == 1) {
      return ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: kAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SketchToCadCanvasScreen())), icon: const Icon(Icons.document_scanner, color: Colors.white), label: const Text('OPEN SKETCH TO CAD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)));
    } else {
      return ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WhiteboardCanvasScreen())), icon: const Icon(Icons.edit, color: Colors.white), label: const Text('OPEN WHITEBOARD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)));
    }
  }

  Widget _buildTab1() => _guideWrapper(title: 'SITE PHOTO MARKUP', subtitle: 'Mark defects directly on site photos', icon: Icons.photo_camera, color: Colors.redAccent, what: 'This is FIELD COMMUNICATION TOOL. Not for drafting. You take a real site photo (Column crack, Beam honeycomb, Tile defect, Slab leakage) and you mark directly on the photo. It creates legal proof + instant instruction for mason/client.', how: ['Step 1: IMPORT - Tap CAMERA for live photo or GALLERY for existing photo. App auto-compresses to 2MB.', 'Step 2: SELECT TOOL - Red Pen = Mistake/Crack, Yellow = Hold/Review, Green = Approved, Blue = New Work. Tools: Freehand Pen, Straight Arrow, Text Box, Dimension Line (Tap 2 points), Circle.', 'Step 3: ANNOTATE - Circle the defect, draw arrow, add text like "CRACK HERE - 3mm wide - Remove & Redo", add date stamp.', 'Step 4: EXPORT - Tap SAVE. File saved as JPG in /ArchitectEngine/PhotoMarkup/PROJECT_NAME_DATE.jpg. Auto-added to Site Report & Punch List. Share via WhatsApp / PDF.'], example: 'Use Case: Kitchen tile alignment wrong. Engineer takes photo > Draws red cross on wrong tiles > Arrow with text "Replace with Design B - Ref Drawing A101" > Saves > Sends to tile contractor on WhatsApp. Time: 45 seconds. No need to go to office and create CAD.', whenToUse: 'Daily Site Inspection, Quality Check, Safety Incident Marking, Client Approval for defects, Handover Punch List');
  Widget _buildTab2() => _guideWrapper(title: 'HAND SKETCH TO CAD', subtitle: 'AI converts paper sketch to editable CAD', icon: Icons.auto_fix_high, color: kAccent, what: 'This is DIGITIZER TOOL. Client gives you a rough hand-drawn plan on paper/notebook. Instead of redrawing manually in CAD for 1 hour, AI converts it to vector lines in 5 seconds.', how: ['Step 1: CAPTURE - Place paper on flat surface in good light. Take top-down photo (No shadow).', 'Step 2: CROP & ALIGN - Use 4-point crop box to select exact boundary. App auto-fixes perspective & skew.', 'Step 3: AI CONVERT - Tap "CONVERT TO CAD". AI detects: Walls (thick lines), Doors/Windows (gaps), Dimensions (handwritten numbers). Output: DXF/DWG vector.', 'Step 4: EDIT IN CAD - Converted file auto-opens in main CAD Workspace (Your Image 2 screen). Now you can add precise dimensions (40\'-0" / 12.20m), Doors, Windows, Layers (WALLS, DOORS), Furniture Blocks.'], example: 'Use Case: Client draws 40\'x30\' 2BHK plan on paper. You photograph > AI converts to editable lines > Open in CAD > Add Living 15\'x12\', Bedroom 12\'x10\', Doors, Windows > Add Title Block > Export PDF. Total time: 10 mins vs 90 mins manually.', whenToUse: 'Digitizing old municipal drawings, Converting client rough ideas, Site survey sketch conversion, Redrawing from photo of old blueprint');
  Widget _buildTab3() => _guideWrapper(title: 'QUICK WHITEBOARD', subtitle: '30-second rough sketch for instant explanation', icon: Icons.draw, color: Colors.orangeAccent, what: 'This is FASTEST EXPLANATION TOOL. No grid, no snap, no scale, no precision. Like a physical whiteboard you carry in pocket. For 30-second explanations on site when you don\'t want to open full CAD.', how: ['Step 1: OPEN BOARD - Blank infinite white canvas opens instantly. No loading.', 'Step 2: FINGER DRAW - Draw with finger. Walls = lines, Doors = gap, Arrow = direction. No straight-line correction. Rough is OK.', 'Step 3: COLOR CODES (Industry Standard) - Black = Existing wall/structure, Red = To be Demolished, Blue = New Construction/Proposal, Green = Approved.', 'Step 4: ADD TEXT & SAVE - Tap anywhere to add text: "Gate Here", "Shift 2ft Left", "Staircase New". 1-tap Save as PNG in /Whiteboard/'], example: 'Use Case: Client on site says "I want to remove this wall and shift gate". You open Whiteboard > In 5 seconds draw 2 boxes > Red cross on wall to remove > Blue line for new gate > Show to client instantly. Client understands. No need to open CAD with X:15.00m coordinates.', whenToUse: 'Client Meetings on Site, Quick Instructions to Mason/Labour, Brainstorming ideas, Explaining changes, Temporary layout discussion');

  Widget _guideWrapper({required String title, required String subtitle, required IconData icon, required Color color, required String what, required List<String> how, required String example, required String whenToUse}) {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)), const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)))]))])),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1E2A4A), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('WHAT IT DOES'), Text(what, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), height: 1.4)),
        const SizedBox(height: 12), _label('HOW IT WORKS'), ...how.map((h) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• $h', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8), height: 1.3)))),
        const SizedBox(height: 12), _label('EXAMPLE'), Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kBg, borderRadius: BorderRadius.circular(8)), child: Text(example, style: const TextStyle(fontSize: 11, color: Colors.white70, fontStyle: FontStyle.italic))),
        const SizedBox(height: 12), Row(children: [const Icon(Icons.access_time, size: 14, color: Colors.white54), const SizedBox(width: 6), Expanded(child: Text('When to Use: $whenToUse', style: const TextStyle(fontSize: 10, color: Colors.white54)))]),
        const SizedBox(height: 70)
      ]))
    ]));
  }
  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kAccent, letterSpacing: 1)));
}

// ================= CANVAS 1: PHOTO MARKUP (ACTUAL WORKING) =================
class PhotoMarkupCanvasScreen extends StatefulWidget { const PhotoMarkupCanvasScreen({super.key}); @override State<PhotoMarkupCanvasScreen> createState() => _PhotoMarkupCanvasScreenState(); }
class _PhotoMarkupCanvasScreenState extends State<PhotoMarkupCanvasScreen> {
  List<Offset> points = []; Color selectedColor = Colors.red;
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Photo Markup - Draw on Photo'), backgroundColor: Colors.redAccent, actions: [IconButton(icon: const Icon(Icons.undo), onPressed: () => setState(() => points.clear())), IconButton(icon: const Icon(Icons.save), onPressed: () => Navigator.pop(context))]), body: Column(children: [
      Container(height: 50, color: Colors.black12, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _colorBtn(Colors.red), _colorBtn(Colors.green), _colorBtn(Colors.yellow), _colorBtn(Colors.blue), const Text('Draw with finger', style: TextStyle(fontSize: 11))])),
      Expanded(child: GestureDetector(onPanUpdate: (d) => setState(() => points.add(d.localPosition)), onPanEnd: (_) => points.add(Offset.zero), child: CustomPaint(painter: _MarkupPainter(points, selectedColor), size: Size.infinite, child: Container(color: Colors.grey.shade300, child: const Center(child: Text('Site Photo Area\n(Draw CRACK HERE here)', textAlign: TextAlign.center))))))
    ]));
  }
  Widget _colorBtn(Color c) => GestureDetector(onTap: () => setState(() => selectedColor = c), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: selectedColor==c?Colors.black:Colors.transparent, width: 2))));
}

class _MarkupPainter extends CustomPainter {
  final List<Offset> points; final Color color; _MarkupPainter(this.points, this.color);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 4..strokeCap = StrokeCap.round;
    for(int i=0;i<points.length-1;i++){ if(points[i]!=Offset.zero && points[i+1]!=Offset.zero){ canvas.drawLine(points[i], points[i+1], p); }}
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ================= CANVAS 2: SKETCH TO CAD =================
class SketchToCadCanvasScreen extends StatelessWidget {
  const SketchToCadCanvasScreen({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Sketch to CAD - AI Convert'), backgroundColor: kAccent), body: Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(height: 180, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kAccent)), child: const Icon(Icons.document_scanner, size: 60, color: kPrimary)),
      const SizedBox(height: 20), const Text('1. Take photo of hand sketch\n2. Crop boundary\n3. Tap CONVERT\n\n(AI will convert to editable CAD - Integration pending)', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
      const SizedBox(height: 20), ElevatedButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Conversion Started... (Demo)'))); Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context)); }, child: const Text('CONVERT TO CAD (DEMO)'))
    ]))));
  }
}

// ================= CANVAS 3: WHITEBOARD (ACTUAL WORKING) =================
class WhiteboardCanvasScreen extends StatefulWidget { const WhiteboardCanvasScreen({super.key}); @override State<WhiteboardCanvasScreen> createState() => _WhiteboardCanvasScreenState(); }
class _WhiteboardCanvasScreenState extends State<WhiteboardCanvasScreen> {
  List<Offset> points = []; Color selectedColor = Colors.black;
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Quick Whiteboard'), backgroundColor: Colors.orangeAccent, actions: [IconButton(icon: const Icon(Icons.undo), onPressed: () => setState(() => points.clear())), IconButton(icon: const Icon(Icons.save), onPressed: () => Navigator.pop(context))]), body: Column(children: [
      Container(height: 50, color: Colors.black12, child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ _colorBtn(Colors.black), _colorBtn(Colors.red), _colorBtn(Colors.blue), _colorBtn(Colors.green), const Text('Black=Existing, Red=Demolish', style: TextStyle(fontSize: 10))])),
      Expanded(child: GestureDetector(onPanUpdate: (d) => setState(() => points.add(d.localPosition)), onPanEnd: (_) => points.add(Offset.zero), child: CustomPaint(painter: _MarkupPainter(points, selectedColor), size: Size.infinite, child: Container(color: Colors.white))))
    ]));
  }
  Widget _colorBtn(Color c) => GestureDetector(onTap: () => setState(() => selectedColor = c), child: Container(width: 28, height: 28, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: selectedColor==c?Colors.orange:Colors.transparent, width: 2))));
}
