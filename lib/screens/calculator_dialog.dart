import 'dart:math' as math;
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
  final Map<String, TextEditingController> _controllers = {};
  String _selectedShape = 'rect';
  String _selectedUnitFrom = 'feet';
  String _selectedUnitTo = 'meter';
  String? _resultValue;
  String? _resultUnit;
  String? _resultExtra;

  @override
  void initState() {
    super.initState();
    _initControllersForTool();
  }

  void _initControllersForTool() {
    switch (widget.tool.id) {
      case 1: // Length
        _controllers['val'] = TextEditingController(text: '25');
        break;
      case 2: // Area
      case 3: // Perimeter
      case 4: // Volume
      case 5: // Surface Area
        _controllers['l'] = TextEditingController(text: '5.0');
        _controllers['w'] = TextEditingController(text: '4.0');
        _controllers['h'] = TextEditingController(text: '3.0');
        _controllers['r'] = TextEditingController(text: '2.5');
        break;
      case 6: // Scale
        _controllers['drawing'] = TextEditingController(text: '50');
        _controllers['scale'] = TextEditingController(text: '100');
        break;
      case 8: // Slope
        _controllers['rise'] = TextEditingController(text: '1');
        _controllers['run'] = TextEditingController(text: '20');
        break;
      case 17: // Built-up
        _controllers['carpet'] = TextEditingController(text: '80');
        _controllers['walls'] = TextEditingController(text: '12');
        break;
      case 19: // FSI
        _controllers['floor'] = TextEditingController(text: '300');
        _controllers['plot'] = TextEditingController(text: '200');
        break;
      case 22: // Staircase
        _controllers['height'] = TextEditingController(text: '3.0');
        _controllers['riser'] = TextEditingController(text: '0.15');
        _controllers['tread'] = TextEditingController(text: '0.28');
        break;
      case 28: // Excavation
      case 32: // Slab
        _controllers['l'] = TextEditingController(text: '10');
        _controllers['w'] = TextEditingController(text: '4');
        _controllers['d'] = TextEditingController(text: '1.5');
        _controllers['qty'] = TextEditingController(text: '1');
        break;
      case 36: // Brickwork
        _controllers['l'] = TextEditingController(text: '5.0');
        _controllers['h'] = TextEditingController(text: '3.0');
        _controllers['t'] = TextEditingController(text: '0.23');
        break;
      case 41: // Tile
        _controllers['area'] = TextEditingController(text: '20');
        _controllers['tileSize'] = TextEditingController(text: '0.6');
        _controllers['waste'] = TextEditingController(text: '5');
        break;
      case 43: // Paint
        _controllers['area'] = TextEditingController(text: '50');
        _controllers['coats'] = TextEditingController(text: '2');
        _controllers['coverage'] = TextEditingController(text: '10');
        break;
      case 51: // Cement
      case 54: // Concrete
        _controllers['vol'] = TextEditingController(text: '1.0');
        _controllers['cementRatio'] = TextEditingController(text: '1');
        _controllers['sandRatio'] = TextEditingController(text: '1.5');
        _controllers['aggRatio'] = TextEditingController(text: '3');
        break;
      case 58: // Steel weight
        _controllers['dia'] = TextEditingController(text: '12');
        _controllers['len'] = TextEditingController(text: '12');
        break;
      case 76: // BOQ Builder
      case 81: // Material Cost
        _controllers['qty'] = TextEditingController(text: '100');
        _controllers['rate'] = TextEditingController(text: '380');
        _controllers['tax'] = TextEditingController(text: '18');
        break;
      case 82: // Labour Cost
        _controllers['workers'] = TextEditingController(text: '10');
        _controllers['days'] = TextEditingController(text: '5');
        _controllers['wage'] = TextEditingController(text: '800');
        break;
      case 88: // Cost per sqft
        _controllers['cost'] = TextEditingController(text: '2400000');
        _controllers['area'] = TextEditingController(text: '1200');
        break;
      case 129: // Water demand
        _controllers['occupants'] = TextEditingController(text: '5');
        _controllers['lpcd'] = TextEditingController(text: '135');
        break;
      case 130: // Water Tank
        _controllers['l'] = TextEditingController(text: '2.0');
        _controllers['w'] = TextEditingController(text: '1.5');
        _controllers['h'] = TextEditingController(text: '1.5');
        break;
      default:
        _controllers['v1'] = TextEditingController(text: '10');
        _controllers['v2'] = TextEditingController(text: '20');
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _val(String key) => double.tryParse(_controllers[key]?.text ?? '0') ?? 0.0;

  void _calculate() {
    setState(() {
      switch (widget.tool.id) {
        case 1: // Unit Convert
          final v = _val('val');
          double inMeters = 0;
          if (_selectedUnitFrom == 'feet') inMeters = v * 0.3048;
          else if (_selectedUnitFrom == 'inch') inMeters = v * 0.0254;
          else inMeters = v;

          double res = inMeters;
          if (_selectedUnitTo == 'feet') res = inMeters / 0.3048;
          else if (_selectedUnitTo == 'inch') res = inMeters / 0.0254;

          _resultValue = res.toStringAsFixed(3);
          _resultUnit = _selectedUnitTo.toUpperCase();
          _resultExtra = '$v $_selectedUnitFrom = ${_resultValue} $_selectedUnitTo';
          break;

        case 2: // Area
          if (_selectedShape == 'rect') {
            final a = _val('l') * _val('w');
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Rectangle: ${_val('l')}m × ${_val('w')}m';
          } else if (_selectedShape == 'tri') {
            final a = 0.5 * _val('l') * _val('h');
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Triangle: 0.5 × Base × Height';
          } else {
            final a = math.pi * math.pow(_val('r'), 2);
            _resultValue = a.toStringAsFixed(2);
            _resultUnit = 'sq.m (m²)';
            _resultExtra = 'Circle: π × r² (radius: ${_val('r')}m)';
          }
          break;

        case 6: // Drawing Scale
          final d = _val('drawing');
          final s = _val('scale');
          final realMeters = (d * s) / 1000.0;
          _resultValue = '${realMeters.toStringAsFixed(2)} m';
          _resultUnit = 'Real World Length';
          _resultExtra = 'Scale 1:$s for ${d}mm on drawing';
          break;

        case 8: // Slope
          final rise = _val('rise');
          final run = _val('run');
          if (run > 0) {
            final pct = (rise / run) * 100;
            final deg = math.atan(rise / run) * (180 / math.pi);
            _resultValue = '${pct.toStringAsFixed(2)} %';
            _resultUnit = 'Gradient / Slope';
            _resultExtra = 'Ratio 1:${(run / rise).toStringAsFixed(1)} • Angle: ${deg.toStringAsFixed(1)}°';
          }
          break;

        case 17: // Built-up Area
          final c = _val('carpet');
          final w = _val('walls');
          _resultValue = (c + w).toStringAsFixed(2);
          _resultUnit = 'sq.m Built-up Area';
          _resultExtra = 'Carpet (${c}m²) + Walls & Balconies (${w}m²)';
          break;

        case 19: // FSI / FAR
          final f = _val('floor');
          final p = _val('plot');
          if (p > 0) {
            _resultValue = (f / p).toStringAsFixed(2);
            _resultUnit = 'FSI / FAR Index';
            _resultExtra = 'Total Covered Floor Area / Plot Area';
          }
          break;

        case 22: // Staircase
          final h = _val('height');
          final r = _val('riser');
          final t = _val('tread');
          if (r > 0) {
            final risers = (h / r).ceil();
            final treads = risers - 1;
            final totalRun = treads * t;
            _resultValue = '$risers Risers';
            _resultUnit = 'Staircase Dimensions';
            _resultExtra = '$treads Treads • Total Run: ${totalRun.toStringAsFixed(2)} m';
          }
          break;

        case 28: // Excavation
        case 32: // Slab Concrete
          final vol = _val('l') * _val('w') * _val('d') * (_val('qty') > 0 ? _val('qty') : 1.0);
          _resultValue = '${vol.toStringAsFixed(2)} m³';
          _resultUnit = 'Total Volume';
          _resultExtra = 'Approx ${(vol * 35.3147).toStringAsFixed(1)} cubic feet (cft)';
          break;

        case 36: // Brickwork
          final vol = _val('l') * _val('h') * _val('t');
          final bricks = (vol * 500).ceil();
          _resultValue = '$bricks Bricks';
          _resultUnit = 'Masonry Material';
          _resultExtra = 'Wall volume: ${vol.toStringAsFixed(2)} m³ (at 500 bricks/m³)';
          break;

        case 41: // Tile Calculator
          final a = _val('area');
          final s = _val('tileSize');
          final w = _val('waste');
          if (s > 0) {
            final tileArea = s * s;
            final count = (a / tileArea) * (1 + w / 100.0);
            _resultValue = '${count.ceil()} Tiles';
            _resultUnit = 'Total Tiles Required';
            _resultExtra = 'Includes $w% cutting & breakage wastage';
          }
          break;

        case 43: // Painting
          final a = _val('area');
          final coats = _val('coats');
          final cov = _val('coverage');
          if (cov > 0) {
            final litres = (a * coats) / cov;
            _resultValue = '${litres.toStringAsFixed(1)} Litres';
            _resultUnit = 'Paint Required';
            _resultExtra = 'For $coats coats over ${a}m² surface';
          }
          break;

        case 51: // Cement Bags
        case 54: // Concrete Material
          final v = _val('vol');
          final c = _val('cementRatio');
          final s = _val('sandRatio');
          final a = _val('aggRatio');
          final total = c + s + a;
          final dryVol = v * 1.54; // Standard dry volume factor
          if (total > 0) {
            final cementM3 = (c / total) * dryVol;
            final bags = (cementM3 * 1440.0 / 50.0).ceil(); // 1440 kg/m3 density, 50kg bag
            final sandM3 = (s / total) * dryVol;
            final aggM3 = (a / total) * dryVol;
            _resultValue = '$bags Bags';
            _resultUnit = 'Cement (50 kg bags)';
            _resultExtra = 'Sand: ${sandM3.toStringAsFixed(2)} m³ • Aggregates: ${aggM3.toStringAsFixed(2)} m³';
          }
          break;

        case 58: // Steel Weight
          final dia = _val('dia');
          final len = _val('len');
          final wtPerM = (dia * dia) / 162.0;
          final totalWt = wtPerM * len;
          _resultValue = '${totalWt.toStringAsFixed(2)} kg';
          _resultUnit = 'Reinforcement Steel Weight';
          _resultExtra = 'D²/162 formula: ${wtPerM.toStringAsFixed(3)} kg/meter';
          break;

        case 76: // BOQ Builder
        case 81: // Material Cost
          final q = _val('qty');
          final r = _val('rate');
          final t = _val('tax');
          final base = q * r;
          final total = base * (1 + t / 100.0);
          _resultValue = '₹ ${total.toStringAsFixed(0)}';
          _resultUnit = 'Total Estimated Cost';
          _resultExtra = 'Base: ₹${base.toStringAsFixed(0)} + $t% GST/Overheads';
          break;

        case 82: // Labour Cost
          final w = _val('workers');
          final d = _val('days');
          final wage = _val('wage');
          final total = w * d * wage;
          _resultValue = '₹ ${total.toStringAsFixed(0)}';
          _resultUnit = 'Labour Expenditure';
          _resultExtra = '$w workers for $d days at ₹$wage/day';
          break;

        case 88: // Cost per sqft
          final cost = _val('cost');
          final area = _val('area');
          if (area > 0) {
            final rate = cost / area;
            _resultValue = '₹ ${rate.toStringAsFixed(1)} / sq.ft';
            _resultUnit = 'Unit Rate';
            _resultExtra = 'Total ₹${cost.toStringAsFixed(0)} for ${area.toStringAsFixed(0)} sq.ft';
          }
          break;

        case 129: // Water Demand
          final occ = _val('occupants');
          final lpcd = _val('lpcd');
          final totalL = occ * lpcd;
          _resultValue = '${totalL.toStringAsFixed(0)} Litres / day';
          _resultUnit = 'Daily Water Consumption';
          _resultExtra = '$occ persons at $lpcd Litres per capita per day (NBC)';
          break;

        case 130: // Water Tank Volume
          final l = _val('l');
          final w = _val('w');
          final h = _val('h');
          final vol = l * w * h;
          final litres = vol * 1000.0;
          _resultValue = '${litres.toStringAsFixed(0)} Litres';
          _resultUnit = 'Tank Capacity';
          _resultExtra = 'Physical Dimensions: ${vol.toStringAsFixed(2)} m³ volume';
          break;

        default:
          final v1 = _val('v1');
          final v2 = _val('v2');
          _resultValue = (v1 * v2).toStringAsFixed(2);
          _resultUnit = 'Output Result';
          _resultExtra = 'Calculation based on inputs $v1 and $v2';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isFav = appState.isFavorite(widget.tool.id);

    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.darkIconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(widget.tool.icon, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tool.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          widget.tool.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.star : Icons.star_border,
                      color: isFav ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => appState.toggleFavorite(widget.tool.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Inputs based on Tool ID
              _buildInputs(),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkPrimary,
                  foregroundColor: const Color(0xFF0A1128),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _calculate,
                icon: const Icon(Icons.calculate),
                label: const Text(
                  'CALCULATE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                ),
              ),

              // Result Card
              if (_resultValue != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkPrimary, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'CALCULATION RESULT',
                        style: TextStyle(fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _resultValue!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_resultUnit != null)
                        Text(
                          _resultUnit!,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      if (_resultExtra != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _resultExtra!,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputs() {
    switch (widget.tool.id) {
      case 1:
        return Column(
          children: [
            _buildField('val', 'Distance / Length Value'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnitFrom,
                    decoration: const InputDecoration(labelText: 'From Unit'),
                    items: const [
                      DropdownMenuItem(value: 'feet', child: Text('Feet')),
                      DropdownMenuItem(value: 'meter', child: Text('Meter')),
                      DropdownMenuItem(value: 'inch', child: Text('Inch')),
                    ],
                    onChanged: (v) => setState(() => _selectedUnitFrom = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnitTo,
                    decoration: const InputDecoration(labelText: 'To Unit'),
                    items: const [
                      DropdownMenuItem(value: 'meter', child: Text('Meter')),
                      DropdownMenuItem(value: 'feet', child: Text('Feet')),
                      DropdownMenuItem(value: 'inch', child: Text('Inch')),
                    ],
                    onChanged: (v) => setState(() => _selectedUnitTo = v!),
                  ),
                ),
              ],
            ),
          ],
        );

      case 2:
      case 3:
        return Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedShape,
              decoration: const InputDecoration(labelText: 'Geometric Shape'),
              items: const [
                DropdownMenuItem(value: 'rect', child: Text('Rectangle / Square')),
                DropdownMenuItem(value: 'tri', child: Text('Triangle')),
                DropdownMenuItem(value: 'circ', child: Text('Circle')),
              ],
              onChanged: (v) => setState(() => _selectedShape = v!),
            ),
            const SizedBox(height: 10),
            if (_selectedShape == 'rect') ...[
              Row(
                children: [
                  Expanded(child: _buildField('l', 'Length (m)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField('w', 'Width (m)')),
                ],
              ),
            ] else if (_selectedShape == 'tri') ...[
              Row(
                children: [
                  Expanded(child: _buildField('l', 'Base (m)')),
                  const SizedBox(width: 10),
                  Expanded(child: _buildField('h', 'Height (m)')),
                ],
              ),
            ] else ...[
              _buildField('r', 'Radius (m)'),
            ],
          ],
        );

      case 6:
        return Row(
          children: [
            Expanded(child: _buildField('drawing', 'Drawing Dimension (mm)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('scale', 'Scale 1:X (e.g. 100)')),
          ],
        );

      case 8:
        return Row(
          children: [
            Expanded(child: _buildField('rise', 'Vertical Rise (m)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('run', 'Horizontal Run (m)')),
          ],
        );

      case 22:
        return Column(
          children: [
            _buildField('height', 'Total Floor Height (m)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('riser', 'Riser Height (e.g. 0.15m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('tread', 'Tread Depth (e.g. 0.28m)')),
              ],
            ),
          ],
        );

      case 28:
      case 32:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('l', 'Length (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('w', 'Width (m)')),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('d', 'Depth / Thickness (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('qty', 'Quantity (Units)')),
              ],
            ),
          ],
        );

      case 36:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('l', 'Wall Length (m)')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('h', 'Wall Height (m)')),
              ],
            ),
            const SizedBox(height: 10),
            _buildField('t', 'Wall Thickness (m, e.g. 0.23m / 9")'),
          ],
        );

      case 51:
      case 54:
        return Column(
          children: [
            _buildField('vol', 'Wet Concrete Volume (m³)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField('cementRatio', 'Cement')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('sandRatio', 'Sand')),
                const SizedBox(width: 8),
                Expanded(child: _buildField('aggRatio', 'Aggregate')),
              ],
            ),
          ],
        );

      case 58:
        return Row(
          children: [
            Expanded(child: _buildField('dia', 'Bar Diameter (mm)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('len', 'Total Bar Length (m)')),
          ],
        );

      case 76:
      case 81:
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildField('qty', 'Quantity')),
                const SizedBox(width: 10),
                Expanded(child: _buildField('rate', 'Rate per Unit (₹)')),
              ],
            ),
            const SizedBox(height: 10),
            _buildField('tax', 'GST & Overheads (%)'),
          ],
        );

      case 88:
        return Row(
          children: [
            Expanded(child: _buildField('cost', 'Total Cost (₹)')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('area', 'Built-up Area (sq.ft)')),
          ],
        );

      case 130:
        return Row(
          children: [
            Expanded(child: _buildField('l', 'Length (m)')),
            const SizedBox(width: 8),
            Expanded(child: _buildField('w', 'Width (m)')),
            const SizedBox(width: 8),
            Expanded(child: _buildField('h', 'Height (m)')),
          ],
        );

      default:
        return Row(
          children: [
            Expanded(child: _buildField('v1', 'Primary Dimension / Qty')),
            const SizedBox(width: 10),
            Expanded(child: _buildField('v2', 'Secondary Factor / Rate')),
          ],
        );
    }
  }

  Widget _buildField(String key, String label) {
    return TextFormField(
      controller: _controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
