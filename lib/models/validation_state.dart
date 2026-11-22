enum InputStatus { complete, incomplete }

enum CapabilityStatus { supported, unsupportedConfiguration }

enum RuleStatus { unverified }

enum GeometryStatus { valid, blocked, notRun }

enum GenerationStatus { notRun, completed, failed, blocked }

class ValidationIssue {
  const ValidationIssue({required this.fieldId, required this.message});
  final String fieldId;
  final String message;
}

class ProjectValidationReport {
  const ProjectValidationReport({
    required this.inputStatus,
    required this.capabilityStatus,
    this.ruleStatus = RuleStatus.unverified,
    this.geometryStatus = GeometryStatus.notRun,
    this.generationStatus = GenerationStatus.notRun,
    this.warnings = const [],
    this.errors = const [],
  });

  final InputStatus inputStatus;
  final CapabilityStatus capabilityStatus;
  final RuleStatus ruleStatus;
  final GeometryStatus geometryStatus;
  final GenerationStatus generationStatus;
  final List<String> warnings;
  final List<ValidationIssue> errors;

  bool get canSaveDraft => true;

  bool get canGenerate =>
      inputStatus == InputStatus.complete &&
      capabilityStatus == CapabilityStatus.supported &&
      geometryStatus != GeometryStatus.blocked;
}
