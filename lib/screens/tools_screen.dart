import 'package:flutter/material.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final TextEditingController _lenCtrl = TextEditingController(text: '10');
  final TextEditingController _widCtrl = TextEditingController(text: '10');
  double _result = 100.0;

  void _calculate() {
    final l = double.tryParse(_lenCtrl.text) ?? 0.0;
    final w = double.tryParse(_widCtrl.text) ?? 0.0;
    setState(() {
      _result = l * w;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('168 Engineering & Civil Calculators', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Civil engineering, BOQ takeoffs, structural, and architectural tools.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF131C35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('📐', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 10),
                    Text('Area Calculator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lenCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Length (ft / m)', filled: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _widCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Width (ft / m)', filled: true),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5B05C),
                    foregroundColor: const Color(0xFF0A1128),
                  ),
                  onPressed: _calculate,
                  child: const Text('CALCULATE AREA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1128),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5B05C)),
                  ),
                  child: Column(
                    children: [
                      const Text('TOTAL AREA', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text('$_result sq. units', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE5B05C))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
