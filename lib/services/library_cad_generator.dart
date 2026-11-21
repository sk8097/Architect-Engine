import '../data/library_cad_fields.dart';
import '../data/project_requirements.dart';
import '../data/project_taxonomy.dart';
import '../models/automatic_floor_plan.dart';
import '../models/concept_zoning.dart';
import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'automatic_floor_plan_generator.dart' show validatePlanGeometry;
import 'enclosed_cad_generator.dart';

class LibraryCadResult {
  const LibraryCadResult(this.plan,this.issue,{this.fixtures=const []});
  final AutomaticFloorPlan? plan;
  final String? issue;
  final List<MeasuredZone> fixtures;
}

/// A branch library layout with a deliberate quiet threshold, measured
/// open shelving and a row of quiet study desks. Not an acoustics assessment.
class LibraryCadGenerator {
  static bool requested(ProjectBrief? brief)=>brief?.requirements?.answers['cad_output']=='library_reading';
  static const _hall='internal_passage',_public='library_public_route',_quiet='library_quiet_route';

  LibraryCadResult generate(ProjectBrief brief,{required double widthFt,required double depthFt,required String facing}) {
    LibraryCadResult stop(String issue)=>LibraryCadResult(null,issue);
    final sel=brief.taxonomy,snap=brief.requirements;
    if(sel==null || snap==null || sel.version!=projectTaxonomyVersion || snap.version!=requirementsSchemaVersion) {
      return stop('Save the library brief with the current measured requirements.');
    }
    if(!libraryCadEligible(sel.categoryId,sel.subcategoryId,sel.typeId)) return stop('Use an Education Library or a Public Library for this layout.');
    if(sel.configurationId!=null && sel.configurationId!=(sel.typeId=='library'?'single_building':'main_hall')) {
      return stop('Use a single library building. Multiple halls, blocks and outdoor program are not drawn here.');
    }
    final counts=sel.spaceQuantities,labels={for(final r in libraryCadRooms)r.id:r.label};
    if(const ['lib_checkout','lib_stacks','lib_reading'].any((id)=>counts[id]!=1) ||
        counts.entries.any((e)=>!labels.containsKey(e.key)||e.value!=1)) {
      return stop('Include one Checkout/Return, Open Book Stacks and Quiet Reading room. Children’s reading, staff book processing and a toilet reserve are optional single rooms.');
    }
    final details=<String,Map<String,Object>>{};
    for(final id in counts.keys) {
      final room=snap.spaceDetails[id]??const <String,Object>{};
      final access=room['access'];
      if(access!=null && (id=='lib_processing')==const {'public','semi_public'}.contains(access)) {
        return stop('${labels[id]} has an access request that conflicts with the public library layout. Book processing is staff-only.');
      }
      if(id=='lib_checkout' && !const {null,'any','front'}.contains(room['zone_edge'])) return stop('Checkout/return must be on the front edge of the library.');
      details[id]={...room, if(id=='lib_checkout') 'zone_edge':'front'};
    }
    final a=snap.answers;
    int? mm(String key) {
      final v=a[key];
      if(v is! num || !v.isFinite || v<=0 || v>300) return null;
      final n=(v*1000).round();
      return n>0?n:null;
    }
    final front=mm('lib_front_depth'),wall=mm('cad_wall'),door=mm('cad_door');
    final rangeW=mm('lib_shelf_width'),rangeL=mm('lib_shelf_length'),stackAisle=mm('lib_stack_aisle');
    final readSpan=mm('lib_read_span'),readDepth=mm('lib_read_depth'),chair=mm('lib_chair_depth'),readAisle=mm('lib_read_aisle');
    final ranges=a['lib_ranges'],seats=a['lib_read_count'];
    if(front==null || wall==null || door==null || rangeW==null || rangeL==null || stackAisle==null ||
        readSpan==null || readDepth==null || chair==null || readAisle==null ||
        ranges is! int || ranges<1 || ranges>30 || seats is! int || seats<1 || seats>100) {
      return stop('Enter measured walls, openings, front passage, shelving and reading furnishings, plus both whole-number counts.');
    }
    if(front<door || stackAisle<door || readAisle<door) return stop('The public passage and both furniture aisles must span the supplied door width.');
    // Put checkout first, front rooms next and quiet last. Keep the user's
    // dimensional and relationship constraints in the common enclosure solver.
    final sortedCounts={for(final room in libraryCadRooms) if(counts.containsKey(room.id) && room.id!='lib_reading') room.id:1,'lib_reading':1};
    final libraryBrief=ProjectBrief(floorCount:brief.floorCount,parking:brief.parking,features:brief.features,
      taxonomy:TaxonomySelection(version:sel.version,categoryId:sel.categoryId,subcategoryId:sel.subcategoryId,typeId:sel.typeId,
        actionId:sel.actionId,configurationId:sel.configurationId,plotShapeId:sel.plotShapeId,spaceQuantities:sortedCounts),
      requirements:ProjectRequirementsSnapshot(version:snap.version,answers:a,customSpaces:labels,spaceDetails:details));
    LibraryCadResult? fitted;
    var hasRoutes=false,hasStacks=false;
    final result=EnclosedCadGenerator().generate(libraryBrief,widthFt:widthFt,depthFt:depthFt,facing:facing,
      roomOrder:(id)=>sortedCounts.keys.toList().indexOf(id),
      roomTypeAcceptance:(shell,ids) {
        final plan=_split(shell,ids,front,wall,door);
        if(plan==null) return false;
        hasRoutes=true;
        PlanRoom room(String id)=>plan.rooms.singleWhere((r)=>ids[r.id]==id);
        PlanOpening entry(PlanRoom room)=>plan.openings.singleWhere((o)=>o.kind==PlanOpeningKind.door&&o.to==room.id);
        final stacks=room('lib_stacks'),reading=room('lib_reading');
        final shelfZones=_stacks(_Frame(stacks.bounds,facing),entry(stacks).bounds,ranges,rangeW,rangeL,stackAisle);
        if(shelfZones==null) return false;
        hasStacks=true;
        final readingZones=_reading(_Frame(reading.bounds,facing),entry(reading).bounds,seats,readSpan,readDepth,chair,readAisle);
        if(readingZones==null) return false;
        fitted=LibraryCadResult(plan,null,fixtures:List.unmodifiable([...shelfZones,...readingZones]));
        return true;
      });
    if(result.sheets.isNotEmpty && fitted!=null) return fitted!;
    return stop('${result.issues.join(' ')} ${!hasRoutes
      ? 'Checkout, stacks and any front support doors must open before the threshold, and quiet reading beyond it.'
      : !hasStacks ? 'The measured shelf ranges and clear aisles do not fit on both sides of the stack door.'
      : 'The requested quiet reading desks, chair clearances and aisle do not fit the measured room.'}');
  }

  AutomaticFloorPlan? _split(AutomaticFloorPlan shell,Map<String,String> ids,int front,int wall,int door) {
    final f=_Frame(shell.rooms.singleWhere((room)=>room.id==_hall).bounds,shell.facing);
    final centre=(f.width-door)~/2,after=front+wall;
    if(centre<1 || f.width-centre-door<1 || f.depth-after<door) return null;
    final openings=<PlanOpening>[];
    for(final o in shell.openings) {
      if(o.to==_hall) {openings.add(PlanOpening(o.kind,o.bounds,o.from,_public));}
      else if(o.from==_hall) {
        final quiet=ids[o.to]=='lib_reading';
        final (begin,end)=f.along(o.bounds);
        if(quiet?begin<after:end>front) return null;
        openings.add(PlanOpening(o.kind,o.bounds,quiet?_quiet:_public,o.to));
      } else {openings.add(o);}
    }
    openings.add(PlanOpening(PlanOpeningKind.door,f.rect(centre,front,centre+door,after),_public,_quiet));
    final plan=AutomaticFloorPlan(plot:shell.plot,footprint:shell.footprint,facing:shell.facing,
      sheetTitle:'LIBRARY / COLLECTIONS & QUIET STUDY',
      rooms:[...shell.rooms.where((r)=>r.id!=_hall),PlanRoom(_public,'Public library passage',f.rect(0,0,f.width,front)),
        PlanRoom(_quiet,'Quiet reading passage',f.rect(0,after,f.width,f.depth))],
      walls:[...shell.walls,f.rect(0,front,centre,after),f.rect(centre+door,front,f.width,after)],openings:openings);
    final reserves=plan.rooms.where((r)=>r.id.startsWith('reserve_')).map((r)=>r.id).toSet();
    return validatePlanGeometry(plan,sealedRooms:reserves)==null?plan:null;
  }

  List<MeasuredZone>? _stacks(_Frame f,PlanRect entry,int count,int width,int run,int aisle) {
    const access='LIBRARY_STACK_AISLES',shelves='LIBRARY_SHELVES';
    final requiredWidth=count*width+(count+1)*aisle;
    final (start,end)=f.along(entry);
    final b=start-(aisle-(end-start))~/2,t=b+aisle;
    if(requiredWidth>f.width || b-run<0 || t+run>f.depth || b>start || t<end) return null;
    final x=(f.width-requiredWidth)~/2;
    return [
      MeasuredZone('lib_stack_cross','Stack cross-aisle',f.rect(0,b,f.width,t),access),
      for(final (bank,y) in [('front',b-run),('rear',t)])
        for(var i=0;i<=count;i++) ...[
          MeasuredZone('lib_${bank}_aisle_$i','Clear shelf aisle',f.rect(x+i*(width+aisle),y,x+i*(width+aisle)+aisle,y+run),access),
          if(i<count)
            MeasuredZone('lib_${bank}_shelf_$i','Shelf range ${i+1}',f.rect(x+i*(width+aisle)+aisle,y,x+(i+1)*(width+aisle),y+run),shelves),
        ],
    ];
  }

  List<MeasuredZone>? _reading(_Frame f,PlanRect entry,int count,int span,int depth,int chair,int aisle) {
    if(aisle+chair+depth>f.width || span*count>f.depth) return null;
    final (a,b)=f.across(entry);
    if(b!=0 && a!=f.width) return null;
    final mirror=a==f.width;
    PlanRect rect(int l,int j,int r,int e)=>mirror?f.rect(f.width-r,j,f.width-l,e):f.rect(l,j,r,e);
    final start=(f.depth-count*span)~/2;
    return [
      MeasuredZone('lib_read_walk','Reading aisle',rect(0,0,aisle,f.depth),'LIBRARY_STUDY_AISLE'),
      for(var i=0;i<count;i++) ...[
        MeasuredZone('lib_read_chair_$i','Chair clearance',rect(aisle,start+i*span,aisle+chair,start+(i+1)*span),'LIBRARY_CHAIR_CLEAR'),
        MeasuredZone('lib_read_desk_$i','Study desk ${i+1}',rect(aisle+chair,start+i*span,aisle+chair+depth,start+(i+1)*span),'LIBRARY_DESKS'),
      ],
    ];
  }
}

class _Frame {
  const _Frame(this.b,this.facing);
  final PlanRect b;
  final String facing;
  bool get rotated=>facing=='East'||facing=='West';
  int get width=>rotated?b.depth:b.width;
  int get depth=>rotated?b.width:b.depth;
  PlanRect rect(int l,int f,int r,int d)=>switch(facing) {
    'North'=>PlanRect(b.right-r,b.top-d,b.right-l,b.top-f),
    'East'=>PlanRect(b.right-d,b.bottom+l,b.right-f,b.bottom+r),
    'West'=>PlanRect(b.left+f,b.top-r,b.left+d,b.top-l),
    _=>PlanRect(b.left+l,b.bottom+f,b.left+r,b.bottom+d),
  };
  (int,int) along(PlanRect r)=>switch(facing) {
    'North'=>(b.top-r.top,b.top-r.bottom),'East'=>(b.right-r.right,b.right-r.left),
    'West'=>(r.left-b.left,r.right-b.left),_=>(r.bottom-b.bottom,r.top-b.bottom),
  };
  (int,int) across(PlanRect r)=>switch(facing) {
    'North'=>(b.right-r.right,b.right-r.left),'East'=>(r.bottom-b.bottom,r.top-b.bottom),
    'West'=>(b.top-r.top,b.top-r.bottom),_=>(r.left-b.left,r.right-b.left),
  };
}
