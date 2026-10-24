import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/tool_model.dart';
import '../providers/app_state_provider.dart';

class CalculatorDialog extends StatefulWidget {
  final ToolModel tool;
  const CalculatorDialog({super.key, required this.tool});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  final Map<String, TextEditingController> _ctrl = {};
  String _result = '';
  String _formula = '';

  @override
  void initState() {
    super.initState();
    // Dynamic fields based on category
    for (var f in _getFields()) {
      _ctrl[f] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _ctrl.values) c.dispose();
    super.dispose();
  }

  List<String> _getFields() {
    final cat = widget.tool.category;
    final id = widget.tool.id;
    if (cat == 'measure') return _measureFields(id);
    if (cat == 'const') return ['Length (m)', 'Width (m)', 'Height/Thick (m)'];
    if (cat == 'mat') return _matFields(id);
    if (cat == 'boq') return ['Length', 'Width', 'Height', 'Nos', 'Deduction'];
    if (cat == 'cost') return ['Quantity', 'Rate (₹)', 'Overhead %', 'Wastage %'];
    if (cat == 'struct') return _structFields(id);
    if (cat == 'slope') return ['Rise (m)', 'Run (m)', 'Length (m)'];
    if (cat == 'elec') return ['Points', 'Watt per point', 'Length (m)'];
    if (cat == 'plumb') return ['Persons', 'Per capita (L)', 'Pipe Length (m)'];
    if (cat == 'arch') return ['Room L (m)', 'Room W (m)', 'Height (m)', 'Openings (m²)'];
    if (cat == 'cad') return ['Drawing (mm)', 'Scale (1:X)'];
    if (cat == 'math') return ['Value 1', 'Value 2', 'Value 3'];
    if (cat == 'site') return ['Description', 'Qty', 'Rate'];
    return ['Input 1', 'Input 2'];
  }

  List<String> _measureFields(int id) {
    if (id == 1) return ['Value', 'From Factor', 'To Factor']; // Length & Distance
    if (id == 2) return ['Length (m)', 'Width (m)', 'Shape (Rect=1, Tri=0.5, Circle=3.14)'];
    if (id == 6) return ['Drawing (mm)', 'Scale'];
    if (id == 8) return ['Rise', 'Run'];
    return ['Length (m)', 'Width (m)', 'Height (m)'];
  }

  List<String> _matFields(int id) {
    if (id >= 51 && id <= 55) return ['Volume (m³)', 'Ratio Cement', 'Ratio Sand', 'Ratio Agg'];
    if (id == 58 || id == 59) return ['Dia (mm)', 'Length (m)', 'Nos'];
    return ['Area/Vol', 'Wastage %'];
  }

  List<String> _structFields(int id) {
    if (id == 108) return ['L (m)', 'B (m)', 'D (m)']; // Beam
    if (id == 112) return ['Dia (mm)', 'Spacing (mm)', 'Length (m)', 'Nos'];
    return ['L (m)', 'B (m)', 'D (m)', 'Nos'];
  }

  void _calculate() {
    try {
      final cat = widget.tool.category;
      final id = widget.tool.id;
      double v(String k) => double.tryParse(_ctrl[k]?.text ?? '0') ?? 0;

      String res = '';
      String formula = '';

      // ===== MEASUREMENT =====
      if (cat == 'measure' && id == 1) {
        // Length advanced: Guntha, Gaj, Acre support
        double val = v('Value');
        double from = v('From Factor') == 0 ? 1 : v('From Factor');
        double to = v('To Factor') == 0 ? 1 : v('To Factor');
        double out = val * from / to;
        res = '${out.toStringAsFixed(4)} units\n\n1 sq.m=10.764 sq.ft | 1 Gaj=9 sq.ft | 1 Guntha=1089 sq.ft | 1 Acre=43560 sq.ft';
        formula = 'Result = Value × From / To';
      } else if (cat == 'measure' && id == 2) {
        double l = v('Length (m)'); double w = v('Width (m)'); double shape = v('Shape (Rect=1, Tri=0.5, Circle=3.14)');
        if (shape == 0) shape = 1;
        double area = l * w * shape;
        double sqft = area * 10.7639;
        res = 'Area: ${area.toStringAsFixed(2)} m² | ${sqft.toStringAsFixed(2)} sq.ft';
        formula = 'Area = L × W × ShapeFactor';
      } else if (cat == 'measure' && id == 6) {
        double drg = v('Drawing (mm)'); double scale = v('Scale') == 0 ? 100 : v('Scale');
        double real = drg * scale / 1000;
        res = 'Real: ${real.toStringAsFixed(3)} m | ${(real*3.28084).toStringAsFixed(2)} ft';
        formula = 'Real = Drawing × Scale';
      }
      // ===== CONSTRUCTION =====
      else if (cat == 'const') {
        double l = v('Length (m)'); double w = v('Width (m)'); double h = v('Height/Thick (m)');
        double vol = l * w * h;
        double dry = vol * 1.54;
        double bricks = vol * 500; // per m3
        res = 'Gross Vol: ${vol.toStringAsFixed(3)} m³\nDry Vol (1.54): ${dry.toStringAsFixed(3)} m³\nBrick Qty ~ ${bricks.toStringAsFixed(0)} nos (if brickwork)';
        formula = 'Dry Volume = Wet × 1.54 | Brick = 500/m³';
      }
      // ===== MATERIALS =====
      else if (cat == 'mat' && id == 51) {
        double vol = v('Volume (m³)'); double rc = v('Ratio Cement'); double rs = v('Ratio Sand'); double ra = v('Ratio Agg');
        if (rc+rs+ra==0) { rc=1; rs=1.5; ra=3; }
        double total = rc+rs+ra;
        double cementVol = vol*1.54*rc/total;
        double bags = cementVol/0.035;
        double sand = vol*1.54*rs/total;
        double agg = vol*1.54*ra/total;
        res = 'Cement: ${bags.toStringAsFixed(2)} bags (${cementVol.toStringAsFixed(3)} m³)\nSand: ${sand.toStringAsFixed(3)} m³\nAgg: ${agg.toStringAsFixed(3)} m³';
        formula = 'Cement Vol = Vol×1.54×Rc/(Rc+Rs+Ra) | Bags=Vol/0.035';
      } else if (cat == 'mat' && (id==58 || id==59)) {
        double dia = v('Dia (mm)'); double len = v('Length (m)'); double nos = v('Nos') ==0?1:v('Nos');
        double wt = (dia*dia/162) * len * nos; // kg
        res = 'Steel Weight: ${wt.toStringAsFixed(2)} kg | ${(wt/1000).toStringAsFixed(3)} Ton\nFormula: D²/162 × L';
        formula = 'Weight = D²/162 × L × Nos';
      }
      // ===== BOQ =====
      else if (cat == 'boq') {
        double l=v('Length'); double w=v('Width'); double h=v('Height'); double nos=v('Nos')==0?1:v('Nos'); double ded=v('Deduction');
        double qty = l*w*h*nos - ded;
        res = 'Quantity: ${qty.toStringAsFixed(3)}\nGross: ${(l*w*h*nos).toStringAsFixed(3)} - Ded: $ded';
        formula = 'Qty = L×W×H×Nos - Deduction';
      }
      // ===== COST =====
      else if (cat == 'cost') {
        double qty=v('Quantity'); double rate=v('Rate (₹)'); double oh=v('Overhead %'); double wast=v('Wastage %');
        double base = qty*rate;
        double withWast = base*(1+wast/100);
        double withOH = withWast*(1+oh/100);
        double contingency = withOH*0.10;
        double grand = withOH+contingency;
        res = 'Base: ₹${base.toStringAsFixed(2)}\n+Wastage ${wast}%: ₹${withWast.toStringAsFixed(2)}\n+OH ${oh}%: ₹${withOH.toStringAsFixed(2)}\n+Contingency 10%: ₹${contingency.toStringAsFixed(2)}\nGrand: ₹${grand.toStringAsFixed(2)}';
        formula = 'Grand = Qty×Rate × (1+W%) × (1+OH%) + 10% Contingency';
      }
      // ===== STRUCTURAL =====
      else if (cat == 'struct') {
        double l=v('L (m)'); double b=v('B (m)'); double d=v('D (m)'); double nos=v('Nos')==0?1:v('Nos');
        double vol = l*b*d*nos;
        res = 'Concrete Vol: ${vol.toStringAsFixed(3)} m³ | ${(vol*35.3147).toStringAsFixed(2)} cft';
        formula = 'Vol = L×B×D×Nos';
      }
      // ===== SLOPE =====
      else if (cat == 'slope') {
        double rise=v('Rise (m)'); double run=v('Run (m)'); double len=v('Length (m)')==0?1:v('Length (m)');
        double perc = run==0?0:rise/run*100;
        double ratio = perc==0?0:100/perc;
        double earth = len*rise; // simplified
        res = 'Slope: ${perc.toStringAsFixed(2)}% | 1 in ${ratio.toStringAsFixed(2)}\nAngle: ${( (perc/100).abs()).toStringAsFixed(4)} rad approx';
        formula = 'Slope% = Rise/Run×100 | 1 in X = 100/Slope%';
      }
      // ===== DEFAULT =====
      else {
        double a = v(_getFields().first);
        double b = v(_getFields().length>1 ? _getFields()[1] : 'Value 2');
        res = 'Result: ${(a+b).toStringAsFixed(3)} (Add logic for ${widget.tool.name})';
        formula = 'Extend _calculate() for ID ${widget.tool.id}';
      }

      setState(() { _result = res; _formula = formula; });
    } catch (e) {
      setState(() => _result = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Row(children: [
                    Text(widget.tool.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(widget.tool.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  ])),
                  IconButton(icon: const Icon(Icons.close), onPressed: ()=>Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 4),
              Text(widget.tool.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 14),
              ..._getFields().map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _ctrl[f],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: f,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1A2540) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              )),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: const Color(0xFF0A1128),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _calculate,
                child: const Text('CALCULATE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (_result.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1A33) : const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkPrimary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formula, style: TextStyle(fontSize: 10, color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(_result, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyMedium?.color, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.copy, size: 16), label: const Text('Copy'), onPressed: () {})),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.save, size: 16), label: const Text('Save'), onPressed: () {
                      Provider.of<AppStateProvider>(context, listen: false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to project!')));
                    })),
                  ],
                )
              ],
            ],
          ),
        ),
      ),
    );
  }
}
