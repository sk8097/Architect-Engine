/// A local, user-supplied brief. Saving this snapshot is not an approval or
/// a statement that the selected plan can be generated.
class ProjectRequirementsSnapshot {
  ProjectRequirementsSnapshot({
    required this.version,
    Map<String, Object> answers = const {},
    Map<String, String> customSpaces = const {},
    Map<String, Map<String, Object>> spaceDetails = const {},
  }) : answers = _readAnswers(answers),
       customSpaces = Map.unmodifiable(customSpaces),
       spaceDetails = Map.unmodifiable(spaceDetails.map((id, details) =>
           MapEntry(id, _readAnswers(details))));

  final int version;
  final Map<String, Object> answers;
  final Map<String, String> customSpaces;
  final Map<String, Map<String, Object>> spaceDetails;

  Map<String, Object> toMap() => {
    'schemaVersion': version,
    'answers': answers,
    'customSpaces': customSpaces,
    'spaceDetails': spaceDetails,
  };

  static ProjectRequirementsSnapshot? fromMap(Object? source) {
    if (source is! Map<String, dynamic> || source['schemaVersion'] is! int) return null;
    final rooms = source['spaceDetails'];
    final custom = source['customSpaces'];
    return ProjectRequirementsSnapshot(
      version: source['schemaVersion'] as int,
      answers: _readAnswers(source['answers']),
      customSpaces: {
        if (custom is Map<String, dynamic>)
          for (final entry in custom.entries)
            if (entry.value is String) entry.key: entry.value as String,
      },
      spaceDetails: {
        if (rooms is Map<String, dynamic>)
          for (final room in rooms.entries) room.key: _readAnswers(room.value),
      },
    );
  }

  static Map<String, Object> _readAnswers(Object? value) {
    if (value is! Map<String, dynamic>) return const {};
    final result = <String, Object>{};
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is String) {
        result[entry.key] = item;
      } else if (item is num && item.isFinite) {
        result[entry.key] = item;
      } else if (item is List && item.every((option) => option is String)) {
        result[entry.key] = List<String>.unmodifiable(item.whereType<String>());
      }
    }
    return Map.unmodifiable(result);
  }
}
