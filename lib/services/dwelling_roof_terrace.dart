import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;
import 'tower_plan_generator.dart';

/// Draft plan only. These dimensions do not validate headroom, structural or
/// waterproofing details, parapet height, drainage or safe use.
({TowerSheet? sheet,String? issue,int headArea}) dwellingRoofTerrace(TowerSheet first,StraightStairSpec stair,{
  required int wall,required int door,required int parapet,required int walkWidth,
  required int deckWidth,required int deckDepth,required double areaLimitSqft,required double targetSqft,
}) {
  ({TowerSheet? sheet,String? issue,int headArea}) block(String issue)=>(sheet:null,issue:issue,headArea:0);
  final plan=first.plan, plate=plan.footprint;
  final rotated=plan.facing=='East'||plan.facing=='West';
  final w=rotated?plate.depth:plate.width,d=rotated?plate.width:plate.depth;
  PlanRect orient(PlanRect b) {
    final r=switch(plan.facing) {
      'North'=>PlanRect(w-b.right,d-b.top,w-b.left,d-b.bottom),
      'East'=>PlanRect(d-b.top,b.left,d-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,w-b.right,b.top,w-b.left),
      _=>b,
    };
    return PlanRect(r.left+plate.left,r.bottom+plate.bottom,r.right+plate.left,r.top+plate.bottom);
  }
  PlanRect local(PlanRect b) {
    final r=PlanRect(b.left-plate.left,b.bottom-plate.bottom,b.right-plate.left,b.top-plate.bottom);
    return switch(plan.facing) {
      'North'=>PlanRect(w-r.right,d-r.top,w-r.left,d-r.bottom),
      'East'=>PlanRect(r.bottom,d-r.right,r.top,d-r.left),
      'West'=>PlanRect(w-r.top,r.left,w-r.bottom,r.right),
      _=>r,
    };
  }
  final flight=local(plan.rooms.singleWhere((r)=>r.id=='stair_1').bounds);
  final hall=local(plan.rooms.singleWhere((r)=>r.id=='internal_passage').bounds);
  if (parapet>wall || walkWidth<door || walkWidth>hall.width || deckWidth<walkWidth) {
    return block('Terrace walk must span the door, fit within the aligned passage width and connect to the deck. Roof parapet thickness cannot exceed the wall in this template.');
  }
  final head=PlanRect(flight.left-wall,flight.bottom-wall,flight.right+wall,flight.top+wall);
  final inside=PlanRect(parapet,parapet,w-parapet,d-parapet);
  if (!PlanRect(0,0,w,d).contains(head) || !inside.contains(flight)) return block('The roof stair enclosure does not fit inside the roof edge.');
  final atLeft=flight.right<=hall.left;
  if (atLeft ? head.right!=hall.left : head.left!=hall.right) return block('The terrace stair does not align with the shared passage.');
  final dy=flight.top-stair.landing+(stair.landing-door)~/2;
  final doorBounds=atLeft?PlanRect(flight.right,dy,head.right,dy+door):PlanRect(head.left,dy,flight.left,dy+door);
  final wx=atLeft?hall.left:hall.right-walkWidth;
  final dx=wx+(walkWidth-deckWidth)~/2;
  final walk=PlanRect(wx,dy,wx+walkWidth,head.top);
  final deck=PlanRect(dx,head.top,dx+deckWidth,head.top+deckDepth);
  if (!inside.contains(walk) || !inside.contains(deck) || head.overlaps(walk) || head.overlaps(deck) ||
      walk.left<deck.left || walk.right>deck.right) return block('The measured terrace deck and its stair-head walk do not fit clear of the enclosure and parapet.');
  final deckSqft=deck.area/92903.04;
  final totalSqft=(deck.area+walk.area)/92903.04;
  if (deckSqft+.001<targetSqft || totalSqft>areaLimitSqft+.001) {
    return block('The measured open deck must meet the requested area, and deck plus walk must fit the available terrace area.');
  }
  final walls=[PlanRect(0,0,w,parapet),PlanRect(0,d-parapet,w,d),
    PlanRect(0,parapet,parapet,d-parapet),PlanRect(w-parapet,parapet,w,d-parapet)];
  void wallPart(PlanRect r) {
    final b=PlanRect(r.left<inside.left?inside.left:r.left,r.bottom<inside.bottom?inside.bottom:r.bottom,
      r.right>inside.right?inside.right:r.right,r.top>inside.top?inside.top:r.top);
    if (b.width>0 && b.depth>0) walls.add(b);
  }
  wallPart(PlanRect(head.left,head.bottom,head.right,flight.bottom));
  wallPart(PlanRect(head.left,flight.top,head.right,head.top));
  for (final (l,r,split) in [(head.left,flight.left,!atLeft),(flight.right,head.right,atLeft)]) {
    if (split) {
      wallPart(PlanRect(l,flight.bottom,r,dy)); wallPart(PlanRect(l,dy+door,r,flight.top));
    } else { wallPart(PlanRect(l,flight.bottom,r,flight.top)); }
  }
  // Partition only the clear roof area. Mark residual pieces as unallocated;
  // they are not verified for usable access or occupancy.
  List<PlanRect> subtract(PlanRect block,PlanRect cut) {
    if (!block.overlaps(cut)) return [block];
    final l=block.left>cut.left?block.left:cut.left, r=block.right<cut.right?block.right:cut.right;
    final b=block.bottom>cut.bottom?block.bottom:cut.bottom, t=block.top<cut.top?block.top:cut.top;
    return [PlanRect(block.left,block.bottom,l,block.top),PlanRect(r,block.bottom,block.right,block.top),
      PlanRect(l,block.bottom,r,b),PlanRect(l,t,r,block.top)].where((room)=>room.width>0 && room.depth>0).toList();
  }
  var residual=[inside];
  for (final used in [head,walk,deck]) { residual=residual.expand((r)=>subtract(r,used)).toList(); }
  (int,int) point(int x,int y){final b=orient(PlanRect(x,y,x,y));return(b.left,b.bottom);}
  final roof=AutomaticFloorPlan(plot:plan.plot,footprint:plate,facing:plan.facing,sheetTitle:'G+1 / OPEN ROOF TERRACE',
    rooms:[PlanRoom('stair_1','Terrace stair enclosure',orient(flight)),PlanRoom('roof_walk','Terrace walk',orient(walk)),
      PlanRoom('roof_deck','Open terrace',orient(deck)),
      for(var i=0;i<residual.length;i++) PlanRoom('reserve_roof_$i','Unallocated roof reserve',orient(residual[i]))],
    walls:walls.map(orient),openings:[PlanOpening(PlanOpeningKind.door,orient(doorBounds),'roof_walk','stair_1')],
    stairs:[stair.drawing('stair_1',flight,false,point)]);
  final issue=validatePlanPartition(roof);
  if (issue!=null) return block('Terrace drawing failed fit validation: $issue');
  return (sheet:TowerSheet('Open terrace','Roof terrace',3,3,roof,residual.fold<int>(0,(sum,r)=>sum+r.area),siteZones:[
    MeasuredZone('roof_deck','Open terrace',orient(deck),'TERRACE_DECK'),
    MeasuredZone('roof_walk','Terrace walk',orient(walk),'TERRACE_ACCESS'),
  ]),issue:null,headArea:head.area);
}
