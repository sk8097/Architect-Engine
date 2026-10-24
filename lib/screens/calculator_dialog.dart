import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/tool_model.dart';
import '../data/advanced_calculators.dart';

class CalculatorDialog extends StatefulWidget {
  final ToolModel tool;
  const CalculatorDialog({super.key, required this.tool});
  @override State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final Map<String, TextEditingController> _ctrl = {};
  String _result = '';
  late ToolDef _def;

  @override void initState() {
    super.initState();
    _def = AdvancedTools.getById(widget.tool.id);
    for(var f in _def.fields){ _ctrl[f]=TextEditingController(); }
  }
  @override void dispose(){ for(var c in _ctrl.values) c.dispose(); super.dispose(); }

  void _calc(){
    Map<String,double> vals={};
    _ctrl.forEach((k,ctrl){ vals[k]=double.tryParse(ctrl.text)??0; });
    setState(()=> _result = AdvancedTools.calculate(widget.tool.id, vals));
  }

  Widget _buildVisual(){
    final isDark = Theme.of(context).brightness==Brightness.dark;
    Color bg = isDark ? Color(0xFF1A2540) : Color(0xFFF1F5F9);
    String icon='📐', desc=_def.formula;
    switch(_def.ui){
      case ToolUI.brick: icon='🧱'; desc='Wall L×H×T | Bricks 500/m³ | Mortar 0.25×Vol'; break;
      case ToolUI.tile: icon='⬜'; desc='Tile grid + Boxes | Area/(L×W) + Wastage'; break;
      case ToolUI.paint: icon='🖌️'; desc='Paint: 1L=100 sqft | Litres=Area×Coats/Coverage'; break;
      case ToolUI.steel: icon='🔩'; desc='Steel: D²/162 × L × Nos = kg | BBS'; break;
      case ToolUI.boq: icon='📋'; desc='BOQ: Gross - Deduction table | Qty abstract'; break;
      case ToolUI.cost: icon='💰'; desc='Cost: Qty×Rate + GST + Wastage'; break;
      case ToolUI.slope: icon='📉'; desc='Slope: Rise/Run×100% | 1 in X'; break;
      case ToolUI.beam: icon='🏗️'; desc='Beam/Column/Slab: L×B×D + Dry 1.54'; break;
      case ToolUI.electrical: icon='⚡'; desc='Electrical: Points×Watt=Load | Cable+15%'; break;
      case ToolUI.plumbing: icon='🚿'; desc='Plumbing: 135L/person/day | Tank 1.2×'; break;
      default: break;
    }
    return Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color:bg, borderRadius: BorderRadius.circular(12)), child: Row(children:[Text(icon, style: TextStyle(fontSize:28)), SizedBox(width:8), Expanded(child: Text(desc, style: TextStyle(fontSize:11)))]));
  }

  @override Widget build(BuildContext context){
    final cardColor = Theme.of(context).cardColor;
    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: EdgeInsets.symmetric(horizontal:16, vertical:24),
      child: Container(constraints: BoxConstraints(maxWidth:480), padding: EdgeInsets.all(18), decoration: BoxDecoration(color:cardColor, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[Expanded(child: Row(children:[Text(widget.tool.icon, style: TextStyle(fontSize:22)), SizedBox(width:8), Expanded(child: Text(widget.tool.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize:14)))])), IconButton(icon: Icon(Icons.close), onPressed: ()=>Navigator.pop(context))]),
          Text(_def.formula, style: TextStyle(fontSize:10, color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
          SizedBox(height:10), _buildVisual(), SizedBox(height:12),
          ..._def.fields.map((f)=> Padding(padding: EdgeInsets.only(bottom:10), child: TextField(controller:_ctrl[f], keyboardType: TextInputType.numberWithOptions(decimal:true), decoration: InputDecoration(labelText:f, filled:true, fillColor: Theme.of(context).brightness==Brightness.dark? Color(0xFF1A2540): Color(0xFFF1F5F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))))),
          SizedBox(height:8),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkPrimary, foregroundColor: Color(0xFF0A1128), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical:14)), onPressed:_calc, child: Text('CALCULATE - ${_def.name.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize:12))),
          if(_result.isNotEmpty)...[SizedBox(height:14), Container(padding: EdgeInsets.all(14), decoration: BoxDecoration(color: Theme.of(context).brightness==Brightness.dark? Color(0xFF0F1A33): Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3))), child: Text(_result, style: TextStyle(fontSize:13, fontWeight: FontWeight.w600, height:1.5)))],
        ])),
      ),
    );
  }
}
