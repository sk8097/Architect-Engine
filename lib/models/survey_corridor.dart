class CorridorPoint {
  const CorridorPoint(this.easting, this.northing);
  final int easting, northing;
}

class CorridorStation {
  const CorridorStation(this.point, this.chainageMm);
  final CorridorPoint point;
  final double chainageMm;
  String get label {
    final cm = (chainageMm / 10).round();
    return '${cm ~/ 100000}+${((cm % 100000) / 100).toStringAsFixed(2).padLeft(6,'0')}';
  }
}

class CorridorBand {
  const CorridorBand(this.label, this.widthMm);
  final String label;
  final int widthMm;
}

class SurveyCorridorDrawing {
  SurveyCorridorDrawing({required this.title, required this.grid, required this.reference, required this.widthMm,
    required this.lengthMm, required Iterable<CorridorStation> stations, required Iterable<CorridorBand> bands,
    required Iterable<List<CorridorPoint>> edges})
    : stations = List.unmodifiable(stations), bands = List.unmodifiable(bands),
      edges = List.unmodifiable(edges.map((edge) => List<CorridorPoint>.unmodifiable(edge)));
  final String title, grid, reference;
  final int widthMm;
  final double lengthMm;
  final List<CorridorStation> stations;
  final List<CorridorBand> bands;
  /// Ordered left ROW edge, unique band dividers, right ROW edge.
  final List<List<CorridorPoint>> edges;
}
