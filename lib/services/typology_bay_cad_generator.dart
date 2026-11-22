import '../data/project_requirements.dart';
import '../data/typology_bay_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class TypologyBayCadResult {
  const TypologyBayCadResult({
    this.plan,
    this.section,
    this.issue,
    this.footprintArea = 0,
    this.grossFloorArea = 0,
    this.netUsableArea = 0,
    this.circulationArea = 0,
    this.siteCoveragePct = 0,
    this.storeys = 0,
    this.clearHeightM = 0,
  });

  final FloorPlanCad? plan;
  final FloorPlanCad? section;
  final String? issue;
  final double footprintArea;
  final double grossFloorArea;
  final double netUsableArea;
  final double circulationArea;
  final double siteCoveragePct;
  final int storeys;
  final double clearHeightM;
}

class TypologyBayCadGenerator {
  static bool requested(ProjectBrief? brief) =>
      brief?.requirements?.answers['cad_output'] == typologyBayMode;

  TypologyBayCadResult generate(ProjectBrief brief) {
    final ans = brief.requirements?.answers ?? const <String, String>{};
    if (!typologyBayCadEligible(brief.category, brief.group, brief.type)) {
      return const TypologyBayCadResult(
        issue: 'Select a valid category, group, and type before generating parametric bay CAD.',
      );
    }

    double? numVal(String k) => double.tryParse((ans[k] ?? '').trim());
    int? intVal(String k) {
      final d = numVal(k);
      if (d == null || d != d.roundToDouble()) return null;
      return d.toInt();
    }

    final siteW = numVal('tb_site_w');
    final siteD = numVal('tb_site_d');
    final sbFront = numVal('tb_setback_front');
    final sbSide = numVal('tb_setback_side');
    final sbRear = numVal('tb_setback_rear');
    final baysX = intVal('tb_bays_x');
    final baysY = intVal('tb_bays_y');
    final bayW = numVal('tb_bay_w');
    final bayD = numVal('tb_bay_d');
    final corrW = numVal('tb_corridor_w');
    final clearH = numVal('tb_clear_h');
    final storeys = intVal('tb_storeys');

    if (siteW == null ||
        siteD == null ||
        sbFront == null ||
        sbSide == null ||
        sbRear == null ||
        baysX == null ||
        baysY == null ||
        bayW == null ||
        bayD == null ||
        corrW == null ||
        clearH == null ||
        storeys == null) {
      return const TypologyBayCadResult(
        issue: 'All measured bay, setback, corridor, and storey fields are required.',
      );
    }

    if (siteW < 3 || siteD < 3 || sbFront < 0 || sbSide < 0 || sbRear < 0) {
      return const TypologyBayCadResult(
        issue: 'Site dimensions must be at least 3.0 m and setbacks cannot be negative.',
      );
    }
    if (baysX < 1 || baysX > 20 || baysY < 1 || baysY > 20) {
      return const TypologyBayCadResult(
        issue: 'Structural bay counts must be whole numbers between 1 and 20.',
      );
    }
    if (bayW < 2 || bayD < 2 || corrW < 1.2 || clearH < 2.4 || storeys < 1 || storeys > 12) {
      return const TypologyBayCadResult(
        issue: 'Bay dimensions (>= 2.0 m), corridor (>= 1.2 m), height (>= 2.4 m), and storeys (1–12) must be within valid limits.',
      );
    }

    final footprintW = baysX * bayW;
    final footprintD = baysY * bayD + corrW;

    if (footprintW + 2 * sbSide > siteW + 1e-6) {
      return TypologyBayCadResult(
        issue:
            'Building width (${footprintW.toStringAsFixed(2)} m) plus side setbacks (${(2 * sbSide).toStringAsFixed(2)} m) exceeds site width (${siteW.toStringAsFixed(2)} m).',
      );
    }
    if (footprintD + sbFront + sbRear > siteD + 1e-6) {
      return TypologyBayCadResult(
        issue:
            'Building depth (${footprintD.toStringAsFixed(2)} m) plus front/rear setbacks (${(sbFront + sbRear).toStringAsFixed(2)} m) exceeds site depth (${siteD.toStringAsFixed(2)} m).',
      );
    }

    final footprintArea = footprintW * footprintD;
    final grossFloorArea = footprintArea * storeys;
    final circulationArea = footprintW * corrW * storeys;
    final netUsableArea = grossFloorArea - circulationArea;
    final siteCoveragePct = (footprintArea / (siteW * siteD)) * 100.0;

    final siteWMm = (siteW * 1000).round();
    final siteDMm = (siteD * 1000).round();
    final sbFrontMm = (sbFront * 1000).round();
    final sbSideMm = (sbSide * 1000).round();
    final bayWMm = (bayW * 1000).round();
    final bayDMm = (bayD * 1000).round();
    final corrWMm = (corrW * 1000).round();
    final fpWMm = (footprintW * 1000).round();
    final fpDMm = (footprintD * 1000).round();

    final rooms = <CadRoom>[];
    final walls = <CadWall>[];
    final lines = <CadLine>[];
    final texts = <CadText>[];

    // Site boundary
    lines.add(CadLine(0, 0, siteWMm, 0, layer: 'A-SITE'));
    lines.add(CadLine(siteWMm, 0, siteWMm, siteDMm, layer: 'A-SITE'));
    lines.add(CadLine(siteWMm, siteDMm, 0, siteDMm, layer: 'A-SITE'));
    lines.add(CadLine(0, siteDMm, 0, 0, layer: 'A-SITE'));

    final originX = sbSideMm + ((siteWMm - 2 * sbSideMm - fpWMm) ~/ 2);
    final originY = sbFrontMm;

    // Circulation corridor at front of bays
    rooms.add(CadRoom(
      name: 'CIRCULATION',
      x: originX,
      y: originY,
      width: fpWMm,
      height: corrWMm,
    ));

    // Structural bays
    for (var ix = 0; ix < baysX; ix++) {
      for (var iy = 0; iy < baysY; iy++) {
        final bx = originX + ix * bayWMm;
        final by = originY + corrWMm + iy * bayDMm;
        rooms.add(CadRoom(
          name: 'BAY ${ix + 1}-${iy + 1}',
          x: bx,
          y: by,
          width: bayWMm,
          height: bayDMm,
        ));
      }
    }

    // Perimeter walls
    walls.add(CadWall(originX, originY, originX + fpWMm, originY, thickness: 230));
    walls.add(CadWall(originX + fpWMm, originY, originX + fpWMm, originY + fpDMm, thickness: 230));
    walls.add(CadWall(originX + fpWMm, originY + fpDMm, originX, originY + fpDMm, thickness: 230));
    walls.add(CadWall(originX, originY + fpDMm, originX, originY, thickness: 230));

    texts.add(CadText(
      x: originX,
      y: siteDMm + 600,
      text: '${brief.type.toUpperCase()} — ${baysX}x$baysY BAYS (${footprintW.toStringAsFixed(2)}x${footprintD.toStringAsFixed(2)} m)',
      height: 300,
    ));

    final plan = FloorPlanCad(
      widthMm: siteWMm,
      heightMm: siteDMm + 1200,
      rooms: rooms,
      walls: walls,
      lines: lines,
      texts: texts,
    );

    // Section sheet
    final secLines = <CadLine>[];
    final secTexts = <CadText>[];
    final clearHMm = (clearH * 1000).round();
    final totalHMm = clearHMm * storeys;

    // Ground line
    secLines.add(CadLine(-1000, 0, fpWMm + 1000, 0, layer: 'A-SITE'));
    for (var s = 0; s <= storeys; s++) {
      final y = s * clearHMm;
      secLines.add(CadLine(0, y, fpWMm, y, layer: 'A-WALL'));
      if (s < storeys) {
        secTexts.add(CadText(
          x: 250,
          y: y + clearHMm ~/ 2,
          text: 'LEVEL ${s + 1} (H=${clearH.toStringAsFixed(2)} m)',
          height: 250,
        ));
      }
    }
    for (var ix = 0; ix <= baysX; ix++) {
      final x = ix * bayWMm;
      secLines.add(CadLine(x, 0, x, totalHMm, layer: 'A-GRID'));
    }

    final section = FloorPlanCad(
      widthMm: fpWMm + 2000,
      heightMm: totalHMm + 1000,
      rooms: const [],
      walls: const [],
      lines: secLines,
      texts: secTexts,
    );

    return TypologyBayCadResult(
      plan: plan,
      section: section,
      footprintArea: footprintArea,
      grossFloorArea: grossFloorArea,
      netUsableArea: netUsableArea,
      circulationArea: circulationArea,
      siteCoveragePct: siteCoveragePct,
      storeys: storeys,
      clearHeightM: clearH,
    );
  }
}
