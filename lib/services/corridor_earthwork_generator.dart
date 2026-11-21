import '../models/project_brief.dart';
import '../models/project_requirements_snapshot.dart';
import 'corridor_section_generator.dart';
import 'floor_plan_cad.dart';

class EarthworkInterval {
  const EarthworkInterval(this.start, this.end);
  final CorridorSectionResult start, end;
  double get lengthM => (end.chainageMm - start.chainageMm) / 1000;
  double get cutM3 => (start.cutM2 + end.cutM2) / 2 * lengthM;
  double get fillM3 => (start.fillM2 + end.fillM2) / 2 * lengthM;
}

class CorridorEarthworkResult {
  const CorridorEarthworkResult({this.issue, this.drawing, this.sections = const [], this.intervals = const []});
  final String? issue;
  final FloorPlanCad? drawing;
  final List<CorridorSectionResult> sections;
  final List<EarthworkInterval> intervals;
  double get totalCutM3 => intervals.fold<double>(0.0, (sum, item) => sum + item.cutM3);
  double get totalFillM3 => intervals.fold<double>(0.0, (sum, item) => sum + item.fillM3);

  /// Unrounded calculations stay in the model; the exported schedule shows
  /// three decimal places. Totals are not sums of the rounded CSV cells.
  String? toCsv() {
    if (drawing == null) return null;
    String n(num value) => value.toStringAsFixed(3);
    final rows = <String>[
      'row_type,start_chainage_m,end_chainage_m,length_m,start_cut_m2,end_cut_m2,start_fill_m2,end_fill_m2,estimated_cut_m3,estimated_fill_m3',
      for (final i in intervals) [
        'interval', n(i.start.chainageMm / 1000), n(i.end.chainageMm / 1000), n(i.lengthM),
        n(i.start.cutM2), n(i.end.cutM2), n(i.start.fillM2), n(i.end.fillM2), n(i.cutM3), n(i.fillM3),
      ].join(','),
      ['total', n(sections.first.chainageMm / 1000), n(sections.last.chainageMm / 1000),
        n((sections.last.chainageMm - sections.first.chainageMm) / 1000), '', '', '', '', n(totalCutM3), n(totalFillM3)].join(','),
    ];
    return '${rows.join('\r\n')}\r\n';
  }
}

/// Estimate between explicit stations only, using separate average-end areas
/// for excavation and fill. No alignment correction or material factors.
class CorridorEarthworkGenerator {
  static bool requested(ProjectBrief? brief) => brief?.requirements?.answers['corridor_cad_mode'] == 'survey_earthwork';

  CorridorEarthworkResult generate(ProjectBrief brief) {
    CorridorEarthworkResult stop(String issue) => CorridorEarthworkResult(issue: issue);
    final source = brief.requirements;
    if (source == null) return stop('Save the current earthwork survey brief first.');
    final a = source.answers;
    final pattern = RegExp(r'^\+?(?:\d+(?:\.\d{1,3})?|\.\d{1,3})$');
    (Map<int, List<String>>?, String?) group(Object? raw, String label, int maxPoints) {
      if (raw is! String || raw.trim().isEmpty || raw.length > 80000) {
        return (null, 'Enter the $label chainage,offset,level rows (maximum 80,000 characters).');
      }
      final result = <int, List<String>>{};
      var previous = -1;
      var row = 0;
      for (final entry in raw.split(RegExp(r'[;\r\n]+'))) {
        if (entry.trim().isEmpty) continue;
        row++;
        final fields = entry.split(',').map((v) => v.trim()).toList();
        final ch = fields.length == 3 && pattern.hasMatch(fields.first) ? double.tryParse(fields.first) : null;
        if (ch == null || !ch.isFinite || ch > 1000000) {
          return (null, '$label row $row: enter chainage,offset,level in metres with chainage from 0 to 1,000,000 m at millimetre precision.');
        }
        final chainage = (ch * 1000).round();
        if (chainage < previous) return (null, '$label row $row: group points by increasing chainage.');
        previous = chainage;
        final points = result.putIfAbsent(chainage, () => []);
        points.add('${fields[1]},${fields[2]}');
        if (points.length > maxPoints) return (null, '$label chainage ${_m(chainage)} m exceeds $maxPoints points.');
        if (result.length > 20) return (null, 'Limit each earthwork takeoff to 20 stations.');
      }
      if (result.length < 2) return (null, 'Enter at least two distinct $label chainages.');
      return (result, null);
    }

    final (ground, groundIssue) = group(a['ew_ground'], 'Surveyed', 150);
    if (ground == null) return stop(groundIssue!);
    final (design, designIssue) = group(a['ew_design'], 'Proposed', 80);
    if (design == null) return stop(designIssue!);
    for (final (left, right, label) in [(ground, design, 'proposed'), (design, ground, 'surveyed')]) {
      for (final ch in left.keys) {
        if (!right.containsKey(ch)) return stop('Chainage ${_m(ch)} m is missing from the $label list. Use matching station sets.');
      }
    }
    if (ground.keys.last - ground.keys.first > 20000000) return stop('Limit the takeoff to a 20 km chainage span.');
    final generator = CorridorSectionGenerator();
    final sections = <CorridorSectionResult>[];
    for (final ch in ground.keys) {
      final section = generator.generate(ProjectBrief(
        taxonomy: brief.taxonomy, floorCount: brief.floorCount, parking: brief.parking, features: brief.features,
        requirements: ProjectRequirementsSnapshot(version: source.version, answers: {
          'section_chainage': ch / 1000,
          'section_ground': ground[ch]!.join(';'),
          'section_design': design[ch]!.join(';'),
          if (a['ew_reference'] case final ref?) 'section_reference': ref,
          if (a['ew_exaggeration'] case final scale?) 'section_exaggeration': scale,
        }),
      ), sheetSet: true);
      if (section.drawing == null) return stop('Chainage ${_m(ch)} m: ${section.issue}');
      sections.add(section);
    }
    return CorridorEarthworkResult(
      sections: List.unmodifiable(sections),
      intervals: List.unmodifiable([
        for (var i = 1; i < sections.length; i++) EarthworkInterval(sections[i - 1], sections[i]),
      ]),
      drawing: FloorPlanCad.combined(sections.map((s) => s.drawing!)),
    );
  }

  String _m(int mm) => (mm / 1000).toStringAsFixed(3);
}
