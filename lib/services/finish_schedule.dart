import '../models/finish_measurement.dart';

typedef FinishTotal = ({String material, String unit, double net, double allowance});

/// No quantities are inferred from room names or CAD that has not been measured.
class FinishSchedule {
  FinishSchedule(Iterable<FinishMeasurement> rows) : rows = List.unmodifiable(rows);
  final List<FinishMeasurement> rows;

  String? get issue {
    if (rows.length > FinishMeasurement.maxRows) return 'Too many finish rows.';
    for (var i = 0; i < rows.length; i++) {
      final issue = rows[i].issue;
      if (issue != null) return 'Row ${i + 1}: $issue';
    }
    return null;
  }

  List<FinishTotal> get totals {
    if (issue != null) return const [];
    final groups = <(String, String), FinishTotal>{};
    for (final row in rows) {
      final material = row.material.trim(), key = (row.material.trim().toLowerCase(), row.unit);
      final total = groups[key];
      groups[key] = (material: total?.material ?? material, unit: row.unit,
        net: (total?.net ?? 0) + row.net, allowance: (total?.allowance ?? 0) + row.allowance);
    }
    return List.unmodifiable(groups.values);
  }

  String? toCsv() {
    if (rows.isEmpty || issue != null) return null;
    String text(String raw) {
      final safe = RegExp(r'^\s*[=+\-@\uFF1D\uFF0B\uFF0D\uFF20]').hasMatch(raw) ? "'$raw" : raw;
      return '"${safe.replaceAll('"', '""')}"';
    }
    String n(double value) => value.toStringAsFixed(6);
    return [
      'record,location,surface,material,unit,length_m,width_m,deduction_each,count,gross,net,waste_pct,with_allowance',
      for (final row in rows) [
        'measurement', text(row.location), text(FinishMeasurement.kinds[row.kind]!), text(row.material), text(row.unit),
        n(row.length), if (row.width != null) n(row.width!) else '', n(row.deduction), '${row.count}', n(row.gross),
        n(row.net), n(row.waste), n(row.allowance),
      ].join(','),
      for (final total in totals) [
        'total', '', '', text(total.material), text(total.unit), '', '', '', '', '', n(total.net), '', n(total.allowance),
      ].join(','),
      '',
    ].join('\r\n');
  }
}
