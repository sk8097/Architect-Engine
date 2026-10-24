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
    ToolDef(36, 'Brickwork', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)','Wastage %'], 'Vol=L*H*T | Bricks=Vol*500 | Mortar=Vol*0.25'),
    ToolDef(37, 'Blockwork', ToolUI.brick, ['Wall L (m)','Wall H (m)','Thick (m)'], 'Blocks=Vol*12.5'),
    ToolDef(41, 'Tile Calc', ToolUI.tile, ['Area (sqft)','Tile L (ft)','Tile W (ft)','Wastage %'], 'Tiles=Area/(L*W)*(1+W%)'),
    ToolDef(60, 'Tile Quantity', ToolUI.tile, ['Area (sqft)','Tile L (ft)','Tile W (ft)','Wastage %'], 'Tiles=Area/(L*W)'),
    ToolDef(43, 'Painting', ToolUI.paint, ['Area (sqft)','Coats','Coverage (sqft/L)'], 'Litres=Area*Coats/Coverage'),
    ToolDef(61, 'Paint Material', ToolUI.paint, ['Area (sqft)','Coats','Coverage'], 'Litres=Area*Coats/Coverage'),
    ToolDef(58, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos'),
    ToolDef(113, 'Steel Weight', ToolUI.steel, ['Dia (mm)','Length (m)','Nos'], 'Weight=D²/162*L*Nos'),
    ToolDef(69, 'Quantity Takeoff', ToolUI.boq, ['Gross L','Gross W','Gross H','Ded L','Ded W','Nos'], 'Qty=Gross-Ded | Gross=L*W*H*Nos'),
    ToolDef(76, 'BOQ Builder', ToolUI.boq, ['Qty','Rate','GST %'], 'Total=Qty*Rate*(1+GST)'),
    ToolDef(81, 'Material Cost', ToolUI.cost, ['Qty','Rate (Rs)','GST %','Wastage %'], 'Total=Qty*Rate*(1+GST)*(1+Wastage)'),
    ToolDef(82, 'Labour Cost', ToolUI.cost, ['Workers','Days','Wage/day'], 'Total=Workers*Days*Wage'),
    ToolDef(88, 'Cost per Sq.Ft', ToolUI.cost, ['Total Cost','Area (sqft)'], 'Cost/sqft=Total/Area'),
    ToolDef(96, 'Slope Calc', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100 | 1 in X=Run/Rise'),
    ToolDef(101, 'Road Gradient', ToolUI.slope, ['Rise (m)','Run (m)'], 'Slope%=Rise/Run*100'),
    ToolDef(108, 'Beam Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos | Dry=Vol*1.54'),
    ToolDef(109, 'Column Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D*Nos'),
    ToolDef(110, 'Slab Calc', ToolUI.beam, ['L (m)','B (m)','D (m)','Nos'], 'Vol=L*B*D'),
    ToolDef(119, 'Electrical Points', ToolUI.electrical, ['Points','Watt/point','Length (m)'], 'Load=Points*Watt | Cable=Length*1.15'),
    ToolDef(123, 'Cable Length', ToolUI.electrical, ['Length (m)','Wastage %'], 'Cable=Length*(1+Wastage%)'),
    ToolDef(129, 'Water Demand', ToolUI.plumbing, ['Persons','Per capita (L)','Pipe Length'], 'Demand=Persons*135L/day'),
    ToolDef(130, 'Water Tank Vol', ToolUI.plumbing, ['Persons','Per capita (L)'], 'Tank=Persons*135*1.2 L'),
    ToolDef(134, 'Drawing Scale', ToolUI.cad, ['Drawing (mm)','Scale 1:X'], 'Real=Drawing*Scale/1000 m'),
    // Baaki 168 tak same pattern - id badal ke add karte ja
  ];

  static String calculate(int id, Map<String,double> v){
    double g(String k)=> v[k]??0;
    final def = getById(id);
    switch(def.ui){
      case ToolUI.brick:
        double vol=g('Wall L (m)')*g('Wall H (m)')* (g('Thick (m)')==0?0.2:g('Thick (m)'));
        double wast=g('Wastage %'); double bricks=vol*500*(1+wast/100);
        return 'Vol: ${vol.toStringAsFixed(3)} m³\nBricks: ${bricks.toStringAsFixed(0)} nos\nMortar: ${(vol*0.25).toStringAsFixed(3)} m³';
      case ToolUI.tile:
        double area=g('Area (sqft)'); double tl=g('Tile L (ft)'); if(tl==0) tl=2; double tw=g('Tile W (ft)'); if(tw==0) tw=2; double wast=g('Wastage %');
        double tiles=area/(tl*tw)*(1+wast/100);
        return 'Tiles: ${tiles.toStringAsFixed(0)} nos\nBoxes: ${(tiles/10).ceil()}\nArea with wastage: ${(area*(1+wast/100)).toStringAsFixed(2)} sqft';
      case ToolUI.paint:
        double area=g('Area (sqft)'); double coats=g('Coats'); if(coats==0) coats=2; double cov=g('Coverage (sqft/L)'); if(cov==0) cov=100;
        return '${(area*coats/cov).toStringAsFixed(2)} Litres\n${(area*coats/cov/20).toStringAsFixed(2)} Buckets (20L)';
      case ToolUI.steel:
        double d=g('Dia (mm)'); double l=g('Length (m)'); double nos=g('Nos'); if(nos==0) nos=1;
        return '${(d*d/162*l*nos).toStringAsFixed(2)} kg | ${((d*d/162*l*nos)/1000).toStringAsFixed(3)} Ton';
      case ToolUI.boq:
        double gross=g('Gross L')*g('Gross W')*g('Gross H')*(g('Nos')==0?1:g('Nos'));
        double ded=g('Ded L')*g('Ded W')*(g('Gross H')==0?1:g('Gross H'));
        return 'Gross: ${gross.toStringAsFixed(3)}\nDed: ${ded.toStringAsFixed(3)}\nNet Qty: ${(gross-ded).toStringAsFixed(3)}';
      case ToolUI.cost:
        double qty=g('Qty'); double rate=g('Rate (Rs)'); double gst=g('GST %'); double wast=g('Wastage %');
        double total=qty*rate*(1+gst/100)*(1+wast/100);
        return 'Base: ₹${(qty*rate).toStringAsFixed(2)}\nGrand (GST+Wastage): ₹${total.toStringAsFixed(2)}';
      case ToolUI.slope:
        double rise=g('Rise (m)'); double run=g('Run (m)'); if(run==0) run=1;
        return 'Slope: ${(rise/run*100).toStringAsFixed(2)}%\n1 in ${(run/rise).toStringAsFixed(2)}';
      case ToolUI.beam:
        double l=g('L (m)'); double b=g('B (m)'); double d=g('D (m)'); double nos=g('Nos'); if(nos==0) nos=1;
        double vol=l*b*d*nos;
        return 'Concrete: ${vol.toStringAsFixed(3)} m³\nDry (1.54): ${(vol*1.54).toStringAsFixed(3)} m³\n${(vol*35.3147).toStringAsFixed(2)} cft';
      case ToolUI.electrical:
        double pts=g('Points'); double watt=g('Watt/point'); if(watt==0) watt=100; double len=g('Length (m)');
        return 'Load: ${(pts*watt).toStringAsFixed(0)} W | ${(pts*watt/1000).toStringAsFixed(2)} kW\nCable: ${(len*1.15).toStringAsFixed(2)} m (15% waste)';
      case ToolUI.plumbing:
        double pers=g('Persons'); if(pers==0) pers=5; double perCap=g('Per capita (L)'); if(perCap==0) perCap=135;
        return 'Demand: ${(pers*perCap).toStringAsFixed(0)} L/day\nTank (1.2x): ${(pers*perCap*1.2).toStringAsFixed(0)} L';
      default:
        double l=g('L (m)'); double w=g('W (m)'); double h=g('H (m)');
        return 'Area: ${(l*w).toStringAsFixed(3)} | Vol: ${(l*w*(h==0?1:h)).toStringAsFixed(3)}';
    }
  }
}
