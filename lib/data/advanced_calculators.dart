import 'package:flutter/material.dart';

enum ToolUI { simple, brick, tile, paint, steel, boq, cost, slope, beam, electrical, plumbing, cad, math, site }

class ToolDef {
  final int id;
  final String name;
  final ToolUI ui;
  final List<String> fields;
  final String formula;
  const ToolDef(this.id, this.name, this.ui, this.fields, this.formula);
}

class AdvancedTools {
  static ToolDef getById(int id) => all.firstWhere((e)=> e.id==id, orElse: ()=> all[0]);
  static const List<ToolDef> all = [
    ToolDef(1, 'Length & Distance', ToolUI.simple, ['Value','From Factor','To Factor'], 'Value*From/To | Guntha=1089 sqft, Gaj=9 sqft'),
    ToolDef(2, 'Area Calculator', ToolUI.simple, ['L (m)','W (m)','Shape Factor'], 'Area=L*W*Factor | Tri=0.5 Circle=0.785'),
    ToolDef(3, 'Perimeter', ToolUI.simple, ['L (m)','W (m)'], 'Perimeter=2*(L+W)'),
    ToolDef(4, 'Volume', ToolUI.simple, ['L (m)','W (m)','H (m)'], 'Vol=L*W*H'),
    ToolDef(5, 'Surface Area', ToolUI.simple, ['L (m)','W (m)','H (m)'], 'SA=2*(L*W+L*H+W*H)'),
    ToolDef(6, 'Drawing Scale', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale/1000 m'),
    ToolDef(7, 'Dimension Calc', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale'),
    ToolDef(8, 'Slope & Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100'),
    ToolDef(9, 'Level Difference', ToolUI.slope, ['Rise (m)','Run (m)'], 'Level Diff=Rise-Run'),
    ToolDef(10, 'Angle Calc', ToolUI.simple, ['Opposite','Adjacent'], 'Angle=atan(O/A)'),
    ToolDef(11, 'Coordinate Distance', ToolUI.simple, ['X1','Y1','X2','Y2'], 'Dist=sqrt((X2-X1)²+(Y2-Y1)²)'),
    ToolDef(12, 'Measurement Sheet', ToolUI.simple, ['L','W','H'], 'Qty=L*W*H'),
    ToolDef(13, 'Measurement Summary', ToolUI.simple, ['Qty1','Qty2'], 'Total=Qty1+Qty2'),
    ToolDef(14, 'Room Area', ToolUI.simple, ['L (m)','W (m)'], 'Area=L*W'),
    ToolDef(15, 'Floor Area', ToolUI.simple, ['Rooms Total Area','Corridor'], 'Floor=Sum Rooms+Corridor'),
    ToolDef(16, 'Carpet Area', ToolUI.simple, ['Built-up','Wall Area'], 'Carpet=Built-up - Walls'),
    ToolDef(17, 'Built-up Area', ToolUI.simple, ['Carpet','Wall Thick','Wall Length'], 'Built-up=Carpet+Walls'),
    ToolDef(18, 'Plot Coverage', ToolUI.simple, ['Built-up','Plot Area'], 'Coverage%=Built-up/Plot*100'),
    ToolDef(19, 'FSI / FAR', ToolUI.simple, ['Total Built-up','Plot Area'], 'FSI=Total/Plot'),
    ToolDef(20, 'Wall Area', ToolUI.simple, ['Wall L','Wall H','Opening L','Opening H'], 'Wall=L*H - Openings'),
    ToolDef(21, 'Door & Window', ToolUI.simple, ['L','H','Nos'], 'Area=L*H*Nos'),
    ToolDef(22, 'Staircase', ToolUI.simple, ['Floor Height (m)','Riser (m)'], 'Risers=Height/Riser | Treads=Risers-1'),
    ToolDef(23, 'Ramp Slope', ToolUI.slope, ['Rise (m)','Run (m)'], 'Ramp%=Rise/Run*100 | 1:12 max'),
    ToolDef(24, 'Parking Area', ToolUI.simple, ['Bay L','Bay W','Nos'], 'Parking=L*W*Nos'),
    ToolDef(25, 'Space Planning', ToolUI.simple, ['Total Area','Room %'], 'Room Area=Total*%'),
    ToolDef(26, 'Room Schedule', ToolUI.simple, ['L','W','H'], 'Vol=L*W*H | Area=L*W'),
    ToolDef(27, 'Floor-wise Area', ToolUI.simple, ['Floor Area','Nos Floors'], 'Total=Area*Floors'),
    ToolDef(28, 'Excavation', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(29, 'Earthwork', ToolUI.slope, ['Cut Area','Fill Area','Length'], 'Vol=(Cut+Fill)/2*L'),
    ToolDef(30, 'PCC', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(31, 'RCC', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos | Dry=1.54*Vol'),
    ToolDef(32, 'Slab Concrete', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(33, 'Beam Concrete', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(34, 'Column Concrete', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(35, 'Footing Concrete', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(36, 'Brickwork', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)','Wastage %'], 'Vol=L*H*T | Bricks=Vol*500'),
    ToolDef(37, 'Blockwork', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)'], 'Blocks=Vol*12.5'),
    ToolDef(38, 'Mortar', ToolUI.simple, ['Wall Vol','Mortar %'], 'Mortar=Vol*%'),
    ToolDef(39, 'Plastering', ToolUI.simple, ['Area (sqm)','Thick (mm)'], 'Vol=Area*Thick/1000'),
    ToolDef(40, 'Flooring', ToolUI.tile, ['Area (sqft)','Wastage %'], 'Floor=Area*(1+Wastage)'),
    ToolDef(41, 'Tile Calc', ToolUI.tile, ['Area (sqft)','Tile L (ft)','Tile W (ft)','Wastage %'], 'Tiles=Area/(L*W)*(1+W%)'),
    ToolDef(42, 'Skirting', ToolUI.simple, ['Perimeter (m)','Wastage %'], 'Skirting=Peri*(1+Wastage)'),
    ToolDef(43, 'Painting', ToolUI.paint, ['Area (sqft)','Coats','Coverage (sqft/L)'], 'Litres=Area*Coats/Coverage'),
    ToolDef(44, 'Primer & Putty', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage'),
    ToolDef(45, 'Waterproofing', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage'),
    ToolDef(46, 'Roofing', ToolUI.beam, ['L (m)','B (m)','Overlap %'], 'Area=L*B*(1+Overlap)'),
    ToolDef(47, 'Backfilling', ToolUI.beam, ['Excavation Vol','Concrete Vol'], 'Backfill=Excav-Conc'),
    ToolDef(48, 'Shuttering', ToolUI.beam, ['L (m)','B (m)','D (m)'], 'Formwork=2*(L+H)*B or L*B'),
    ToolDef(49, 'Concrete Wastage', ToolUI.beam, ['Base Vol','Wastage %'], 'Total=Base*(1+Wastage)'),
    ToolDef(50, 'Material Wastage', ToolUI.simple, ['Base Qty','Wastage %'], 'Total=Base*(1+Wastage)'),
    ToolDef(51, 'Cement Calc', ToolUI.simple, ['Concrete Vol (m3)','Ratio Cement','Total Ratio'], 'Cement Bags=Vol*1.54*Ratio/Total/0.035'),
    ToolDef(52, 'Sand Calc', ToolUI.simple, ['Concrete Vol','Ratio Sand','Total Ratio'], 'Sand=Vol*1.54*Ratio/Total'),
    ToolDef(53, 'Aggregate Calc', ToolUI.simple, ['Concrete Vol','Ratio Agg','Total Ratio'], 'Agg=Vol*1.54*Ratio/Total'),
    ToolDef(54, 'Concrete Material', ToolUI.beam, ['L','B','D','Mix Ratio Total'], 'Cem/Sand/Agg=Vol*1.54*Ratio/Total'),
    ToolDef(55, 'Mortar Material', ToolUI.simple, ['Mortar Vol','Cement Ratio','Sand Ratio'], 'Cem=Vol*1.33*Ratio/Total'),
    ToolDef(56, 'Brick Material', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)','Wastage %'], 'Bricks=Vol*500*(1+W%)'),
    ToolDef(57, 'Block Material', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)'], 'Blocks=Vol*12.5'),
    ToolDef(58, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos'),
    ToolDef(59, 'Reinforcement Qty', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Bars+Weight=D²/162*L*Nos'),
    ToolDef(60, 'Tile Quantity', ToolUI.tile, ['Area (sqft)','Tile L (ft)','Tile W (ft)','Wastage %'], 'Tiles=Area/(L*W)*(1+W%)'),
    ToolDef(61, 'Paint Material', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage'),
    ToolDef(62, 'Primer Material', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage'),
    ToolDef(63, 'Putty Material', ToolUI.paint, ['Area (sqft)','Coats','Coverage kg/sqm'], 'Kg=Area*Coats/Coverage'),
    ToolDef(64, 'Flooring Material', ToolUI.tile, ['Area (sqft)','Wastage %'], 'Floor=Area*(1+W%)'),
    ToolDef(65, 'Roofing Material', ToolUI.beam, ['Roof Area','Sheet Area','Overlap %'], 'Sheets=Roof/Sheet*(1+Overlap)'),
    ToolDef(66, 'Waterproof Material', ToolUI.paint, ['Area (sqft)','Coverage'], 'Litres=Area/Coverage'),
    ToolDef(67, 'Material Consumption', ToolUI.cost, ['Qty','Rate (Rs)'], 'Cost=Qty*Rate'),
    ToolDef(68, 'Material Wastage 2', ToolUI.simple, ['Base Qty','Wastage %'], 'Total=Base*(1+Wastage)'),
    ToolDef(69, 'Quantity Takeoff', ToolUI.boq, ['Gross L','Gross W','Gross H','Ded L','Ded W','Nos'], 'Qty=Gross-Ded'),
    ToolDef(70, 'Item-wise Qty', ToolUI.boq, ['Item L','Item W','Item H','Nos'], 'Qty=L*W*H*Nos'),
    ToolDef(71, 'Room-wise Qty', ToolUI.boq, ['Room L','Room W','Room H','Nos'], 'Room Qty=L*W*H'),
    ToolDef(72, 'Floor-wise Qty', ToolUI.boq, ['Floor Area','Nos Floors'], 'Qty=Area*Floors'),
    ToolDef(73, 'Material Summary', ToolUI.boq, ['Total Qty','Rate'], 'Cost=Qty*Rate | Consolidated'),
    ToolDef(74, 'Measurement Book', ToolUI.boq, ['Gross L','Gross W','Gross H','Ded L','Ded W','Nos'], 'MB=Gross-Ded'),
    ToolDef(75, 'Quantity Abstract', ToolUI.boq, ['Qty1','Qty2','Qty3'], 'Abstract=Sum Qty'),
    ToolDef(76, 'BOQ Builder', ToolUI.boq, ['Qty','Rate','GST %'], 'BOQ=Qty*Rate*(1+GST)'),
    ToolDef(77, 'BOQ Item Library', ToolUI.boq, ['Qty','Rate'], 'Standard Items'),
    ToolDef(78, 'BOQ Comparison', ToolUI.boq, ['Original Qty','Revised Qty'], 'Variance=Revised-Original'),
    ToolDef(79, 'BOQ Revision', ToolUI.boq, ['Original','Revised'], 'Revision=Revised-Original'),
    ToolDef(80, 'BOQ Export', ToolUI.boq, ['Qty','Rate'], 'Export CSV/XLSX/PDF'),
    ToolDef(81, 'Material Cost', ToolUI.cost, ['Qty','Rate (Rs)','GST %','Wastage %'], 'Total=Qty*Rate*(1+GST)*(1+Wastage)'),
    ToolDef(82, 'Labour Cost', ToolUI.cost, ['Workers','Days','Wage/day'], 'Cost=Workers*Days*Wage'),
    ToolDef(83, 'Equipment Cost', ToolUI.cost, ['Hours','Rental/hr'], 'Cost=Hours*Rental'),
    ToolDef(84, 'Rate Analysis', ToolUI.cost, ['Direct Cost','Overhead %','Profit %'], 'Rate=Direct*(1+OH)*(1+Profit)'),
    ToolDef(85, 'Construction Cost', ToolUI.cost, ['Material Cost','Labour Cost','GST %'], 'Total=(Mat+Lab)*(1+GST)'),
    ToolDef(86, 'Floor-wise Cost', ToolUI.cost, ['Area','Rate/sqft'], 'Cost=Area*Rate'),
    ToolDef(87, 'Room-wise Cost', ToolUI.cost, ['Area','Rate/sqft'], 'Cost=Area*Rate'),
    ToolDef(88, 'Cost per Sq.Ft', ToolUI.cost, ['Total Cost','Area (sqft)'], 'Cost/sqft=Total/Area'),
    ToolDef(89, 'Cost per Sq.M', ToolUI.cost, ['Total Cost','Area (sqm)'], 'Cost/sqm=Total/Area'),
    ToolDef(90, 'Budget Planner', ToolUI.cost, ['Total Budget','Allocation %'], 'Allocated=Total*%'),
    ToolDef(91, 'Budget vs Estimate', ToolUI.cost, ['Budget','Estimate'], 'Variance%=(Est-Bud)/Bud*100'),
    ToolDef(92, 'Contingency', ToolUI.cost, ['Base Cost','Contingency %'], 'Reserve=Base*%'),
    ToolDef(93, 'Tax Calc', ToolUI.cost, ['Amount','GST %'], 'Tax=Amount*GST/100 | Total=Amount+Tax'),
    ToolDef(94, 'Quotation Builder', ToolUI.cost, ['Material Cost','Labour Cost','Profit %'], 'Quote=(Mat+Lab)*(1+Profit)'),
    ToolDef(95, 'Project Estimate', ToolUI.cost, ['Area (sqft)','Rate/sqft'], 'Estimate=Area*Rate'),
    ToolDef(96, 'Slope Calc', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100'),
    ToolDef(97, 'Gradient Calc', ToolUI.slope, ['Rise (m)','Run (m)'], '1 in X=Run/Rise'),
    ToolDef(98, 'Level Difference', ToolUI.slope, ['Level 1','Level 2'], 'Diff=L1-L2'),
    ToolDef(99, 'Rise & Fall', ToolUI.slope, ['Back Sight','Fore Sight'], 'Rise/Fall=BS-FS'),
    ToolDef(100, 'Cut & Fill', ToolUI.slope, ['Cut Area','Fill Area','Length'], 'Cut Vol=Area*L | Fill Vol=Area*L'),
    ToolDef(101, 'Road Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Road Gradient=Rise/Run*100%'),
    ToolDef(102, 'Drainage Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Drainage Slope=Rise/Run | Min 1%'),
    ToolDef(103, 'Cross-Section Area', ToolUI.slope, ['Base','Height'], 'Area=Base*Height (Trapezoid avg)'),
    ToolDef(104, 'Earthwork Volume', ToolUI.slope, ['Area 1','Area 2','Length'], 'Vol=(A1+A2)/2*L'),
    ToolDef(105, 'Chainage & Offset', ToolUI.slope, ['Chainage','Offset'], 'Alignment calc'),
    ToolDef(106, 'Survey Calc', ToolUI.slope, ['Easting 1','Northing 1','Easting 2','Northing 2'], 'Dist=sqrt(dE²+dN²)'),
    ToolDef(107, 'Retaining Wall', ToolUI.beam, ['L (m)','B (m)','H (m)'], 'Vol=L*B*H'),
    ToolDef(108, 'Beam Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos | Concrete 1.54*Vol'),
    ToolDef(109, 'Column Calc', ToolUI.beam, ['L (m)','B (m)','H (m)','Nos'], 'Vol=L*B*H*Nos'),
    ToolDef(110, 'Slab Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(111, 'Footing Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(112, 'Reinforcement Qty', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Bar count + Weight'),
    ToolDef(113, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos'),
    ToolDef(114, 'Bar Bending Schedule', ToolUI.steel, ['Dia (mm)','Length (m)','Nos','Shape Factor'], 'BBS Length=Length*Factor'),
    ToolDef(115, 'Rebar Cutting Length', ToolUI.steel, ['Length (m)','Dia (mm)','Bends Nos'], 'Cut Len=Length - Bends*Dia'),
    ToolDef(116, 'Stirrup Qty', ToolUI.steel, ['Beam L (m)','Spacing (m)'], 'Stirrups=L/Spacing +1'),
    ToolDef(117, 'Concrete Summary', ToolUI.beam, ['Vol 1','Vol 2','Vol 3'], 'Total=Sum Vol'),
    ToolDef(118, 'Reinforcement Summary', ToolUI.steel, ['Weight 1','Weight 2'], 'Total Steel=Sum Weights'),
    ToolDef(119, 'Electrical Points', ToolUI.electrical, ['Points','Watt/point'], 'Load=Points*Watt'),
    ToolDef(120, 'Lighting Schedule', ToolUI.electrical, ['Fixtures','Watt/fixture'], 'Load=Fixtures*Watt'),
    ToolDef(121, 'Connected Load', ToolUI.electrical, ['Load 1 (W)','Load 2 (W)'], 'Total Load=Sum'),
    ToolDef(122, 'Circuit Load', ToolUI.electrical, ['Total Watt','Voltage (V)'], 'Current A=Watt/Volt'),
    ToolDef(123, 'Cable Length', ToolUI.electrical, ['Length (m)','Wastage %'], 'Cable=Length*(1+W%)'),
    ToolDef(124, 'Electrical Material', ToolUI.electrical, ['Points','Material Rate'], 'Cost=Points*Rate'),
    ToolDef(125, 'Electrical Cost', ToolUI.cost, ['Material Cost','Labour Cost'], 'Total=Mat+Lab'),
    ToolDef(126, 'Fixture Schedule', ToolUI.plumbing, ['WC Nos','Basin Nos','Rate'], 'Fixtures + Cost'),
    ToolDef(127, 'Pipe Length', ToolUI.plumbing, ['Length (m)','Wastage %'], 'Pipe=Length*(1+W%)'),
    ToolDef(128, 'Pipe & Fitting', ToolUI.plumbing, ['Pipe Length','Fitting Nos'], 'Fittings calc'),
    ToolDef(129, 'Water Demand', ToolUI.plumbing, ['Persons','Per capita (L)'], 'Demand=Persons*135 L/day'),
    ToolDef(130, 'Water Tank Vol', ToolUI.plumbing, ['Persons','Per capita (L)'], 'Tank=Persons*PerCap*1.2 L'),
    ToolDef(131, 'Drainage Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope=Rise/Run | Min 1:100'),
    ToolDef(132, 'Plumbing Material', ToolUI.plumbing, ['Pipe Length','Rate/m'], 'Cost=Length*Rate'),
    ToolDef(133, 'Plumbing Cost', ToolUI.cost, ['Material Cost','Labour Cost'], 'Total=Mat+Lab'),
    ToolDef(134, 'Drawing Scale', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale/1000 m'),
    ToolDef(135, 'Dimension Calc', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Diagonal=sqrt(L²+W²)*Scale'),
    ToolDef(136, 'Annotation Tools', ToolUI.cad, ['Text','Scale'], 'Text labels'),
    ToolDef(137, 'Layer Management', ToolUI.cad, ['Layers','Props'], 'Layer props'),
    ToolDef(138, 'Sheet Setup', ToolUI.cad, ['Width (mm)','Height (mm)'], 'A3=420x297 | A4=297x210'),
    ToolDef(139, 'Title Block', ToolUI.cad, ['Project Name','Scale'], 'Project info'),
    ToolDef(140, 'Revision Manager', ToolUI.cad, ['Rev No','Changes'], 'Change tracking'),
    ToolDef(141, 'Drawing Validation', ToolUI.cad, ['Checks'], 'Rule checks'),
    ToolDef(142, 'Drawing Preview', ToolUI.cad, ['Scale'], 'Vector view'),
    ToolDef(143, 'DXF Import/Export', ToolUI.cad, ['File Size'], 'CAD conversion'),
    ToolDef(144, 'Basic Calculator', ToolUI.math, ['Value 1','Value 2'], 'Add/Sub/Mul/Div'),
    ToolDef(145, 'Percentage Calc', ToolUI.math, ['Value','Percent %'], 'Result=Value*%/100'),
    ToolDef(146, 'Ratio Calc', ToolUI.math, ['Ratio A','Ratio B'], 'Simplify A:B'),
    ToolDef(147, 'Proportion Calc', ToolUI.math, ['A','B','C'], 'D=B*C/A'),
    ToolDef(148, 'Average Calc', ToolUI.math, ['Value 1','Value 2','Value 3'], 'Mean=Sum/Nos'),
    ToolDef(149, 'Decimal to Fraction', ToolUI.math, ['Decimal'], 'Fraction conversion'),
    ToolDef(150, 'Date Difference', ToolUI.math, ['Days 1','Days 2'], 'Diff=Days2-Days1'),
    ToolDef(151, 'Project Duration', ToolUI.math, ['Start Days','End Days','Holidays'], 'Duration=End-Start-Holidays'),
    ToolDef(152, 'Saved Calculations', ToolUI.site, ['Saved Qty'], 'Storage'),
    ToolDef(153, 'Calculation History', ToolUI.site, ['History'], 'Audit log'),
    ToolDef(154, 'Site Notes', ToolUI.site, ['Notes'], 'Observations'),
    ToolDef(155, 'Copy & Share', ToolUI.site, ['Text'], 'Clipboard'),
    ToolDef(156, 'Export Reports', ToolUI.site, ['Report'], 'CSV/PDF'),
    ToolDef(157, 'Stakeholder Directory', ToolUI.site, ['Contacts'], 'Directory'),
    ToolDef(158, 'Stakeholder Notes', ToolUI.site, ['Trade','Notes'], 'Trade log'),
    ToolDef(159, 'Daily Progress', ToolUI.site, ['Work Done %','Labour Nos'], 'Weather/labor log'),
    ToolDef(160, 'Material Delivery', ToolUI.site, ['Material','Qty','Rate'], 'Delivery note'),
    ToolDef(161, 'Site Instruction', ToolUI.site, ['Instruction','Qty'], 'Change ticket'),
    ToolDef(162, 'Safety Incident', ToolUI.site, ['Incident','Qty'], 'Safety record'),
    ToolDef(163, 'Punch List', ToolUI.site, ['Snag Items','Qty'], 'Snag list'),
    ToolDef(164, 'Labour Attendance', ToolUI.site, ['Workers','Days','Wage'], 'Wages=Workers*Days*Wage'),
    ToolDef(165, 'Client Meeting', ToolUI.site, ['Meeting Notes'], 'Decision notes'),
    ToolDef(166, 'Equipment Deployment', ToolUI.site, ['Equipment','Hours'], 'Custody log'),
    ToolDef(167, 'Voice Memo', ToolUI.site, ['Memo'], 'Field notes'),
    ToolDef(168, 'Stakeholder Report', ToolUI.site, ['Report Type'], 'PDF/TXT/CSV export'),
  ];

  static String calculate(int id, Map<String,double> v){
    double g(String k)=> v[k]??0;
    final def = getById(id);
    switch(def.ui){
      case ToolUI.brick:
        double vol=g('Wall L (m)')*g('Wall H (m)')* (g('Thick (m)')==0?0.2:g('Thick (m)'));
        double wast=g('Wastage %'); double bricks=vol*500*(1+wast/100);
        return 'Vol: ${vol.toStringAsFixed(3)} m³\nBricks: ${bricks.toStringAsFixed(0)} nos\nMortar: ${(vol*0.25).toStringAsFixed(3)} m³\nBlocks: ${(vol*12.5).toStringAsFixed(0)}';
      case ToolUI.tile:
        double area=g('Area (sqft)'); if(area==0) area=g('L (m)')*g('W (m)')*10.764;
        double tl=g('Tile L (ft)'); if(tl==0) tl=2; double tw=g('Tile W (ft)'); if(tw==0) tw=2; double wast=g('Wastage %');
        double tiles=area/(tl*tw)*(1+wast/100);
        return 'Tiles: ${tiles.toStringAsFixed(0)} nos\nBoxes (10/tile): ${(tiles/10).ceil()}\nFloor Area with waste: ${(area*(1+wast/100)).toStringAsFixed(2)} sqft';
      case ToolUI.paint:
        double area=g('Area (sqft)'); if(area==0) area=g('L (m)')*g('W (m)')*10.764;
        double coats=g('Coats'); if(coats==0) coats=2; double cov=g('Coverage (sqft/L)'); if(cov==0) cov=100;
        return '${(area*coats/cov).toStringAsFixed(2)} Litres\n${(area*coats/cov/20).toStringAsFixed(2)} Buckets (20L)\n${(area*coats/cov*1.2).toStringAsFixed(2)} kg Putty';
      case ToolUI.steel:
        double d=g('Dia (mm)'); if(d==0) d=g('Value 1'); double l=g('Length (m)'); if(l==0) l=g('Value 2'); double nos=g('Nos'); if(nos==0) nos=1;
        double wt=d*d/162*l*nos;
        return '${wt.toStringAsFixed(2)} kg | ${(wt/1000).toStringAsFixed(3)} Ton\nBars: ${nos.toStringAsFixed(0)}';
      case ToolUI.boq:
        double gross=g('Gross L')*g('Gross W')*g('Gross H')*(g('Nos')==0?1:g('Nos'));
        if(gross==0) gross=g('Item L')*g('Item W')*g('Item H')*(g('Nos')==0?1:g('Nos'));
        if(gross==0) gross=g('Qty1')+g('Qty2')+g('Qty3');
        double ded=g('Ded L')*g('Ded W')* (g('Gross H')==0?1:g('Gross H'));
        return 'Gross: ${gross.toStringAsFixed(3)}\nDeduction: ${ded.toStringAsFixed(3)}\nNet Qty: ${(gross-ded).toStringAsFixed(3)}';
      case ToolUI.cost:
        double qty=g('Qty'); if(qty==0) qty=g('Workers')*g('Days');
        if(qty==0) qty=g('Area (sqft)')>0?g('Area (sqft)'):g('Total Cost')>0?1:g('Qty');
        double rate=g('Rate (Rs)'); if(rate==0) rate=g('Wage/day')>0?g('Wage/day'):g('Rate/sqft')>0?g('Rate/sqft'):g('Rental/hr');
        if(rate==0) rate=g('Rate'); double gst=g('GST %'); double wast=g('Wastage %');
        double base=qty*rate;
        if(g('Workers')>0 && g('Days')>0) base=g('Workers')*g('Days')*g('Wage/day');
        if(g('Hours')>0) base=g('Hours')*g('Rental/hr');
        double total=base*(1+gst/100)*(1+wast/100);
        return 'Base: ₹${base.toStringAsFixed(2)}\nGST ${gst}% + Wastage ${wast}%\nGrand: ₹${total.toStringAsFixed(2)}';
      case ToolUI.slope:
        double rise=g('Rise (m)'); if(rise==0) rise=g('Level 1')-g('Level 2');
        if(rise==0) rise=g('Cut Area'); double run=g('Run (m)'); if(run==0) run=1;
        double perc=rise/run*100;
        return 'Slope: ${perc.toStringAsFixed(2)}%\n1 in ${(run/rise).toStringAsFixed(2)}\nAngle: ${perc.toStringAsFixed(2)}%';
      case ToolUI.beam:
        double l=g('L (m)'); double b=g('B (m)'); double d=g('D (m)'); double nos=g('Nos'); if(nos==0) nos=1;
        double vol=l*b*d*nos; if(vol==0) vol=g('Base Vol')*(1+g('Wastage %')/100);
        return 'Concrete: ${vol.toStringAsFixed(3)} m³\nDry (1.54): ${(vol*1.54).toStringAsFixed(3)} m³\n${(vol*35.3147).toStringAsFixed(2)} cft\nCement Bags: ${(vol*1.54*0.22/0.035).toStringAsFixed(1)}';
      case ToolUI.electrical:
        double pts=g('Points'); if(pts==0) pts=g('Fixtures'); double watt=g('Watt/point'); if(watt==0) watt=g('Watt/fixture'); if(watt==0) watt=100;
        double len=g('Length (m)'); if(len==0) len=g('Length (m)'); double wast=g('Wastage %');
        return 'Load: ${(pts*watt).toStringAsFixed(0)} W | ${(pts*watt/1000).toStringAsFixed(2)} kW\nCurrent: ${(pts*watt/230).toStringAsFixed(2)} A (230V)\nCable: ${(len*(1+wast/100==0?1.15:1+wast/100)).toStringAsFixed(2)} m';
      case ToolUI.plumbing:
        double pers=g('Persons'); if(pers==0) pers=5; double perCap=g('Per capita (L)'); if(perCap==0) perCap=135;
        double demand=pers*perCap; double len=g('Pipe Length (m)'); if(len==0) len=g('Length (m)');
        return 'Demand: ${demand.toStringAsFixed(0)} L/day\nTank (1.2x): ${(demand*1.2).toStringAsFixed(0)} L\nPipe: ${len} m';
      case ToolUI.cad:
        double dr=g('Drawing (mm)'); double sc=g('Scale 1:X'); if(sc==0) sc=100;
        return 'Real: ${(dr*sc/1000).toStringAsFixed(3)} m | ${(dr*sc/100).toStringAsFixed(1)} cm\nScale 1:${sc.toStringAsFixed(0)}';
      case ToolUI.math:
        double v1=g('Value 1'); double v2=g('Value 2');
        return 'Sum: ${(v1+v2).toStringAsFixed(3)}\nDiff: ${(v1-v2).toStringAsFixed(3)}\n%: ${(v1==0?0:v2/v1*100).toStringAsFixed(2)}%';
      case ToolUI.site:
        return '${def.name}: Entry logged\nQty: ${g('Qty')}\nRate: ${g('Rate')}\nCost: ${(g('Qty')*g('Rate')).toStringAsFixed(2)}';
      default:
        double l=g('L (m)'); double w=g('W (m)'); double h=g('H (m)');
        return 'Area: ${(l*w).toStringAsFixed(3)}\nVol: ${(l*w*(h==0?1:h)).toStringAsFixed(3)}';
    }
  }
}
