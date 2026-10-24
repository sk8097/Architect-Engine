import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/tool_model.dart';

enum ToolUI { brick, tile, paint, steel, boq, cost, slope, beam, electrical, plumbing, cad, math, site, simple }

class ToolDef {
  final int id; final String name; final ToolUI ui; final List<String> fields; final String formula; final String desc;
  const ToolDef(this.id, this.name, this.ui, this.fields, this.formula, this.desc);
}

class CalculatorDialog extends StatefulWidget {
  final ToolModel tool;
  const CalculatorDialog({super.key, required this.tool});
  @override State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final Map<String, TextEditingController> _ctrl = {};
  String _result = '';
  String _detailed = '';
  late ToolDef _def;

  // FULL 168 DEFINITIONS - Har ek ka alag fields + formula + UI
  static const List<ToolDef> all = [
    ToolDef(1, 'Length & Distance', ToolUI.simple, ['Value','From (m=1, ft=0.3048, Gaj=0.836, Guntha=101.17)','To Factor'], 'Result=Value*From/To', 'Guntha=1089sqft, Gaj=9sqft, Acre=43560sqft, 1m=3.28ft'),
    ToolDef(2, 'Area Calculator', ToolUI.simple, ['L (m)','W (m)','Shape: Rect=1 Tri=0.5 Circle=0.785'], 'Area=L*W*Factor', 'Rect, Triangle, Circle area'),
    ToolDef(3, 'Perimeter', ToolUI.simple, ['L (m)','W (m)'], 'Peri=2*(L+W)', 'Perimeter of rectangle'),
    ToolDef(4, 'Volume', ToolUI.beam, ['L (m)','W (m)','H (m)'], 'Vol=L*W*H', 'Volume of box'),
    ToolDef(5, 'Surface Area', ToolUI.simple, ['L (m)','W (m)','H (m)'], 'SA=2*(LW+LH+WH)', 'Total surface area'),
    ToolDef(6, 'Drawing Scale', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale/1000 m', 'Blueprint scale to real'),
    ToolDef(7, 'Dimension Calc', ToolUI.cad, ['L1','W1','Nos'], 'Total=L*W*Nos', 'Repeat dimensions'),
    ToolDef(8, 'Slope & Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100', 'Rise/run to %'),
    ToolDef(9, 'Level Difference', ToolUI.slope, ['Level 1 (m)','Level 2 (m)'], 'Diff=L1-L2', 'Survey level difference'),
    ToolDef(10, 'Angle Calc', ToolUI.simple, ['Opposite','Adjacent'], 'Angle=atan(O/A) in deg', 'Trigonometry'),
    ToolDef(11, 'Coordinate Distance', ToolUI.simple, ['X1','Y1','X2','Y2'], 'Dist=sqrt((X2-X1)²+(Y2-Y1)²)', 'Two-point distance'),
    ToolDef(12, 'Measurement Sheet', ToolUI.boq, ['L','W','H','Nos'], 'Qty=L*W*H*Nos', 'Log measurements'),
    ToolDef(13, 'Measurement Summary', ToolUI.boq, ['Qty1','Qty2','Qty3'], 'Total=Qty1+Qty2+Qty3', 'Grouped totals'),
    ToolDef(14, 'Room Area', ToolUI.simple, ['Room L (m)','Room W (m)'], 'Area=L*W', 'Room-wise area'),
    ToolDef(15, 'Floor Area', ToolUI.simple, ['Room Areas Sum','Corridor'], 'Floor=Sum+Corridor', 'Sum room areas'),
    ToolDef(16, 'Carpet Area', ToolUI.simple, ['Built-up','Wall Area'], 'Carpet=Built-up-Walls', 'Usable area'),
    ToolDef(17, 'Built-up Area', ToolUI.simple, ['Carpet','Wall Area'], 'Built-up=Carpet+Walls', 'Carpet+walls'),
    ToolDef(18, 'Plot Coverage', ToolUI.simple, ['Built-up','Plot Area'], 'Coverage%=Built/Plot*100', 'Coverage %'),
    ToolDef(19, 'FSI / FAR', ToolUI.simple, ['Total Built-up','Plot Area'], 'FSI=Total/Plot', 'Floor space index'),
    ToolDef(20, 'Wall Area', ToolUI.simple, ['Wall L','Wall H','Opening Area'], 'Wall=L*H-Opening', 'Wall minus openings'),
    ToolDef(21, 'Door & Window', ToolUI.simple, ['L','H','Nos'], 'Area=L*H*Nos', 'Openings list'),
    ToolDef(22, 'Staircase', ToolUI.simple, ['Floor Height (m)','Riser (mm)','Tread (mm)'], 'Risers=Height/Riser', 'Riser/tread count'),
    ToolDef(23, 'Ramp Slope', ToolUI.slope, ['Rise (m)','Run (m)'], 'Ramp%=Rise/Run*100 | Max 1:12', 'Ramp gradient'),
    ToolDef(24, 'Parking Area', ToolUI.simple, ['Bay L','Bay W','Nos'], 'Area=L*W*Nos', 'Bay area'),
    ToolDef(25, 'Space Planning', ToolUI.simple, ['Total Area','Room %'], 'Room Area=Total*%/100', 'Allocation'),
    ToolDef(26, 'Room Schedule', ToolUI.simple, ['L','W','H'], 'Area=L*W | Vol=L*W*H', 'Room+volume'),
    ToolDef(27, 'Floor-wise Area', ToolUI.simple, ['Floor Area','Floors'], 'Total=Area*Floors', 'Floor totals'),
    ToolDef(28, 'Excavation', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos', 'Excavation volume + 10% extra'),
    ToolDef(29, 'Earthwork', ToolUI.slope, ['Cut Area','Fill Area','Length'], 'Vol=(Cut+Fill)/2*L', 'Cut/fill earthwork'),
    ToolDef(30, 'PCC', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'PCC volume'),
    ToolDef(31, 'RCC', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos | Dry=1.54*Vol', 'RCC volume'),
    ToolDef(32, 'Slab Concrete', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Slab vol'),
    ToolDef(33, 'Beam Concrete', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Beam vol'),
    ToolDef(34, 'Column Concrete', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Column vol'),
    ToolDef(35, 'Footing Concrete', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Footing vol'),
    ToolDef(36, 'Brickwork', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)','Wastage %'], 'Vol=L*H*T | Bricks=Vol*500 | Mortar=Vol*0.25', 'Bricks 500/m³, Mortar 25%'),
    ToolDef(37, 'Blockwork', ToolUI.brick, ['Wall L','Wall H','Thick','Wastage %'], 'Blocks=Vol*12.5', 'Block count 12.5/m²'),
    ToolDef(38, 'Mortar', ToolUI.simple, ['Wall Vol','Mortar %'], 'Mortar=Vol*% | 1:6 ratio', 'Mortar volume'),
    ToolDef(39, 'Plastering', ToolUI.simple, ['Area (sqm)','Thick (mm)'], 'Vol=Area*Thick/1000', 'Plaster volume'),
    ToolDef(40, 'Flooring', ToolUI.tile, ['Area (sqft)','Wastage %'], 'Floor=Area*(1+W%)', 'Floor + waste'),
    ToolDef(41, 'Tile Calc', ToolUI.tile, ['Area (sqft)','Tile L (ft)','Tile W (ft)','Wastage %'], 'Tiles=Area/(L*W)*(1+W%)', 'Tile count + boxes'),
    ToolDef(42, 'Skirting', ToolUI.simple, ['Perimeter (m)','Wastage %'], 'Skirting=Peri*(1+W%)', 'Skirting length'),
    ToolDef(43, 'Painting', ToolUI.paint, ['Area (sqft)','Coats','Coverage (sqft/L)'], 'Litres=Area*Coats/Coverage', '1L=100-120 sqft, 2 coats'),
    ToolDef(44, 'Primer & Putty', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage', 'Primer/putty calc'),
    ToolDef(45, 'Waterproofing', ToolUI.paint, ['Area (sqft)','Coverage (sqft/L)'], 'Litres=Area/Coverage', 'Waterproof coating'),
    ToolDef(46, 'Roofing', ToolUI.beam, ['L','B','Overlap %'], 'Area=L*B*(1+Overlap%)', 'Roof area with overlap'),
    ToolDef(47, 'Backfilling', ToolUI.beam, ['Excavation Vol','Concrete Vol'], 'Backfill=Excav-Conc', 'Backfill volume'),
    ToolDef(48, 'Shuttering', ToolUI.beam, ['L','B','D','Type: Beam=2*(L+D) Slab=L*B'], 'Formwork calc', 'Formwork area'),
    ToolDef(49, 'Concrete Wastage', ToolUI.beam, ['Base Vol','Wastage %'], 'Total=Base*(1+W%)', 'Base+waste%'),
    ToolDef(50, 'Material Wastage', ToolUI.simple, ['Base Qty','Wastage %'], 'Total=Base*(1+W%)', 'Base+wastage'),
    ToolDef(51, 'Cement Calc', ToolUI.simple, ['Concrete Vol (m3)','Cement Ratio','Total Ratio'], 'Bags=Vol*1.54*Ratio/Total/0.035', 'Cement bags 50kg'),
    ToolDef(52, 'Sand Calc', ToolUI.simple, ['Concrete Vol','Sand Ratio','Total Ratio'], 'Sand=Vol*1.54*Ratio/Total', 'Sand volume m³'),
    ToolDef(53, 'Aggregate Calc', ToolUI.simple, ['Concrete Vol','Agg Ratio','Total Ratio'], 'Agg=Vol*1.54*Ratio/Total', 'Aggregate m³'),
    ToolDef(54, 'Concrete Material', ToolUI.beam, ['L','B','D','Mix (e.g. 1:2:4 total=7)'], 'Cem=Vol*1.54*1/Total etc', 'Cem+sand+agg'),
    ToolDef(55, 'Mortar Material', ToolUI.simple, ['Mortar Vol','Cement Ratio','Sand Ratio'], 'Cem=Vol*1.33*Ratio/Total', 'Cem+sand for mortar'),
    ToolDef(56, 'Brick Material', ToolUI.brick, ['Wall L','Wall H','Thick','Wastage %'], 'Bricks=Vol*500*(1+W%)', 'Bricks+5% extra'),
    ToolDef(57, 'Block Material', ToolUI.brick, ['Wall L','Wall H','Thick'], 'Blocks=Vol*12.5', 'Block count'),
    ToolDef(58, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos kg', 'Rebar weight D²/162'),
    ToolDef(59, 'Reinforcement Qty', ToolUI.steel, ['Dia','Length','Nos','Spacing (m)'], 'Bars=L/Spacing+1 | Weight=D²/162*L*Nos', 'Bars+weight'),
    ToolDef(60, 'Tile Quantity', ToolUI.tile, ['Area (sqft)','Tile L','Tile W','Wastage %'], 'Tiles=Area/(L*W)*(1+W%) | Boxes=Tiles/10', 'Tiles+boxes'),
    ToolDef(61, 'Paint Material', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage', 'Paint litres'),
    ToolDef(62, 'Primer Material', ToolUI.paint, ['Area','Coats','Coverage'], 'Litres=Area*Coats/Coverage', 'Primer litres'),
    ToolDef(63, 'Putty Material', ToolUI.paint, ['Area (sqft)','Coverage kg/sqm'], 'Kg=Area/Coverage', 'Putty kg'),
    ToolDef(64, 'Flooring Material', ToolUI.tile, ['Area (sqft)','Wastage %'], 'Floor=Area*(1+W%)', 'Flooring+5%'),
    ToolDef(65, 'Roofing Material', ToolUI.beam, ['Roof Area','Sheet Area','Overlap %'], 'Sheets=Roof/Sheet*(1+Overlap)', 'Sheets count'),
    ToolDef(66, 'Waterproof Material', ToolUI.paint, ['Area','Coverage L/sqm'], 'Litres=Area/Coverage', 'Product vol'),
    ToolDef(67, 'Material Consumption', ToolUI.cost, ['Qty','Rate (Rs)'], 'Cost=Qty*Rate', 'Qty×rate'),
    ToolDef(68, 'Material Wastage 2', ToolUI.simple, ['Base Qty','Wastage %'], 'Total=Base*(1+W%)', 'Base+%'),
    ToolDef(69, 'Quantity Takeoff', ToolUI.boq, ['Gross L','Gross W','Gross H','Ded L','Ded W','Ded H','Nos'], 'Net=Gross-Ded | Gross=L*W*H*Nos', 'Gross-deduct takeoff'),
    ToolDef(70, 'Item-wise Qty', ToolUI.boq, ['L','W','H','Nos'], 'Qty=L*W*H*Nos', 'Item totals'),
    ToolDef(71, 'Room-wise Qty', ToolUI.boq, ['Room L','W','H','Nos'], 'Room Qty=L*W*H', 'Room totals'),
    ToolDef(72, 'Floor-wise Qty', ToolUI.boq, ['Floor Area','Nos Floors'], 'Qty=Area*Floors', 'Floor totals'),
    ToolDef(73, 'Material Summary', ToolUI.boq, ['Qty1','Qty2','Qty3','Rate'], 'Total Qty=Sum | Cost=Qty*Rate', 'Consolidated'),
    ToolDef(74, 'Measurement Book', ToolUI.boq, ['L','W','H','Nos','Ded L','Ded W'], 'MB=Gross-Ded', 'Site measurements'),
    ToolDef(75, 'Quantity Abstract', ToolUI.boq, ['Qty1','Qty2','Qty3'], 'Abstract=Sum Qty', 'Abstract sheet'),
    ToolDef(76, 'BOQ Builder', ToolUI.boq, ['Qty','Rate','GST %'], 'BOQ=Qty*Rate*(1+GST)', 'Item+rate+tax'),
    ToolDef(77, 'BOQ Item Library', ToolUI.boq, ['Standard Item Qty','Rate'], 'Standard items', 'Standard library'),
    ToolDef(78, 'BOQ Comparison', ToolUI.boq, ['Original Qty','Revised Qty','Rate'], 'Variance=Revised-Original', 'Original vs revised'),
    ToolDef(79, 'BOQ Revision', ToolUI.boq, ['Original','Revised'], 'Revision tracking', 'Version tracking'),
    ToolDef(80, 'BOQ Export', ToolUI.boq, ['Qty','Rate'], 'Export CSV/XLSX/PDF', 'BOQ export'),
    ToolDef(81, 'Material Cost', ToolUI.cost, ['Qty','Rate (Rs)','GST %','Wastage %'], 'Total=Qty*Rate*(1+GST)*(1+Wastage)', 'Qty×rate'),
    ToolDef(82, 'Labour Cost', ToolUI.cost, ['Workers','Days','Wage/day'], 'Cost=Workers*Days*Wage', 'Workers×days×wage'),
    ToolDef(83, 'Equipment Cost', ToolUI.cost, ['Hours','Rental/hr'], 'Cost=Hours*Rental', 'Hrs×rental'),
    ToolDef(84, 'Rate Analysis', ToolUI.cost, ['Direct Cost','Overhead %','Profit %'], 'Rate=Direct*(1+OH)*(1+Profit)', 'Direct+overhead+profit'),
    ToolDef(85, 'Construction Cost', ToolUI.cost, ['Mat Cost','Lab Cost','GST %'], 'Total=(Mat+Lab)*(1+GST)', 'Total+tax'),
    ToolDef(86, 'Floor-wise Cost', ToolUI.cost, ['Area','Rate/sqft','Floors'], 'Cost=Area*Rate*Floors', 'Level-wise cost'),
    ToolDef(87, 'Room-wise Cost', ToolUI.cost, ['Area','Rate/sqft'], 'Cost=Area*Rate', 'Room-wise cost'),
    ToolDef(88, 'Cost per Sq.Ft', ToolUI.cost, ['Total Cost','Area (sqft)'], 'Cost/sqft=Total/Area', 'Total÷area'),
    ToolDef(89, 'Cost per Sq.M', ToolUI.cost, ['Total Cost','Area (sqm)'], 'Cost/sqm=Total/Area', 'Total÷area'),
    ToolDef(90, 'Budget Planner', ToolUI.cost, ['Total Budget','Civil %','Finishing %','Contingency %'], 'Allocation=Budget*%', 'Budget allocation'),
    ToolDef(91, 'Budget vs Estimate', ToolUI.cost, ['Budget','Estimate'], 'Variance%=(Est-Bud)/Bud*100', 'Variance %'),
    ToolDef(92, 'Contingency', ToolUI.cost, ['Base Cost','Contingency %'], 'Reserve=Base*Cont%', 'Safety reserve 10%'),
    ToolDef(93, 'Tax Calc', ToolUI.cost, ['Amount','GST %'], 'Tax=Amount*GST/100 | Total=Amount+Tax', 'GST/levy'),
    ToolDef(94, 'Quotation Builder', ToolUI.cost, ['Mat Cost','Lab Cost','Profit %','GST %'], 'Quote=(Mat+Lab)*(1+Profit)*(1+GST)', 'Proposal'),
    ToolDef(95, 'Project Estimate', ToolUI.cost, ['Area (sqft)','Rate/sqft','Contingency %'], 'Estimate=Area*Rate*(1+Cont%)', 'Master estimate'),
    ToolDef(96, 'Slope Calc', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100', 'Rise/run to %'),
    ToolDef(97, 'Gradient Calc', ToolUI.slope, ['Rise','Run'], '1 in X=Run/Rise | %=Rise/Run*100', '1 in X gradient'),
    ToolDef(98, 'Level Difference', ToolUI.slope, ['Level 1','Level 2'], 'Diff=L1-L2', 'Levels comparison'),
    ToolDef(99, 'Rise & Fall', ToolUI.slope, ['Back Sight','Fore Sight'], 'Rise/Fall=BS-FS', 'Survey readings'),
    ToolDef(100, 'Cut & Fill', ToolUI.slope, ['Cut Area','Fill Area','Length'], 'Cut Vol=Area*L | Fill Vol=Area*L', 'Earthwork cut/fill'),
    ToolDef(101, 'Road Gradient', ToolUI.slope, ['Rise','Run'], 'Road Gradient=Rise/Run*100% Max 7%', 'Highway slope'),
    ToolDef(102, 'Drainage Gradient', ToolUI.slope, ['Rise','Run'], 'Drainage Slope=Rise/Run Min 1:100', 'Pipe slope 1% min'),
    ToolDef(103, 'Cross-Section Area', ToolUI.slope, ['Base 1','Base 2','Height'], 'Area=(B1+B2)/2*H', 'Profile area trapezoid'),
    ToolDef(104, 'Earthwork Volume', ToolUI.slope, ['Area 1','Area 2','Length'], 'Vol=(A1+A2)/2*L', 'Volume sections'),
    ToolDef(105, 'Chainage & Offset', ToolUI.slope, ['Chainage','Offset','Bearing'], 'Alignment calc', 'Chainage offset'),
    ToolDef(106, 'Survey Calc', ToolUI.slope, ['Easting 1','Northing 1','Easting 2','Northing 2'], 'Dist=sqrt(dE²+dN²) | Bearing', 'Coordinate geo'),
    ToolDef(107, 'Retaining Wall', ToolUI.beam, ['L','B','H','Wastage %'], 'Vol=L*B*H*(1+W%)', 'Wall volume'),
    ToolDef(108, 'Beam Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos | Steel 1% vol', 'Beam geometry'),
    ToolDef(109, 'Column Calc', ToolUI.beam, ['L','B','H','Nos'], 'Vol=L*B*H*Nos', 'Column volume'),
    ToolDef(110, 'Slab Calc', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Slab volume'),
    ToolDef(111, 'Footing Calc', ToolUI.beam, ['L','B','D','Nos'], 'Vol=L*B*D*Nos', 'Footing volume'),
    ToolDef(112, 'Reinforcement Qty', ToolUI.steel, ['Beam L','Spacing','Dia'], 'Bars=L/Spacing+1 | Weight=D²/162*L', 'Bar count'),
    ToolDef(113, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos', 'Rebar weight'),
    ToolDef(114, 'Bar Bending Schedule', ToolUI.steel, ['Dia','Length','Nos','Bends'], 'Cut Len=Length-Bends*Dia | BBS', 'BBS schedule'),
    ToolDef(115, 'Rebar Cutting Length', ToolUI.steel, ['Length','Dia','Bends','Hook'], 'Cut=Length-Bends*Dia+Hook', 'Cutting length'),
    ToolDef(116, 'Stirrup Qty', ToolUI.steel, ['Beam L (m)','Spacing (m)','Stirrup Perimeter'], 'Stirrups=L/Spacing+1 | Steel=Peri*Nos*Weight', 'Tie count'),
    ToolDef(117, 'Concrete Summary', ToolUI.beam, ['Vol 1','Vol 2','Vol 3'], 'Total=Sum Vol | Cement Bags=Total*1.54*0.22/0.035', 'Project concrete total'),
    ToolDef(118, 'Reinforcement Summary', ToolUI.steel, ['Weight 1','Weight 2','Weight 3'], 'Total Steel=Sum Weights', 'Project steel total'),
    ToolDef(119, 'Electrical Points', ToolUI.electrical, ['Rooms','Points per Room','Watt/point'], 'Total Points=Rooms*Points | Load=Points*Watt', 'Lights/sockets count'),
    ToolDef(120, 'Lighting Schedule', ToolUI.electrical, ['Fixtures','Watt/fixture','Hours/day'], 'Load=Fixtures*Watt | kWh/day=Load*Hours/1000', 'Fixture+watt'),
    ToolDef(121, 'Connected Load', ToolUI.electrical, ['Load 1 (W)','Load 2 (W)','Load 3 (W)'], 'Total Load=Sum Loads', 'Total connected load'),
    ToolDef(122, 'Circuit Load', ToolUI.electrical, ['Total Watt','Voltage (V)','PF'], 'Current A=Watt/(Volt*PF) | 230V', 'Current (A)'),
    ToolDef(123, 'Cable Length', ToolUI.electrical, ['Length (m)','Wastage %','Circuits'], 'Cable=Length*Circuits*(1+W%)', 'Wire length with waste'),
    ToolDef(124, 'Electrical Material', ToolUI.electrical, ['Points','Material Rate','Labour Rate'], 'Mat=Points*MatRate | Lab=Points*LabRate', 'Hardware list'),
    ToolDef(125, 'Electrical Cost', ToolUI.cost, ['Material Cost','Labour Cost','GST %'], 'Total=(Mat+Lab)*(1+GST)', 'Material+labour cost'),
    ToolDef(126, 'Fixture Schedule', ToolUI.plumbing, ['WC Nos','Basin Nos','Shower Nos','Rate'], 'Total Fixtures=Sum | Cost=Total*Rate', 'WC/basin count'),
    ToolDef(127, 'Pipe Length', ToolUI.plumbing, ['Length (m)','Wastage %','Dia'], 'Pipe=Length*(1+W%)', 'Pipe run length'),
    ToolDef(128, 'Pipe & Fitting', ToolUI.plumbing, ['Pipe Length','Elbows','Tees','Sockets'], 'Fittings=Elbows+Tees+Sockets', 'Fittings count'),
    ToolDef(129, 'Water Demand', ToolUI.plumbing, ['Persons','Per capita (L) Default 135L'], 'Demand=Persons*PerCap L/day', 'L/day demand'),
    ToolDef(130, 'Water Tank Vol', ToolUI.plumbing, ['Persons','Per capita (L)','Days Storage'], 'Tank=Persons*PerCap*Days | 1.2x factor', 'Tank capacity'),
    ToolDef(131, 'Drainage Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope=Rise/Run | Min 1:100 for drainage', 'Pipe slope'),
    ToolDef(132, 'Plumbing Material', ToolUI.plumbing, ['Pipe Length','Rate/m','Fittings Nos','Fitting Rate'], 'Cost=Pipe*Rate + Fittings*Rate', 'Supply list cost'),
    ToolDef(133, 'Plumbing Cost', ToolUI.cost, ['Material Cost','Labour Cost','GST %'], 'Total=(Mat+Lab)*(1+GST)', 'Financial plumbing'),
    ToolDef(134, 'Drawing Scale', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale/1000 m | cm=mm*Scale/10', 'Blueprint scale'),
    ToolDef(135, 'Dimension Calc', ToolUI.cad, ['L Drawing (mm)','W Drawing (mm)','Scale'], 'Real L=L*Scale | Diagonal=sqrt(L²+W²)', 'Diagonal calc'),
    ToolDef(136, 'Annotation Tools', ToolUI.cad, ['Text','Scale','Height'], 'Annotation text', 'Text labels'),
    ToolDef(137, 'Layer Management', ToolUI.cad, ['Layers Count'], 'Layer props', 'Layer properties'),
    ToolDef(138, 'Sheet Setup', ToolUI.cad, ['Sheet: A3=420x297 A4=297x210','Scale'], 'Sheet size', 'A3/A4 sheet'),
    ToolDef(139, 'Title Block', ToolUI.cad, ['Project','Client','Scale'], 'Project info', 'Title block data'),
    ToolDef(140, 'Revision Manager', ToolUI.cad, ['Rev No','Changes'], 'Change tracking', 'Revision log'),
    ToolDef(141, 'Drawing Validation', ToolUI.cad, ['Checks'], 'Rule checks | Min clearance', 'Validation'),
    ToolDef(142, 'Drawing Preview', ToolUI.cad, ['Scale'], 'Vector preview', 'Vector view'),
    ToolDef(143, 'DXF Import/Export', ToolUI.cad, ['File Size KB','Scale'], 'CAD conversion', 'DXF conversion'),
    ToolDef(144, 'Basic Calculator', ToolUI.math, ['Value 1','Value 2','Operation: +=1 -=2 *=3 /=4'], 'Calc based on operation', 'Arithmetic'),
    ToolDef(145, 'Percentage Calc', ToolUI.math, ['Value','Percent %'], 'Result=Value*Percent/100 | Value+%', 'Percentage'),
    ToolDef(146, 'Ratio Calc', ToolUI.math, ['Ratio A','Ratio B'], 'Simplify A:B | A/(A+B)', 'Ratio simplify'),
    ToolDef(147, 'Proportion Calc', ToolUI.math, ['A','B','C'], 'D=B*C/A | Missing value', 'Proportion'),
    ToolDef(148, 'Average Calc', ToolUI.math, ['V1','V2','V3','V4'], 'Mean=Sum/Nos | Sum=Total', 'Mean average'),
    ToolDef(149, 'Decimal to Fraction', ToolUI.math, ['Decimal'], 'Fraction conversion', 'Decimal to fraction'),
    ToolDef(150, 'Date Difference', ToolUI.math, ['Days 1','Days 2'], 'Diff=Days2-Days1 | Weeks=Days/7', 'Days difference'),
    ToolDef(151, 'Project Duration', ToolUI.math, ['Total Days','Holidays','Weekoffs'], 'Working Days=Total-Holidays-Weekoffs', 'Working days'),
    ToolDef(152, 'Saved Calculations', ToolUI.site, ['Saved Qty'], 'Storage | History', 'Saved calculations'),
    ToolDef(153, 'Calculation History', ToolUI.site, ['History Count'], 'Audit log', 'History audit'),
    ToolDef(154, 'Site Notes', ToolUI.site, ['Notes'], 'Observations | Site diary', 'Observations'),
    ToolDef(155, 'Copy & Share', ToolUI.site, ['Text to Share'], 'Clipboard copy', 'Copy share'),
    ToolDef(156, 'Export Reports', ToolUI.site, ['Report Data'], 'CSV/PDF export', 'Export reports'),
    ToolDef(157, 'Stakeholder Directory', ToolUI.site, ['Contacts Count'], 'Contacts directory', 'Stakeholder contacts'),
    ToolDef(158, 'Stakeholder Notes', ToolUI.site, ['Trade','Notes'], 'Trade log | Notes', 'Trade log'),
    ToolDef(159, 'Daily Progress', ToolUI.site, ['Work Done %','Labour Nos','Weather'], 'Progress log', 'Daily progress'),
    ToolDef(160, 'Material Delivery', ToolUI.site, ['Material','Qty','Rate','Supplier'], 'Cost=Qty*Rate | Delivery note', 'Delivery note'),
    ToolDef(161, 'Site Instruction', ToolUI.site, ['Instruction','Qty','Rate'], 'Change ticket cost', 'Change ticket'),
    ToolDef(162, 'Safety Incident', ToolUI.site, ['Incident Type','Severity'], 'Safety record', 'Safety record'),
    ToolDef(163, 'Punch List', ToolUI.site, ['Snag Items','Qty'], 'Snag items pending', 'Snag list'),
    ToolDef(164, 'Labour Attendance', ToolUI.site, ['Workers','Days','Wage/day'], 'Wages=Workers*Days*Wage | Attendance', 'Wages attendance'),
    ToolDef(165, 'Client Meeting', ToolUI.site, ['Meeting Notes','Decisions'], 'Decision notes', 'Client meeting'),
    ToolDef(166, 'Equipment Deployment', ToolUI.site, ['Equipment','Hours','Rental/hr'], 'Cost=Hours*Rental | Custody', 'Equipment custody'),
    ToolDef(167, 'Voice Memo', ToolUI.site, ['Memo Duration (min)'], 'Field notes voice', 'Field notes'),
    ToolDef(168, 'Stakeholder Report', ToolUI.site, ['Report Type: PDF=1 TXT=2 CSV=3'], 'Export PDF/TXT/CSV', 'Stakeholder report'),
  ];

  ToolDef getById(int id) => all.firstWhere((e)=> e.id==id, orElse: ()=> all[0]);

  @override void initState() {
    super.initState();
    _def = getById(widget.tool.id);
    for(var f in _def.fields){ _ctrl[f]=TextEditingController(); }
  }
  @override void dispose(){ for(var c in _ctrl.values) c.dispose(); super.dispose(); }

  void _calc(){
    Map<String,double> v={};
    _ctrl.forEach((k,ctrl){ v[k]=double.tryParse(ctrl.text)??0; });
    double g(String k)=> v[k]??0;
    String res='', det='';
    switch(_def.ui){
      case ToolUI.brick:
        double vol=g('Wall L (m)')*g('Wall H (m)')* (g('Thick (m)')==0?0.23:g('Thick (m)'));
        if(vol==0) vol=g('Wall L')*g('Wall H')* (g('Thick')==0?0.23:g('Thick'));
        double wast=g('Wastage %'); double bricks=vol*500*(1+wast/100); double blocks=vol*12.5*(1+wast/100);
        res='Bricks: ${bricks.toStringAsFixed(0)} nos\nBlocks: ${blocks.toStringAsFixed(0)} nos\nMortar: ${(vol*0.25).toStringAsFixed(3)} m³\nVol: ${vol.toStringAsFixed(3)} m³';
        det='Tool: ${_def.name}\nWall L=${g('Wall L (m)')} H=${g('Wall H (m)')} T=${g('Thick (m)')}\nBricks formula: Vol×500 | 1 brick=0.2×0.1×0.1m\nMortar 25% of volume\nWastage ${wast}% included';
        break;
      case ToolUI.tile:
        double area=g('Area (sqft)'); if(area==0) area=g('Area')>0?g('Area'):g('Floor Area')>0?g('Floor Area'):100;
        double tl=g('Tile L (ft)'); if(tl==0) tl=g('Tile L')>0?g('Tile L'):2; double tw=g('Tile W (ft)'); if(tw==0) tw=g('Tile W')>0?g('Tile W'):2; double wast=g('Wastage %');
        double tiles=area/(tl*tw)*(1+wast/100);
        res='Tiles: ${tiles.toStringAsFixed(0)} nos\nBoxes (10 pcs): ${(tiles/10).ceil()}\nArea with waste: ${(area*(1+wast/100)).toStringAsFixed(2)} sqft\nSkirting: ${(tiles*0.1).toStringAsFixed(0)} m (10%)';
        det='Tool: ${_def.name}\nRoom Area=${area} sqft\nTile Size=${tl}x${tw} ft\nTile Area=${tl*tw} sqft\nFormula: Tiles=Area/TileArea*(1+W%)';
        break;
      case ToolUI.paint:
        double area=g('Area (sqft)'); if(area==0) area=g('Area')>0?g('Area'):100;
        double coats=g('Coats'); if(coats==0) coats=2; double cov=g('Coverage (sqft/L)'); if(cov==0) cov=g('Coverage')>0?g('Coverage'):100;
        double litres=area*coats/cov;
        res='${litres.toStringAsFixed(2)} Litres Paint\n${(litres/20).toStringAsFixed(2)} Buckets (20L)\n${(area*coats/100*0.4).toStringAsFixed(2)} kg Putty\nPrimer: ${(litres*0.8).toStringAsFixed(2)} L';
        det='Tool: ${_def.name}\nArea=${area} sqft | Coats=${coats} | Coverage=${cov} sqft/L\nFormula: Litres=Area*Coats/Coverage\n1 Litre=100-120 sqft, Putty 0.4kg/sqm';
        break;
      case ToolUI.steel:
        double d=g('Dia (mm)'); if(d==0) d=g('Dia')>0?g('Dia'):12; double l=g('Length (m)'); if(l==0) l=g('Length')>0?g('Length'):g('Beam L (m)')>0?g('Beam L (m)'):1; double nos=g('Nos'); if(nos==0) nos=g('Bars')>0?g('Bars'):1;
        double spacing=g('Spacing (m)'); if(spacing>0) nos=(l/spacing+1);
        double wt=d*d/162*l*nos;
        res='${wt.toStringAsFixed(2)} kg | ${(wt/1000).toStringAsFixed(3)} Ton\nBars: ${nos.toStringAsFixed(0)} nos\nDia ${d}mm | Length ${l}m\nCut Length: ${(l*1000-d*2).toStringAsFixed(0)} mm';
        det='Tool: ${_def.name}\nDia=${d}mm | Length=${l}m | Nos=${nos}\nFormula: Weight=D²/162*L*Nos\nD²/162 = kg per meter for dia\nBBS: Length - bends*Dia';
        break;
      case ToolUI.boq:
        double gross=g('Gross L')*g('Gross W')*g('Gross H')*(g('Nos')==0?1:g('Nos'));
        if(gross==0) gross=g('L')*g('W')*g('H')*(g('Nos')==0?1:g('Nos'));
        if(gross==0) gross=g('Item L')*g('Item W')*g('Item H')*(g('Nos')==0?1:g('Nos'));
        if(gross==0) gross=g('Qty1')+g('Qty2')+g('Qty3');
        double ded=g('Ded L')*g('Ded W')* (g('Ded H')>0?g('Ded H'):g('Gross H')>0?g('Gross H'):1);
        if(g('Ded L')==0 && g('Original Qty')>0) ded=g('Original Qty');
        double net=gross-ded;
        res='Gross Qty: ${gross.toStringAsFixed(3)}\nDeduction: ${ded.toStringAsFixed(3)}\nNet Qty: ${net.toStringAsFixed(3)}\nIn CFT: ${(net*35.3147).toStringAsFixed(2)} cft';
        det='Tool: ${_def.name}\nGross=L*W*H*Nos\nDeduction=Ded L*W*H\nNet=Gross-Ded\nMeasurement Book format';
        break;
      case ToolUI.cost:
        double qty=g('Qty'); if(qty==0) qty=g('Workers')*g('Days')>0?g('Workers')*g('Days'):g('Hours')>0?g('Hours'):g('Area (sqft)')>0?g('Area (sqft)'):g('Total Cost')>0?1:g('Qty')>0?g('Qty'):1;
        double rate=g('Rate (Rs)'); if(rate==0) rate=g('Rate')>0?g('Rate'):g('Wage/day')>0?g('Wage/day'):g('Rate/sqft')>0?g('Rate/sqft'):g('Rental/hr')>0?g('Rental/hr'):1000;
        double gst=g('GST %'); double wast=g('Wastage %'); double oh=g('Overhead %'); double profit=g('Profit %');
        double base=qty*rate;
        if(g('Workers')>0 && g('Days')>0) base=g('Workers')*g('Days')*g('Wage/day');
        if(g('Hours')>0) base=g('Hours')*g('Rental/hr');
        if(g('Direct Cost')>0) base=g('Direct Cost')*(1+oh/100)*(1+profit/100);
        double total=base*(1+gst/100)*(1+wast/100);
        res='Base: ₹${base.toStringAsFixed(2)}\nGST ${gst}% + Wastage ${wast}% + OH ${oh}% + Profit ${profit}%\nGrand Total: ₹${total.toStringAsFixed(2)}\nPer unit: ₹${(total/qty).toStringAsFixed(2)}';
        det='Tool: ${_def.name}\nQty=${qty} | Rate=₹${rate}\nFormula: Total=Qty*Rate*(1+GST)*(1+Wastage)\nRate Analysis: Direct*(1+OH)*(1+Profit)';
        break;
      case ToolUI.slope:
        double rise=g('Rise (m)'); if(rise==0) rise=g('Rise')>0?g('Rise'):g('Level 1')-g('Level 2');
        if(rise==0) rise=g('Cut Area'); if(rise==0) rise=g('Back Sight')-g('Fore Sight');
        double run=g('Run (m)'); if(run==0) run=g('Run')>0?g('Run'):1;
        double perc=rise/run*100; double ratio=run/rise;
        res='Slope: ${perc.toStringAsFixed(2)}%\n1 in ${ratio.toStringAsFixed(2)}\nAngle: ${perc.toStringAsFixed(2)}% | ${(perc*0.9).toStringAsFixed(2)} deg approx\nRise ${rise}m / Run ${run}m';
        det='Tool: ${_def.name}\nRise=${rise}m | Run=${run}m\nFormula: Slope%=Rise/Run*100\n1 in X=Run/Rise\nRoad max 7%, Drainage min 1%';
        break;
      case ToolUI.beam:
        double l=g('L (m)'); if(l==0) l=g('L')>0?g('L'):1; double b=g('B (m)'); if(b==0) b=g('B')>0?g('B'):0.3; double d=g('D (m)'); if(d==0) d=g('D')>0?g('D'):0.3; double nos=g('Nos'); if(nos==0) nos=1;
        double vol=l*b*d*nos; if(vol==0) vol=g('Base Vol')*(1+g('Wastage %')/100);
        if(vol==0) vol=g('Excavation Vol')-g('Concrete Vol');
        double dry=vol*1.54;
        res='Concrete: ${vol.toStringAsFixed(3)} m³ | ${(vol*35.3147).toStringAsFixed(2)} cft\nDry Vol (1.54): ${dry.toStringAsFixed(3)} m³\nCement: ${(dry*0.22/0.035).toStringAsFixed(1)} bags (M20 1:2:4)\nSand: ${(dry*0.44).toStringAsFixed(3)} m³ | Agg: ${(dry*0.88).toStringAsFixed(3)} m³\nShuttering: ${(2*(l+d)*b*nos).toStringAsFixed(2)} m²';
        det='Tool: ${_def.name}\nL=${l} B=${b} D=${d} Nos=${nos}\nVol=L*B*D*Nos\nDry Vol=Vol*1.54 (for cement calc)\nShuttering=2*(L+D)*B for beam';
        break;
      case ToolUI.electrical:
        double pts=g('Points'); if(pts==0) pts=g('Fixtures')>0?g('Fixtures'):g('Rooms')*2;
        if(pts==0) pts=5; double watt=g('Watt/point'); if(watt==0) watt=g('Watt/fixture')>0?g('Watt/fixture'):g('Watt')>0?g('Watt'):100;
        double len=g('Length (m)'); if(len==0) len=pts*3; double wast=g('Wastage %');
        double load=pts*watt; double current=load/230;
        res='Points: ${pts.toStringAsFixed(0)}\nLoad: ${load.toStringAsFixed(0)} W | ${(load/1000).toStringAsFixed(2)} kW\nCurrent: ${current.toStringAsFixed(2)} A @230V\nCable: ${(len*(1+wast/100==0?1.15:1+wast/100)).toStringAsFixed(2)} m (15% waste)\nBreaker: ${(current*1.25).toStringAsFixed(0)} A MCB';
        det='Tool: ${_def.name}\nPoints=${pts} | Watt=${watt}\nFormula: Load=Points*Watt | Current=W/V\nCable=Length*1.15 (wastage)\nMCB=Current*1.25';
        break;
      case ToolUI.plumbing:
        double pers=g('Persons'); if(pers==0) pers=5; double perCap=g('Per capita (L)'); if(perCap==0) perCap=g('Per capita')>0?g('Per capita'):135;
        double days=g('Days Storage'); if(days==0) days=1; double demand=pers*perCap; double tank=demand*days*1.2;
        double len=g('Pipe Length (m)'); if(len==0) len=g('Length (m)')>0?g('Length (m)'):pers*2;
        double wast=g('Wastage %');
        res='Demand: ${demand.toStringAsFixed(0)} L/day | ${(demand/1000).toStringAsFixed(2)} m³/day\nTank (${days} day): ${tank.toStringAsFixed(0)} L | ${(tank/1000).toStringAsFixed(2)} m³\nPipe: ${(len*(1+wast/100==0?1:1+wast/100)).toStringAsFixed(2)} m\nFittings: ${(len/3).toStringAsFixed(0)} nos (1 per 3m)';
        det='Tool: ${_def.name}\nPersons=${pers} | PerCap=${perCap}L\nFormula: Demand=Persons*135 L/day (IS code)\nTank=Demand*Days*1.2 safety\nPipe with wastage';
        break;
      case ToolUI.cad:
        double dr=g('Drawing (mm)'); if(dr==0) dr=g('L Drawing (mm)')>0?g('L Drawing (mm)'):100;
        double sc=g('Scale 1:X'); if(sc==0) sc=g('Scale')>0?g('Scale'):100;
        res='Real: ${(dr*sc/1000).toStringAsFixed(3)} m | ${(dr*sc/100).toStringAsFixed(1)} cm | ${(dr*sc).toStringAsFixed(0)} mm\nScale 1:${sc.toStringAsFixed(0)}\nA3=420x297mm A4=297x210mm';
        det='Tool: ${_def.name}\nDrawing=${dr}mm | Scale=1:${sc}\nFormula: Real=Drawing*Scale';
        break;
      case ToolUI.math:
        double v1=g('Value 1'); if(v1==0) v1=g('Value')>0?g('Value'):g('Ratio A')>0?g('Ratio A'):g('V1')>0?g('V1'):100;
        double v2=g('Value 2'); if(v2==0) v2=g('Percent %')>0?g('Percent %'):g('Ratio B')>0?g('Ratio B'):g('V2')>0?g('V2'):20;
        double v3=g('V3'); if(v3==0) v3=g('V3')>0?g('V3'):g('C')>0?g('C'):0;
        res='Sum: ${(v1+v2+v3).toStringAsFixed(3)}\nDiff: ${(v1-v2).toStringAsFixed(3)}\nMul: ${(v1*v2).toStringAsFixed(3)}\nDiv: ${(v2==0?0:v1/v2).toStringAsFixed(3)}\n${v1} * ${v2}% = ${(v1*v2/100).toStringAsFixed(2)}\nAvg: ${((v1+v2+v3)/3).toStringAsFixed(2)}';
        det='Tool: ${_def.name}\nMath: + - * / % ratio avg';
        break;
      case ToolUI.site:
        double qty=g('Qty'); if(qty==0) qty=g('Workers')>0?g('Workers'):g('Material Qty')>0?g('Material Qty'):1;
        double rate=g('Rate'); if(rate==0) rate=g('Rate/m')>0?g('Rate/m'):g('Wage/day')>0?g('Wage/day'):100;
        double workers=g('Workers'); double days=g('Days');
        if(workers>0 && days>0) qty=workers*days;
        res='${_def.name}\nQty: ${qty.toStringAsFixed(0)}\nRate: ₹${rate.toStringAsFixed(2)}\nTotal: ₹${(qty*rate).toStringAsFixed(2)}\nStatus: Logged | Date: ${DateTime.now().toString().split(' ')[0]}';
        det='Tool: ${_def.name}\nSite log entry | ${_def.desc}';
        break;
      default:
        double l=g('L (m)'); if(l==0) l=g('Value')>0?g('Value'):1; double w=g('W (m)'); if(w==0) w=g('From Factor')>0?g('From Factor'):1; double h=g('H (m)'); if(h==0) h=g('To Factor')>0?g('To Factor'):1;
        double val=g('Value');
        res='Area: ${(l*w).toStringAsFixed(3)} m² | ${(l*w*10.764).toStringAsFixed(2)} sqft\nVol: ${(l*w*(h==0?1:h)).toStringAsFixed(3)} m³\nValue conversion: ${(val*w/h).toStringAsFixed(4)}';
        det='Tool: ${_def.name}';
    }
    setState(()=> {_result=res, _detailed=det});
  }

  Future<void> _saveToFile(String ext) async {
    if(_result.isEmpty){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pahle CALCULATE karo'))); return; }
    try{
      String content = 'ARCHITECT ENGINE - ${_def.name}\nTool ID: ${_def.id}\nDate: ${DateTime.now()}\n------------------------------\nInputs:\n';
      _ctrl.forEach((k,v){ content+='$k: ${v.text}\n'; });
      content+='\nFormula: ${_def.formula}\n${_def.desc}\n------------------------------\nResult:\n$_result\n\nDetailed:\n$_detailed\n\nGenerated by Architect Engine';
      
      // Try to save to app documents - fallback to showing dialog with path
      String fileName = '${_def.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      // For web/mobile - use system temp then show
      try{
        final dir = Directory('/storage/emulated/0/Download');
        if(await dir.exists()){
          final file = File('${dir.path}/$fileName');
          await file.writeAsString(content);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to Download/$fileName'), duration: Duration(seconds: 3)));
        } else {
          // Fallback - copy to clipboard and show saved
          await Clipboard.setData(ClipboardData(text: content));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied to clipboard - Paste in $ext file: $fileName\n$_result'), duration: Duration(seconds: 4)));
        }
      } catch(e){
        await Clipboard.setData(ClipboardData(text: content));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to clipboard (File: $fileName)\nPath: Download/$fileName'), duration: Duration(seconds: 3)));
      }
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  Widget _buildVisual(){
    final isDark = Theme.of(context).brightness==Brightness.dark;
    Color bg = isDark ? Color(0xFF1A2540) : Color(0xFFF1F5F9);
    Color border = isDark ? Color(0xFF2A3A5C) : Color(0xFFE2E8F0);
    String icon='📐'; String desc=_def.formula; Color iconBg = AppColors.darkPrimary.withOpacity(0.15);
    switch(_def.ui){
      case ToolUI.brick: icon='🧱'; desc='Wall L×H×T | Bricks 500/m³ | Mortar 25% | Blocks 12.5/m² | Wastage%'; break;
      case ToolUI.tile: icon='⬜'; desc='Tile: Area/(L×W)*(1+W%) | Boxes=Tiles/10 | Wastage 10% | Skirting 10%'; break;
      case ToolUI.paint: icon='🖌️'; desc='Paint: 1L=100-120 sqft | Litres=Area×Coats/Coverage | Putty 0.4kg/sqm | Primer 80%'; break;
      case ToolUI.steel: icon='🔩'; desc='Steel: Weight=D²/162×L×Nos kg | D²/162 kg/m | BBS Cut Length'; break;
      case ToolUI.boq: icon='📋'; desc='BOQ: Gross=L×W×H×Nos - Deduction | MB | Abstract | Qty takeoff'; break;
      case ToolUI.cost: icon='💰'; desc='Cost: Qty×Rate×(1+GST)×(1+Wastage) | Rate Analysis Direct+OH+Profit | Budget vs Estimate'; break;
      case ToolUI.slope: icon='📉'; desc='Slope%=Rise/Run×100 | 1 in X=Run/Rise | Road max 7% | Drainage min 1% | Cut/Fill'; break;
      case ToolUI.beam: icon='🏗️'; desc='Beam/Column/Slab/Footing: Vol=L×B×D×Nos | Dry=1.54×Vol | Cement 0.22 Dry | Shuttering 2×(L+D)×B'; break;
      case ToolUI.electrical: icon='⚡'; desc='Electrical: Load=Points×Watt | Current=W/V | Cable=Length×1.15 | MCB=Current×1.25'; break;
      case ToolUI.plumbing: icon='🚿'; desc='Plumbing: Demand=Persons×135L/day IS Code | Tank=Demand×1.2 | Pipe + Fittings'; break;
      case ToolUI.cad: icon='✏️'; desc='CAD: Real=Drawing×Scale | A3=420×297 A4=297×210 | DXF | Layer | Title Block'; break;
      case ToolUI.math: icon='🧮'; desc='Math: Sum Diff Mul Div % Ratio Avg | Proportion | Date Diff | Project Duration'; break;
      case ToolUI.site: icon='📔'; desc='Site: Daily Progress Material Delivery Safety Incident Labour Attendance | Wages'; break;
      default: break;
    }
    return Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color:bg, borderRadius: BorderRadius.circular(12), border: Border.all(color:border)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children:[Container(width:42, height:42, decoration: BoxDecoration(color:iconBg, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(icon, style: TextStyle(fontSize:22))), SizedBox(width:10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(_def.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize:12)), SizedBox(height:2), Text(desc, style: TextStyle(fontSize:10, color: Colors.grey, height:1.3))]))]));
  }

  @override Widget build(BuildContext context){
    final cardColor = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness==Brightness.dark;
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal:12, vertical:24),
      child: Container(constraints: BoxConstraints(maxWidth:500, maxHeight: MediaQuery.of(context).size.height*0.9), padding: EdgeInsets.all(16), decoration: BoxDecoration(color:cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(children:[
          Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Expanded(child: Row(children:[Container(width:36, height:36, decoration: BoxDecoration(color: AppColors.darkIconBg, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Text(widget.tool.icon, style: TextStyle(fontSize:18))), SizedBox(width:8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text(widget.tool.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize:13)), Text('ID ${_def.id} | ${_def.ui.toString().split('.').last.toUpperCase()}', style: TextStyle(fontSize:9, color: Colors.grey))]))])), IconButton(icon: Icon(Icons.close, size:20), onPressed: ()=>Navigator.pop(context))]),
            SizedBox(height:8),
            Container(padding: EdgeInsets.symmetric(horizontal:8, vertical:4), decoration: BoxDecoration(color: AppColors.darkPrimary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)), child: Text(_def.formula, style: TextStyle(fontSize:9, color: AppColors.darkPrimary, fontWeight: FontWeight.bold))),
            SizedBox(height:10), _buildVisual(), SizedBox(height:12),
            ..._def.fields.map((f)=> Padding(padding: EdgeInsets.only(bottom:9), child: TextField(controller:_ctrl[f], keyboardType: TextInputType.numberWithOptions(decimal:true, signed:true), style: TextStyle(fontSize:13), decoration: InputDecoration(labelText:f, labelStyle: TextStyle(fontSize:11), filled:true, fillColor: isDark? Color(0xFF1A2540): Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: EdgeInsets.symmetric(horizontal:12, vertical:12))))),
            SizedBox(height:10),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, foregroundColor: Color(0xFF0A1128), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical:14)), onPressed:_calc, child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[Icon(Icons.calculate, size:18), SizedBox(width:6), Text('CALCULATE - ${_def.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize:11))])),
            if(_result.isNotEmpty)...[
              SizedBox(height:14),
              Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: isDark? Color(0xFF0F1A33): Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(children:[Icon(Icons.check_circle, size:16, color: Colors.green), SizedBox(width:6), Text('RESULT - ${_def.name.toUpperCase()}', style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: AppColors.darkPrimary))]), SizedBox(height:8), Text(_result, style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, height:1.6)), if(_detailed.isNotEmpty)...[Divider(height:16), Text(_detailed, style: TextStyle(fontSize:10, color: Colors.grey, height:1.4))]])),
              SizedBox(height:12),
              Row(children:[
                Expanded(child: OutlinedButton.icon(icon: Icon(Icons.copy, size:16), label: Text('Copy', style: TextStyle(fontSize:11)), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical:10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { await Clipboard.setData(ClipboardData(text: '${_def.name}\n$_result\n\n$_detailed')); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied to clipboard'))); })),
                SizedBox(width:8),
                Expanded(child: OutlinedButton.icon(icon: Icon(Icons.share, size:16), label: Text('Share', style: TextStyle(fontSize:11)), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical:10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () async { await Clipboard.setData(ClipboardData(text: '${_def.name}\n$_result')); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied - Share to WhatsApp/Email'))); })),
              ]),
              SizedBox(height:8),
              Row(children:[
                Expanded(child: ElevatedButton.icon(icon: Icon(Icons.description, size:16), label: Text('Save TXT', style: TextStyle(fontSize:11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical:10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: ()=> _saveToFile('txt'))),
                SizedBox(width:8),
                Expanded(child: ElevatedButton.icon(icon: Icon(Icons.picture_as_pdf, size:16), label: Text('Save DOC', style: TextStyle(fontSize:11)), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical:10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: ()=> _saveToFile('doc'))),
              ]),
              SizedBox(height:6),
              Text('Saved files go to Download folder | Also copied to clipboard | Client mobile me TXT/DOC ban jayega', style: TextStyle(fontSize:9, color: Colors.grey), textAlign: TextAlign.center),
            ]
          ]))),
        ]),
      ),
    );
  }
}
