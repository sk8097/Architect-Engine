import 'dart:math' as math;

import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../data/public_market_cad_fields.dart';
import '../models/automatic_floor_plan.dart';
import '../models/project_brief.dart';
import 'floor_plan_cad.dart';

class PublicMarketCadResult {
  const PublicMarketCadResult({this.drawing, this.issue, this.stalls = 0, this.widthMm = 0,
    this.depthMm = 0, this.stallAreaM2 = 0, this.circulationM2 = 0});
  final FloorPlanCad? drawing;
  final String? issue;
  final int stalls, widthMm, depthMm;
  final double stallAreaM2, circulationM2;
}

/// One open-air market with two inward-facing rows and a pedestrian loop.
class PublicMarketCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output'] == 'public_market_stalls';

  PublicMarketCadResult generate(ProjectBrief brief, {required double widthFt, required double depthFt, required String facing}) {
    PublicMarketCadResult stop(String reason) => PublicMarketCadResult(issue: reason);
    final sel = brief.taxonomy, snap = brief.requirements;
    if (sel == null || snap == null || sel.version != projectTaxonomyVersion || snap.version != requirementsSchemaVersion ||
        !publicMarketCadEligible(sel.categoryId, sel.subcategoryId, sel.typeId)) {
      return stop('Select Public Market and save the current measured market brief.');
    }
    if (!const {null, 'outdoor'}.contains(sel.configurationId) ||
        !const {null, 'new_design', 'concept_design', 'feasibility'}.contains(sel.actionId) ||
        (brief.floorCount ?? 0) != 0 || !const {null, ProjectParking.none}.contains(brief.parking) || sel.spaceQuantities.isNotEmpty) {
      return stop('Use one outdoor market without buildings, parking or separate Space selections.');
    }
    if (!const {'rectangular', 'square'}.contains(sel.plotShapeId) || !const {'South','North','East','West'}.contains(facing)) {
      return stop('Use a rectangular or square plot with a cardinal frontage.');
    }
    final a = snap.answers;
    int? mm(Object? value, {bool zero = false, int max = 300}) {
      if (value is! num || !value.isFinite || value < (zero ? 0 : .001) || value > max) return null;
      return (value * 1000).round();
    }
    final pw = mm(widthFt * .3048,max:2000), pd = mm(depthFt * .3048,max:2000), count = a['pm_stalls'];
    final pitch = mm(a['pm_pitch']), stallDepth = mm(a['pm_depth']), opening = mm(a['pm_opening']);
    final aisle = mm(a['pm_aisle']), side = mm(a['pm_side']), frontCross = mm(a['pm_entry_cross']), rearCross = mm(a['pm_rear_cross']);
    final entry = mm(a['pm_entry']), left = mm(a['pm_left'],zero:true), front = mm(a['pm_front']);
    if (pw == null || pd == null || count is! int || count < 1 || count > 24 || pitch == null || stallDepth == null ||
        opening == null || aisle == null || side == null || frontCross == null || rearCross == null || entry == null ||
        left == null || front == null || (sel.plotShapeId == 'square' && pw != pd)) {
      return stop('Enter measured plot, stall, aisle, offset and slot opening dimensions.');
    }
    if (opening > pitch) return stop('The centred stall opening cannot be wider than the stall frontage.');
    if (entry > aisle) return stop('The frontage approach must be no wider than the central shopping aisle.');
    final row = count * pitch, width = 2 * (side + stallDepth) + aisle, depth = frontCross + row + rearCross;
    for (final (edge, clear) in [('left',left),('right',pw - left - width),('front',front),('rear',pd - front - depth)]) {
      final raw = a['${edge}_setback'], minClear = raw == null ? 0 : mm(raw,zero:true,max:2000);
      if (minClear == null || clear < minClear) return stop('The market envelope conflicts with the $edge plot edge or supplied setback.');
    }
    final rotated = facing == 'East' || facing == 'West', plotW = rotated ? pd : pw, plotD = rotated ? pw : pd;
    CadPoint point(num x, num y) {
      final u = x + left, v = y + front;
      return switch (facing) {
        'North' => CadPoint(pw-u,pd-v), 'East' => CadPoint(pd-v,u), 'West' => CadPoint(v,pw-u), _ => CadPoint(u,v),
      };
    }
    final lines = <CadLine>[], labels = <CadLabel>[];
    void line(String layer,num x,num y,num xx,num yy) {
      if (x != xx || y != yy) lines.add(CadLine(layer,point(x,y),point(xx,yy)));
    }
    void box(String layer,num x,num y,num xx,num yy) {
      line(layer,x,y,xx,y);line(layer,xx,y,xx,yy);line(layer,xx,yy,x,yy);line(layer,x,yy,x,y);
    }
    box('MARKET_PLOT',-left,-front,pw-left,pd-front);
    // Leave the entrance open across the market boundary, not a closed box.
    final entryL = (width-entry)/2, entryR = entryL+entry;
    line('MARKET_LOOP',0,0,entryL,0); line('MARKET_LOOP',entryR,0,width,0);
    line('MARKET_LOOP',width,0,width,depth); line('MARKET_LOOP',width,depth,0,depth); line('MARKET_LOOP',0,depth,0,0);
    line('MARKET_ENTRY',entryL,-front,entryL,0); line('MARKET_ENTRY',entryR,-front,entryR,0);
    final near = frontCross, far = near + row;
    final text = (math.max(plotW,plotD)/83).clamp(40,4000).toDouble();
    final stallText = math.min(text*.7,math.min(pitch,stallDepth)/4);
    for (final (prefix,back,face) in [('L',side,side+stallDepth),('R',width-side,width-side-stallDepth)]) {
      line('MARKET_STALL',back,near,back,far);
      for (var i=0;i<=count;i++) {
        final y = near+i*pitch;
        line('MARKET_STALL',back,y,face,y);
        if (i == count) continue;
        final gapStart = y+(pitch-opening)/2;
        line('MARKET_STALL',face,y,face,gapStart);
        line('MARKET_STALL',face,gapStart+opening,face,y+pitch);
        labels.add(CadLabel('MARKET_STALL',point((face+back)/2,y+pitch/2),'$prefix${i+1}',stallText));
      }
    }
    if (aisle >= text*4 && row >= text*2) {
      labels.add(CadLabel('MARKET_AISLE',point(width/2,near+row/2),'SHOPPING AISLE',math.min(text*.7,math.min(aisle/10,row/12)),
        angle:rotated ? 0 : 90));
    }
    final stalls = 2*count, stallArea = stalls*pitch*stallDepth/1e6;
    final circulation = (width*depth-stalls*pitch*stallDepth)/1e6;
    final arrowX = plotW+text*2;
    lines.addAll([
      CadLine('ANNOTATIONS',CadPoint(arrowX,plotD-text*1.7),CadPoint(arrowX,plotD)),
      CadLine('ANNOTATIONS',CadPoint(arrowX-text*.4,plotD-text*.7),CadPoint(arrowX,plotD)),
      CadLine('ANNOTATIONS',CadPoint(arrowX+text*.4,plotD-text*.7),CadPoint(arrowX,plotD)),
    ]);
    String m(num mm) => (mm/1000).toStringAsFixed(3);
    labels.addAll([
      CadLabel('ANNOTATIONS',CadPoint(arrowX,plotD+text),'N',text*.7),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*5.5),'OPEN-AIR PUBLIC MARKET / LOCAL MM',text),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*4),'$stalls STALLS / ${m(width)} x ${m(depth)} M MARKET / ${facing.toUpperCase()} ENTRY',text*.67),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*2.55),'CLEAR AISLE ${m(aisle)} M / FRONTAGE APPROACH ${m(entry)} M',text*.67),
      CadLabel('ANNOTATIONS',CadPoint(plotW/2,plotD+text*1.1),'INTERNAL CIRCULATION ${circulation.toStringAsFixed(3)} M2 / NO EGRESS CERTIFICATION',text*.6),
    ]);
    final bounds = PlanRect(math.min(-2*text,plotW/2-26*text).floor(),(-2*text).floor(),
      math.max(arrowX+2*text,plotW/2+26*text).ceil(),(plotD+7*text).ceil());
    return PublicMarketCadResult(drawing:FloorPlanCad.fromEntities(bounds:bounds,lines:lines,labels:labels),
      stalls:stalls,widthMm:width,depthMm:depth,stallAreaM2:stallArea,circulationM2:circulation);
  }
}
