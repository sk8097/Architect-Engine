import '../data/mixed_retail_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry,validatePlanPartition;
import 'enclosed_cad_generator.dart';
import 'retail_cad_generator.dart';
import 'tower_plan_generator.dart';

/// One retail unit below one dwelling. The two occupied wings have no
/// internal ground-floor connection; an aligned stair strip serves the home.
class StackedRetailCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='mixed_shop_below_home';

  TowerResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    TowerResult block(String issue)=>TowerResult(const [],[issue]);
    final sel=brief.taxonomy, snapshot=brief.requirements;
    if (sel==null || snapshot==null || sel.version!=projectTaxonomyVersion || snapshot.version!=requirementsSchemaVersion) {
      return block('Save the mixed-use brief with the current measured requirements.');
    }
    if (sel.categoryId!='mixed_use' || sel.subcategoryId!='mixed_development' || sel.typeId!=mixedRetailCadType) {
      return block('This vertical shop and home template is for Residential + Retail only.');
    }
    final a=snapshot.answers;
    bool positive(String id)=>a[id] is num && (a[id] as num)>0;
    if (brief.floorCount!=2 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
        !const {null,'vertical_mixed_use'}.contains(sel.configurationId)) {
      return block('A stacked shop and home requires two floors: ground-floor shop and first-floor dwelling in one vertical building.');
    }
    if (!const {null,'new_design','concept_design','feasibility'}.contains(sel.actionId) ||
        const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return block('Use this for a new mixed-use concept, not surveyed alterations or approval drawings.');
    }
    if (!const {null,ProjectParking.none}.contains(brief.parking) || a['parking_sqft']!=null || a['terrace_needed']=='yes' ||
        a['rt_rear_access']!=null || !const {null,'none'}.contains(a['lift_plan']) ||
        !const {null,'inside'}.contains(a['stair_access']) || !const {null,'straight'}.contains(a['stair_form'])) {
      return block('This template draws one dedicated straight indoor stair, without a lift, parking, terrace or rear shop access.');
    }
    final components=a['mixed_components'], levels=a['mixed_levels'], needs=a['mixed_separation'];
    if ((components is Iterable && components.isNotEmpty && !({'housing','retail'}.containsAll(components) && components.toSet().length==2)) ||
        (levels is Iterable && levels.isNotEmpty && !({'ground','housing'}.containsAll(levels) && levels.toSet().length==2))) {
      return block('Use only Retail on public ground and Housing on the first floor.');
    }
    if (needs is Iterable && needs.any((v)=>!const {'entries','fire','acoustics','exhaust'}.contains(v))) {
      return block('A separate lobby, lift bank, shared utilities or loading and waste design is not included in this layout.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return block('Use a rectangular or square measured plot and a cardinal shop frontage.');
    }
    if (a['ms_access']!='confirmed') return block('Confirm independent shop and home access at the two frontage entry points.');
    int? mm(Object? v,{bool zero=false}) {
      if (v is! num || !v.isFinite || v<0 || v>300) return null;
      final n=(v*1000).round();
      return n>0 || zero ? n : null;
    }
    final plotW=mm(widthFt*.3048),plotD=mm(depthFt*.3048);
    final w=mm(a['cad_plate_width']),d=mm(a['cad_plate_depth']),t=mm(a['cad_wall']);
    final x=mm(a['cad_offset_left'],zero:true),y=mm(a['cad_offset_front'],zero:true),door=mm(a['cad_door']);
    final shopWalk=mm(a['mx_shop_walk']),homeWalk=mm(a['mx_home_walk']);
    if (plotW==null || plotD==null || w==null || d==null || t==null || x==null || y==null || door==null || shopWalk==null || homeWalk==null ||
        (sel.plotShapeId=='square' && plotW!=plotD)) return block('Enter measured plot, plate, offsets, wall, home door and both walk widths.');
    if (y==0) return block('Independent entry walks need space between the frontage and the building.');
    final right=plotW-x-w,rear=plotD-y-d;
    final setbacks=<String,int>{};
    for (final (side,available) in [('left',x),('right',right),('front',y),('rear',rear)]) {
      final raw=a['${side}_setback'], s=raw==null?0:mm(raw,zero:true);
      if (s==null || available<s) return block('The common floor plate conflicts with the plot boundary or $side setback.');
      setbacks[side]=s;
    }
    final fsi=a['fsi_limit'], coverage=a['coverage_limit'];
    if (fsi is num && 2*w*d>plotW*plotD*fsi) return block('Both gross floor plates together exceed the supplied FAR/FSI allowance.');
    if (coverage is num && w*d>plotW*plotD*coverage/100) return block('The footprint exceeds the supplied coverage allowance.');
    final sw=mm(a['g1_width']),h=mm(a['g1_height']),going=mm(a['g1_going']),landing=mm(a['g1_landing']);
    final risers=a['g1_risers'];
    if (sw==null || h==null || going==null || landing==null || risers is! int || risers<2 || risers>50) {
      return block('Enter measured private stair width, rise, 2–50 risers, going and both end landings.');
    }
    if (door<=2*t || sw<=door || landing<door) return block('The stair and both landings must fit the door swing; the landing doorway must be wider than both adjoining walls combined.');
    final spec=StraightStairSpec(risers:risers,going:going,landing:landing,height:h);
    final shopWidth=w-sw-2*t;
    if (shopWidth<=2*t) return block('The stair strip leaves no usable shop or dwelling width.');
    final counts=sel.spaceQuantities;
    if (counts.keys.any((id)=>!mixedDwellingRoomIds.contains(id))) return block('Select only the measured first-floor dwelling rooms. The shop is drawn from its fixture measurements.');
    final beds=a['mx_bedrooms'];
    if (beds is! int || beds<1 || beds>5 || beds!=counts.entries.where((e)=>mixedDwellingBedrooms.contains(e.key)).fold(0,(n,e)=>n+e.value)) {
      return block('The measured bedroom quantity must match the dwelling bedroom count.');
    }
    if (counts.values.any((n)=>n<1) || counts['family_living_room']!=1 || counts['closed_kitchen']!=1 || (counts['shared_bathroom']??0)<1) {
      return block('Include one measured living room, one closed kitchen and at least one shared bathroom.');
    }
    final homeDetails=<String,Map<String,Object>>{};
    for (final id in counts.keys) {
      final detail=snapshot.spaceDetails[id]??const <String,Object>{};
      if (detail['floor_level']!='1') return block('Assign each measured dwelling room to the first floor above the shop.');
      if (const {'public','semi_public'}.contains(detail['access'])) return block('Dwelling rooms must not use the public shop route.');
      final edge=detail['zone_edge'];
      if (edge=='right') return block('The right side contains the enclosed stair strip. Select a true exterior edge for the dwelling room.');
      // The domestic passage approaches from the right of the shop wing;
      // rotate explicit plot-relative edge preferences into that frame.
      homeDetails[id]={...detail,'floor_level':'0',if(edge!=null) 'zone_edge':switch(edge) {
        'front'=>'left','rear'=>'right','left'=>'rear',_=>edge,
      }};
    }
    final joint=x+shopWidth, exterior=x+w, top=y+d;
    double m(int value)=>value/1000;
    ProjectBrief subBrief(bool home)=>ProjectBrief(floorCount:1,parking:ProjectParking.none,features:const [],
      taxonomy:TaxonomySelection(version:sel.version,categoryId:home?'residential':'commercial',subcategoryId:home?'houses':'retail',
        typeId:home?'independent_house':'shop',plotShapeId:sel.plotShapeId,actionId:sel.actionId,spaceQuantities:home?counts:const {}),
      requirements:ProjectRequirementsSnapshot(version:snapshot.version,spaceDetails:home?homeDetails:const {},answers:{
        ...a,'cad_plate_width':m(home?d:shopWidth),'cad_plate_depth':m(home?shopWidth:d),
        'cad_offset_left':m(home?y:x),'cad_offset_front':m(home?plotW-joint:y),
        if(home) ...{'bedrooms':beds,'kitchen_type':'closed','left_setback':m(setbacks['front']!),'right_setback':m(setbacks['rear']!),
          'front_setback':m(setbacks['right']!),'rear_setback':m(setbacks['left']!)} else 'shop_count':1,
      }));
    final retail=RetailCadGenerator().generate(subBrief(false),widthFt:widthFt,depthFt:depthFt,facing:'South');
    if (retail.plan==null) return block('Shop: ${retail.issue}');
    final house=EnclosedCadGenerator().generate(subBrief(true),widthFt:depthFt,depthFt:widthFt,facing:'East');
    if (house.sheets.isEmpty) return block('Upper dwelling: ${house.issues.join(' ')}');
    final home=house.sheets.single.plan, shop=retail.plan!;
    const outside=AutomaticFloorPlan.entry, stairId='stair_0';
    final homeDoor=home.openings.singleWhere((o)=>o.from==outside&&o.kind==PlanOpeningKind.door);
    final dx=joint+t,rightX=exterior-t,frontY=y+t,backY=top-t;
    final flightEnd=homeDoor.bounds.bottom-(landing-door)~/2+landing,flightStart=flightEnd-spec.depth;
    if (flightStart<frontY || flightEnd>backY || (flightStart>frontY && flightStart-frontY<t) || (flightEnd<backY && backY-flightEnd<t)) {
      return block('The straight flight and both landings do not align with the first-floor passage inside the measured stair strip. Check the floor depth and stair run.');
    }
    final flight=PlanRect(dx,flightStart,rightX,flightEnd);
    final frontDoorX=dx+(sw-door)~/2;
    final privateDoor=PlanRect(frontDoorX,y,frontDoorX+door,frontY);
    final shopDoor=shop.openings.singleWhere((o)=>o.from==outside&&o.kind==PlanOpeningKind.door).bounds;
    PlanRect walk(PlanRect b,int width) {
      final start=b.left-(width-b.width)~/2;
      return PlanRect(start,0,start+width,y);
    }
    final publicPath=walk(shopDoor,shopWalk),privatePath=walk(privateDoor,homeWalk);
    if (shopWalk<shopDoor.width || homeWalk<door || !shop.plot.contains(privatePath) || !shop.plot.contains(publicPath) || privatePath.overlaps(publicPath)) {
      return block('The frontage walks must span their doors, fit within the plot and not overlap.');
    }
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),_=>b,
    };
    (int,int) point(int x,int y) {final p=orient(PlanRect(x,y,x,y));return(p.left,p.bottom);}
    final footprint=orient(PlanRect(x,y,exterior,top)), plot=orient(shop.plot);
    final sheets=<TowerSheet>[];
    for(final upper in [false,true]) {
      final wing=upper?home:shop;
      final rooms=[...wing.rooms,PlanRoom(stairId,upper?'Private stair landing':'Private access and stair',
        upper?flight:PlanRect(dx,frontY,rightX,flightEnd))];
      final walls=[...wing.walls,PlanRect(rightX,frontY,exterior,backY),PlanRect(joint,backY,exterior,top)];
      final openings=[for(final o in wing.openings) if(!upper || o!=homeDoor) o];
      if (upper) {
        final b=homeDoor.bounds;
        walls.addAll([PlanRect(joint,y,exterior,frontY),PlanRect(joint,frontY,dx,b.bottom),PlanRect(joint,b.top,dx,backY)]);
        openings.add(PlanOpening(PlanOpeningKind.door,PlanRect(b.left,b.bottom,dx,b.top),stairId,homeDoor.to));
        if (flightStart>frontY) {
          walls.add(PlanRect(dx,flightStart-t,rightX,flightStart));
          if(flightStart-t>frontY) rooms.add(PlanRoom('reserve_stair_front','Sealed stair-strip reserve',PlanRect(dx,frontY,rightX,flightStart-t)));
        }
      } else {
        walls.addAll([PlanRect(joint,frontY,dx,backY),PlanRect(joint,y,privateDoor.left,frontY),PlanRect(privateDoor.right,y,exterior,frontY)]);
        openings.add(PlanOpening(PlanOpeningKind.door,privateDoor,outside,stairId));
      }
      if(flightEnd<backY) {
        walls.add(PlanRect(dx,flightEnd,rightX,flightEnd+t));
        if(flightEnd+t<backY) rooms.add(PlanRoom('reserve_stair_rear','Sealed stair-strip reserve',PlanRect(dx,flightEnd+t,rightX,backY)));
      }
      final plan=AutomaticFloorPlan(plot:plot,footprint:footprint,facing:facing,
        sheetTitle:upper?'FIRST FLOOR / PRIVATE DWELLING':'GROUND FLOOR / SHOP AND PRIVATE STAIR',
        rooms:rooms.map((r)=>PlanRoom(r.id,r.label,orient(r.bounds))),walls:walls.map(orient),
        openings:openings.map((o)=>PlanOpening(o.kind,orient(o.bounds),o.from,o.to)),
        stairs:[spec.drawing(stairId,flight,!upper,point)]);
      final reserves=rooms.where((r)=>r.id.startsWith('reserve_')).toList();
      // Both ground networks are independently generated and joined only as
      // disjoint partitions. Upper starts from its internal stair landing.
      final issue=upper?validatePlanGeometry(plan,indoorSeed:stairId,sealedRooms:reserves.map((r)=>r.id).toSet()):validatePlanPartition(plan);
      if (issue!=null) return block('The ${upper?'first':'ground'} floor failed geometry validation: $issue');
      sheets.add(TowerSheet(upper?'Private dwelling':'Retail and private stair',upper?'First floor':'Ground floor',upper?2:1,upper?2:1,
        plan,reserves.fold<int>(0,(n,r)=>n+r.bounds.area),siteZones:upper?const []:[
          for(final z in retail.zones) MeasuredZone(z.id,z.name,orient(z.bounds),z.layer),
          MeasuredZone('mx_shop_walk','Shop walk',orient(publicPath),'MIXED_SHOP_ACCESS'),
          MeasuredZone('mx_home_walk','Private home walk',orient(privatePath),'MIXED_HOME_ACCESS'),
          MeasuredZone('mx_ground_divider','Solid stair divider',orient(PlanRect(joint-t,y,dx,top)),'MIXED_DIVIDER'),
      ]));
    }
    return TowerResult(List.unmodifiable(sheets),const []);
  }
}
