import '../data/mixed_retail_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanPartition;
import 'enclosed_cad_generator.dart';
import 'retail_cad_generator.dart';

class MixedRetailCadResult {
  const MixedRetailCadResult(this.plan, this.issue,{this.zones = const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> zones;
}

/// Ground-floor side-by-side retail and dwelling. Separate circulation is a
/// geometry property, not proof of fire compartment, acoustic or access rating.
class MixedRetailCadGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['cad_output']=='mixed_shop_home';

  MixedRetailCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    MixedRetailCadResult block(String issue)=>MixedRetailCadResult(null,issue);
    final sel=brief.taxonomy, snapshot=brief.requirements;
    if (sel==null || snapshot==null || sel.version!=projectTaxonomyVersion || snapshot.version!=requirementsSchemaVersion) {
      return block('Save the mixed-use brief with the current measured requirements.');
    }
    if (sel.categoryId!='mixed_use' || sel.subcategoryId!='mixed_development' || sel.typeId!=mixedRetailCadType) {
      return block('This template is only for Residential + Retail.');
    }
    final a=snapshot.answers;
    bool positive(String name)=>a[name] is num && (a[name] as num)>0;
    if (brief.floorCount!=1 || (a['building_count']??1)!=1 || positive('basements') || positive('mezzanines') ||
        (sel.configurationId!=null && sel.configurationId!='horizontal_mixed_use')) {
      return block('Use one ground-floor horizontal shop and dwelling, without basements, mezzanines or upper floors.');
    }
    if ((sel.actionId!=null && !const {'new_design','concept_design','feasibility'}.contains(sel.actionId)) ||
        const {'existing','brownfield','partial_demolition'}.contains(a['build_status']) ||
        const {'existing','partial','renovation','demolish'}.contains(a['construction_status'])) {
      return block('The side-by-side layout is for a new concept, not retrofitting an existing shop or dwelling.');
    }
    if ((brief.parking!=null && brief.parking!=ProjectParking.none) || a['terrace_needed']=='yes' || a['parking_sqft']!=null || a['rt_rear_access']!=null) {
      return block('Shared parking, accessible terrace and rear stock access are not modelled in this mixed-use template.');
    }
    final components=a['mixed_components'], levels=a['mixed_levels'], separation=a['mixed_separation'];
    if ((components is Iterable && components.isNotEmpty && (components.toSet().length!=2 || !components.contains('housing') || !components.contains('retail'))) ||
        (levels is Iterable && levels.any((level)=>level!='ground'))) {
      return block('This layout supports one dwelling plus one shop, both on the ground floor, with no other uses.');
    }
    if (separation is Iterable && separation.any((need)=>!const {'entries','fire','acoustics','exhaust'}.contains(need))) {
      return block('The requested shared or specialist circulation/services need a different design. This layout provides independent entries only.');
    }
    if (!const {'rectangular','square'}.contains(sel.plotShapeId) || !const {'North','East','South','West'}.contains(facing)) {
      return block('Use a measured rectangular/square plot and select the cardinal shop frontage.');
    }
    final homeEntry=a['mx_home_entry'];
    if (a['mx_access']!='confirmed' || (homeEntry!='same' && homeEntry!='opposite')) {
      return block('Confirm independent access to both plot boundary entry points and choose the dwelling entrance side.');
    }
    int? mm(Object? v,{bool zero=false}) {
      if (v is! num || !v.isFinite || v<0 || v>300) return null;
      final n=(v*1000).round();
      return n>0 || zero ? n : null;
    }
    final plotW=mm(widthFt*.3048), plotD=mm(depthFt*.3048);
    final w=mm(a['cad_plate_width']), d=mm(a['cad_plate_depth']), t=mm(a['cad_wall']);
    final x=mm(a['cad_offset_left'],zero:true), y=mm(a['cad_offset_front'],zero:true);
    final retailW=mm(a['mx_retail_width']), divider=mm(a['mx_divider']);
    final shopWalk=mm(a['mx_shop_walk']), homeWalk=mm(a['mx_home_walk']);
    if (plotW==null || plotD==null || w==null || d==null || t==null || x==null || y==null || retailW==null || divider==null || shopWalk==null || homeWalk==null ||
        (sel.plotShapeId=='square' && plotW!=plotD)) {
      return block('Enter measured plot, building, offsets, wing, wall, divider and entry-walk dimensions.');
    }
    if (divider<2*t) return block('The solid divider must include both wing walls, so it cannot be thinner than twice the wall thickness.');
    final gap=divider-2*t, homeW=w-retailW-gap;
    if (homeW<=2*t || retailW<=2*t) return block('The shop, divider and dwelling leave no usable width for both wings.');
    final right=plotW-x-w,rear=plotD-y-d;
    final setbacks=<String,int>{};
    for (final (side,distance) in [('left',x),('right',right),('front',y),('rear',rear)]) {
      final raw=a['${side}_setback'];
      final inset=raw==null ? 0 : mm(raw,zero:true);
      if (inset==null || distance<inset) return block('The combined building exceeds the plot or the supplied $side setback.');
      setbacks[side]=inset;
    }
    final coverage=a['coverage_limit'], fsi=a['fsi_limit'];
    if (coverage is num && w*d>plotW*plotD*coverage/100) return block('The combined footprint exceeds the supplied plot coverage.');
    if (fsi is num && w*d>plotW*plotD*fsi) return block('The combined footprint exceeds supplied FAR/FSI.');
    final reversed=homeEntry=='opposite';
    const opposite={'South':'North','North':'South','East':'West','West':'East'};
    final homeFacing=reversed?opposite[facing]!:facing;
    if (y<=0 || (reversed && rear<=0)) return block('Each entry walk needs positive depth between the building and its plot boundary.');
    final counts=sel.spaceQuantities;
    if (counts.keys.any((id)=>!mixedDwellingRooms.any((room)=>room.id==id))) {
      return block('Add only the listed measured dwelling rooms in Spaces. The shop geometry comes from its fixture inputs; no other use, extra component or custom room is generated.');
    }
    final bedrooms=a['mx_bedrooms'];
    if (bedrooms is! int || bedrooms<1 || bedrooms>5 || bedrooms!=counts.entries.where((entry)=>mixedDwellingBedrooms.contains(entry.key)).fold(0,(sum,e)=>sum+e.value)) {
      return block('The measured bedroom quantities must match the dwelling bedroom count.');
    }
    if (counts.values.any((count)=>count<1) || counts['family_living_room']!=1 || counts['closed_kitchen']!=1 || (counts['shared_bathroom']??0)<1) {
      return block('Include one measured living room, one closed kitchen and at least one shared bathroom for the dwelling.');
    }
    if (counts.keys.any((id)=>snapshot.spaceDetails[id]?['access']=='public')) return block('Dwelling rooms cannot use the public shop route.');
    PlanRect orient(PlanRect b)=>switch(facing) {
      'North'=>PlanRect(plotW-b.right,plotD-b.top,plotW-b.left,plotD-b.bottom),
      'East'=>PlanRect(plotD-b.top,b.left,plotD-b.bottom,b.right),
      'West'=>PlanRect(b.bottom,plotW-b.right,b.top,plotW-b.left),
      _=>b,
    };
    final footprint=orient(PlanRect(x,y,x+w,y+d));
    double m(int mm)=>mm/1000;
    // Typed sub-briefs are generated only in memory. They share the caller's
    // survey and measurements; the persisted brief remains the mixed use one.
    ProjectBrief wing({required bool home}) {
      return ProjectBrief(floorCount:1,parking:ProjectParking.none,features:const [],
        taxonomy:TaxonomySelection(version:sel.version,categoryId:home?'residential':'commercial',subcategoryId:home?'houses':'retail',
          typeId:home?'independent_house':'shop',plotShapeId:sel.plotShapeId,actionId:sel.actionId,spaceQuantities:home?counts:const {}),
        requirements:ProjectRequirementsSnapshot(version:snapshot.version,answers:{
          ...a,'cad_plate_width':m(home?homeW:retailW),
          'cad_offset_left':m(!home?x:reversed?right:x+retailW+gap),
          'cad_offset_front':m(home && reversed?rear:y),
          if (home) ...{'bedrooms':bedrooms,'kitchen_type':'closed'} else 'shop_count':1,
          if (home && reversed) ...{'left_setback':m(setbacks['right']!),'right_setback':m(setbacks['left']!),
            'front_setback':m(setbacks['rear']!),'rear_setback':m(setbacks['front']!)},
        },spaceDetails:home?snapshot.spaceDetails:const {}));
    }
    final retail=RetailCadGenerator().generate(wing(home:false),widthFt:widthFt,depthFt:depthFt,facing:facing);
    if (retail.plan==null) return block('Shop: ${retail.issue}');
    bool trueExterior(PlanOpening o) {
      if (o.kind!=PlanOpeningKind.window) return true;
      final b=o.bounds;
      return b.left==footprint.left || b.right==footprint.right || b.bottom==footprint.bottom || b.top==footprint.top;
    }
    final enclosed=EnclosedCadGenerator().generate(wing(home:true),widthFt:widthFt,depthFt:depthFt,facing:homeFacing,
      extraAcceptance:(plan)=>plan.openings.every(trueExterior));
    if (enclosed.sheets.isEmpty) return block('Dwelling: ${enclosed.issues.join(' ')} Any window must open to a true exterior, not into the divider.');
    final shop=retail.plan!,home=enclosed.sheets.single.plan;
    const outside=AutomaticFloorPlan.entry;
    PlanRect walkFor(AutomaticFloorPlan plan,int width) {
      final b=plan.openings.singleWhere((o)=>o.from==outside && o.kind==PlanOpeningKind.door).bounds;
      final p=plan.plot;
      final horizontal=plan.facing=='North'||plan.facing=='South';
      final along=horizontal?b.width:b.depth;
      if (width<along) return PlanRect(0,0,0,0);
      if (horizontal) {
        final start=b.left-(width-along)~/2;
        return plan.facing=='North'?PlanRect(start,b.top,start+width,p.top):PlanRect(start,p.bottom,start+width,b.bottom);
      }
      final start=b.bottom-(width-along)~/2;
      return plan.facing=='East'?PlanRect(b.right,start,p.right,start+width):PlanRect(p.left,start,b.left,start+width);
    }
    final publicPath=walkFor(shop,shopWalk), privatePath=walkFor(home,homeWalk);
    final paths=[publicPath,privatePath];
    if (paths.any((path)=>path.width<=0 || path.depth<=0 || !shop.plot.contains(path) || path.overlaps(footprint))) {
      return block('An entry walk is narrower than its door, beyond the plot boundary or blocked by the building.');
    }
    if (publicPath.overlaps(privatePath)) return block('The two entry walks overlap. Reduce their measured widths or choose opposite entry sides.');
    String homeId(String id)=>id==outside ? id : 'dwelling_$id';
    final combined=AutomaticFloorPlan(plot:shop.plot,footprint:footprint,facing:facing,sheetTitle:'RESIDENTIAL + RETAIL / INDEPENDENT ENTRIES',
      rooms:[...shop.rooms,...home.rooms.map((r)=>PlanRoom(homeId(r.id),r.id=='internal_passage'?'Private home passage':r.label,r.bounds))],
      walls:[...shop.walls,...home.walls,if(gap>0) orient(PlanRect(x+retailW,y,x+retailW+gap,y+d))],
      openings:[...shop.openings,...home.openings.map((o)=>PlanOpening(o.kind,o.bounds,homeId(o.from),homeId(o.to)))]);
    final issue=validatePlanPartition(combined);
    if (issue!=null) return block('The combined drawing failed geometry validation: $issue');
    final dividerBounds=orient(PlanRect(x+retailW-t,y,x+retailW+gap+t,y+d));
    return MixedRetailCadResult(combined,null,zones:List.unmodifiable([
      ...retail.zones,MeasuredZone('mx_shop_walk','Shop walk',publicPath,'MIXED_SHOP_ACCESS'),
      MeasuredZone('mx_home_walk','Home walk',privatePath,'MIXED_HOME_ACCESS'),
      MeasuredZone('mx_divider','Solid divider',dividerBounds,'MIXED_DIVIDER'),
    ]));
  }
}
