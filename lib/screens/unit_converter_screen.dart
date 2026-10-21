import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _val = TextEditingController(text: '1000');
  double _factor = 0.0929;
  String _unitName = 'Square Meter';

  @override
  void dispose() {
    _val.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inputVal = double.tryParse(_val.text) ?? 0.0;
    final result = inputVal * _factor;

    return Scaffold(
      appBar: AppBar(title: const Text('Unit Converter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _val,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'From Area (Square Feet / sq.ft)'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              value: _factor,
              decoration: const InputDecoration(labelText: 'Convert To'),
              items: const [
                DropdownMenuItem(value: 0.092903, child: Text('Square Meter (sq.m)')),
                DropdownMenuItem(value: 0.111111, child: Text('Square Yard (Gaj)')),
                DropdownMenuItem(value: 0.0000229568, child: Text('Acre')),
                DropdownMenuItem(value: 0.00091827, child: Text('Guntha')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _factor = v;
                    if (v == 0.092903) _unitName = 'sq.m';
                    else if (v == 0.111111) _unitName = 'Gaj (sq.yd)';
                    else if (v == 0.0000229568) _unitName = 'Acre';
                    else _unitName = 'Guntha';
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('CONVERTED VALUE', style: TextStyle(color: Color(0xFF0A1128), fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(
                    '${result.toStringAsFixed(4)} $_unitName',
                    style: const TextStyle(color: Color(0xFF0A1128), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
