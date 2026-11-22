/// One measured finish surface or run. Deductions apply per identical repeat.
class FinishMeasurement {
  const FinishMeasurement({required this.location, required this.kind, required this.material,
    required this.length, this.width, this.deduction = 0, this.count = 1, this.waste = 0});

  static const kinds = <String, String>{
    'floor': 'Floor', 'wall': 'Wall face', 'ceiling': 'Ceiling', 'roof': 'Roof face',
    'facade': 'Façade face', 'paving': 'Paving / site surface', 'coating': 'Coating surface',
    'skirting': 'Skirting', 'trim': 'Trim / edge', 'marking': 'Linear marking',
  };
  static bool linear(String kind) => const {'skirting', 'trim', 'marking'}.contains(kind);
  static const maxRows = 120;

  final String location, kind, material;
  final double length, deduction, waste;
  final double? width;
  final int count;

  bool get isLinear => linear(kind);
  String get unit => isLinear ? 'm' : 'm²';
  double get grossPerItem => length * (width ?? 1);
  double get gross => grossPerItem * count;
  double get net => (grossPerItem - deduction) * count;
  double get allowance => net * (1 + waste / 100);

  String? get issue {
    if (!kinds.containsKey(kind)) return 'Select a supported finish surface or run.';
    if (location.trim().isEmpty || material.trim().isEmpty || location.length > 100 || material.length > 100 ||
        RegExp(r'[\x00-\x1f]').hasMatch('$location$material')) {
      return 'Enter a location and material code, each on one line and at most 100 characters.';
    }
    if (!_dimension(length) || (isLinear ? width != null : width == null || !_dimension(width!))) {
      return 'Enter measured dimensions between 0.001 m and 20,000 m; linear runs have no width.';
    }
    if (count < 1 || count > 10000) return 'Repeat count must be from 1 to 10,000.';
    if (!deduction.isFinite || deduction < 0 || deduction >= grossPerItem) {
      return 'Deduction per item must be nonnegative and smaller than the gross measurement.';
    }
    if (!waste.isFinite || waste < 0 || waste > 100) return 'Waste allowance must be between 0 and 100%.';
    return null;
  }

  static bool _dimension(double n) => n.isFinite && n >= .001 && n <= 20000;

  Map<String, Object> toMap() => {
    'location': location, 'kind': kind, 'material': material, 'length': length,
    if (width != null) 'width': width!, 'deduction': deduction, 'count': count, 'waste': waste,
  };

  static FinishMeasurement? fromMap(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final location = raw['location'], kind = raw['kind'], material = raw['material'];
    final length = raw['length'], width = raw['width'], deduction = raw['deduction'], count = raw['count'], waste = raw['waste'];
    if (location is! String || kind is! String || material is! String || length is! num ||
        (width != null && width is! num) || deduction is! num || count is! int || waste is! num) return null;
    final row = FinishMeasurement(location: location, kind: kind, material: material, length: length.toDouble(),
      width: (width as num?)?.toDouble(), deduction: deduction.toDouble(), count: count, waste: waste.toDouble());
    return row.issue == null ? row : null;
  }
}
