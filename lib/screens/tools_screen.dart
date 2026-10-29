import '../models/tool_model.dart';

class ToolsData {
  static const List<ToolCategory> categories = [
    ToolCategory(id: 'all', translationKey: 'All', icon: '📦'),
    ToolCategory(id: 'Quantity', translationKey: 'Quantity', icon: '🧱'),
    ToolCategory(id: 'Area & Volume', translationKey: 'Area & Volume', icon: '📐'),
    ToolCategory(id: 'Converter', translationKey: 'Converter', icon: '🔄'),
    ToolCategory(id: 'Study & Quiz', translationKey: 'Study & Quiz', icon: '📚'),
    ToolCategory(id: 'Building Construction', translationKey: 'Building Construction', icon: '🏗️'),
    ToolCategory(id: 'Infrastructure', translationKey: 'Infrastructure', icon: '🛣️'),
    ToolCategory(id: 'MEP', translationKey: 'MEP', icon: '⚡'),
    ToolCategory(id: 'General', translationKey: 'General', icon: '📦'),
    ToolCategory(id: 'fav', translationKey: 'Favorites', icon: '⭐'),
  ];

  // Base templates for 900
  static const List<Map<String, String>> _base = [
    // Building Construction - Quantity, Bonds, Shapes (like your 3 screenshots)
    {'name':'Brickwork By Volume','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🧱','formula':'Bricks = WallVol/(BrickVol+Joint)*1.15, Mortar 25%, IS1200 P3','ref':'https://civils.ai/brickwork','unit':'Nos'},
    {'name':'Brickwork By Area','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🧱','formula':'Bricks = Area*500 (190x90x90+10mm), Mortar 0.25Vol','ref':'https://civils.ai','unit':'Nos'},
    {'name':'Clay Brick','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🧱','formula':'IS 1077, 19x9x9 cm + 10mm joint','ref':'https://buildvision.ai','unit':'Nos'},
    {'name':'AAC Block','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🧊','formula':'Blocks = Area/0.08 (600x200), Mortar 0.1m3','ref':'https://civils.ai','unit':'Nos'},
    {'name':'CLC Block','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🧊','formula':'CLC 600x200x100','ref':'https://civils.ai','unit':'Nos'},
    {'name':'Sand Plaster','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🥣','formula':'Vol = Area*Thickness, 1:4 ratio, IS 1661','ref':'https://civils.ai','unit':'m3'},
    {'name':'Gypsum Plaster','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Quantity','icon':'🎨','formula':'12.5kg/m2 for 13mm','ref':'https://civils.ai','unit':'kg'},
    {'name':'Stretcher Bond','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Bonds','icon':'🧱','formula':'Full bricks stretcher pattern','ref':'https://onsiteteams.com','unit':'Nos'},
    {'name':'Header Bond','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Bonds','icon':'🧱','formula':'Header bond - short face','ref':'https://onsiteteams.com','unit':'Nos'},
    {'name':'English Bond','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Bonds','icon':'🧱','formula':'Alternate header stretcher course','ref':'https://buildvision.ai','unit':'Nos'},
    {'name':'Flemish Bond','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Bonds','icon':'🧱','formula':'Alternate header stretcher same course','ref':'https://buildvision.ai','unit':'Nos'},
    {'name':'Cube','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'📦','formula':'Vol = L*B*H, IS 1200','ref':'https://omnicalculator.com','unit':'m3'},
    {'name':'Wall','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'🧱','formula':'Wall Vol = L*H*T - openings','ref':'https://civils.ai','unit':'m3'},
    {'name':'L Wall','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'↩️','formula':'L Wall = (L1+L2)*H*T - overlap','ref':'https://civils.ai','unit':'m3'},
    {'name':'C Wall','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'©️','formula':'C Wall = 3 sides deduction','ref':'https://civils.ai','unit':'m3'},
    {'name':'U Wall','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'🔲','formula':'U Wall volume','ref':'https://civils.ai','unit':'m3'},
    {'name':'Arch Calculator','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Shapes','icon':'🌉','formula':'Arch Length = π*r*θ/180','ref':'https://civils.ai','unit':'m'},
    {'name':'Precast Boundary Wall','cat':'const','main':'Quantity','sub':'Building Construction','subsub':'Others','icon':'🧱','formula':'Panels = Length/2.5m','ref':'https://buildvision.ai','unit':'Nos'},
    {'name':'Beam Concrete','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Concrete','icon':'📏','formula':'Vol = L*B*D*1.54 factor, IS456, wastage 5%','ref':'https://civils.ai/concrete','unit':'m3'},
    {'name':'Column Concrete','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Concrete','icon':'🏛️','formula':'Vol = B*D*H, IS456','ref':'https://civils.ai','unit':'m3'},
    {'name':'Slab Concrete','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Concrete','icon':'🧱','formula':'Vol = L*B*T','ref':'https://civils.ai','unit':'m3'},
    {'name':'Footing Concrete','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Concrete','icon':'⬛','formula':'Vol = L*B*H + trapezoidal, IS456','ref':'https://civils.ai','unit':'m3'},
    {'name':'Steel Weight D²/162','cat':'mat','main':'Quantity','sub':'Building Construction','subsub':'Steel','icon':'🔩','formula':'kg/m = D²/162, Lap 50D, Hook 9D, IS2502, 5% wastage','ref':'https://civils.ai/rebar','unit':'kg'},
    {'name':'Stirrups Quantity','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Steel','icon':'🔗','formula':'Length = 2*(A+B)+24D, IS2502','ref':'https://civils.ai','unit':'Nos'},
    {'name':'Bar Bending Schedule','cat':'struct','main':'Quantity','sub':'Building Construction','subsub':'Steel','icon':'📋','formula':'BBS cutting length = L + 2*Hook - Bend deduction','ref':'https://estimator.com','unit':'kg'},
    // Infrastructure, MEP, Area&Volume, Converter, Study
    {'name':'Excavation','cat':'const','main':'Quantity','sub':'Infrastructure','subsub':'Earthwork','icon':'⛏️','formula':'Vol = L*B*D, Loose 1.2, IS1200 Part1','ref':'https://civils.ai','unit':'m3'},
    {'name':'PCC','cat':'const','main':'Quantity','sub':'Infrastructure','subsub':'Foundation','icon':'🪨','formula':'PCC M10 Vol = L*B*T','ref':'https://civils.ai','unit':'m3'},
    {'name':'Shuttering','cat':'const','main':'Quantity','sub':'Infrastructure','subsub':'Formwork','icon':'🔲','formula':'Area = 2*(L+B)*H for column, IS1200','ref':'https://estimator.com','unit':'m2'},
    {'name':'Water Tank Vol','cat':'plumb','main':'Quantity','sub':'MEP','subsub':'Plumbing','icon':'🛢️','formula':'Capacity = 135L*Persons, IS1172','ref':'https://civils.ai','unit':'L'},
    {'name':'Pipe Length','cat':'plumb','main':'Quantity','sub':'MEP','subsub':'Plumbing','icon':'🪈','formula':'Length + fittings 20%, IS2065','ref':'https://buildvision.ai','unit':'m'},
    {'name':'Cable Length','cat':'elec','main':'Quantity','sub':'MEP','subsub':'Electrical','icon':'🪢','formula':'Length+15% wastage+sag, IS732','ref':'https://electrical.com','unit':'m'},
    {'name':'Square Area','cat':'measure','main':'Area & Volume','sub':'2D Area','subsub':'Quadrilateral','icon':'◼️','formula':'A = a²','ref':'https://omnicalculator.com/area','unit':'m2'},
    {'name':'Rectangle Area','cat':'measure','main':'Area & Volume','sub':'2D Area','subsub':'Quadrilateral','icon':'▭','formula':'A = L*B','ref':'https://omnicalculator.com','unit':'m2'},
    {'name':'Circle Area','cat':'measure','main':'Area & Volume','sub':'2D Area','subsub':'Circle','icon':'⭕','formula':'A = πr²','ref':'https://omnicalculator.com','unit':'m2'},
    {'name':'Triangle Area','cat':'measure','main':'Area & Volume','sub':'2D Area','subsub':'Triangle','icon':'📐','formula':'A = 0.5*B*H','ref':'https://omnicalculator.com','unit':'m2'},
    {'name':'Cylinder Volume','cat':'measure','main':'Area & Volume','sub':'3D Volume','subsub':'Basic Solids','icon':'🛢️','formula':'V = πr²h','ref':'https://omnicalculator.com/volume','unit':'m3'},
    {'name':'Cone Volume','cat':'measure','main':'Area & Volume','sub':'3D Volume','subsub':'Basic Solids','icon':'🔺','formula':'V = 1/3πr²h','ref':'https://omnicalculator.com','unit':'m3'},
    {'name':'Length Converter','cat':'math','main':'Converter','sub':'Measurement','subsub':'Length','icon':'📏','formula':'ft = m*3.28084, in = m*39.3701','ref':'https://converter.com','unit':'ft'},
    {'name':'Area Converter','cat':'math','main':'Converter','sub':'Measurement','subsub':'Area','icon':'📐','formula':'ft2 = m2*10.7639','ref':'https://converter.com','unit':'ft2'},
    {'name':'Volume Converter','cat':'math','main':'Converter','sub':'Measurement','subsub':'Volume','icon':'📦','formula':'ft3 = m3*35.3147','ref':'https://converter.com','unit':'ft3'},
    {'name':'BOQ Builder','cat':'boq','main':'Study & Quiz','sub':'BOQ','subsub':'All','icon':'📋','formula':'BOQ = Σ(Qty*Rate)+GST+Contingency','ref':'https://boq.com','unit':'₹'},
    {'name':'Rate Analysis','cat':'cost','main':'Study & Quiz','sub':'Cost','subsub':'All','icon':'📊','formula':'Rate = Mat+Lab+Equip+15%OH+10%Profit+Wastage','ref':'https://estimator.com','unit':'₹'},
  ];

  static List<ToolModel> get _generate900 {
    List<ToolModel> list = [];
    int id = 1;
    // Repeat base 23 times to make ~900 (40*23=920)
    for (int r = 0; r < 23; r++) {
      for (var t in _base) {
        if (id > 900) break;
        String name = r == 0 ? t['name']! : "${t['name']} ${r+1}";
        // Distribute subcategories for Quantity
        String sub = t['sub']!;
        if (t['main'] == 'Quantity' && r % 4 == 1) sub = 'Infrastructure';
        if (t['main'] == 'Quantity' && r % 4 == 2) sub = 'MEP';
        if (t['main'] == 'Quantity' && r % 4 == 3) sub = 'General';
        list.add(ToolModel(
          id: id,
          category: t['cat']!,
          mainCategory: t['main'],
          subCategory: sub,
          subSubCategory: t['subsub'],
          icon: t['icon']!,
          name: name,
          description: t['formula']!.substring(0, t['formula']!.length > 30 ? 30 : t['formula']!.length),
          advanceFormula: t['formula'],
          refLink: t['ref'],
          unit: t['unit'],
          isWorking: true,
          isNew: r < 2,
        ));
        id++;
      }
    }
    return list;
  }

  static List<ToolModel> get allTools => _generate900;
}